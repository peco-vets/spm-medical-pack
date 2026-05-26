---
name: laravel-patterns
description: 本番アプリケーション向け Laravel アーキテクチャパターン、ルーティング/コントローラ、Eloquent ORM、サービス層、キュー、イベント、キャッシュ、API リソース (Laravel architecture patterns, routing/controllers, Eloquent ORM, service layers, queues, events, caching, API resources for production apps)。
origin: ECC
---

# Laravel 開発パターン

スケーラブルで保守可能なアプリケーションのための本番グレード Laravel アーキテクチャパターン。

## 使用するタイミング

- Laravel Web アプリケーションや API を構築する場合
- コントローラ、サービス、ドメインロジックを構造化する場合
- Eloquent モデルとリレーションを扱う場合
- リソースとページネーションで API を設計する場合
- キュー、イベント、キャッシュ、バックグラウンドジョブを追加する場合

## 動作の仕組み

- 明確な境界 (コントローラ -> サービス/アクション -> モデル) を中心にアプリを構造化する
- ルーティングを予測可能に保つために明示的バインディングとスコープバインディングを使う。それでもアクセス制御には認可を強制する
- ドメインロジックを一貫させるために、型付きモデル、キャスト、スコープを優先する
- IO 重い作業はキューに入れ、高コストな読み取りはキャッシュする
- 設定は `config/*` に集約し、環境を明示する

## 例

### プロジェクト構成

明確な層境界 (HTTP、サービス/アクション、モデル) を持つ慣習的な Laravel レイアウトを使う。

### 推奨レイアウト

```
app/
├── Actions/            # Single-purpose use cases
├── Console/
├── Events/
├── Exceptions/
├── Http/
│   ├── Controllers/
│   ├── Middleware/
│   ├── Requests/       # Form request validation
│   └── Resources/      # API resources
├── Jobs/
├── Models/
├── Policies/
├── Providers/
├── Services/           # Coordinating domain services
└── Support/
config/
database/
├── factories/
├── migrations/
└── seeders/
resources/
├── views/
└── lang/
routes/
├── api.php
├── web.php
└── console.php
```

### コントローラ -> サービス -> アクション

コントローラは薄く保つ。オーケストレーションはサービスに、単一目的のロジックはアクションに置く。

```php
final class CreateOrderAction
{
    public function __construct(private OrderRepository $orders) {}

    public function handle(CreateOrderData $data): Order
    {
        return $this->orders->create($data);
    }
}

final class OrdersController extends Controller
{
    public function __construct(private CreateOrderAction $createOrder) {}

    public function store(StoreOrderRequest $request): JsonResponse
    {
        $order = $this->createOrder->handle($request->toDto());

        return response()->json([
            'success' => true,
            'data' => OrderResource::make($order),
            'error' => null,
            'meta' => null,
        ], 201);
    }
}
```

### ルーティングとコントローラ

明瞭性のためにルートモデルバインディングとリソースコントローラを優先する。

```php
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('projects', ProjectController::class);
});
```

### ルートモデルバインディング (スコープ付き)

テナント横断アクセスを防ぐためにスコープバインディングを使う。

```php
Route::scopeBindings()->group(function () {
    Route::get('/accounts/{account}/projects/{project}', [ProjectController::class, 'show']);
});
```

### ネストルートとバインディング名

- 二重ネストを避けるためにプレフィックスとパスを一貫させる (例: `conversation` 対 `conversations`)
- バインドされたモデルに合う単一パラメータ名を使う (例: `Conversation` に対して `{conversation}`)
- 親子関係を強制するためにネスト時はスコープバインディングを優先する

```php
use App\Http\Controllers\Api\ConversationController;
use App\Http\Controllers\Api\MessageController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->prefix('conversations')->group(function () {
    Route::post('/', [ConversationController::class, 'store'])->name('conversations.store');

    Route::scopeBindings()->group(function () {
        Route::get('/{conversation}', [ConversationController::class, 'show'])
            ->name('conversations.show');

        Route::post('/{conversation}/messages', [MessageController::class, 'store'])
            ->name('conversation-messages.store');

        Route::get('/{conversation}/messages/{message}', [MessageController::class, 'show'])
            ->name('conversation-messages.show');
    });
});
```

パラメータを異なるモデルクラスに解決させたい場合は、明示的バインディングを定義する。カスタムバインディングロジックには `Route::bind()` を使うか、モデル上に `resolveRouteBinding()` を実装する。

```php
use App\Models\AiConversation;
use Illuminate\Support\Facades\Route;

Route::model('conversation', AiConversation::class);
```

### サービスコンテナバインディング

明確な依存関係配線のために、サービスプロバイダ内でインターフェースを実装にバインドする。

```php
use App\Repositories\EloquentOrderRepository;
use App\Repositories\OrderRepository;
use Illuminate\Support\ServiceProvider;

final class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(OrderRepository::class, EloquentOrderRepository::class);
    }
}
```

### Eloquent モデルパターン

### モデル設定

```php
final class Project extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'owner_id', 'status'];

    protected $casts = [
        'status' => ProjectStatus::class,
        'archived_at' => 'datetime',
    ];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->whereNull('archived_at');
    }
}
```

### カスタムキャストと値オブジェクト

厳密な型付けには enum や値オブジェクトを使う。

```php
use Illuminate\Database\Eloquent\Casts\Attribute;

protected $casts = [
    'status' => ProjectStatus::class,
];
```

```php
protected function budgetCents(): Attribute
{
    return Attribute::make(
        get: fn (int $value) => Money::fromCents($value),
        set: fn (Money $money) => $money->toCents(),
    );
}
```

### N+1 を避けるための Eager Loading

```php
$orders = Order::query()
    ->with(['customer', 'items.product'])
    ->latest()
    ->paginate(25);
```

### 複雑なフィルタのためのクエリオブジェクト

```php
final class ProjectQuery
{
    public function __construct(private Builder $query) {}

    public function ownedBy(int $userId): self
    {
        $query = clone $this->query;

        return new self($query->where('owner_id', $userId));
    }

    public function active(): self
    {
        $query = clone $this->query;

        return new self($query->whereNull('archived_at'));
    }

    public function builder(): Builder
    {
        return $this->query;
    }
}
```

### グローバルスコープと論理削除

デフォルトフィルタにはグローバルスコープを、回復可能レコードには `SoftDeletes` を使う。
同じフィルタにはグローバルスコープか名前付きスコープのどちらか一方を使い、層化された振る舞いを意図しない限り両方を使わない。

```php
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Builder;

final class Project extends Model
{
    use SoftDeletes;

    protected static function booted(): void
    {
        static::addGlobalScope('active', function (Builder $builder): void {
            $builder->whereNull('archived_at');
        });
    }
}
```

### 再利用可能フィルタのためのクエリスコープ

```php
use Illuminate\Database\Eloquent\Builder;

final class Project extends Model
{
    public function scopeOwnedBy(Builder $query, int $userId): Builder
    {
        return $query->where('owner_id', $userId);
    }
}

// In service, repository etc.
$projects = Project::ownedBy($user->id)->get();
```

### マルチステップ更新のためのトランザクション

```php
use Illuminate\Support\Facades\DB;

DB::transaction(function (): void {
    $order->update(['status' => 'paid']);
    $order->items()->update(['paid_at' => now()]);
});
```

### マイグレーション

### 命名規約

- ファイル名はタイムスタンプを使用: `YYYY_MM_DD_HHMMSS_create_users_table.php`
- マイグレーションは匿名クラスを使用 (名前付きクラスなし); ファイル名が意図を伝える
- テーブル名はデフォルトで `snake_case` で複数形

### マイグレーション例

```php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->string('status', 32)->index();
            $table->unsignedInteger('total_cents');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```

### フォームリクエストとバリデーション

バリデーションはフォームリクエスト内に保ち、入力を DTO に変換する。

```php
use App\Models\Order;

final class StoreOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can('create', Order::class) ?? false;
    }

    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'integer', 'exists:customers,id'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.sku' => ['required', 'string'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ];
    }

    public function toDto(): CreateOrderData
    {
        return new CreateOrderData(
            customerId: (int) $this->validated('customer_id'),
            items: $this->validated('items'),
        );
    }
}
```

### API リソース

リソースとページネーションで API レスポンスを一貫させる。

```php
$projects = Project::query()->active()->paginate(25);

return response()->json([
    'success' => true,
    'data' => ProjectResource::collection($projects->items()),
    'error' => null,
    'meta' => [
        'page' => $projects->currentPage(),
        'per_page' => $projects->perPage(),
        'total' => $projects->total(),
    ],
]);
```

### イベント、ジョブ、キュー

- 副作用 (メール、アナリティクス) にはドメインイベントを発行する
- 遅い作業 (レポート、エクスポート、Webhook) にはキューイングされたジョブを使う
- リトライとバックオフを伴う冪等ハンドラを優先する

### キャッシュ

- 読み取り集中型エンドポイントと高コストなクエリをキャッシュする
- モデルイベント (created/updated/deleted) でキャッシュを無効化する
- 関連データをキャッシュする場合は容易な無効化のためにタグを使う

### 設定と環境

- シークレットは `.env` に、設定は `config/*.php` に保つ
- 環境ごとの設定オーバーライドと本番での `config:cache` を使う

---
name: laravel-tdd
description: PHPUnit と Pest を用いた Laravel のテスト駆動開発、ファクトリ、データベーステスト、フェイク、カバレッジ目標 (Test-driven development for Laravel with PHPUnit and Pest, factories, database testing, fakes, coverage targets)。
origin: ECC
---

# Laravel TDD ワークフロー

PHPUnit と Pest を使用した Laravel アプリケーションのテスト駆動開発。80% 以上のカバレッジ (ユニット + フィーチャー) を目標とする。

## 使用するタイミング

- Laravel での新機能やエンドポイント
- バグ修正やリファクタリング
- Eloquent モデル、ポリシー、ジョブ、通知のテスト
- プロジェクトが PHPUnit に標準化されていない限り、新規テストには Pest を優先する

## 動作の仕組み

### Red-Green-Refactor サイクル

1) 失敗するテストを書く
2) 通すための最小変更を実装する
3) テストをグリーンに保ったままリファクタリングする

### テスト層

- **ユニット**: 純 PHP クラス、値オブジェクト、サービス
- **フィーチャー**: HTTP エンドポイント、認証、バリデーション、ポリシー
- **統合**: データベース + キュー + 外部境界

スコープに基づいて層を選ぶ。

- 純粋なビジネスロジックとサービスには **ユニット** テストを使う
- HTTP、認証、バリデーション、レスポンス形状には **フィーチャー** テストを使う
- DB/キュー/外部サービスを併せて検証する場合は **統合** テストを使う

### データベース戦略

- ほとんどのフィーチャー/統合テストには `RefreshDatabase` (テスト実行ごとに 1 回マイグレーションを実行し、サポートされる場合は各テストをトランザクションでラップする。インメモリ DB はテストごとに再マイグレーション)
- スキーマが既にマイグレーションされ、テストごとのロールバックのみが必要な場合は `DatabaseTransactions`
- すべてのテストで完全な migrate/fresh が必要で、そのコストを許容できる場合は `DatabaseMigrations`

DB に触れるテストのデフォルトとして `RefreshDatabase` を使う。トランザクションをサポートする DB では、テスト実行ごとに 1 回マイグレーションを実行し (静的フラグ経由)、各テストをトランザクションでラップする。`:memory:` SQLite やトランザクションのない接続では、各テスト前にマイグレーションする。スキーマが既にマイグレーションされ、テストごとのロールバックのみが必要な場合は `DatabaseTransactions` を使う。

### テストフレームワークの選択

- 利用可能であれば新規テストには **Pest** をデフォルトとする
- プロジェクトが PHPUnit に標準化されているか、PHPUnit 固有のツーリングが必要な場合のみ **PHPUnit** を使う

## 例

### PHPUnit の例

```php
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class ProjectControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_can_create_project(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/projects', [
            'name' => 'New Project',
        ]);

        $response->assertCreated();
        $this->assertDatabaseHas('projects', ['name' => 'New Project']);
    }
}
```

### フィーチャーテスト例 (HTTP 層)

```php
use App\Models\Project;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class ProjectIndexTest extends TestCase
{
    use RefreshDatabase;

    public function test_projects_index_returns_paginated_results(): void
    {
        $user = User::factory()->create();
        Project::factory()->count(3)->for($user)->create();

        $response = $this->actingAs($user)->getJson('/api/projects');

        $response->assertOk();
        $response->assertJsonStructure(['success', 'data', 'error', 'meta']);
    }
}
```

### Pest の例

```php
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\assertDatabaseHas;

uses(RefreshDatabase::class);

test('owner can create project', function () {
    $user = User::factory()->create();

    $response = actingAs($user)->postJson('/api/projects', [
        'name' => 'New Project',
    ]);

    $response->assertCreated();
    assertDatabaseHas('projects', ['name' => 'New Project']);
});
```

### フィーチャーテスト Pest 例 (HTTP 層)

```php
use App\Models\Project;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

use function Pest\Laravel\actingAs;

uses(RefreshDatabase::class);

test('projects index returns paginated results', function () {
    $user = User::factory()->create();
    Project::factory()->count(3)->for($user)->create();

    $response = actingAs($user)->getJson('/api/projects');

    $response->assertOk();
    $response->assertJsonStructure(['success', 'data', 'error', 'meta']);
});
```

### ファクトリとステート

- テストデータにはファクトリを使う
- エッジケース (archived、admin、trial) にはステートを定義する

```php
$user = User::factory()->state(['role' => 'admin'])->create();
```

### データベーステスト

- クリーン状態のために `RefreshDatabase` を使う
- テストを分離して決定論的に保つ
- 手動クエリよりも `assertDatabaseHas` を優先する

### 永続性テスト例

```php
use App\Models\Project;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class ProjectRepositoryTest extends TestCase
{
    use RefreshDatabase;

    public function test_project_can_be_retrieved_by_slug(): void
    {
        $project = Project::factory()->create(['slug' => 'alpha']);

        $found = Project::query()->where('slug', 'alpha')->firstOrFail();

        $this->assertSame($project->id, $found->id);
    }
}
```

### 副作用のためのフェイク

- ジョブには `Bus::fake()`
- キューイング作業には `Queue::fake()`
- 通知には `Mail::fake()` と `Notification::fake()`
- ドメインイベントには `Event::fake()`

```php
use Illuminate\Support\Facades\Queue;

Queue::fake();

dispatch(new SendOrderConfirmation($order->id));

Queue::assertPushed(SendOrderConfirmation::class);
```

```php
use Illuminate\Support\Facades\Notification;

Notification::fake();

$user->notify(new InvoiceReady($invoice));

Notification::assertSentTo($user, InvoiceReady::class);
```

### 認証テスト (Sanctum)

```php
use Laravel\Sanctum\Sanctum;

Sanctum::actingAs($user);

$response = $this->getJson('/api/projects');
$response->assertOk();
```

### HTTP と外部サービス

- 外部 API を分離するために `Http::fake()` を使う
- `Http::assertSent()` でアウトバウンドペイロードをアサート

### カバレッジ目標

- ユニット + フィーチャーテストで 80% 以上のカバレッジを強制する
- CI では `pcov` または `XDEBUG_MODE=coverage` を使う

### テストコマンド

- `php artisan test`
- `vendor/bin/phpunit`
- `vendor/bin/pest`

### テスト設定

- 高速テストのために `phpunit.xml` で `DB_CONNECTION=sqlite` と `DB_DATABASE=:memory:` を設定する
- dev/prod データに触れないようにテスト用に env を分離する

### 認可テスト

```php
use Illuminate\Support\Facades\Gate;

$this->assertTrue(Gate::forUser($user)->allows('update', $project));
$this->assertFalse(Gate::forUser($otherUser)->allows('update', $project));
```

### Inertia フィーチャーテスト

Inertia.js を使用する場合、Inertia テストヘルパーでコンポーネント名と props をアサートする。

```php
use App\Models\User;
use Inertia\Testing\AssertableInertia;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class DashboardInertiaTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_inertia_props(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->get('/dashboard');

        $response->assertOk();
        $response->assertInertia(fn (AssertableInertia $page) => $page
            ->component('Dashboard')
            ->where('user.id', $user->id)
            ->has('projects')
        );
    }
}
```

Inertia レスポンスとテストを揃えるために、生 JSON アサーションよりも `assertInertia` を優先する。

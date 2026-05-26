---
name: laravel-security
description: 認証/認可、バリデーション、CSRF、マスアサインメント、ファイルアップロード、シークレット、レート制限、セキュアデプロイのための Laravel セキュリティベストプラクティス (Laravel security best practices for authn/authz, validation, CSRF, mass assignment, file uploads, secrets, rate limiting, secure deployment)。
origin: ECC
---

# Laravel セキュリティベストプラクティス

一般的な脆弱性から保護するための、Laravel アプリケーション向け包括的セキュリティガイダンス。

## 起動するタイミング

- 認証や認可を追加する場合
- ユーザー入力やファイルアップロードを扱う場合
- 新しい API エンドポイントを構築する場合
- シークレットや環境設定を管理する場合
- 本番デプロイをハードニングする場合

## 動作の仕組み

- ミドルウェアがベースライン保護を提供する (`VerifyCsrfToken` による CSRF、`SecurityHeaders` によるセキュリティヘッダー)
- ガードとポリシーがアクセス制御を強制する (`auth:sanctum`、`$this->authorize`、ポリシーミドルウェア)
- フォームリクエストはサービスに到達する前に入力を検証・整形する (`UploadInvoiceRequest`)
- レート制限は認証制御と並んで濫用保護を追加する (`RateLimiter::for('login')`)
- データ安全性は暗号化キャスト、マスアサインメントガード、署名付きルート (`URL::temporarySignedRoute` + `signed` ミドルウェア) から生まれる

## 主要なセキュリティ設定

- 本番では `APP_DEBUG=false`
- `APP_KEY` は必須で、漏洩時にローテーションする
- `SESSION_SECURE_COOKIE=true` と `SESSION_SAME_SITE=lax` (機密アプリには `strict`) を設定
- 正しい HTTPS 検出のために信頼プロキシを設定

## セッションと Cookie のハードニング

- JavaScript アクセスを防ぐために `SESSION_HTTP_ONLY=true` を設定
- 高リスクフローには `SESSION_SAME_SITE=strict` を使用
- ログインと権限変更時にセッションを再生成

## 認証とトークン

- API 認証には Laravel Sanctum または Passport を使用
- 機密データには短寿命トークンとリフレッシュフローを優先
- ログアウトと侵害アカウントでトークンを失効

ルート保護の例:

```php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->get('/me', function (Request $request) {
    return $request->user();
});
```

## パスワードセキュリティ

- `Hash::make()` でパスワードをハッシュ化し、平文を保存しない
- リセットフローには Laravel のパスワードブローカーを使用

```php
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

$validated = $request->validate([
    'password' => ['required', 'string', Password::min(12)->letters()->mixedCase()->numbers()->symbols()],
]);

$user->update(['password' => Hash::make($validated['password'])]);
```

## 認可: ポリシーとゲート

- モデルレベル認可にはポリシーを使用
- コントローラとサービスで認可を強制

```php
$this->authorize('update', $project);
```

ルートレベル強制にはポリシーミドルウェアを使用:

```php
use Illuminate\Support\Facades\Route;

Route::put('/projects/{project}', [ProjectController::class, 'update'])
    ->middleware(['auth:sanctum', 'can:update,project']);
```

## バリデーションとデータサニタイズ

- 入力は常にフォームリクエストで検証する
- 厳格なバリデーションルールと型チェックを使う
- 派生フィールドのためにリクエストペイロードを信頼しない

## マスアサインメント保護

- `$fillable` または `$guarded` を使用し、`Model::unguard()` を避ける
- DTO または明示的な属性マッピングを優先する

## SQL インジェクション防止

- Eloquent またはクエリビルダのパラメータバインディングを使う
- 厳密に必要でない限り生 SQL を避ける

```php
DB::select('select * from users where email = ?', [$email]);
```

## XSS 防止

- Blade はデフォルトで出力をエスケープする (`{{ }}`)
- 信頼されサニタイズされた HTML にのみ `{!! !!}` を使う
- リッチテキストは専用ライブラリでサニタイズする

## CSRF 保護

- `VerifyCsrfToken` ミドルウェアを有効に保つ
- フォームに `@csrf` を含め、SPA リクエストには XSRF トークンを送る

Sanctum での SPA 認証には、ステートフルリクエストが設定されていることを確認:

```php
// config/sanctum.php
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', 'localhost')),
```

## ファイルアップロードの安全性

- ファイルサイズ、MIME タイプ、拡張子を検証
- 可能な場合はパブリックパスの外にアップロードを保存
- 必要であればマルウェアスキャン

```php
final class UploadInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user()?->can('upload-invoice');
    }

    public function rules(): array
    {
        return [
            'invoice' => ['required', 'file', 'mimes:pdf', 'max:5120'],
        ];
    }
}
```

```php
$path = $request->file('invoice')->store(
    'invoices',
    config('filesystems.private_disk', 'local') // set this to a non-public disk
);
```

## レート制限

- 認証と書き込みエンドポイントに `throttle` ミドルウェアを適用
- ログイン、パスワードリセット、OTP には厳しい制限を使う

```php
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

RateLimiter::for('login', function (Request $request) {
    return [
        Limit::perMinute(5)->by($request->ip()),
        Limit::perMinute(5)->by(strtolower((string) $request->input('email'))),
    ];
});
```

## シークレットと認証情報

- シークレットをソースコントロールにコミットしない
- 環境変数とシークレットマネージャーを使う
- 露出後はキーをローテーションし、セッションを無効化する

## 暗号化属性

保存時の機密カラムには暗号化キャストを使う。

```php
protected $casts = [
    'api_token' => 'encrypted',
];
```

## セキュリティヘッダー

- 必要に応じて CSP、HSTS、フレーム保護を追加
- HTTPS リダイレクトを強制するために信頼プロキシ設定を使う

ヘッダー設定のためのミドルウェア例:

```php
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class SecurityHeaders
{
    public function handle(Request $request, \Closure $next): Response
    {
        $response = $next($request);

        $response->headers->add([
            'Content-Security-Policy' => "default-src 'self'",
            'Strict-Transport-Security' => 'max-age=31536000', // add includeSubDomains/preload only when all subdomains are HTTPS
            'X-Frame-Options' => 'DENY',
            'X-Content-Type-Options' => 'nosniff',
            'Referrer-Policy' => 'no-referrer',
        ]);

        return $response;
    }
}
```

## CORS と API 露出

- `config/cors.php` でオリジンを制限する
- 認証ルートにワイルドカードオリジンを避ける

```php
// config/cors.php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    'allowed_origins' => ['https://app.example.com'],
    'allowed_headers' => [
        'Content-Type',
        'Authorization',
        'X-Requested-With',
        'X-XSRF-TOKEN',
        'X-CSRF-TOKEN',
    ],
    'supports_credentials' => true,
];
```

## ロギングと PII

- パスワード、トークン、完全なカードデータを決してログに記録しない
- 構造化ログ内の機密フィールドをリダクションする

```php
use Illuminate\Support\Facades\Log;

Log::info('User updated profile', [
    'user_id' => $user->id,
    'email' => '[REDACTED]',
    'token' => '[REDACTED]',
]);
```

## 依存関係セキュリティ

- `composer audit` を定期的に実行
- 依存関係を注意してピン留めし、CVE には迅速に更新する

## 署名付き URL

一時的で改ざん防止のリンクには署名付きルートを使う。

```php
use Illuminate\Support\Facades\URL;

$url = URL::temporarySignedRoute(
    'downloads.invoice',
    now()->addMinutes(15),
    ['invoice' => $invoice->id]
);
```

```php
use Illuminate\Support\Facades\Route;

Route::get('/invoices/{invoice}/download', [InvoiceController::class, 'download'])
    ->name('downloads.invoice')
    ->middleware('signed');
```

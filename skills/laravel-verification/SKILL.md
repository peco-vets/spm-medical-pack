---
name: laravel-verification
description: "Laravel プロジェクトの検証ループ。環境チェック、リンティング、静的解析、カバレッジ付きテスト、セキュリティスキャン、デプロイ準備 (Verification loop for Laravel projects: env checks, linting, static analysis, tests with coverage, security scans, deployment readiness)。"
origin: ECC
---

# Laravel 検証ループ

PR 前、主要変更後、デプロイ前に実行する。

## 使用するタイミング

- Laravel プロジェクトのプルリクエストを開く前
- 主要なリファクタリングや依存関係アップグレード後
- ステージングや本番のためのデプロイ前検証
- 完全な lint -> テスト -> セキュリティ -> デプロイ準備パイプラインの実行

## 動作の仕組み

- 各層が前の層に積み上がるよう、環境チェックからデプロイ準備までフェーズを順次実行する
- 環境と Composer チェックがそれ以降の前提条件となる。失敗したら直ちに停止する
- 完全なテストとカバレッジを実行する前に、リンティング/静的解析がクリーンであるべきである
- セキュリティとマイグレーションレビューはテスト後に行い、データやリリースステップの前に振る舞いを検証する
- ビルド/デプロイ準備とキュー/スケジューラチェックは最終ゲート。失敗があればリリースをブロックする

## フェーズ 1: 環境チェック

```bash
php -v
composer --version
php artisan --version
```

- `.env` が存在し、必要なキーが存在することを検証する
- 本番環境では `APP_DEBUG=false` を確認
- `APP_ENV` が対象デプロイ (`production`、`staging`) に合うことを確認

ローカルで Laravel Sail を使う場合:

```bash
./vendor/bin/sail php -v
./vendor/bin/sail artisan --version
```

## フェーズ 1.5: Composer とオートロード

```bash
composer validate
composer dump-autoload -o
```

## フェーズ 2: リンティングと静的解析

```bash
vendor/bin/pint --test
vendor/bin/phpstan analyse
```

プロジェクトが PHPStan の代わりに Psalm を使う場合:

```bash
vendor/bin/psalm
```

## フェーズ 3: テストとカバレッジ

```bash
php artisan test
```

カバレッジ (CI):

```bash
XDEBUG_MODE=coverage php artisan test --coverage
```

CI 例 (フォーマット -> 静的解析 -> テスト):

```bash
vendor/bin/pint --test
vendor/bin/phpstan analyse
XDEBUG_MODE=coverage php artisan test --coverage
```

## フェーズ 4: セキュリティと依存関係チェック

```bash
composer audit
```

## フェーズ 5: データベースとマイグレーション

```bash
php artisan migrate --pretend
php artisan migrate:status
```

- 破壊的マイグレーションを慎重にレビューする
- マイグレーションファイル名が `Y_m_d_His_*` (例: `2025_03_14_154210_create_orders_table.php`) に従い、変更を明確に記述することを確認する
- ロールバックが可能であることを確認する
- `down()` メソッドを検証し、明示的バックアップなしの取り返しのつかないデータ損失を避ける

## フェーズ 6: ビルドとデプロイ準備

```bash
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

- 本番設定でキャッシュウォームアップが成功することを確認する
- キューワーカーとスケジューラが設定されていることを検証する
- 対象環境で `storage/` と `bootstrap/cache/` が書き込み可能であることを確認する

## フェーズ 7: キューとスケジューラチェック

```bash
php artisan schedule:list
php artisan queue:failed
```

Horizon を使う場合:

```bash
php artisan horizon:status
```

`queue:monitor` が利用可能な場合、ジョブを処理せずバックログを確認するために使う:

```bash
php artisan queue:monitor default --max=100
```

アクティブ検証 (ステージングのみ): ノーオペジョブを専用キューにディスパッチし、1 つのワーカーを実行して処理する (`sync` 以外のキュー接続が設定されていることを確認)。

```bash
php artisan tinker --execute="dispatch((new App\\Jobs\\QueueHealthcheck())->onQueue('healthcheck'))"
php artisan queue:work --once --queue=healthcheck
```

ジョブが期待される副作用 (ログエントリ、ヘルスチェックテーブル行、メトリック) を生成したことを検証する。

これはテストジョブの処理が安全な非本番環境でのみ実行する。

## 例

最小フロー:

```bash
php -v
composer --version
php artisan --version
composer validate
vendor/bin/pint --test
vendor/bin/phpstan analyse
php artisan test
composer audit
php artisan migrate --pretend
php artisan config:cache
php artisan queue:failed
```

CI スタイルパイプライン:

```bash
composer validate
composer dump-autoload -o
vendor/bin/pint --test
vendor/bin/phpstan analyse
XDEBUG_MODE=coverage php artisan test --coverage
composer audit
php artisan migrate --pretend
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan schedule:list
```

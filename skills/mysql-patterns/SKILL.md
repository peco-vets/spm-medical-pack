---
name: mysql-patterns
description: 本番バックエンド向け MySQL/MariaDB スキーマ、クエリ、インデックス、トランザクション、レプリケーション、コネクションプールパターン (MySQL and MariaDB schema, query, indexing, transaction, replication, connection-pool patterns for production backends)。
origin: ECC
---

# MySQL パターン

MySQL または MariaDB スキーマ設計、マイグレーション、スロークエリ調査、キュースタイルトランザクション、コネクションプール、または本番データベース設定を扱う場合にこのスキルを使う。MySQL と MariaDB はいくつかの SQL 詳細で分岐しているため、機能固有パターンを適用する前に正確なバージョンチェックを優先する。

## 起動

- MySQL または MariaDB テーブル、インデックス、制約の設計
- 大規模本番テーブルでのマイグレーション実行前のレビュー
- スロークエリ、ロック待ち、デッドロック、コネクション枯渇のデバッグ
- キーセットページネーション、upsert、全文検索、JSON カラム、キューの追加
- アプリケーションコネクションプール、リードレプリカ、TLS、スローログの設定

## バージョンチェック

エンジンとバージョンの特定から始める:

```sql
SELECT VERSION();
SHOW VARIABLES LIKE 'version_comment';
```

構文が異なる場合は MySQL と MariaDB ガイダンスを分ける:

- MySQL は `ON DUPLICATE KEY UPDATE` で `VALUES(col)` の代替として行エイリアスを文書化する。そこでは `VALUES(col)` は非推奨である
- MariaDB は `ON DUPLICATE KEY UPDATE` で挿入された値を参照するサポート済みの方法として `VALUES(col)` を文書化する。クロスエンジン互換性のために使う
- `SKIP LOCKED` はキューライクな作業のみに適切である。ロックされた行をスキップし、一貫性のないビューを返す可能性があるため、一般的な会計や整合性に敏感な読み取りには使わない

## スキーマデフォルト

```sql
CREATE TABLE orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_id BIGINT UNSIGNED NOT NULL,
    status VARCHAR(32) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_orders_account_status_created (account_id, status, created_at),
    KEY idx_orders_active (account_id, deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

デフォルト選択:

| 使用ケース | 優先 | 避ける |
| --- | --- | --- |
| 代理主キー | `BIGINT UNSIGNED AUTO_INCREMENT` | 20 億行を超える可能性のあるテーブルでの `INT` |
| UUID ルックアップキー | 変換ヘルパー付き `BINARY(16)` | ホットテーブルでの `VARCHAR(36)` 主キー |
| お金と正確な数量 | `DECIMAL(p, s)` | `FLOAT` または `DOUBLE` |
| ユーザー向けテキスト | `utf8mb4` テーブルとインデックス | MySQL `utf8` / `utf8mb3` デフォルト |
| アプリケーションタイムスタンプ | アプリが管理する UTC を持つ `DATETIME` | `DATETIME` がタイムゾーンメタデータを保存すると仮定 |
| 論理削除 | `deleted_at DATETIME NULL` とスコープインデックス | インデックスなしでの論理削除行のフィルタリング |
| 拡張可能ステータス値 | ルックアップテーブルまたは制約付き `VARCHAR` | 値が頻繁に変わる場合の `ENUM` |

## インデックス

複合インデックスの順序は通常、等価述語が最初、次に範囲またはソートカラムに従う:

```sql
CREATE INDEX idx_orders_account_status_created
    ON orders (account_id, status, created_at);

SELECT id, total
FROM orders
WHERE account_id = ?
  AND status = 'pending'
  AND created_at >= ?
ORDER BY created_at DESC
LIMIT 50;
```

インデックスを追加または変更する前に `EXPLAIN` を使う:

```sql
EXPLAIN
SELECT id, total
FROM orders
WHERE account_id = 123 AND status = 'pending'
ORDER BY created_at DESC
LIMIT 50;
```

調査すべきシグナル:

| フィールド | リスクシグナル |
| --- | --- |
| `type` | 大規模テーブルでの `ALL` |
| `key` | 選択的述語が存在するときの `NULL` |
| `rows` | インタラクティブパスでの非常に高い行推定 |
| `Extra` | `Using temporary`、`Using filesort`、または広範な `Using where` |

盲目的にインデックスを追加しない。各インデックスは書き込みコスト、マイグレーション時間、バックアップサイズ、バッファプール圧力を増加させる。

## クエリパターン

### Upsert

クロスエンジン互換形式:

```sql
INSERT INTO user_settings (user_id, setting_key, setting_value)
VALUES (?, ?, ?)
ON DUPLICATE KEY UPDATE
    setting_value = VALUES(setting_value),
    updated_at = CURRENT_TIMESTAMP;
```

MySQL 行エイリアス形式:

```sql
INSERT INTO user_settings (user_id, setting_key, setting_value)
VALUES (?, ?, ?) AS new
ON DUPLICATE KEY UPDATE
    setting_value = new.setting_value,
    updated_at = CURRENT_TIMESTAMP;
```

ターゲットが MySQL であることを確認した後にのみ行エイリアス形式を使う。MariaDB または混在 MySQL/MariaDB フリートには `VALUES(col)` を使う。

### キーセットページネーション

```sql
SELECT id, name, created_at
FROM products
WHERE (created_at, id) < (?, ?)
ORDER BY created_at DESC, id DESC
LIMIT 50;
```

カーソルに合うインデックスでバックアップする:

```sql
CREATE INDEX idx_products_created_id ON products (created_at, id);
```

大規模テーブルで深い `OFFSET` ページネーションを使わない。サーバーがページを返す前に行をスキャンして破棄する。

### JSON フィールド

JSON カラムは拡張データに使い、重い関係フィルタリングや制約が必要なフィールドには使わない。

```sql
CREATE TABLE events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payload JSON NOT NULL,
    event_type VARCHAR(64)
        GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(payload, '$.type'))) STORED,
    KEY idx_events_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

頻繁にクエリされる JSON パスには、生成カラムを公開しそのカラムにインデックスを張る。外部キー、所有権、テナンシー、ライフサイクルフィールドはリレーショナルに保つ。

### 全文検索

```sql
ALTER TABLE articles ADD FULLTEXT KEY ft_articles_title_body (title, body);

SELECT id, title, MATCH(title, body) AGAINST (? IN NATURAL LANGUAGE MODE) AS score
FROM articles
WHERE MATCH(title, body) AGAINST (? IN NATURAL LANGUAGE MODE)
ORDER BY score DESC
LIMIT 20;
```

タイポ耐性、複雑なランキング、クロステーブルファセット、または組み込み全文挙動を超える言語固有解析が必要な場合は外部検索を使う。

## トランザクション

トランザクションを短く保ち、行を一貫した順序でロックする:

```sql
START TRANSACTION;

SELECT id, balance
FROM accounts
WHERE id IN (?, ?)
ORDER BY id
FOR UPDATE;

UPDATE accounts SET balance = balance - ? WHERE id = ?;
UPDATE accounts SET balance = balance + ? WHERE id = ?;

COMMIT;
```

デッドロックとロック待ちチェックリスト:

- コードパス間で行を決定的順序でロックする
- 外部 API 呼び出しはトランザクションを開く前に行い、内部では行わない
- `UPDATE`、`DELETE`、ロック付き読み取りで使う述語にインデックスを追加する
- デッドロック時はロールバックし、境界付きリトライバジェットでトランザクション全体をリトライする
- デッドロックの直後に `SHOW ENGINE INNODB STATUS\G` をキャプチャする。後のイベントで上書きされる

キュースタイルワーカー要求:

```sql
START TRANSACTION;

SELECT id
FROM jobs
WHERE status = 'pending'
ORDER BY created_at
LIMIT 1
FOR UPDATE SKIP LOCKED;

UPDATE jobs
SET status = 'processing', started_at = CURRENT_TIMESTAMP
WHERE id = ?;

COMMIT;
```

`SKIP LOCKED` はロックされた行のスキップが許容されるキューライクなワークロードでのみ使う。通常のトランザクション一貫性の代替ではない。

## コネクションプール

SQLAlchemy 例:

```python
from sqlalchemy import create_engine

engine = create_engine(
    "mysql+mysqlconnector://app:secret@db.internal/app",
    pool_size=10,
    max_overflow=5,
    pool_timeout=30,
    pool_recycle=240,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 5},
)
```

Node.js `mysql2` 例:

```javascript
import mysql from 'mysql2/promise';

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 30000,
});

const [rows] = await pool.execute(
  'SELECT id, total FROM orders WHERE account_id = ? LIMIT 50',
  [accountId],
);
```

アプリケーションプールリサイクリングをサーバーの `wait_timeout` より下に保つ。サーバーが `wait_timeout = 300` を使う場合、約 240 秒の `pool_recycle` が一貫している。`pool_pre_ping` はネットワークとフェイルオーバーイベントからの回復にも役立つ。

## 診断

有用なファーストパスコマンド:

```sql
SHOW FULL PROCESSLIST;
SHOW ENGINE INNODB STATUS\G;
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';
```

制御環境でスローログを有効化する:

```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
SET GLOBAL log_queries_not_using_indexes = 'ON';
```

`EXPLAIN ANALYZE` はクエリを実行するのが安全なときのみ使う。ステートメントを実行し、本番サイズのデータでは高コストになる可能性がある。

## レプリケーション

リードレプリカは遅延し得る。書き込み直後にレプリカへ自分の書き込みパス、チェックアウトフロー、権限チェック、または冪等キー読み取りをルーティングしない。

```sql
-- MySQL legacy terminology, still common in existing fleets
SHOW SLAVE STATUS\G;

-- Newer terminology where supported
SHOW REPLICA STATUS\G;
```

1 つのコマンドに標準化する前にエンジン/バージョンを確認する。TCP 接続が生きているかどうかだけでなく、レプリカ SQL スレッド健全性、IO スレッド健全性、遅延を監視する。

## セキュリティ

```sql
CREATE USER 'app'@'%' IDENTIFIED BY 'use-a-secret-manager';
GRANT SELECT, INSERT, UPDATE, DELETE ON appdb.* TO 'app'@'%';

ALTER USER 'app'@'%' REQUIRE SSL;

SELECT user, host
FROM mysql.user
WHERE user = '';

DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'%';
```

セキュリティレビューポイント:

- アプリケーションユーザーに `ALL PRIVILEGES` や `*.*` を付与しない
- トラフィックがホストまたはネットワークを越えるアプリケーションユーザーには TLS を要求する
- 認証情報は例、スクリプト、リポジトリファイルではなくプラットフォームシークレットマネージャーに保存する
- マイグレーション/管理ユーザーをランタイムアプリケーションユーザーから分離する
- パフォーマンスチューニング前にパブリックネットワーク露出とバインドアドレスを監査する

## 設定

専用データベースホスト用の出発点例:

```ini
[mysqld]
innodb_buffer_pool_size = 4G
innodb_flush_log_at_trx_commit = 1
sync_binlog = 1

max_connections = 300
thread_cache_size = 50

wait_timeout = 300
interactive_timeout = 300
innodb_lock_wait_timeout = 10

slow_query_log = ON
long_query_time = 1
log_queries_not_using_indexes = ON

log_bin = mysql-bin
binlog_format = ROW
binlog_expire_logs_seconds = 604800
```

設定値を普遍的なプリセットではなく、レビューのためのプロンプトとして扱う。ワークロード、ハードウェア、バックアップポリシー、回復目標からメモリ、コネクション、ログ保持、耐久性設定をサイズする。

## アンチパターン

| アンチパターン | リスク | より良いパターン |
| --- | --- | --- |
| ホットパスでの `SELECT *` | 過剰取得と脆いクライアント | 明示的カラムを選択 |
| 深い `OFFSET` ページネーション | 線形スキャンと遅いページ | キーセットページネーション |
| 外部キー結合にインデックスなし | 遅い結合とロック重い削除 | FK カラムに意図的にインデックス |
| 長いトランザクション | ロック待ちと大きな undo 履歴 | 小さな作業単位でコミット |
| `mysql.user` への直接 DML | 付与テーブル破損リスク | `CREATE USER`、`ALTER USER`、`DROP USER` を使用 |
| 管理者付与権限を持つアプリケーションユーザー | 高い爆発半径 | 最小権限ランタイムユーザー |
| `wait_timeout` を超えるプールリサイクル | プールされたコネクションが古い | タイムアウト未満でリサイクルしプレピング |
| 書き込み後のレプリカ読み取り | ユーザー向け状態が古い | Read-after-write フローをプライマリにピン |

## 出力の期待

このスキルがレビューに使われる場合、以下を返す:

1. エンジン/バージョン仮定
2. 最高リスクの正確性、ロック、セキュリティ、マイグレーション問題
3. 安全パスのための正確な SQL またはコード変更
4. 検証計画: `EXPLAIN`、マイグレーションドライラン、ロック/デッドロックチェック、ロールバック基準
5. 推奨に影響する MySQL/MariaDB 構文の違い

## 関連

- スキル: `postgres-patterns` - PostgreSQL 固有のスキーマとクエリパターン
- スキル: `database-migrations` - マイグレーション計画とロールアウト安全性
- スキル: `backend-patterns` - API とサービス層パターン
- スキル: `security-review` - シークレット処理、認証、最小権限
- エージェント: `database-reviewer` - より広範なデータベースレビューワークフロー

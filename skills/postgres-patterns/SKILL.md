---
name: postgres-patterns
description: クエリ最適化、スキーマ設計、インデックス、セキュリティのための PostgreSQL データベースパターン。Supabase ベストプラクティスに基づく (PostgreSQL database patterns for query optimization, schema design, indexing, security; based on Supabase best practices)。
origin: ECC
---

# PostgreSQL パターン

PostgreSQL ベストプラクティスのクイックリファレンス。詳細なガイダンスには `database-reviewer` エージェントを使う。

## 起動するタイミング

- SQL クエリやマイグレーションの記述
- データベーススキーマの設計
- スロークエリのトラブルシューティング
- Row Level Security の実装
- コネクションプールのセットアップ

## クイックリファレンス

### インデックスチートシート

| クエリパターン | インデックスタイプ | 例 |
|--------------|------------|---------|
| `WHERE col = value` | B-tree (デフォルト) | `CREATE INDEX idx ON t (col)` |
| `WHERE col > value` | B-tree | `CREATE INDEX idx ON t (col)` |
| `WHERE a = x AND b > y` | 複合 | `CREATE INDEX idx ON t (a, b)` |
| `WHERE jsonb @> '{}'` | GIN | `CREATE INDEX idx ON t USING gin (col)` |
| `WHERE tsv @@ query` | GIN | `CREATE INDEX idx ON t USING gin (col)` |
| 時系列範囲 | BRIN | `CREATE INDEX idx ON t USING brin (col)` |

### データ型クイックリファレンス

| 使用ケース | 正しい型 | 避ける |
|----------|-------------|-------|
| ID | `bigint` | `int`、ランダム UUID |
| 文字列 | `text` | `varchar(255)` |
| タイムスタンプ | `timestamptz` | `timestamp` |
| お金 | `numeric(10,2)` | `float` |
| フラグ | `boolean` | `varchar`、`int` |

### 一般的なパターン

**複合インデックス順序:**
```sql
-- Equality columns first, then range columns
CREATE INDEX idx ON orders (status, created_at);
-- Works for: WHERE status = 'pending' AND created_at > '2024-01-01'
```

**カバリングインデックス:**
```sql
CREATE INDEX idx ON users (email) INCLUDE (name, created_at);
-- Avoids table lookup for SELECT email, name, created_at
```

**部分インデックス:**
```sql
CREATE INDEX idx ON users (email) WHERE deleted_at IS NULL;
-- Smaller index, only includes active users
```

**RLS ポリシー (最適化):**
```sql
CREATE POLICY policy ON orders
  USING ((SELECT auth.uid()) = user_id);  -- Wrap in SELECT!
```

**UPSERT:**
```sql
INSERT INTO settings (user_id, key, value)
VALUES (123, 'theme', 'dark')
ON CONFLICT (user_id, key)
DO UPDATE SET value = EXCLUDED.value;
```

**カーソルページネーション:**
```sql
SELECT * FROM products WHERE id > $last_id ORDER BY id LIMIT 20;
-- O(1) vs OFFSET which is O(n)
```

**キュー処理:**
```sql
UPDATE jobs SET status = 'processing'
WHERE id = (
  SELECT id FROM jobs WHERE status = 'pending'
  ORDER BY created_at LIMIT 1
  FOR UPDATE SKIP LOCKED
) RETURNING *;
```

### アンチパターン検出

```sql
-- Find unindexed foreign keys
SELECT conrelid::regclass, a.attname
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
  );

-- Find slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC;

-- Check table bloat
SELECT relname, n_dead_tup, last_vacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### 設定テンプレート

```sql
-- Connection limits (adjust for RAM)
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET work_mem = '8MB';

-- Timeouts
ALTER SYSTEM SET idle_in_transaction_session_timeout = '30s';
ALTER SYSTEM SET statement_timeout = '30s';

-- Monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Security defaults
REVOKE ALL ON SCHEMA public FROM public;

SELECT pg_reload_conf();
```

## 関連

- エージェント: `database-reviewer` - 完全なデータベースレビューワークフロー
- スキル: `clickhouse-io` - ClickHouse 分析パターン
- スキル: `backend-patterns` - API とバックエンドパターン

---

*Supabase Agent Skills (クレジット: Supabase チーム) に基づく (MIT ライセンス)*

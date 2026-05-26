---
name: database-migrations
description: PostgreSQL、MySQL、共通 ORM (Prisma、Drizzle、Kysely、Django、TypeORM、golang-migrate) にわたるスキーマ変更、データマイグレーション、ロールバック、ゼロダウンタイムデプロイのためのデータベースマイグレーションのベストプラクティス (database migrations, PostgreSQL, MySQL, Prisma, Drizzle, Kysely, Django, golang-migrate, zero-downtime, expand-contract)。
origin: ECC
---

# データベースマイグレーションパターン

本番システムのための安全で可逆的なデータベーススキーマ変更。

## 起動するタイミング

- データベーステーブルの作成や変更
- カラムやインデックスの追加/削除
- データマイグレーションの実行 (バックフィル、変換)
- ゼロダウンタイムスキーマ変更の計画
- 新プロジェクトのマイグレーションツールのセットアップ

## 中核原則

1. **すべての変更はマイグレーション** — 本番データベースを手動で変更しない
2. **本番ではマイグレーションは前方のみ** — ロールバックは新しい前方マイグレーションを使う
3. **スキーマとデータマイグレーションは分離** — DDL と DML を 1 つのマイグレーションに混ぜない
4. **本番サイズのデータに対してマイグレーションをテスト** — 100 行で動くマイグレーションが 10M でロックするかもしれない
5. **デプロイ後マイグレーションは不変** — 本番で実行されたマイグレーションを編集しない

## マイグレーション安全チェックリスト

任意のマイグレーション適用前に:

- [ ] マイグレーションは UP と DOWN 両方を持つ (または明示的に不可逆としてマーク)
- [ ] 大きなテーブルでフルテーブルロックなし (並行操作を使う)
- [ ] 新カラムはデフォルトを持つか nullable (デフォルトなしの NOT NULL を追加しない)
- [ ] インデックスは並行作成 (既存テーブルの CREATE TABLE とインライン化しない)
- [ ] データバックフィルはスキーマ変更とは別のマイグレーション
- [ ] 本番データのコピーに対してテスト済
- [ ] ロールバック計画が文書化されている

## PostgreSQL パターン

### カラムを安全に追加

```sql
-- GOOD: Nullable column, no lock
ALTER TABLE users ADD COLUMN avatar_url TEXT;

-- GOOD: Column with default (Postgres 11+ is instant, no rewrite)
ALTER TABLE users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;

-- BAD: NOT NULL without default on existing table (requires full rewrite)
ALTER TABLE users ADD COLUMN role TEXT NOT NULL;
-- This locks the table and rewrites every row
```

### ダウンタイムなしでインデックスを追加

```sql
-- BAD: Blocks writes on large tables
CREATE INDEX idx_users_email ON users (email);

-- GOOD: Non-blocking, allows concurrent writes
CREATE INDEX CONCURRENTLY idx_users_email ON users (email);

-- Note: CONCURRENTLY cannot run inside a transaction block
-- Most migration tools need special handling for this
```

### カラムをリネーム (ゼロダウンタイム)

本番で直接リネームしない。expand-contract パターンを使う:

```sql
-- Step 1: Add new column (migration 001)
ALTER TABLE users ADD COLUMN display_name TEXT;

-- Step 2: Backfill data (migration 002, data migration)
UPDATE users SET display_name = username WHERE display_name IS NULL;

-- Step 3: Update application code to read/write both columns
-- Deploy application changes

-- Step 4: Stop writing to old column, drop it (migration 003)
ALTER TABLE users DROP COLUMN username;
```

### カラムを安全に削除

```sql
-- Step 1: Remove all application references to the column
-- Step 2: Deploy application without the column reference
-- Step 3: Drop column in next migration
ALTER TABLE orders DROP COLUMN legacy_status;

-- For Django: use SeparateDatabaseAndState to remove from model
-- without generating DROP COLUMN (then drop in next migration)
```

### 大規模データマイグレーション

```sql
-- BAD: Updates all rows in one transaction (locks table)
UPDATE users SET normalized_email = LOWER(email);

-- GOOD: Batch update with progress
DO $$
DECLARE
  batch_size INT := 10000;
  rows_updated INT;
BEGIN
  LOOP
    UPDATE users
    SET normalized_email = LOWER(email)
    WHERE id IN (
      SELECT id FROM users
      WHERE normalized_email IS NULL
      LIMIT batch_size
      FOR UPDATE SKIP LOCKED
    );
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    RAISE NOTICE 'Updated % rows', rows_updated;
    EXIT WHEN rows_updated = 0;
    COMMIT;
  END LOOP;
END $$;
```

## Prisma (TypeScript/Node.js)

### ワークフロー

```bash
# Create migration from schema changes
npx prisma migrate dev --name add_user_avatar

# Apply pending migrations in production
npx prisma migrate deploy

# Reset database (dev only)
npx prisma migrate reset

# Generate client after schema changes
npx prisma generate
```

### スキーマ例

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  avatarUrl String?  @map("avatar_url")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")
  orders    Order[]

  @@map("users")
  @@index([email])
}
```

### カスタム SQL マイグレーション

Prisma が表現できない操作 (並行インデックス、データバックフィル) のため:

```bash
# Create empty migration, then edit the SQL manually
npx prisma migrate dev --create-only --name add_email_index
```

```sql
-- migrations/20240115_add_email_index/migration.sql
-- Prisma cannot generate CONCURRENTLY, so we write it manually
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users (email);
```

## Drizzle (TypeScript/Node.js)

```bash
# Generate migration from schema changes
npx drizzle-kit generate

# Apply migrations
npx drizzle-kit migrate

# Push schema directly (dev only, no migration file)
npx drizzle-kit push
```

## Kysely (TypeScript/Node.js)

```bash
# Initialize config file (kysely.config.ts)
kysely init

# Create a new migration file
kysely migrate make add_user_avatar

# Apply all pending migrations
kysely migrate latest

# Rollback last migration
kysely migrate down
```

### マイグレーションファイル

```typescript
// migrations/2024_01_15_001_create_user_profile.ts
import { type Kysely, sql } from 'kysely'

// IMPORTANT: Always use Kysely<any>, not your typed DB interface.
// Migrations are frozen in time and must not depend on current schema types.
export async function up(db: Kysely<any>): Promise<void> {
  await db.schema
    .createTable('user_profile')
    .addColumn('id', 'serial', (col) => col.primaryKey())
    .addColumn('email', 'varchar(255)', (col) => col.notNull().unique())
    .addColumn('avatar_url', 'text')
    .addColumn('created_at', 'timestamp', (col) =>
      col.defaultTo(sql`now()`).notNull()
    )
    .execute()
}

export async function down(db: Kysely<any>): Promise<void> {
  await db.schema.dropTable('user_profile').execute()
}
```

## Django (Python)

```bash
# Generate migration from model changes
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Show migration status
python manage.py showmigrations

# Generate empty migration for custom SQL
python manage.py makemigrations --empty app_name -n description
```

### データマイグレーション

```python
from django.db import migrations

def backfill_display_names(apps, schema_editor):
    User = apps.get_model("accounts", "User")
    batch_size = 5000
    users = User.objects.filter(display_name="")
    while users.exists():
        batch = list(users[:batch_size])
        for user in batch:
            user.display_name = user.username
        User.objects.bulk_update(batch, ["display_name"], batch_size=batch_size)

def reverse_backfill(apps, schema_editor):
    pass  # Data migration, no reverse needed

class Migration(migrations.Migration):
    dependencies = [("accounts", "0015_add_display_name")]

    operations = [
        migrations.RunPython(backfill_display_names, reverse_backfill),
    ]
```

## golang-migrate (Go)

```bash
# Create migration pair
migrate create -ext sql -dir migrations -seq add_user_avatar

# Apply all pending migrations
migrate -path migrations -database "$DATABASE_URL" up

# Rollback last migration
migrate -path migrations -database "$DATABASE_URL" down 1
```

```sql
-- migrations/000003_add_user_avatar.up.sql
ALTER TABLE users ADD COLUMN avatar_url TEXT;
CREATE INDEX CONCURRENTLY idx_users_avatar ON users (avatar_url) WHERE avatar_url IS NOT NULL;

-- migrations/000003_add_user_avatar.down.sql
DROP INDEX IF EXISTS idx_users_avatar;
ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;
```

## ゼロダウンタイムマイグレーション戦略

重要な本番変更には、expand-contract パターンに従う:

```
Phase 1: EXPAND
  - Add new column/table (nullable or with default)
  - Deploy: app writes to BOTH old and new
  - Backfill existing data

Phase 2: MIGRATE
  - Deploy: app reads from NEW, writes to BOTH
  - Verify data consistency

Phase 3: CONTRACT
  - Deploy: app only uses NEW
  - Drop old column/table in separate migration
```

### タイムライン例

```
Day 1: Migration adds new_status column (nullable)
Day 1: Deploy app v2 — writes to both status and new_status
Day 2: Run backfill migration for existing rows
Day 3: Deploy app v3 — reads from new_status only
Day 7: Migration drops old status column
```

## アンチパターン

| アンチパターン | なぜ失敗するか | より良いアプローチ |
|-------------|-------------|-----------------|
| 本番での手動 SQL | 監査証跡なし、繰り返し不能 | 常にマイグレーションファイルを使う |
| デプロイ済みマイグレーションの編集 | 環境間のドリフトを引き起こす | 代わりに新マイグレーションを作る |
| デフォルトなしの NOT NULL | テーブルロック、全行リライト | nullable で追加、バックフィル、その後制約追加 |
| 大テーブルでインラインインデックス | ビルド中書き込みブロック | CREATE INDEX CONCURRENTLY |
| スキーマ + データを 1 マイグレーションに | ロールバック困難、長いトランザクション | マイグレーションを分離 |
| コード削除前のカラム削除 | 欠落カラムでアプリケーションエラー | 最初にコード削除、次のデプロイでカラム削除 |

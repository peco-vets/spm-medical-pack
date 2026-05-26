---
name: prisma-patterns
description: TypeScript バックエンド用 Prisma ORM パターン — スキーマ設計、クエリ最適化、トランザクション、ページネーション、updateMany がレコードではなくカウントを返す、$transaction タイムアウト、migrate dev が DB をリセット、@updatedAt がバルク書き込みでスキップされる、サーバーレスでのコネクション枯渇などの重要なトラップ (Prisma ORM patterns for TypeScript backends — schema design, query optimization, transactions, pagination, critical traps)。
origin: ECC
---

# Prisma パターン

TypeScript バックエンドの Prisma ORM の本番パターンと明白でないトラップ。
Prisma 5.x と 6.x に対してテスト済み。一部の挙動は Prisma 4 と異なる。

バージョン固有パターンを適用する前に Prisma バージョンを確認する:

```bash
npx prisma --version
```

Prisma 5 は `relationJoins` を導入し、クエリ戦略と設定に応じて、別個のクエリではなく JOIN 経由でリレーションをロードできる。`omit` フィールド修飾子と `prisma.$extends` Client Extensions API も追加された。注: `relationJoins` は大規模な 1:N リレーションや深いネスト `include` で行爆発を引き起こす可能性がある — リレーションが親ごとに多くの行を返す可能性がある場合は両方のアプローチをベンチマークする。

## 起動するタイミング

- Prisma スキーマモデルとリレーションの設計または変更
- クエリ、トランザクション、ページネーションロジックの記述
- `updateMany`、`deleteMany`、または任意のバルク操作の使用
- データベースマイグレーションの実行または計画
- サーバーレス環境 (Vercel、Lambda、Cloudflare Workers) へのデプロイ
- 論理削除またはマルチテナント行フィルタリングの実装

## コア概念

### ID 戦略

| 戦略 | 使用ケース | 避ける場合 |
|---|---|---|
| `@default(cuid())` | デフォルト選択 — URL セーフ、ソート可能、衝突なし | 外部システムにシーケンシャル ID が必要 |
| `@default(uuid())` | 非 Prisma システムとの相互運用性が必要 | 高書き込みテーブル (ランダム UUID は B-tree インデックスをフラグメント化) |
| `@default(autoincrement())` | 内部結合テーブル、監査ログ | 公開向け ID (レコード数を露出) |

### スキーマデフォルト

```prisma
model User {
  id        String    @id @default(cuid())
  email     String    @unique  // @unique already creates an index — no @@index needed
  name      String
  role      Role      @default(USER)
  posts     Post[]
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  deletedAt DateTime?

  @@index([createdAt])
  @@index([deletedAt, createdAt]) // composite for soft-delete + sort queries
}
```

- すべての外部キーと `WHERE` または `ORDER BY` で使われるカラムに `@@index` を追加する
- 論理削除が予見可能な要件のとき `deletedAt DateTime?` を事前に宣言する — 後で追加するには本番テーブルでのマイグレーションが必要
- `updatedAt @updatedAt` は `update` と `upsert` でのみ Prisma によって自動的に設定される (バルク更新トラップについてはアンチパターン参照)

### `include` 対 `select`

| | `include` | `select` |
|---|---|---|
| 返却 | すべてのスカラフィールド + 指定リレーション | 指定フィールドのみ |
| 使用ケース | リレーションに加えてほとんどのフィールドが必要 | ホットパス、大きなテーブル、過剰取得回避 |
| パフォーマンス | 広いテーブルで過剰取得の可能性 | 最小ペイロード、大規模データセットで高速 |
| Prisma 5 注 | デフォルトで JOIN を使う (`relationJoins`) | 同じ |

```ts
// include — all columns + relation
const user = await prisma.user.findUnique({
  where: { id },
  include: { posts: { select: { id: true, title: true } } },
});

// select — explicit allowlist
const user = await prisma.user.findUnique({
  where: { id },
  select: { id: true, email: true, name: true },
});
```

API レスポンスから生の Prisma エンティティを決して返さない — 公開フィールドを制御するためにレスポンス DTO にマッピングする:

```ts
// BAD: leaks passwordHash, deletedAt, internal fields
return await prisma.user.findUniqueOrThrow({ where: { id } });

// GOOD: explicit DTO mapping
const user = await prisma.user.findUniqueOrThrow({ where: { id } });
return { id: user.id, name: user.name, email: user.email };
```

### トランザクション形式選択

| 状況 | 使用 |
|---|---|
| 独立操作、相互依存なし | 配列形式 |
| 後のステップが前の結果に依存 | インタラクティブ形式 |
| 外部呼び出し (メール、HTTP) が関与 | トランザクション外完全に |

```ts
// Array form — batched in one round trip
const [user, post] = await prisma.$transaction([
  prisma.user.update({ where: { id }, data: { name } }),
  prisma.post.create({ data: { title, authorId: id } }),
]);

// Interactive form — use tx client only, never the outer prisma client
const post = await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUniqueOrThrow({ where: { id } });
  if (user.role !== 'ADMIN') throw new Error('Forbidden');
  return tx.post.create({ data: { title, authorId: user.id } });
});
```

### PrismaClient シングルトン

各 `PrismaClient` インスタンスは独自のコネクションプールを開く。一度だけインスタンス化する。

```ts
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
```

`globalThis` パターンはホットリロード (Next.js、nodemon、ts-node-dev) 中の重複インスタンスを防ぐ。

### N+1 問題

ループ内でリレーションをロードすると、行ごとに 1 つのクエリが発行される。

```ts
// BAD: N+1 — one extra query per user
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({ where: { authorId: user.id } });
}

// GOOD: single query
const users = await prisma.user.findMany({ include: { posts: true } });
```

Prisma 5+ `relationJoins` では、`include` 形式は単一の JOIN を使う。大規模な 1:N セットではこれが結果セットサイズを増やす可能性がある — リレーションが親ごとに多くの行を返す可能性がある場合は両方のアプローチをベンチマークする。

## コード例

### カーソルページネーション (フィードと大規模データセットに優先)

```ts
async function getPosts(cursor?: string, limit = 20) {
  const items = await prisma.post.findMany({
    where: { published: true },
    orderBy: [
      { createdAt: 'desc' },
      { id: 'desc' }, // secondary sort prevents unstable pagination on duplicate timestamps
    ],
    take: limit + 1,
    ...(cursor && { cursor: { id: cursor }, skip: 1 }),
  });

  const hasNextPage = items.length > limit;
  if (hasNextPage) items.pop();

  return { items, nextCursor: hasNextPage ? items[items.length - 1].id : null };
}
```

`limit + 1` を取得して pop する — 追加のカウントクエリなしで `hasNextPage` を検出する正規の方法。複数行が同じタイムスタンプを共有するときの不安定なページネーションを防ぐため、常に一意フィールド (例: `id`) を二次 `orderBy` として含める。ユーザーが任意のページにジャンプする必要がある場合 (管理テーブル) のみオフセットページネーションを使う。

### 論理削除

```ts
// Always filter explicitly — do not rely on middleware (hides behavior, hard to debug)
const activeUsers = await prisma.user.findMany({ where: { deletedAt: null } });

await prisma.user.update({ where: { id }, data: { deletedAt: new Date() } });
await prisma.user.update({ where: { id }, data: { deletedAt: null } }); // restore
```

### エラー処理

```ts
import { Prisma } from '@prisma/client';

try {
  await prisma.user.create({ data: { email } });
} catch (e) {
  if (e instanceof Prisma.PrismaClientKnownRequestError) {
    if (e.code === 'P2002') throw new ConflictError('Email already exists');
    if (e.code === 'P2025') throw new NotFoundError('Record not found');
    if (e.code === 'P2003') throw new BadRequestError('Referenced record does not exist');
  }
  throw e;
}
```

一般的なコード: `P2002` 一意違反 · `P2025` not found · `P2003` 外部キー違反

サービス境界でキャッチし、ドメインエラーに翻訳する。API コンシューマーに生の Prisma メッセージを決して公開しない。

### コネクションプール — サーバーレス

接続パラメータを `DATABASE_URL` に直接埋め込む — URL に既にクエリパラメータ (例: `?schema=public`) がある場合、文字列連結は壊れる:

```bash
# .env — preferred: embed params in the URL
DATABASE_URL="postgresql://user:pass@host/db?connection_limit=1&pool_timeout=20"

# With an external pooler (PgBouncer, Supabase pooler)
DATABASE_URL="postgresql://user:pass@host/db?pgbouncer=true&connection_limit=1"
```

```ts
// Vercel, AWS Lambda, and similar serverless runtimes: cap pool to 1 per instance
// connection_limit and pool_timeout are controlled via DATABASE_URL
const prisma = new PrismaClient();
```

## アンチパターン

### `updateMany` はカウントを返し、レコードではない

```ts
// BAD: result is { count: 2 } — users[0] is undefined
const users = await prisma.user.updateMany({ where: { role: 'GUEST' }, data: { role: 'USER' } });

// GOOD: capture IDs first, then update, then fetch only the affected rows
const targets = await prisma.user.findMany({
  where: { role: 'GUEST' },
  select: { id: true },
});
const ids = targets.map((u) => u.id);
await prisma.user.updateMany({ where: { id: { in: ids } }, data: { role: 'USER' } });
const updated = await prisma.user.findMany({ where: { id: { in: ids } } });
```

`deleteMany` でも同じ — `{ count: n }` を返し、削除された行を返さない。

### `$transaction` インタラクティブ形式は 5 秒後にタイムアウト

```ts
// BAD: external call inside transaction exceeds 5s default → "Transaction already closed"
await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUniqueOrThrow({ where: { id } });
  await sendWelcomeEmail(user.email); // external call
  await tx.user.update({ where: { id }, data: { emailSent: true } });
});

// GOOD: external calls outside the transaction
const user = await prisma.user.findUniqueOrThrow({ where: { id } });
await sendWelcomeEmail(user.email);
await prisma.user.update({ where: { id }, data: { emailSent: true } });

// Only raise timeout when bulk processing genuinely needs it
await prisma.$transaction(async (tx) => { ... }, { timeout: 30_000 });
```

### `migrate dev` はデータベースをリセットする可能性がある

`migrate dev` はスキーマドリフトを検出し、DB をリセットするよう促す可能性がある。すべてのデータをドロップする。

```bash
# NEVER on shared dev, staging, or production
npx prisma migrate dev --name add_column

# Safe everywhere except local solo dev
npx prisma migrate deploy

# Check drift without applying
npx prisma migrate diff \
  --from-migrations ./prisma/migrations \
  --to-schema-datamodel ./prisma/schema.prisma \
  --shadow-database-url "$SHADOW_DATABASE_URL"
```

### マイグレーションファイルを手動編集すると将来のデプロイが壊れる

Prisma はすべてのマイグレーションファイルをチェックサムする。適用後の編集は、オリジナルが既に実行された各環境で `P3006 checksum mismatch` を引き起こす。代わりに新しいマイグレーションを作成する。

### 破壊的スキーマ変更にはマルチステップマイグレーションが必要

既存カラムに `NOT NULL` を追加するか、1 つのマイグレーションでカラム名を変更すると、テーブルをロックするかデータをドロップする。expand-and-contract を使う:

```bash
# Step 1: create migration locally, then deploy
npx prisma migrate dev --name add_new_column   # local only
npx prisma migrate deploy                       # staging / production
```

```ts
// Step 2: backfill data (run in a script or migration job, not in the shell)
await prisma.user.updateMany({ data: { newColumn: derivedValue } });
```

```bash
# Step 3: create the NOT NULL constraint migration locally, then deploy
npx prisma migrate dev --name make_new_column_required  # local only
npx prisma migrate deploy                               # staging / production
```

### `@updatedAt` は `updateMany` で発火しない

`@updatedAt` は `update` と `upsert` でのみ自動的に設定される。バルク書き込みでは古い値のままになる。

```ts
// BAD: updatedAt stays at its old value
await prisma.post.updateMany({ where: { authorId }, data: { published: true } });

// GOOD
await prisma.post.updateMany({
  where: { authorId },
  data: { published: true, updatedAt: new Date() },
});
```

### 論理削除 + `findUniqueOrThrow` は削除されたレコードをリークする

`findUniqueOrThrow` は行が DB に存在しないときのみ `P2025` をスローする。論理削除された行はまだ存在し、エラーなしで返される。

`findUniqueOrThrow` は `where` に一意制約フィールドを要求する — `id` と一緒に `deletedAt: null` を追加すると、`{ id, deletedAt }` は複合一意制約ではないため型が壊れる。代わりに `findFirstOrThrow` を使う。

```ts
// BAD: returns soft-deleted user
const user = await prisma.user.findUniqueOrThrow({ where: { id } });

// BAD: Prisma type error — { id, deletedAt } is not a unique constraint
const user = await prisma.user.findUniqueOrThrow({ where: { id, deletedAt: null } });

// GOOD: findFirstOrThrow supports arbitrary where conditions
const user = await prisma.user.findFirstOrThrow({ where: { id, deletedAt: null } });
```

### `where` なしの `deleteMany` はすべての行を削除する

```ts
// BAD: silently wipes the table
await prisma.post.deleteMany();

// GOOD
await prisma.post.deleteMany({ where: { authorId: userId } });
```

## ベストプラクティス

| ルール | 理由 |
|---|---|
| CI/CD では `migrate deploy`、ローカルのみ `migrate dev` | `migrate dev` はドリフトで DB をリセットする可能性 |
| エンティティをレスポンス DTO にマッピング | 内部フィールドのリークを防ぐ |
| サービス境界で `PrismaClientKnownRequestError` をキャッチ | ドメインエラーに翻訳 |
| 手動 null チェックよりも `*OrThrow` メソッドを優先 | 自動的に P2025 をスロー。非一意フィールドをフィルタするときは `findFirstOrThrow` を使う |
| サーバーレスで `connection_limit=1` + 外部プーラ | コネクション枯渇を防ぐ |
| `deleteMany` には常に `where` を提供 | 偶発的テーブルワイプを防ぐ |
| `updateMany` で手動 `updatedAt: new Date()` を設定 | `@updatedAt` はバルク書き込みをスキップする |

## 関連スキル

- `nestjs-patterns` — Prisma を統合する NestJS サービス層
- `postgres-patterns` — PostgreSQL レベルのインデックスとコネクションチューニング
- `database-migrations` — 本番のマルチステップマイグレーション計画
- `backend-patterns` — 一般的な API とサービス層設計

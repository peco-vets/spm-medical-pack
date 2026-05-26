---
name: documentation-lookup
description: トレーニングデータの代わりに Context7 MCP 経由で最新ライブラリ・フレームワークのドキュメントを参照する（documentation lookup, Context7 MCP）。セットアップ質問、API リファレンス、コード例、またはユーザーがフレームワーク名（React, Next.js, Prisma 等）を挙げた場合に起動する。
origin: ECC
---

# ドキュメント参照（Context7）

ユーザーがライブラリ・フレームワーク・API について質問した場合、トレーニングデータに頼らず Context7 MCP（`resolve-library-id` と `query-docs`）経由で最新ドキュメントを取得する。

## 中核コンセプト

- **Context7**: ライブラリ・API のライブドキュメントを公開する MCP サーバ。トレーニングデータの代わりに利用する。
- **resolve-library-id**: ライブラリ名とクエリから Context7 互換ライブラリ ID（例 `/vercel/next.js`）を返す。
- **query-docs**: 指定ライブラリ ID と質問に対してドキュメントとコードスニペットを取得する。必ず先に resolve-library-id を呼んで有効なライブラリ ID を取得する。

## 利用タイミング

ユーザーが以下のいずれかを行うときに起動する。

- セットアップや設定の質問（例: "How do I configure Next.js middleware?"）
- ライブラリ依存のコード要求（"Write a Prisma query for..."）
- API・リファレンス情報の要求（"What are the Supabase auth methods?"）
- 特定フレームワーク・ライブラリ名に言及（React, Vue, Svelte, Express, Tailwind, Prisma, Supabase 等）

ライブラリ・フレームワーク・API の正確かつ最新の挙動に依存するリクエストでは常にこのスキルを用いる。Context7 MCP が構成されたハーネス（Claude Code、Cursor、Codex 等）全般に適用される。

## 仕組み

### Step 1: ライブラリ ID を解決する

**resolve-library-id** MCP ツールを以下の引数で呼ぶ。

- **libraryName**: ユーザー質問中のライブラリ/プロダクト名（例 `Next.js`, `Prisma`, `Supabase`）。
- **query**: ユーザーの質問全文。結果の関連度ランキングを改善する。

ドキュメント取得前に Context7 互換ライブラリ ID（形式 `/org/project` または `/org/project/version`）を取得する必要がある。このステップで有効な ID を得るまで query-docs を呼ばないこと。

### Step 2: 最適マッチを選ぶ

解決結果から1件を以下を基準に選ぶ。

- **名前マッチ**: ユーザーの問いに完全一致または最も近いものを優先。
- **ベンチマークスコア**: 高いほどドキュメント品質が高い（最高100）。
- **ソースの信頼性**: High または Medium を優先。
- **バージョン**: ユーザーがバージョンを指定した場合（例 "React 19"、"Next.js 15"）、バージョン固有のライブラリ ID（例 `/org/project/v1.2.0`）が列挙されていればそれを優先。

### Step 3: ドキュメントを取得する

**query-docs** MCP ツールを以下の引数で呼ぶ。

- **libraryId**: Step 2 で選択した Context7 ライブラリ ID（例 `/vercel/next.js`）。
- **query**: ユーザーの具体的な質問・タスク。関連スニペット獲得のため具体的に書く。

制限: 質問1件あたり query-docs（および resolve-library-id）の呼び出しは最大3回まで。3回呼んでも明確でない場合は不確実性を述べ、得られた最良情報で回答し、推測しない。

### Step 4: ドキュメントを使う

- 取得した最新情報をもとにユーザーの問いに答える。
- 役立つ場合はドキュメントのコード例を含める。
- 重要なときはライブラリ・バージョンを明記する（例: "In Next.js 15..."）。

## 例

### 例: Next.js middleware

1. **resolve-library-id** を `libraryName: "Next.js"`, `query: "How do I set up Next.js middleware?"` で呼ぶ。
2. 結果から名前マッチとベンチマークスコアに基づき最適なもの（例 `/vercel/next.js`）を選ぶ。
3. **query-docs** を `libraryId: "/vercel/next.js"`, `query: "How do I set up Next.js middleware?"` で呼ぶ。
4. 返ってきたスニペットとテキストで回答する。必要なら最小限の `middleware.ts` 例を引用する。

### 例: Prisma クエリ

1. **resolve-library-id** を `libraryName: "Prisma"`, `query: "How do I query with relations?"` で呼ぶ。
2. 公式 Prisma ライブラリ ID（例 `/prisma/prisma`）を選ぶ。
3. **query-docs** を呼ぶ。
4. Prisma Client パターン（`include` または `select`）を、ドキュメントからの短いコードスニペット付きで返す。

### 例: Supabase auth メソッド

1. **resolve-library-id** を `libraryName: "Supabase"`, `query: "What are the auth methods?"` で呼ぶ。
2. Supabase ドキュメントのライブラリ ID を選ぶ。
3. **query-docs** を呼ぶ。auth メソッドを要約し、取得ドキュメントからの最小例を示す。

## ベストプラクティス

- **具体的に書く**: 関連度向上のため、可能ならユーザーの全文をクエリとして使う。
- **バージョン意識**: バージョン言及時は resolve ステップで得られたバージョン固有 ID を使う。
- **公式ソースを優先**: 複数マッチがある場合は公式またはプライマリパッケージをコミュニティフォークより優先する。
- **機密データ禁止**: Context7 へ送るクエリから API キー・パスワード・トークン他のシークレットを削除する。resolve-library-id や query-docs に渡す前に、ユーザー質問にシークレットが含まれていないか確認すること。

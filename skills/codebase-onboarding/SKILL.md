---
name: codebase-onboarding
description: 不慣れなコードベースを分析し、アーキテクチャマップ、主要エントリポイント、規約、スターター CLAUDE.md を含む構造化されたオンボーディングガイドを生成する。新しいプロジェクトに参加するときや、リポジトリで初めて Claude Code をセットアップするときに使う (codebase onboarding, architecture map, entry points, conventions, CLAUDE.md, reconnaissance)。
origin: ECC
---

# Codebase Onboarding

不慣れなコードベースを体系的に分析し、構造化されたオンボーディングガイドを生成する。新しいプロジェクトに参加する、または既存リポジトリで初めて Claude Code をセットアップする開発者向けに設計されている。

## 利用するタイミング

- Claude Code で初めてプロジェクトを開く
- 新しいチームやリポジトリに参加する
- ユーザーが「このコードベースを理解させて」と尋ねる
- ユーザーがプロジェクトの CLAUDE.md 生成を求める
- ユーザーが「オンボード」「このリポを案内」と言う

## 仕組み

### Phase 1: 偵察

すべてのファイルを読まずにプロジェクトについての生のシグナルを集める。これらのチェックを並列で実行する:

```
1. Package manifest detection
   → package.json, go.mod, Cargo.toml, pyproject.toml, pom.xml, build.gradle,
     Gemfile, composer.json, mix.exs, pubspec.yaml

2. Framework fingerprinting
   → next.config.*, nuxt.config.*, angular.json, vite.config.*,
     django settings, flask app factory, fastapi main, rails config

3. Entry point identification
   → main.*, index.*, app.*, server.*, cmd/, src/main/

4. Directory structure snapshot
   → Top 2 levels of the directory tree, ignoring node_modules, vendor,
     .git, dist, build, __pycache__, .next

5. Config and tooling detection
   → .eslintrc*, .prettierrc*, tsconfig.json, Makefile, Dockerfile,
     docker-compose*, .github/workflows/, .env.example, CI configs

6. Test structure detection
   → tests/, test/, __tests__/, *_test.go, *.spec.ts, *.test.js,
     pytest.ini, jest.config.*, vitest.config.*
```

### Phase 2: アーキテクチャマッピング

偵察データから以下を特定する:

**技術スタック**
- 言語とバージョン制約
- フレームワークと主要ライブラリ
- データベースと ORM
- ビルドツールとバンドラ
- CI/CD プラットフォーム

**アーキテクチャパターン**
- モノリス・モノレポ・マイクロサービス・サーバーレス
- フロントエンド/バックエンド分割またはフルスタック
- API スタイル: REST・GraphQL・gRPC・tRPC

**主要ディレクトリ**
トップレベルディレクトリをその目的にマップする:

<!-- Example for a React project — replace with detected directories -->
```
src/components/  → React UI components
src/api/         → API route handlers
src/lib/         → Shared utilities
src/db/          → Database models and migrations
tests/           → Test suites
scripts/         → Build and deployment scripts
```

**データフロー**
1 つのリクエストをエントリからレスポンスまでトレースする:
- リクエストはどこに入るか? (ルーター・ハンドラ・コントローラ)
- どう検証されるか? (ミドルウェア・スキーマ・ガード)
- ビジネスロジックはどこか? (サービス・モデル・ユースケース)
- どうデータベースに到達するか? (ORM・raw クエリ・リポジトリ)

### Phase 3: 規約検出

コードベースが既に従っているパターンを特定する:

**命名規約**
- ファイル命名: kebab-case・camelCase・PascalCase・snake_case
- コンポーネント/クラス命名パターン
- テストファイル命名: `*.test.ts`・`*.spec.ts`・`*_test.go`

**コードパターン**
- エラー処理スタイル: try/catch・Result 型・エラーコード
- 依存注入または直接インポート
- 状態管理アプローチ
- 非同期パターン: コールバック・promise・async/await・チャネル

**Git 規約**
- 最近のブランチからのブランチ命名
- 最近のコミットからのコミットメッセージスタイル
- PR ワークフロー (squash・merge・rebase)
- リポジトリにコミットがないか浅い履歴 (例: `git clone --depth 1`) のみの場合、このセクションをスキップして「Git history unavailable or too shallow to detect conventions」と記す

### Phase 4: オンボーディングアーティファクト生成

2 つの出力を生成する:

#### Output 1: オンボーディングガイド

```markdown
# Onboarding Guide: [Project Name]

## Overview
[2-3 sentences: what this project does and who it serves]

## Tech Stack
<!-- Example for a Next.js project — replace with detected stack -->
| Layer | Technology | Version |
|-------|-----------|---------|
| Language | TypeScript | 5.x |
| Framework | Next.js | 14.x |
| Database | PostgreSQL | 16 |
| ORM | Prisma | 5.x |
| Testing | Jest + Playwright | - |

## Architecture
[Diagram or description of how components connect]

## Key Entry Points
<!-- Example for a Next.js project — replace with detected paths -->
- **API routes**: `src/app/api/` — Next.js route handlers
- **UI pages**: `src/app/(dashboard)/` — authenticated pages
- **Database**: `prisma/schema.prisma` — data model source of truth
- **Config**: `next.config.ts` — build and runtime config

## Directory Map
[Top-level directory → purpose mapping]

## Request Lifecycle
[Trace one API request from entry to response]

## Conventions
- [File naming pattern]
- [Error handling approach]
- [Testing patterns]
- [Git workflow]

## Common Tasks
<!-- Example for a Node.js project — replace with detected commands -->
- **Run dev server**: `npm run dev`
- **Run tests**: `npm test`
- **Run linter**: `npm run lint`
- **Database migrations**: `npx prisma migrate dev`
- **Build for production**: `npm run build`

## Where to Look
<!-- Example for a Next.js project — replace with detected paths -->
| I want to... | Look at... |
|--------------|-----------|
| Add an API endpoint | `src/app/api/` |
| Add a UI page | `src/app/(dashboard)/` |
| Add a database table | `prisma/schema.prisma` |
| Add a test | `tests/` matching the source path |
| Change build config | `next.config.ts` |
```

#### Output 2: スターター CLAUDE.md

検出された規約に基づいてプロジェクト固有の CLAUDE.md を生成または更新する。`CLAUDE.md` が既に存在する場合、まずそれを読んで強化する — 既存のプロジェクト固有の指示を保持し、追加または変更されたものを明確に呼び出す。

```markdown
# Project Instructions

## Tech Stack
[Detected stack summary]

## Code Style
- [Detected naming conventions]
- [Detected patterns to follow]

## Testing
- Run tests: `[detected test command]`
- Test pattern: [detected test file convention]
- Coverage: [if configured, the coverage command]

## Build & Run
- Dev: `[detected dev command]`
- Build: `[detected build command]`
- Lint: `[detected lint command]`

## Project Structure
[Key directory → purpose map]

## Conventions
- [Commit style if detectable]
- [PR workflow if detectable]
- [Error handling patterns]
```

## ベストプラクティス

1. **すべてを読まない** — 偵察は Glob と Grep を使うべきで、すべてのファイルに対して Read ではない。曖昧なシグナルのみ選択的に読む。
2. **検証し、推測しない** — フレームワークが設定から検出されたが実際のコードは別のものを使っている場合、コードを信頼する。
3. **既存の CLAUDE.md を尊重する** — 既に存在するなら、置き換えではなく強化する。新規 vs 既存を呼び出す。
4. **簡潔に保つ** — オンボーディングガイドは 2 分でスキャン可能であるべき。詳細はガイドではなくコードに属する。
5. **不明をフラグする** — 規約が確信を持って検出できないなら、推測するよりそう言う。「テストランナーを判断できなかった」が誤答よりよい。

## 避けるべきアンチパターン

- 100 行を超える CLAUDE.md を生成 — 集中して保つ
- すべての依存関係をリスト — コードの書き方を形作るものだけをハイライト
- 自明なディレクトリ名を記述 — `src/` は説明不要
- README をコピー — オンボーディングガイドは README にない構造的洞察を加える

## 例

### 例 1: 新しいリポジトリでの初回
**User**: 「このコードベースにオンボードして」
**Action**: フル 4 フェーズワークフローを実行 → オンボーディングガイド + スターター CLAUDE.md を生成
**Output**: オンボーディングガイドを会話に直接表示、加えてプロジェクトルートに `CLAUDE.md` を書く

### 例 2: 既存プロジェクトの CLAUDE.md を生成
**User**: 「このプロジェクト用に CLAUDE.md を生成して」
**Action**: Phase 1-3 を実行、オンボーディングガイドはスキップ、CLAUDE.md のみ生成
**Output**: 検出された規約付きのプロジェクト固有 `CLAUDE.md`

### 例 3: 既存 CLAUDE.md を強化
**User**: 「現在のプロジェクト規約で CLAUDE.md を更新して」
**Action**: 既存 CLAUDE.md を読み、Phase 1-3 を実行、新しい発見をマージ
**Output**: 追加が明確にマークされた更新済み `CLAUDE.md`

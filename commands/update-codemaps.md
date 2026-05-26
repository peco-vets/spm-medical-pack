---
description: プロジェクト構造をスキャンし、トークン効率のよいアーキテクチャ codemap を生成する / Scan project structure and generate token-lean architecture codemaps.
---

# Update Codemaps

コードベース構造を分析し、トークン効率のよいアーキテクチャドキュメントを生成する。

## Step 1: プロジェクト構造をスキャンする

1. プロジェクトタイプを特定する（monorepo、単一アプリ、ライブラリ、マイクロサービス）
2. すべてのソースディレクトリ（src/、lib/、app/、packages/）を見つける
3. エントリポイント（main.ts、index.ts、app.py、main.go など）をマップする

## Step 2: Codemap を生成する

`docs/CODEMAPS/`（または `.reports/codemaps/`）に codemap を作成または更新する：

| File | Contents |
|------|----------|
| `architecture.md` | ハイレベルシステム図、サービス境界、データフロー |
| `backend.md` | API ルート、ミドルウェアチェーン、service → repository マッピング |
| `frontend.md` | ページツリー、コンポーネント階層、状態管理フロー |
| `data.md` | データベーステーブル、リレーション、マイグレーション履歴 |
| `dependencies.md` | 外部サービス、サードパーティ統合、共有ライブラリ |

### Codemap 形式

各 codemap はトークン効率のよいものであるべき — AI コンテキスト消費用に最適化されている：

```markdown
# Backend Architecture

## Routes
POST /api/users → UserController.create → UserService.create → UserRepo.insert
GET  /api/users/:id → UserController.get → UserService.findById → UserRepo.findById

## Key Files
src/services/user.ts (business logic, 120 lines)
src/repos/user.ts (database access, 80 lines)

## Dependencies
- PostgreSQL (primary data store)
- Redis (session cache, rate limiting)
- Stripe (payment processing)
```

## Step 3: Diff 検出

1. 前の codemap が存在する場合、diff パーセンテージを計算する
2. 変更が 30% を超える場合、diff を表示し、上書き前にユーザー承認を求める
3. 変更が 30% 以下の場合、その場で更新する

## Step 4: メタデータを追加する

各 codemap に新鮮度ヘッダを追加する：

```markdown
<!-- Generated: 2026-02-11 | Files scanned: 142 | Token estimate: ~800 -->
```

## Step 5: 分析レポートを保存する

`.reports/codemap-diff.txt` にサマリーを書き出す：
- 前回スキャン以降に追加/削除/変更されたファイル
- 検出された新しい依存関係
- アーキテクチャ変更（新ルート、新サービスなど）
- 90 日以上更新されていない docs の古さ警告

## Tips

- 実装詳細ではなく**ハイレベル構造**に焦点を当てる
- 完全なコードブロックよりも**ファイルパスと関数シグネチャ**を優先する
- 効率的なコンテキストロードのために各 codemap を**1000 トークン**以下に保つ
- 冗長な記述の代わりにデータフロー用に ASCII 図を使う
- 主要な機能追加やリファクタリングセッション後に実行する

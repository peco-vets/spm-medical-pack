---
description: スクリプト、スキーマ、ルート、エクスポートのような source-of-truth ファイルからドキュメントを同期する / Sync documentation from source-of-truth files such as scripts, schemas, routes, and exports.
---

# Update Documentation

source-of-truth ファイルから生成して、ドキュメントをコードベースと同期する。

## Step 1: Source of Truth を特定する

| Source | Generates |
|--------|-----------|
| `package.json` scripts | 利用可能なコマンドリファレンス |
| `.env.example` | 環境変数ドキュメント |
| `openapi.yaml` / route files | API エンドポイントリファレンス |
| Source code exports | 公開 API ドキュメント |
| `Dockerfile` / `docker-compose.yml` | インフラセットアップドキュメント |

## Step 2: スクリプトリファレンスを生成する

1. `package.json`（または `Makefile`、`Cargo.toml`、`pyproject.toml`）を読む
2. すべてのスクリプト/コマンドとその説明を抽出する
3. リファレンステーブルを生成する：

```markdown
| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with hot reload |
| `npm run build` | Production build with type checking |
| `npm test` | Run test suite with coverage |
```

## Step 3: 環境ドキュメントを生成する

1. `.env.example`（または `.env.template`、`.env.sample`）を読む
2. すべての変数とその目的を抽出する
3. 必須 vs 任意として分類する
4. 期待される形式と有効な値を文書化する

```markdown
| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DATABASE_URL` | Yes | PostgreSQL connection string | `postgres://user:pass@host:5432/db` |
| `LOG_LEVEL` | No | Logging verbosity (default: info) | `debug`, `info`, `warn`, `error` |
```

## Step 4: コントリビューティングガイドを更新する

以下を含む `docs/CONTRIBUTING.md` を生成または更新する：
- 開発環境セットアップ（前提条件、インストールステップ）
- 利用可能なスクリプトとその目的
- テスト手順（実行方法、新しいテストの書き方）
- コードスタイルの強制（linter、formatter、pre-commit hooks）
- PR 提出チェックリスト

## Step 5: Runbook を更新する

以下を含む `docs/RUNBOOK.md` を生成または更新する：
- デプロイ手順（ステップバイステップ）
- ヘルスチェックエンドポイントとモニタリング
- よくある問題とその修正
- ロールバック手順
- アラートとエスカレーションパス

## Step 6: 古さチェック

1. 90 日以上変更されていないドキュメントファイルを見つける
2. 最近のソースコード変更とクロス参照する
3. 手動レビュー用に古い可能性のある docs をフラグする

## Step 7: サマリーを表示する

```
Documentation Update
──────────────────────────────
Updated:  docs/CONTRIBUTING.md (scripts table)
Updated:  docs/ENV.md (3 new variables)
Flagged:  docs/DEPLOY.md (142 days stale)
Skipped:  docs/API.md (no changes detected)
──────────────────────────────
```

## ルール

- **Single source of truth**：常にコードから生成し、生成されたセクションを手動編集しない
- **手動セクションを保持**：生成されたセクションのみ更新；手書きの散文はそのままにする
- **生成された内容にマークを付ける**：生成されたセクションの周りに `<!-- AUTO-GENERATED -->` マーカーを使う
- **促されずに docs を作成しない**：コマンドが明示的に要求した場合のみ新しい doc ファイルを作成する

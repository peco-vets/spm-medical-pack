---
description: 決定論的なリポジトリハーネス監査を実行し、優先順位付きスコアカードを返す / Run a deterministic repository harness audit and return a prioritized scorecard.
---

# Harness Audit Command

決定論的なリポジトリハーネス監査を実行し、優先順位付きスコアカードを返す。

## Usage

`/harness-audit [scope] [--format text|json] [--root path]`

- `scope` (任意)：`repo`（デフォルト）、`hooks`、`skills`、`commands`、`agents`
- `--format`：出力スタイル（デフォルトは `text`、自動化用は `json`）
- `--root`：カレントディレクトリではなく特定のパスを監査する

## 決定論的エンジン

常に実行する：

```bash
node scripts/harness-audit.js <scope> --format <text|json> [--root <path>]
```

このスクリプトがスコアリングとチェックの真実のソースである。追加の次元やアドホックなポイントを発明してはならない。

ルーブリックバージョン：`2026-05-19`。

スクリプトは最大12の固定カテゴリを計算する（それぞれ `0-10` に正規化される）。最初の7つは常に適用可能；GitHub Integration は常に適用可能；デプロイターゲットカテゴリは一致するマーカーが検出された場合のみ適用可能である。

1. Tool Coverage
2. Context Efficiency
3. Quality Gates
4. Memory Persistence
5. Eval Coverage
6. Security Guardrails
7. Cost Efficiency
8. GitHub Integration
9. Vercel Integration *(`vercel.json` または `.vercel/` が存在する場合)*
10. Netlify Integration *(`netlify.toml` または `.netlify/` が存在する場合)*
11. Cloudflare Integration *(`wrangler.toml` または `wrangler.jsonc` が存在する場合)*
12. Fly Integration *(`fly.toml` が存在する場合)*

スコアは明示的なファイル/ルールチェックから導出され、同じコミットに対して再現可能である。
スクリプトはデフォルトで現在の作業ディレクトリを監査し、ターゲットが ECC リポジトリ自体か、ECC を使用するコンシューマプロジェクトかを自動検出する。

## 出力契約

以下を返す：

1. `overall_score` を `max_score` のうちで。`max_score` はターゲットに適用可能なカテゴリに依存する；固定の合計を仮定してはならない。
2. `applicable_categories[]` と `category_count` で寄与したカテゴリを示す。
3. カテゴリスコアと具体的な findings。
4. 正確なファイルパスと共に失敗したチェック。
5. 決定論的出力からの Top 3 アクション（`top_actions`）。
6. 次に適用すべき ECC スキルの提案。

## チェックリスト

- スクリプト出力を直接使用する；手動で再スコアリングしない。
- `--format json` が要求された場合、スクリプト JSON を変更せずに返す。
- text が要求された場合、失敗したチェックと top actions を要約する。
- `checks[]` と `top_actions[]` からの正確なファイルパスを含める。

## 結果例

```text
Harness Audit (repo, repo): 71/80
- Tool Coverage: 10/10 (10/10 pts)
- Context Efficiency: 9/10 (9/10 pts)
- Quality Gates: 10/10 (10/10 pts)
- GitHub Integration: 2/10 (2/10 pts)

Top 3 Actions:
1) [GitHub Integration] Add at least one workflow under .github/workflows/. (.github/workflows/)
2) [Security Guardrails] Add prompt/tool preflight security guards in hooks/hooks.json. (hooks/hooks.json)
3) [Eval Coverage] Increase automated test coverage across scripts/hooks/lib. (tests/)
```

## 引数

$ARGUMENTS:
- `repo|hooks|skills|commands|agents`（任意の scope）
- `--format text|json`（任意の出力形式）

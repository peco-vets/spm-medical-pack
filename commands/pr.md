---
description: "未プッシュコミットを含む現在のブランチから GitHub PR を作成する — テンプレートを発見、変更を分析、push を行う / Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes"
argument-hint: "[base-branch] (default: main)"
---

# Create Pull Request

**Input**：`$ARGUMENTS` — 任意、ベースブランチ名や/フラグ（例：`--draft`）を含むことがある。

**Parse `$ARGUMENTS`**:
- 認識されるフラグ（`--draft`）を抽出する
- 残りの非フラグテキストをベースブランチ名として扱う
- 指定がなければベースブランチを `main` にデフォルト設定する

---

## Phase 1 — VALIDATE

前提条件を確認する：

```bash
git branch --show-current
git status --short
git log origin/<base>..HEAD --oneline
```

| Check | Condition | Action if Failed |
|---|---|---|
| ベースブランチにいない | Current branch ≠ base | 停止：「まずフィーチャーブランチに切り替えてください。」 |
| クリーンな作業ディレクトリ | コミットされていない変更なし | 警告：「コミットされていない変更があります。先にコミットまたは stash してください。」 |
| 先行コミットあり | `git log origin/<base>..HEAD` が空でない | 停止：「`<base>` の先にコミットがありません。PR にするものがありません。」 |
| 既存 PR なし | `gh pr list --head <branch> --json number` が空 | 停止：「PR が既に存在します：#<number>。`gh pr view <number> --web` で開きます。」 |

すべてのチェックがパスしたら、進む。

---

## Phase 2 — DISCOVER

### PR テンプレート

以下の順で PR テンプレートを検索する：

1. `.github/PULL_REQUEST_TEMPLATE/` ディレクトリ — 存在すれば、ファイルをリストしユーザーに選択させる（または `default.md` を使う）
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/pull_request_template.md`
4. `docs/pull_request_template.md`

見つかった場合、それを読み、その構造を PR 本文に使用する。

### コミット分析

```bash
git log origin/<base>..HEAD --format="%h %s" --reverse
```

コミットを分析して以下を決定する：
- **PR title**：type プレフィックスを使ったコンベンショナルコミット形式 — `feat: ...`、`fix: ...` など
  - 複数の type がある場合、支配的なものを使う
  - 単一コミットなら、そのメッセージをそのまま使う
- **Change summary**：type/area でコミットをグループ化する

### ファイル分析

```bash
git diff origin/<base>..HEAD --stat
git diff origin/<base>..HEAD --name-only
```

変更されたファイルを分類する：source、tests、docs、config、migrations。

### 計画アーティファクト

`/plan-prd`、`/plan`、またはレガシー PRP ワークフローが生成した関連アーティファクトを確認する：
- `.claude/prds/` — この PR がそのマイルストーンを実装する PRD
- `.claude/plans/` — この PR が実行する計画
- `.claude/PRPs/prds/` — レガシー PRP PRD
- `.claude/PRPs/plans/` — レガシー PRP 実装計画
- `.claude/PRPs/reports/` — レガシー PRP 実装レポート

存在する場合、PR 本文でそれらを参照する。

---

## Phase 3 — PUSH

```bash
git push -u origin HEAD
```

発散により push が失敗した場合：
```bash
git fetch origin
git rebase origin/<base>
git push -u origin HEAD
```

rebase 衝突が起きたら、停止してユーザーに通知する。

---

## Phase 4 — CREATE

### テンプレート使用時

Phase 2 で PR テンプレートが見つかった場合、コミットとファイル分析を使って各セクションを埋める。すべてのテンプレートセクションを保持する — 適用できないセクションは削除せず "N/A" のままにする。

### テンプレートなし

このデフォルトフォーマットを使う：

```markdown
## Summary

<1-2 sentence description of what this PR does and why>

## Changes

<bulleted list of changes grouped by area>

## Files Changed

<table or list of changed files with change type: Added/Modified/Deleted>

## Testing

<description of how changes were tested, or "Needs testing">

## Related Issues

<linked issues with Closes/Fixes/Relates to #N, or "None">
```

### PR を作成する

```bash
gh pr create \
  --title "<PR title>" \
  --base <base-branch> \
  --body "<PR body>"
  # Add --draft if the --draft flag was parsed from $ARGUMENTS
```

---

## Phase 5 — VERIFY

```bash
gh pr view --json number,url,title,state,baseRefName,headRefName,additions,deletions,changedFiles
gh pr checks --json name,status,conclusion 2>/dev/null || true
```

---

## Phase 6 — OUTPUT

ユーザーに報告する：

```
PR #<number>: <title>
URL: <url>
Branch: <head> → <base>
Changes: +<additions> -<deletions> across <changedFiles> files

CI Checks: <status summary or "pending" or "none configured">

Artifacts referenced:
  - <any PRDs/plans linked in PR body>

Next steps:
  - gh pr view <number> --web   → open in browser
  - /code-review <number>       → review the PR
  - gh pr merge <number>        → merge when ready
```

---

## エッジケース

- **`gh` CLI なし**：「GitHub CLI (`gh`) が必要です。インストール：<https://cli.github.com/>」で停止
- **未認証**：「先に `gh auth login` を実行してください。」で停止
- **Force push が必要**：リモートが発散し rebase した場合、`git push --force-with-lease` を使う（`--force` は決して使わない）
- **複数の PR テンプレート**：`.github/PULL_REQUEST_TEMPLATE/` に複数ファイルがある場合、リストアップしユーザーに選択を求める
- **大きな PR（20ファイル超）**：PR サイズについて警告する。変更が論理的に分離可能なら分割を提案する

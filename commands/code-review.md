---
description: コードレビュー — ローカルの未コミット変更または GitHub PR（PR モードでは PR 番号/URL を渡す）/ Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)
argument-hint: [pr-number | pr-url | blank for local review]
---

# Code Review

> PR レビューモードは Wirasm 氏による PRPs-agentic-eng から派生したものである。PRP ワークフローシリーズの一部である。

**Input**: $ARGUMENTS

---

## モード選択

`$ARGUMENTS` に PR 番号、PR URL、または `--pr` が含まれる場合：
→ 下記の **PR Review Mode** にジャンプする。

それ以外の場合：
→ **Local Review Mode** を使用する。

---

## Local Review Mode

未コミット変更のセキュリティ・品質の包括的レビュー。

### Phase 1 — GATHER

```bash
git diff --name-only HEAD
```

変更ファイルがなければ停止：「Nothing to review.」

### Phase 2 — REVIEW

変更されたファイルそれぞれを完全に読む。以下をチェックする：

**セキュリティ問題（CRITICAL）：**
- ハードコードされた認証情報、API キー、トークン
- SQL インジェクション脆弱性
- XSS 脆弱性
- 入力バリデーションの不足
- 安全でない依存関係
- パストラバーサルリスク

**コード品質（HIGH）：**
- 50行を超える関数
- 800行を超えるファイル
- ネスト深度4超
- エラーハンドリングの不足
- console.log 文
- TODO/FIXME コメント
- 公開 API の JSDoc 不足

**ベストプラクティス（MEDIUM）：**
- ミューテーションパターン（代わりに不変パターンを使う）
- コード・コメント内の絵文字使用
- 新規コードのテスト不足
- アクセシビリティ問題（a11y）

### Phase 3 — REPORT

以下を含むレポートを生成する：
- 重要度：CRITICAL、HIGH、MEDIUM、LOW
- ファイルの場所と行番号
- 問題の説明
- 修正案

CRITICAL または HIGH の問題が見つかった場合はコミットをブロックする。
セキュリティ脆弱性のあるコードは決して承認しない。

---

## PR Review Mode

包括的な GitHub PR レビュー — diff 取得、完全なファイル読み込み、バリデーション実行、レビュー投稿。

### Phase 1 — FETCH

入力をパースして PR を特定する：

| 入力 | アクション |
|---|---|
| Number (e.g. `42`) | PR 番号として使用 |
| URL (`github.com/.../pull/42`) | PR 番号を抽出 |
| Branch name | `gh pr list --head <branch>` 経由で PR を検索 |

```bash
gh pr view <NUMBER> --json number,title,body,author,baseRefName,headRefName,changedFiles,additions,deletions
gh pr diff <NUMBER>
```

PR が見つからなければエラーで停止。PR メタデータを後のフェーズ用に保存する。

### Phase 2 — CONTEXT

レビューコンテキストを構築する：

1. **プロジェクトルール** — `CLAUDE.md`、`.claude/docs/`、および任意のコントリビューティングガイドラインを読む
2. **計画アーティファクト** — `.claude/prds/`、`.claude/plans/`、`.claude/reviews/`、およびレガシーの `.claude/PRPs/{prds,plans,reports,reviews}/` でこの PR に関連するコンテキストを確認する
3. **PR の意図** — PR の説明から目標、リンクされた issue、テスト計画をパースする
4. **変更ファイル** — すべての変更ファイルをリストアップし、タイプ別に分類する（source、test、config、docs）

### Phase 3 — REVIEW

変更されたファイルそれぞれを**完全に**読む（diff hunk だけではない — 周囲のコンテキストが必要）。

PR レビューでは、PR head リビジョンでの完全なファイル内容を取得する：
```bash
gh pr diff <NUMBER> --name-only | while IFS= read -r file; do
  gh api "repos/{owner}/{repo}/contents/$file?ref=<head-branch>" --jq '.content' | base64 -d
done
```

7つのカテゴリにわたるレビューチェックリストを適用する：

| カテゴリ | チェック内容 |
|---|---|
| **Correctness** | ロジックエラー、off-by-one、null 処理、エッジケース、レースコンディション |
| **Type Safety** | 型ミスマッチ、安全でないキャスト、`any` 使用、ジェネリクス不足 |
| **Pattern Compliance** | プロジェクト規約への適合（命名、ファイル構造、エラーハンドリング、import） |
| **Security** | インジェクション、認証ギャップ、シークレット露出、SSRF、パストラバーサル、XSS |
| **Performance** | N+1 クエリ、インデックス不足、無制限ループ、メモリリーク、大きなペイロード |
| **Completeness** | テスト不足、エラーハンドリング不足、不完全なマイグレーション、ドキュメント不足 |
| **Maintainability** | デッドコード、マジックナンバー、深いネスト、不明瞭な命名、型不足 |

各 finding に重要度を割り当てる：

| 重要度 | 意味 | アクション |
|---|---|---|
| **CRITICAL** | セキュリティ脆弱性またはデータ損失リスク | マージ前に修正必須 |
| **HIGH** | バグまたは問題を引き起こす可能性が高いロジックエラー | マージ前に修正すべき |
| **MEDIUM** | コード品質問題またはベストプラクティス不足 | 修正推奨 |
| **LOW** | スタイル指摘または軽微な提案 | 任意 |

### Phase 4 — VALIDATE

利用可能なバリデーションコマンドを実行する：

config ファイル（`package.json`、`Cargo.toml`、`go.mod`、`pyproject.toml` 等）からプロジェクトタイプを検出し、適切なコマンドを実行する：

**Node.js / TypeScript** (has `package.json`):
```bash
npm run typecheck 2>/dev/null || npx tsc --noEmit 2>/dev/null  # Type check
npm run lint                                                    # Lint
npm test                                                        # Tests
npm run build                                                   # Build
```

**Rust** (has `Cargo.toml`):
```bash
cargo clippy -- -D warnings  # Lint
cargo test                   # Tests
cargo build                  # Build
```

**Go** (has `go.mod`):
```bash
go vet ./...    # Lint
go test ./...   # Tests
go build ./...  # Build
```

**Python** (has `pyproject.toml` / `setup.py`):
```bash
pytest  # Tests
```

検出されたプロジェクトタイプに該当するコマンドのみを実行する。それぞれの pass/fail を記録する。

### Phase 5 — DECIDE

findings に基づいて推奨を形成する：

| 条件 | 決定 |
|---|---|
| CRITICAL/HIGH 問題ゼロ、バリデーション pass | **APPROVE** |
| MEDIUM/LOW 問題のみ、バリデーション pass | **APPROVE** コメント付き |
| HIGH 問題あり、またはバリデーション失敗 | **REQUEST CHANGES** |
| CRITICAL 問題あり | **BLOCK** — マージ前に修正必須 |

特殊ケース：
- Draft PR → 常に **COMMENT** を使用（承認/ブロックしない）
- docs/config の変更のみ → 軽量レビュー、正確性に焦点
- 明示的な `--approve` または `--request-changes` フラグ → 決定を上書き（ただし全 findings は報告）

### Phase 6 — REPORT

このワークストリームでリポジトリが既にレガシーの `.claude/PRPs/reviews/` を使用していない限り、`.claude/reviews/pr-<NUMBER>-review.md` にレビュー成果物を作成する：

```markdown
# PR Review: #<NUMBER> — <TITLE>

**Reviewed**: <date>
**Author**: <author>
**Branch**: <head> → <base>
**Decision**: APPROVE | REQUEST CHANGES | BLOCK

## Summary
<1-2 sentence overall assessment>

## Findings

### CRITICAL
<findings or "None">

### HIGH
<findings or "None">

### MEDIUM
<findings or "None">

### LOW
<findings or "None">

## Validation Results

| Check | Result |
|---|---|
| Type check | Pass / Fail / Skipped |
| Lint | Pass / Fail / Skipped |
| Tests | Pass / Fail / Skipped |
| Build | Pass / Fail / Skipped |

## Files Reviewed
<list of files with change type: Added/Modified/Deleted>
```

### Phase 7 — PUBLISH

GitHub にレビューを投稿する：

```bash
# If APPROVE
gh pr review <NUMBER> --approve --body "<summary of review>"

# If REQUEST CHANGES
gh pr review <NUMBER> --request-changes --body "<summary with required fixes>"

# If COMMENT only (draft PR or informational)
gh pr review <NUMBER> --comment --body "<summary>"
```

特定の行へのインラインコメントには、GitHub review comments API を使用する：
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/comments" \
  -f body="<comment>" \
  -f path="<file>" \
  -F line=<line-number> \
  -f side="RIGHT" \
  -f commit_id="$(gh pr view <NUMBER> --json headRefOid --jq .headRefOid)"
```

または、複数のインラインコメントを含む1つのレビューを一度に投稿する：
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/reviews" \
  -f event="COMMENT" \
  -f body="<overall summary>" \
  --input comments.json  # [{"path": "file", "line": N, "body": "comment"}, ...]
```

### Phase 8 — OUTPUT

ユーザーに報告する：

```
PR #<NUMBER>: <TITLE>
Decision: <APPROVE|REQUEST_CHANGES|BLOCK>

Issues: <critical_count> critical, <high_count> high, <medium_count> medium, <low_count> low
Validation: <pass_count>/<total_count> checks passed

Artifacts:
  Review: .claude/reviews/pr-<NUMBER>-review.md
  GitHub: <PR URL>

Next steps:
  - <contextual suggestions based on decision>
```

---

## エッジケース

- **`gh` CLI なし**：ローカル限定レビューにフォールバック（diff を読み、GitHub への投稿はスキップ）。ユーザーに警告する。
- **分岐したブランチ**：レビュー前に `git fetch origin && git rebase origin/<base>` を提案する。
- **大きな PR（50ファイル超）**：レビュー範囲について警告する。まずソース変更、次にテスト、次に config/docs に焦点を当てる。

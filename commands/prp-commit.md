---
description: "自然言語のファイルターゲティングで素早くコミットする — コミットする内容を普通の言葉で説明する / Quick commit with natural language file targeting — describe what to commit in plain English"
argument-hint: "[target description] (blank = all changes)"
---

# Smart Commit

> Wirasm 氏による PRPs-agentic-eng から派生したものである。PRP ワークフローシリーズの一部である。

**Input**：$ARGUMENTS

---

## Phase 1 — ASSESS

```bash
git status --short
```

出力が空なら → 停止：「Nothing to commit.」

何が変わったかのサマリーをユーザーに表示する（added、modified、deleted、untracked）。

---

## Phase 2 — INTERPRET & STAGE

`$ARGUMENTS` を解釈してステージするものを決定する：

| 入力 | 解釈 | Git Command |
|---|---|---|
| *(blank / empty)* | すべてをステージ | `git add -A` |
| `staged` | 既にステージされているものを使う | *(no git add)* |
| `*.ts` or `*.py` etc. | マッチするグロブをステージ | `git add '*.ts'` |
| `except tests` | すべてステージしてからテストをアンステージ | `git add -A && git reset -- '**/*.test.*' '**/*.spec.*' '**/test_*' 2>/dev/null \|\| true` |
| `only new files` | 追跡されていないファイルのみステージ | `git ls-files --others --exclude-standard \| grep . && git ls-files --others --exclude-standard \| xargs git add` |
| `the auth changes` | status/diff から解釈 — auth 関連ファイルを見つける | `git add <matched files>` |
| 特定のファイル名 | それらのファイルをステージ | `git add <files>` |

自然言語入力（「the auth changes」など）の場合、`git status` 出力と `git diff` を相互参照して関連ファイルを特定する。どのファイルをステージしているか、その理由をユーザーに表示する。

```bash
git add <determined files>
```

ステージ後、検証する：
```bash
git diff --cached --stat
```

何もステージされていなければ、停止：「No files matched your description.」

---

## Phase 3 — COMMIT

命令形ムードで単一行コミットメッセージを作成する：

```
{type}: {description}
```

Types:
- `feat` — 新機能または能力
- `fix` — バグ修正
- `refactor` — 動作変更なしのコード再構成
- `docs` — ドキュメント変更
- `test` — テスト追加/更新
- `chore` — ビルド、設定、依存関係
- `perf` — パフォーマンス改善
- `ci` — CI/CD 変更

ルール：
- 命令形ムード（"added feature" ではなく "add feature"）
- type プレフィックスの後は小文字
- 末尾にピリオドなし
- 72文字未満
- HOW ではなく WHAT が変わったかを記述

```bash
git commit -m "{type}: {description}"
```

---

## Phase 4 — OUTPUT

ユーザーに報告する：

```
Committed: {hash_short}
Message:   {type}: {description}
Files:     {count} file(s) changed

Next steps:
  - git push           → push to remote
  - /prp-pr            → create a pull request
  - /code-review       → review before pushing
```

---

## 例

| あなたが言うこと | 何が起こるか |
|---|---|
| `/prp-commit` | すべてをステージし、メッセージを自動生成 |
| `/prp-commit staged` | 既にステージされたものだけをコミット |
| `/prp-commit *.ts` | すべての TypeScript ファイルをステージしてコミット |
| `/prp-commit except tests` | テストファイル以外すべてをステージ |
| `/prp-commit the database migration` | status から DB migration ファイルを見つけてステージ |
| `/prp-commit only new files` | 追跡されていないファイルのみステージ |

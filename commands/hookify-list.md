---
description: 設定済みのすべての hookify ルールを一覧表示する / List all configured hookify rules
---

すべての hookify ルールを見つけて、フォーマットされたテーブルで表示する。

## Steps

1. すべての `.claude/hookify.*.local.md` ファイルを見つける
2. 各ファイルの frontmatter を読む：
   - `name`
   - `enabled`
   - `event`
   - `action`
   - `pattern`
3. テーブルとして表示する：

| Rule | Enabled | Event | Pattern | File |
|------|---------|-------|---------|------|

4. ルール数を表示し、`/hookify-configure` で後から状態を変更できることをユーザーに思い出させる。

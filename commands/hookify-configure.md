---
description: hookify ルールを対話的に有効化または無効化する / Enable or disable hookify rules interactively
---

既存の hookify ルールを対話的に有効化または無効化する。

## Steps

1. すべての `.claude/hookify.*.local.md` ファイルを見つける
2. 各ルールの現在の状態を読む
3. 現在の有効/無効ステータスと共にリストを提示する
4. どのルールを切り替えるかを尋ねる
5. 選択されたルールファイルの `enabled:` フィールドを更新する
6. 変更を確認する

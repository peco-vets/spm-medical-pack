---
description: 現在のセッションから再利用可能なパターンを抽出し、候補スキルまたはガイダンスとして保存する / Extract reusable patterns from the current session and save them as candidate skills or guidance.
---

# /learn - Extract Reusable Patterns

現在のセッションを分析し、スキルとして保存する価値のあるパターンを抽出する。

## トリガー

セッション中、自明でない問題を解決したときにいつでも `/learn` を実行する。

## 抽出するもの

以下を探す：

1. **エラー解決パターン**
   - どんなエラーが起きたか？
   - 根本原因は何か？
   - 何が修正したか？
   - 類似のエラーに対して再利用可能か？

2. **デバッグ技法**
   - 自明でないデバッグステップ
   - 有効だったツールの組み合わせ
   - 診断パターン

3. **ワークアラウンド**
   - ライブラリの癖
   - API の制限
   - バージョン固有の修正

4. **プロジェクト固有のパターン**
   - 発見されたコードベースの規約
   - 行われたアーキテクチャ決定
   - 統合パターン

## 出力フォーマット

`~/.claude/skills/learned/[pattern-name].md` にスキルファイルを作成する：

```markdown
# [Descriptive Pattern Name]

**Extracted:** [Date]
**Context:** [Brief description of when this applies]

## Problem
[What problem this solves - be specific]

## Solution
[The pattern/technique/workaround]

## Example
[Code example if applicable]

## When to Use
[Trigger conditions - what should activate this skill]
```

## プロセス

1. 抽出可能なパターンについてセッションをレビューする
2. 最も価値があり再利用可能な洞察を特定する
3. スキルファイルをドラフトする
4. 保存前にユーザーに確認を求める
5. `~/.claude/skills/learned/` に保存する

## 注意事項

- 些末な修正（タイプミス、単純な構文エラー）を抽出しない
- 一度限りの問題（特定の API ダウンなど）を抽出しない
- 将来のセッションで時間を節約するパターンに焦点を当てる
- スキルを焦点を絞ったものに保つ — 1スキルにつき1パターン

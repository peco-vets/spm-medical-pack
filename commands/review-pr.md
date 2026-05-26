---
description: 専門エージェントを使った包括的な PR レビュー / Comprehensive PR review using specialized agents
---

プルリクエストの包括的な多視点レビューを実行する。

## Usage

`/review-pr [PR-number-or-URL] [--focus=comments|tests|errors|types|code|simplify]`

PR が指定されない場合、現在のブランチの PR をレビューする。フォーカスが指定されない場合、フルレビュースタックを実行する。

## ステップ

1. PR を特定する：
   - PR の詳細、変更されたファイル、diff を取得するために `gh pr view` を使う
2. プロジェクトのガイダンスを見つける：
   - `CLAUDE.md`、lint config、TypeScript config、リポジトリ規約を探す
3. 専門レビューエージェントを実行する：
   - `code-reviewer`
   - `comment-analyzer`
   - `pr-test-analyzer`
   - `silent-failure-hunter`
   - `type-design-analyzer`
   - `code-simplifier`
4. 結果を集約する：
   - 重複する発見事項を除去する
   - 重要度でランク付けする
5. 重要度別にグループ化された発見事項を報告する

## 信頼度ルール

信頼度 >= 80 の問題のみを報告する：

- Critical：バグ、セキュリティ、データ損失
- Important：テスト不足、品質問題、スタイル違反
- Advisory：明示的に求められた場合のみの提案

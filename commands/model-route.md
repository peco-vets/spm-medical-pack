---
description: 複雑度、リスク、予算に基づいて、現在のタスクに最適なモデルティアを推奨する / Recommend the best model tier for the current task based on complexity, risk, and budget.
---

# Model Route Command

複雑度と予算で、現在のタスクに最適なモデルティアを推奨する。

## Usage

`/model-route [task-description] [--budget low|med|high]`

## ルーティングヒューリスティック

- `haiku`：決定論的、低リスクな機械的変更
- `sonnet`：実装とリファクタのデフォルト
- `opus`：アーキテクチャ、深いレビュー、曖昧な要件

## 必要な出力

- 推奨モデル
- 信頼度レベル
- なぜこのモデルが適合するか
- 最初の試行が失敗した場合のフォールバックモデル

## 引数

$ARGUMENTS:
- `[task-description]` 任意のフリーテキスト
- `--budget low|med|high` 任意

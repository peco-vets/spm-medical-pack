---
description: 安全のデフォルトと明示的な停止条件と共に、管理された自律ループパターンを開始する / Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.
---

# Loop Start Command

安全のデフォルトと共に、管理された自律ループパターンを開始する。

## Usage

`/loop-start [pattern] [--mode safe|fast]`

- `pattern`：`sequential`、`continuous-pr`、`rfc-dag`、`infinite`
- `--mode`：
  - `safe`（デフォルト）：厳格な品質ゲートとチェックポイント
  - `fast`：速度のためにゲートを軽減

## フロー

1. リポジトリの状態とブランチ戦略を確認する。
2. ループパターンとモデルティア戦略を選択する。
3. 選択されたモードに必要なフック/プロファイルを有効化する。
4. ループ計画を作成し、`.claude/plans/` の下に runbook を書き出す。
5. ループを開始・監視するコマンドを表示する。

## 必須の安全チェック

- 最初のループ反復前にテストが通ることを検証する。
- `ECC_HOOK_PROFILE` がグローバルに無効化されていないことを確認する。
- ループに明示的な停止条件があることを確認する。

## 引数

$ARGUMENTS:
- `<pattern>` 任意（`sequential|continuous-pr|rfc-dag|infinite`）
- `--mode safe|fast` 任意

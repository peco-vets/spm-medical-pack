---
description: ファイルまたはプロジェクトスコープに対して ECC 品質パイプラインを実行し、修復ステップを報告する / Run the ECC quality pipeline for a file or project scope and report remediation steps.
---

# Quality Gate Command

ファイルまたはプロジェクトスコープに対してオンデマンドで ECC 品質パイプラインを実行する。

## Usage

`/quality-gate [path|.] [--fix] [--strict]`

- デフォルトターゲット：現在のディレクトリ（`.`）
- `--fix`：設定されている場所で auto-format/fix を許可
- `--strict`：サポートされている場所で警告で失敗

## パイプライン

1. ターゲットの言語/ツールを検出する。
2. フォーマッタチェックを実行する。
3. 利用可能な場合 lint/型チェックを実行する。
4. 簡潔な修復リストを生成する。

## 注意事項

このコマンドはフック動作をミラーするが、オペレータ起動である。

## 引数

$ARGUMENTS:
- `[path|.]` 任意のターゲットパス
- `--fix` 任意
- `--strict` 任意

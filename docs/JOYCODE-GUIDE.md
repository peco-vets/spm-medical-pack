# JoyCode アダプタガイド

JoyCode は selective installer 経由で ECC を消費できる。アダプタは共有 ECC コマンド、エージェント、スキル、フラット化ルールをプロジェクトローカルな `.joycode/` ディレクトリにインストールする。

## インストール

インストールプランをプレビューする:

```bash
node scripts/install-plan.js --target joycode --profile full
```

現プロジェクトに適用する:

```bash
node scripts/install-apply.js --target joycode --profile full
```

より小さなインストールには、モジュールを明示的に選択する:

```bash
node scripts/install-apply.js --target joycode --modules rules-core,commands-core,workflow-quality
```

## レイアウト

プロジェクトアダプタは以下配下に管理ファイルを書き込む:

```text
.joycode/
  agents/
  commands/
  rules/
  skills/
  mcp-configs/
  scripts/
  ecc-install-state.json
```

JoyCode プロジェクトが `rules/common/coding-style.md` のようなネストしたルールディレクトリを受け取らないよう、ルールは名前空間付きファイル名にフラット化される。コマンド、エージェント、スキルは ECC の他所と同じ構造を保つ。
full プロファイルには、他の ECC プロジェクトローカルアダプタが使う共有 MCP とセットアップヘルパーファイルも含まれる。

## アンインストール

ファイルを手動で削除する代わりに ECC の管理アンインストールパスを使う:

```bash
node scripts/uninstall.js --target joycode
```

アンインストールコマンドは `.joycode/ecc-install-state.json` を読み、ECC がインストールしたファイルのみを削除する。ユーザー作成 JoyCode ファイルは保持される。

## ソース PR

このアダプタは陳腐 PR #1429 から有用なプロジェクトローカル JoyCode 意図をサルベージし、スタンドアロンシェルインストーラを ECC の現行 install-state とアンインストール機構で置き換える。

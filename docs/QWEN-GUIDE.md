# Qwen CLI アダプタガイド

ECC は管理コマンド、エージェント、スキル、ルール、MCP サーフェスを Qwen CLI ホームディレクトリにインストールできる。

## インストール

ECC リポジトリルートから:

```bash
./install.sh --target qwen --profile minimal
```

ファイルをコピーする前により大きなインストールをプレビュー:

```bash
./install.sh --target qwen --profile full --dry-run
```

Qwen アダプタは `~/.qwen/` に書き込み、管理ファイル所有権を `~/.qwen/ecc-install-state.json` に記録する。

## インストール後のレイアウト

管理インストールは以下を埋めうる:

```text
~/.qwen/
  QWEN.md
  agents/
  commands/
  mcp-configs/
  rules/
  skills/
  ecc-install-state.json
```

インストーラはルール用のソースレイアウトを保持するため、言語ルールセットは `~/.qwen/rules/common/` や `~/.qwen/rules/typescript/` のようなパス配下に留まる。

## 更新

ECC 更新を pull した後、同じインストールコマンドを再実行する。インストーラはインストール状態ファイルを使い、`~/.qwen/` 内の無関係なユーザーファイルを所有することなく ECC 管理ファイルを更新する。

## アンインストール

Qwen ディレクトリ全体を削除するのではなく、管理アンインストールパスを使う:

```bash
node scripts/uninstall.js --target qwen
```

これは `~/.qwen/ecc-install-state.json` に記録されたファイルを削除し、無関係な Qwen 設定をそのまま残す。

## スコープ

このターゲットは陳腐 PR #1352 より意図的に狭い。Qwen のフック/イベントコントラクトが確認されるまで、未検証のフックランタイムクレームを避けつつ、保守可能な Qwen インストールターゲット意図を現行 selective installer に port する。

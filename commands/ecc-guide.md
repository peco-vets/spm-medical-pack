---
description: ECC の現在のエージェント、スキル、コマンド、フック、インストールプロファイル、ドキュメントをライブのリポジトリ表面からナビゲートする / Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.
---

# /ecc-guide

このコマンドは Everything Claude Code の会話マップとして使用する。README 全体や古いカタログ件数をダンプせずに、ユーザーがタスクに適した ECC の表面を見つけられるように手助けする。

## Usage

```text
/ecc-guide
/ecc-guide setup
/ecc-guide skills
/ecc-guide commands
/ecc-guide hooks
/ecc-guide install
/ecc-guide find: <query>
/ecc-guide <feature-or-file-name>
```

## 動作ルール

1. チェックアウトが利用可能な場合、回答前に現在のリポジトリファイルを読む。
2. ハードコードされた件数より、現在のファイルシステム/カタログのデータを優先する。
3. 最初の回答は短く、その後で具体的なドリルダウンパスを提案する。
4. 長い節をコピーするのではなく、ユーザーを正式なファイルにリンクする。
5. 存在しないコマンド、スキル、エージェント、インストールプロファイルを作り上げてはならない。

## 何を調査するか

これらのファイルを正式なマップとして使用する：

- インストールパス、リセット/アンインストールガイダンス、ハイレベルなポジショニングは `README.md`
- コントリビューターおよびプロジェクト構造ガイダンスは `AGENTS.md`
- エクスポートされたエージェントとコマンドの表面は `agent.yaml`
- メンテナンス対象のスラッシュコマンド shim は `commands/`
- 再利用可能なスキルワークフローは `skills/*/SKILL.md`
- 委譲エージェントの役割は `agents/*.md`
- フックの挙動は `hooks/README.md` と `hooks/hooks.json`
- 選択的なインストールモジュール、コンポーネント、プロファイルは `manifests/install-*.json`
- ECC 内部で実行する場合、ライブのカタログ件数は `scripts/ci/catalog.js --json`

## 応答パターン

### 引数なし

コンパクトなメニューを提示する：

- セットアップとインストール
- スキルの選び方
- コマンド互換 shim
- エージェントと委譲
- フックと安全性
- インストールのトラブルシューティング
- 特定機能の検索

その後、次に何をしたいかを尋ねる。

### トピック検索

`skills`、`commands`、`hooks`、`install`、または `agents` のようなトピックの場合：

1. 現在の表面を 3-6 個の箇条書きで要約する。
2. 正式なディレクトリ/ファイルを指し示す。
3. 状態を検証できる1〜2個のコマンドを提案する。
4. ユーザーが要求しない限り、徹底的なリストは避ける。

### 検索モード

`find: <query>` の場合：

1. `rg` で関連ファイルを検索する。
2. 結果を表面別にグループ化する：skills、commands、agents、rules、docs、hooks。
3. 最も強いマッチをファイルパス付きで先に返す。
4. 各マッチについて次のアクションを推奨する。

### 機能検索

特定の機能名の場合：

1. まず `skills/<name>/SKILL.md`、`commands/<name>.md`、`agents/<name>.md` のような正確なパスを確認する。
2. 完全一致が失敗した場合は `rg` で検索する。
3. 機能の動作、利用シーン、正式なファイルを説明する。
4. 混乱を減らす場合のみ、隣接する機能を言及する。

## 関連コマンド

- `/project-init` - ターゲットプロジェクトのスタックを認識した ECC オンボーディング
- `/harness-audit` - 決定論的なリポジトリ準備度スコアリング
- `/skill-health` - スキル品質チェック
- `/skill-create` - ローカル git 履歴から新しいスキルを抽出
- `/security-scan` - Claude/OpenCode 設定セキュリティレビュー

# Hermes × ECC セットアップ

Hermes はオペレータシェルである。ECC はその背後にある再利用可能システムである。

本ガイドは、コンテンツ、アウトリーチ、研究、セールスオペ、財務チェック、エンジニアリングワークフローを 1 つのターミナルネイティブサーフェスから実行するために使われる Hermes スタックの、公開・サニタイズされたバージョンである。

## 公開出荷されるもの

- 本リポジトリの ECC スキル、エージェント、コマンド、フック、MCP 設定
- 再利用可能なほど安定した Hermes 生成ワークフロースキル
- チャット、cron、ワークスペースメモリ、配信フロー用の文書化されたオペレータトポロジー
- スタックを公開共有するためのローンチコラテラル

本ガイドにはプライベートシークレット、ライブトークン、個人データ、または生 `~/.hermes` エクスポートは含まれない。

## アーキテクチャ

Hermes をフロントドア、ECC を再利用可能ワークフロー基盤として使う。

```text
Telegram / CLI / TUI
        ↓
      Hermes
        ↓
 ECC skills + hooks + MCPs + generated workflow packs
        ↓
 Google Drive / GitHub / browser automation / research APIs / media tools / finance tools
```

## 公開ワークスペースマップ

プライベート状態を漏らさずにセットアップを再現するための最小サーフェスとしてこれを使う。

- `~/.hermes/config.yaml`
  - モデルルーティング
  - MCP サーバー登録
  - プラグインロード
- `~/.hermes/skills/ecc-imports/`
  - Hermes ネイティブ利用のためにコピーされた ECC スキル
- `skills/hermes-generated/`
  - 繰り返しの Hermes セッションから蒸留されたオペレータパターン
- `~/.hermes/plugins/`
  - フック、リマインダ、ワークフロー固有ツールグルー用ブリッジプラグイン
- `~/.hermes/cron/jobs.json`
  - 明示的プロンプトとチャネルを持つスケジュール自動化実行
- `~/.hermes/workspace/`
  - ビジネス、運用、健康、コンテンツ、メモリアーティファクト

## 推奨ケーパビリティスタック

### コア

- チャット、cron、オーケストレーション、ワークスペース状態のための Hermes
- スキル、ルール、プロンプト、クロスハーネス規約のための ECC
- ベースライン MCP レイヤとしての GitHub + Context7 + Exa + Firecrawl + Playwright

### コンテンツ

- ローカル編集と組み立てのための FFmpeg
- プログラマブルクリップのための Remotion
- 画像/動画生成のための fal.ai
- 音声、クリーンアップ、オーディオパッケージングのための ElevenLabs
- 最終ソーシャルネイティブポリッシュのための CapCut または VectCutAPI

### ビジネスオペ

- ドキュメント、シート、デッキ、研究ダンプのレコードシステムとしての Google Drive
- 収益と支払い運用のための Stripe
- エンジニアリング実行のための GitHub
- 緊急ナッジと承認のための Telegram と iMessage 様チャネル

## 依然ローカル認証を要するもの

これらはローカルに留め、オペレータごとに設定すべきである:

- Drive / Docs / Sheets / Slides 用 Google OAuth トークン
- X / LinkedIn / アウトバウンド配信認証情報
- Stripe キー
- ブラウザ自動化認証情報と stealth/プロキシ設定
- Linear や Apollo など任意の CRM またはプロジェクトシステム認証情報
- 健康自動化が有効な場合 Apple Health エクスポートまたは取り込みパス

## 推奨ブリングアップ順序

0. 最初に `ecc migrate audit --source ~/.hermes` を実行してレガシーワークスペースをインベントリし、どの部分が既に ECC2 にマップされるかを確認する。
0.5. インポート前にマイグレーションアーティファクトを計画・足場化する:
   - `ecc migrate plan` と `ecc migrate scaffold` でレビュー可能プランを生成
   - `ecc migrate import-skills --output-dir migration-artifacts/skills` で再利用可能なレガシースキルを足場化
   - `ecc migrate import-tools --output-dir migration-artifacts/tools` でツール翻訳テンプレートを足場化
   - `ecc migrate import-plugins --output-dir migration-artifacts/plugins` でブリッジプラグインテンプレートを足場化
   - `ecc migrate import-schedules --dry-run` で繰り返しジョブをプレビュー
   - `ecc migrate import-remote --dry-run` でゲートウェイディスパッチをプレビュー
   - `ecc migrate import-env --dry-run` で安全な env/サービスコンテキストをプレビュー
   - `ecc migrate import-memory` でサニタイズされたワークスペースメモリをインポート
1. ECC をインストールし、`node tests/run-all.js` でベースラインハーネスセットアップを検証する。期待結果はゼロ失敗テストサマリ。
2. Hermes をインストールし、ECC インポート済みスキルを指す。
3. 日常的に使う MCP サーバーを登録する。
4. 最初に Google Drive、次に GitHub、最後に配信チャネルを認証する。
5. 小さな cron サーフェスから始める: レディネスチェック、コンテンツ説明責任、インボックストリアージ、収益モニタ。
6. その後にのみ健康、関係グラフ、アウトバウンドシーケンシングのような重い個人ワークフローを追加する。

## 関連ドキュメント

- [Hermes/OpenClaw マイグレーションガイド](HERMES-OPENCLAW-MIGRATION.md)
- [クロスハーネスアーキテクチャ](architecture/cross-harness.md)

## なぜ Hermes × ECC か

このスタックは以下を望むときに有用である:

- ビジネスとエンジニアリング運用を実行する 1 つのターミナルネイティブな場所
- 1 回限りのプロンプトではなく再利用可能スキル
- nudge、監査、エスカレートできる自動化
- プライベートオペレータ状態を露出せずにシステム形状を見せる公開リポジトリ

## 公開リリース候補スコープ

ECC v2.0.0-rc.1 は Hermes サーフェスを文書化し、ローンチコラテラルを今出荷する。

残るプライベートピースは後で重ねることができる:

- 追加のサニタイズテンプレート
- より豊富な公開例
- より多くの生成ワークフローパック
- より緊密な CRM と Google Workspace 統合

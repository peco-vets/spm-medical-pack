---
name: google-workspace-ops
description: Google Drive・Docs・Sheets・Slides をプラン、トラッカー、デッキ、共有ドキュメントのワークフロー表面として一体運用する（Google Workspace ops, Drive, Docs, Sheets, Slides）。Google Workspace アセットの検索・要約・編集・移行・整理をユーザーが必要とし、生のツール呼び出しに落とさず行いたいときに用いる。
origin: ECC
---

# Google Workspace Ops

このスキルは、1ファイルを孤立して編集するのではなく、共有ドキュメント・スプレッドシート・デッキを稼働システムとして運用するためのものである。

## 利用タイミング

- ドキュメント・シート・デッキを探し、その場で更新する
- Google Drive 内のプラン・トラッカー・ノート・顧客リストの統合
- 共有スプレッドシートの整理または再構造化
- Google Slides のインポート・修復・フォーマット変換
- 意思決定のための Docs・Sheets・Slides からのサマリ生成

## 推奨ツール表面

Google Drive をエントリポイントとし、適切なスペシャリストへ切り替える。

- テキスト中心のドキュメントは Google Docs
- 表形式の作業・式・チャートは Google Sheets
- デッキ・インポート・テンプレ移行・整理は Google Slides

ファイル名のみから構造を推測しない。先に内容を確認する。

## ワークフロー

### 1. アセットを見つける

Drive の検索表面から開始し、以下を特定する。

- 正確なファイル
- 兄弟アセット
- 重複候補
- 直近更新版

複数の類似ドキュメントがある場合、タイトル・オーナー・更新時刻・フォルダで確認する。

### 2. 編集前に確認する

変更前に以下を行う。

- 現状構造を要約する
- タブ・見出し・スライド数を特定する
- タスクが局所的クリーンアップか構造的手術かを判別する

作業を安全に行える最小のツールを選ぶ。

### 3. 精密に編集する

- Docs: 曖昧な書き換えではなく、インデックス対応編集を使う
- Sheets: 明示的なタブと範囲で操作する
- Slides: コンテンツ編集と視覚クリーンアップやテンプレ移行を区別する

要求作業が視覚的・レイアウト敏感ならば、一括盲目更新ではなく、確認と検証で反復する。

### 4. 稼働システムをクリーンに保つ

ファイルがより大きなワークフローの一部の場合、以下も表面化する。

- 重複トラッカー
- 古いデッキ
- 陳腐ドキュメント vs 正本ドキュメント
- 当該アセットがアーカイブ・統合・改名されるべきか

## 出力フォーマット

```text
ASSET
- file name
- type
- why this is the right file

CURRENT STATE
- structure summary
- key problems or blockers

ACTION
- edits made or recommended

FOLLOW-UPS
- archive / merge / duplicate cleanup / next file to update
```

## 適用例

- "Find the active planning doc and condense it"
- "Clean up this customer spreadsheet and show me the churn-risk rows"
- "Import this deck into Slides and make it presentable"
- "Find the current tracker, not the stale duplicate"

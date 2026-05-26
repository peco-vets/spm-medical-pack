---
name: project-flow-ops
description: GitHub と Linear をまたいだ実行フローを運用し、issue や pull request をトリアージし、進行中の作業をリンクし、GitHub を対外的、Linear を内部実行レイヤとして維持する（project flow ops / GitHub Linear coordination / PR triage / backlog control / プロジェクトフロー運用 / バックログ管理 / PR トリアージ / GitHub から Linear への連携）。ユーザーがバックログ管理、PR トリアージ、または GitHub と Linear の調整を求めるときに使用する。
origin: ECC
---

# プロジェクトフロー運用

このスキルは、断片化した GitHub の issue、PR、Linear のタスクを単一の実行フローに変換するものである。

問題がコーディングではなく調整である場合に使用する。

## 使用するタイミング

- オープンな PR や issue のバックログをトリアージする
- 何が Linear に属し、何が GitHub のみに留めるべきかを判断する
- 進行中の GitHub 作業を内部の実行レーンにリンクする
- PR を merge、port/rebuild、close、park に分類する
- レビューコメント、CI 失敗、または古い issue が実行をブロックしていないか監査する

## 運用モデル

- **GitHub** は公開およびコミュニティの真実である
- **Linear** は進行中のスケジュール済み作業に関する内部実行の真実である
- すべての GitHub issue が Linear issue を必要とするわけではない
- 以下に該当する場合にのみ Linear を作成または更新する:
  - active（進行中）
  - delegated（委任済み）
  - scheduled（予定済み）
  - cross-functional（部門横断）
  - 内部追跡に値する重要性がある

## コアワークフロー

### 1. まず公開面を読む

以下を収集する:

- GitHub issue または PR の状態
- 作成者とブランチの状態
- レビューコメント
- CI ステータス
- リンクされた issue

### 2. 作業を分類する

すべてのアイテムは以下のいずれかの状態に行き着くべきである:

| 状態 | 意味 |
|-------|---------|
| Merge | 自己完結しており、ポリシーに準拠し、準備完了である |
| Port/Rebuild | 有用なアイデアだが、ECC 内部で手動で再ランディングすべきである |
| Close | 方向性が誤っている、古い、安全でない、または重複している |
| Park | 潜在的に有用だが、現時点ではスケジュールされていない |

### 3. Linear が必要かどうか判断する

以下の場合にのみ Linear を作成または更新する:

- 実行が積極的に計画されている
- 複数のリポジトリまたはワークストリームが関与する
- 作業に内部オーナーシップまたはシーケンスが必要である
- issue が大規模なプログラムレーンの一部である

すべてを機械的にミラーリングしない。

### 4. 2 つのシステムを一貫性のある状態に保つ

作業が進行中のとき:

- GitHub issue/PR は公開で何が起きているかを示すべきである
- Linear はオーナー、優先度、実行レーンを内部で追跡すべきである

作業が出荷または却下されたとき:

- 公開された解決を GitHub に投稿する
- Linear タスクを適切にマークする

## レビュールール

- タイトル、サマリ、または信頼だけからマージしない。完全な diff を使う
- 外部由来の機能は、価値があるが自己完結していない場合、ECC 内部で再構築すべきである
- CI が赤の場合は分類して修正するかブロックする。マージ準備完了のふりをしない
- 真のブロッカーがプロダクト方向性である場合、ツール越しに隠さず、そう述べる

## 出力フォーマット

以下を返す:

```text
PUBLIC STATUS
- issue / PR state
- CI / review state

CLASSIFICATION
- merge / port-rebuild / close / park
- one-paragraph rationale

LINEAR ACTION
- create / update / no Linear item needed
- project / lane if applicable

NEXT OPERATOR ACTION
- exact next move
```

## 良い使用例

- 「オープンな PR バックログを監査して、マージすべきものと再構築すべきものを教えて」
- 「GitHub issue を ECC 1.x と ECC 2.0 のプログラムレーンにマップして」
- 「これに Linear issue が必要か、GitHub のみに留めるべきか確認して」

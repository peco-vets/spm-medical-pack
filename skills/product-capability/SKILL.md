---
name: product-capability
description: PRD 意図、ロードマップ要求、製品議論をマルチサービス作業開始前に制約、不変量、インターフェース、未解決決定を露わにする実装準備可能な機能計画に変換する。ユーザーが曖昧な計画文ではなく ECC ネイティブ PRD-to-SRS レーンを必要とする場合に使用 (Translate PRD intent, roadmap asks, product discussions into implementation-ready capability plan; ECC-native PRD-to-SRS lane)。
origin: ECC
---

# Product Capability

このスキルは製品意図を明示的なエンジニアリング制約に変える。

ギャップが「何を構築すべきか?」ではなく「実装開始前に正確に何が真でなければならないか?」のときに使う。

## 使用するタイミング

- PRD、ロードマップアイテム、議論、または創業者ノートが存在するが、実装制約がまだ暗黙的
- 機能が複数のサービス、リポ、またはチームにまたがり、コーディング前に機能契約が必要
- 製品意図は明確だが、アーキテクチャ、データ、ライフサイクル、またはポリシーへの影響がまだ曖昧
- シニアエンジニアがレビュー中に同じ隠された仮定を繰り返し述べる
- ハーネスとセッションを越えて生き残ることができる再利用可能なアーティファクトが必要

## 正規アーティファクト

リポに `PRODUCT.md`、`docs/product/`、またはプログラム-スペックディレクトリなどの永続的な製品コンテキストファイルがある場合、そこで更新する。

機能マニフェストがまだ存在しない場合、以下のテンプレートを使って作成する:

- `docs/examples/product-capability-template.md`

目標は別の計画スタックを作ることではない。目標は隠された機能制約を永続的かつ再利用可能にすることである。

## 交渉不可ルール

- 製品の真実を発明しない。未解決の質問を明示的にマークする
- ユーザー可視の約束を実装詳細から分離する
- 何が固定ポリシーで、何がアーキテクチャ選好で、何がまだ開いているかを呼び出す
- リクエストが既存のリポ制約と競合する場合、滑らかにせず明確に言う
- 散在するアドホックなノートよりも 1 つの再利用可能な機能アーティファクトを優先する

## 入力

必要なもののみを読む:

1. 製品意図
   - issue、議論、PRD、ロードマップノート、創業者メッセージ
2. 現在のアーキテクチャ
   - 関連するリポドキュメント、契約、スキーマ、ルート、既存ワークフロー
3. 既存の機能コンテキスト
   - `PRODUCT.md`、設計ドキュメント、RFC、マイグレーションノート、運用モデルドキュメント
4. 配信制約
   - 認証、課金、コンプライアンス、ロールアウト、後方互換性、パフォーマンス、レビューポリシー

## コアワークフロー

### 1. 機能を再記述

依頼を 1 つの正確なステートメントに圧縮する:

- ユーザーまたはオペレータは誰か
- これが出荷された後どんな新しい機能が存在するか
- それによってどんな結果が変わるか

このステートメントが弱い場合、実装はドリフトする。

### 2. 機能制約を解決

実装前に成立しなければならない制約を抽出する:

- ビジネスルール
- スコープ境界
- 不変量
- 信頼境界
- データ所有権
- ライフサイクル遷移
- ロールアウト / マイグレーション要件
- 失敗と回復の期待

これらはしばしばシニアエンジニアの記憶にのみ存在するものである。

### 3. 実装向け契約を定義

以下を含む SRS スタイルの機能計画を生成する:

- 機能サマリー
- 明示的な非目標
- アクターとサーフェス
- 必要な状態と遷移
- インターフェース / 入力 / 出力
- データモデルへの影響
- セキュリティ / 課金 / ポリシー制約
- 観測可能性とオペレータ要件
- 実装をブロックするオープン質問

### 4. 実行に翻訳

以下の正確なハンドオフで終わる:

- 直接実装の準備が整った
- 最初にアーキテクチャレビューが必要
- 最初に製品の明確化が必要

有用であれば、次の ECC ネイティブレーンを指す:

- `project-flow-ops`
- `workspace-surface-audit`
- `api-connector-builder`
- `dashboard-builder`
- `tdd-workflow`
- `verification-loop`

## 出力形式

この順序で結果を返す:

```text
CAPABILITY
- one-paragraph restatement

CONSTRAINTS
- fixed rules, invariants, and boundaries

IMPLEMENTATION CONTRACT
- actors
- surfaces
- states and transitions
- interface/data implications

NON-GOALS
- what this lane explicitly does not own

OPEN QUESTIONS
- blockers or product decisions still required

HANDOFF
- what should happen next and which ECC lane should take it
```

## 良い成果

- 製品意図が、PR 中盤で隠れた制約を再発見せずに実装できるほど具体的になった
- エンジニアリングレビューが記憶や Slack コンテキストに依存する代わりに永続的なアーティファクトを持つ
- 結果の計画は Claude Code、Codex、Cursor、OpenCode、ECC 2.0 計画サーフェスを越えて再利用可能

---
name: hipaa-compliance
description: ヘルスケアプライバシー・セキュリティ作業向けの HIPAA 固有エントリポイント（HIPAA, PHI, covered entities, BAA, US healthcare compliance）。タスクが HIPAA、PHI 取扱、covered entity、BAA、breach 姿勢、米国ヘルスケアコンプライアンス要件に明示的に枠付けされたときに用いる。
origin: ECC direct-port adaptation
version: "1.0.0"
---

# HIPAA コンプライアンス

タスクが米国ヘルスケアコンプライアンスに明確に関連するとき、HIPAA 固有エントリポイントとして用いる。本スキルは意図的に薄く正規である:

- PHI/PII 取扱、データ分類、監査ロギング、暗号化、漏洩防止の主要実装スキルは `healthcare-phi-compliance` のまま
- コード・アーキテクチャ・プロダクト挙動がヘルスケア対応の二次パスを要する場合の専門レビュアは `healthcare-reviewer` のまま
- 認証・入力処理・シークレット・API・デプロイハードニングの一般事項は依然として `security-review` が適用

## 利用タイミング

- 要求が HIPAA、PHI、covered entity、business associate、BAA に明示言及
- PHI を保存・処理・エクスポート・送信する米国ヘルスケアソフトウェアの構築またはレビュー
- ロギング・解析・LLM プロンプト・ストレージ・サポートワークフローが HIPAA 露出を生むか評価
- 最小限必要アクセスと監査可能性が重要な患者向け・臨床医向けシステムの設計

## 仕組み

HIPAA はより広いヘルスケアプライバシースキルに重ねるオーバーレイとして扱う:

1. 具体的実装ルールは `healthcare-phi-compliance` から開始する
2. HIPAA 固有の意思決定ゲートを適用する:
   - このデータは PHI か?
   - このアクターは covered entity か business associate か?
   - データに触れる前にベンダーやモデルプロバイダは BAA を要するか?
   - アクセスは最小限必要なスコープに制限されているか?
   - read/write/export イベントは監査可能か?
3. タスクが患者安全、臨床ワークフロー、または規制下本番アーキテクチャに影響する場合は `healthcare-reviewer` にエスカレートする

## HIPAA 固有ガードレール

- PHI をログ・解析イベント・クラッシュレポート・プロンプト・クライアント可視エラー文字列に絶対に置かない
- PHI を URL・ブラウザストレージ・スクリーンショット・コピーされた例ペイロードに露出させない
- PHI の read/write には認証アクセス、スコープ付き認可、監査証跡を必須にする
- サードパーティ SaaS・観測ツール・サポートツーリング・LLM プロバイダは、BAA 状況とデータ境界が明確になるまでデフォルト block 扱いとする
- 最小限必要アクセスに従う: 正しいユーザーはタスクに必要な最小 PHI スライスのみを見られるべきである
- 名前・MRN・電話番号・住所その他識別子よりも不透明な内部 ID を優先する

## 例

### 例 1: HIPAA を冠したプロダクト要求

ユーザー要求:

> Add AI-generated visit summaries to our clinician dashboard. We serve US clinics and need to stay HIPAA compliant.

応答パターン:

- `hipaa-compliance` を起動する
- `healthcare-phi-compliance` で PHI の移動・ロギング・ストレージ・プロンプト境界をレビューする
- 要約プロバイダが BAA でカバーされているか、PHI 送信前に検証する
- 要約が臨床判断に影響する場合は `healthcare-reviewer` へエスカレートする

### 例 2: ベンダー/ツーリング判断

ユーザー要求:

> Can we send support transcripts and patient messages into our analytics stack?

応答パターン:

- それらメッセージが PHI を含む可能性を仮定する
- 解析ベンダーが HIPAA 拘束ワークロードに承認されていて、データパスが最小化されていない限り、設計を block する
- 可能なら redaction または非 PHI イベントモデルを要求する

## 関連スキル

- `healthcare-phi-compliance`
- `healthcare-reviewer`
- `healthcare-emr-patterns`
- `healthcare-eval-harness`
- `security-review`

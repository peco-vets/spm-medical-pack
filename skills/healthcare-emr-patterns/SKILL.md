---
name: healthcare-emr-patterns
description: ヘルスケアアプリ向けの EMR/EHR 開発パターン（healthcare EMR, EHR, clinical safety, encounter workflow, prescription, CDSS）。臨床安全性、診察ワークフロー、処方箋生成、臨床意思決定支援統合、医療データ入力向けアクセシビリティファースト UI を扱う。
origin: Health1 Super Speciality Hospitals — contributed by Dr. Keyur Patel
version: "1.0.0"
---

# ヘルスケア EMR 開発パターン

電子カルテ（EMR）・電子健康記録（EHR）システム構築のパターンである。患者安全・臨床精度・医療従事者効率を優先する。

## 利用タイミング

- 患者診察ワークフロー（主訴・診察・診断・処方）の構築
- 臨床ノート記録（構造化 + 自由テキスト + 音声テキスト変換）の実装
- 薬物相互作用チェック付き処方/薬剤モジュールの設計
- 臨床意思決定支援システム（CDSS）の統合
- 基準値ハイライト付き検査結果表示の構築
- 臨床データの監査証跡実装
- 臨床データ入力向けヘルスケアアクセシブル UI の設計

## 仕組み

### 患者安全ファースト

すべての設計判断は「これが患者に害を与えうるか?」で評価する。

- 薬物相互作用は無音通過ではなく必ずアラートする
- 異常検査値は必ず視覚的にフラグする
- クリティカルバイタルは必ずエスカレーションワークフローをトリガする
- 監査証跡なしの臨床データ修正を許さない

### 単一ページ診察フロー

臨床診察はタブ切替なしで単一ページを縦に流れるべきである。

```
Patient Header (sticky — always visible)
├── Demographics, allergies, active medications
│
Encounter Flow (vertical scroll)
├── 1. Chief Complaint (structured templates + free text)
├── 2. History of Present Illness
├── 3. Physical Examination (system-wise)
├── 4. Vitals (auto-trigger clinical scoring)
├── 5. Diagnosis (ICD-10/SNOMED search)
├── 6. Medications (drug DB + interaction check)
├── 7. Investigations (lab/radiology orders)
├── 8. Plan & Follow-up
└── 9. Sign / Lock / Print
```

### スマートテンプレートシステム

```typescript
interface ClinicalTemplate {
  id: string;
  name: string;             // e.g., "Chest Pain"
  chips: string[];          // clickable symptom chips
  requiredFields: string[]; // mandatory data points
  redFlags: string[];       // triggers non-dismissable alert
  icdSuggestions: string[]; // pre-mapped diagnosis codes
}
```

任意テンプレートのレッドフラグは必ず可視・非閉鎖アラートをトリガする — トースト通知ではない。

### 薬剤安全パターン

```
User selects drug
  → Check current medications for interactions
  → Check encounter medications for interactions
  → Check patient allergies
  → Validate dose against weight/age/renal function
  → If CRITICAL interaction: BLOCK prescribing entirely
  → Clinician must document override reason to proceed past a block
  → If MAJOR interaction: display warning, require acknowledgment
  → Log all alerts and override reasons in audit trail
```

Critical 相互作用は**デフォルトで処方を阻止**する。臨床医はドキュメント化された理由を監査証跡に保存して明示的にオーバーライドする必要がある。システムは Critical 相互作用を決して silent に許可しない。

### 診察ロックパターン

臨床診察が署名済みになると:
- 編集不可 — 追記（独立リンク記録）のみ可能
- 患者タイムラインに元記録と追記の両方が表示される
- 監査証跡が署名者・時刻・追記記録を捕捉する

### 臨床データの UI パターン

**バイタル表示:** 正常範囲ハイライト（緑/黄/赤）付き現値、前回値からの傾向矢印、自動算出される臨床スコア（NEWS2、qSOFA）、インラインのエスカレーション指針。

**検査結果表示:** 正常範囲ハイライト、前回値比較、Critical 値の非閉鎖アラート、採取/分析タイムスタンプ、想定 turnaround 付き保留オーダー。

**処方箋 PDF:** ワンクリック生成。患者デモグラフィクス・アレルギー・診断・薬剤詳細（generic + brand、用量、経路、頻度、期間）、臨床医署名ブロックを含む。

### ヘルスケア向けアクセシビリティ

ヘルスケア UI は典型的 Web アプリより厳しい要件を持つ:
- 最低コントラスト 4.5:1（WCAG AA） — 臨床医は様々な照明で作業する
- 大きなタッチターゲット（最低 44x44px） — グローブ装着/急ぎの操作向け
- キーボードナビゲーション — 高速データ入力するパワーユーザー向け
- 色のみのインジケータ禁止 — 必ず色とテキスト/アイコンをペアにする（色覚多様性ある臨床医向け）
- すべてのフォームフィールドにスクリーンリーダーラベル
- 臨床アラートに自動閉鎖トーストを使わない — 臨床医が能動的に確認すべきである

### アンチパターン

- 臨床データをブラウザ localStorage に保存する
- 薬物相互作用チェックでの silent failure
- Critical 臨床アラートに閉鎖可能トーストを使う
- 臨床ワークフローを断片化するタブベースの診察 UI
- 署名/ロック済み診察への編集許可
- 監査証跡なしの臨床データ表示
- 臨床データ構造に `any` 型を使う

## 例

### 例 1: 患者診察フロー

```
Doctor opens encounter for Patient #4521
  → Sticky header shows: "Rajesh M, 58M, Allergies: Penicillin, Active Meds: Metformin 500mg"
  → Chief Complaint: selects "Chest Pain" template
    → Clicks chips: "substernal", "radiating to left arm", "crushing"
    → Red flag "crushing substernal chest pain" triggers non-dismissable alert
  → Examination: CVS system — "S1 S2 normal, no murmur"
  → Vitals: HR 110, BP 90/60, SpO2 94%
    → NEWS2 auto-calculates: score 8, risk HIGH, escalation alert shown
  → Diagnosis: searches "ACS" → selects ICD-10 I21.9
  → Medications: selects Aspirin 300mg
    → CDSS checks against Metformin: no interaction
  → Signs encounter → locked, addendum-only from this point
```

### 例 2: 薬剤安全ワークフロー

```
Doctor prescribes Warfarin for Patient #4521
  → CDSS detects: Warfarin + Aspirin = CRITICAL interaction
  → UI: red non-dismissable modal blocks prescribing
  → Doctor clicks "Override with reason"
  → Types: "Benefits outweigh risks — monitored INR protocol"
  → Override reason + alert stored in audit trail
  → Prescription proceeds with documented override
```

### 例 3: ロック済み診察 + 追記

```
Encounter #E-2024-0891 signed by Dr. Shah at 14:30
  → All fields locked — no edit buttons visible
  → "Add Addendum" button available
  → Dr. Shah clicks addendum, adds: "Lab results received — Troponin elevated"
  → New record E-2024-0891-A1 linked to original
  → Timeline shows both: original encounter + addendum with timestamps
```

---
name: spm-mrna-gmp
description: SPM Layer4（AI 調剤ロボット F3〜）または Layer5（mRNA 個別ワクチン製造・最短5日）の製造設備・管理システム・トレーサビリティ・品質管理コードを実装する時に必ず使う、薬機法 GMP（Good Manufacturing Practice）と治験法対応の論点整理。製造管理・品質管理・トレーサビリティ・出荷判定・苦情処理・回収手順の実装要件をチェック。ゲノム解析パイプライン・個別化医療データ処理時にも参照。
---

# mRNA 個別ワクチン製造／調剤の GMP・治験法対応（SPM Layer4-5）

mRNA 個別ワクチン製造（Layer5）と AI 調剤ロボット（Layer4）の運用に必要な薬機法・GMP・治験法対応の論点整理。

## 適用法規

- **薬機法**: 医薬品・医療機器等の製造販売・製造業の許可
- **GMP 省令**: 医薬品の製造管理及び品質管理の基準
- **GCP 省令**: 治験の実施基準（治験段階）
- **再生医療等安全性確保法**: 細胞・遺伝子治療に該当する場合
- **遺伝子組換え生物等規制法（カルタヘナ法）**: mRNA 製造の一部

## mRNA ワクチンの法的位置づけ

- 治験段階: 治験用薬剤として GCP 準拠
- 承認後: 医薬品として GMP 準拠
- 個別化医療の場合: 「特定ロット」扱い等、規制スキーム要確認

## GMP の実装要件（システム側）

### 1. 製造管理
- [ ] 製造指図記録の電子化（紙との二重管理を避ける場合は CSV / DI 適合）
- [ ] 各工程の作業記録（誰が・いつ・何を・どの装置で）
- [ ] 原材料・中間製品・最終製品のロット管理
- [ ] バリデーション済みプロセスからの逸脱検知

### 2. 品質管理
- [ ] 製品品質試験の記録（試験データ・判定）
- [ ] 規格外品の隔離フロー
- [ ] 安定性試験データの蓄積

### 3. トレーサビリティ
- [ ] 原料ロット → 製造ロット → 患者投与までの全紐付け
- [ ] 不具合発生時に影響範囲を瞬時に特定可能
- [ ] **個別化 mRNA の場合：患者DNA → 設計配列 → 製造ロット → 投与記録 のフル紐付け**

実装テンプレ：
```typescript
model MrnaProductionBatch {
  id              String   @id @default(cuid())
  patientId       String   // 個別化のため患者紐付け
  genomeAnalysisId String  // 元となるゲノム解析
  targetSequence  String   // 設計された mRNA 配列
  materialLots    Json     // 使用原料ロット群
  productionStarted DateTime
  productionCompleted DateTime?
  qualityTestResults Json
  qualityJudgment String   // "passed" | "rejected" | "hold"
  releaseApprover String?  // 出荷判定者
  releaseApprovedAt DateTime?
  administeredAt  DateTime?
  // GMP 監査
  productionLog   ProductionLog[]
  deviations      Deviation[]
}

model Deviation {
  id          String   @id @default(cuid())
  batchId     String
  detectedAt  DateTime
  description String
  severity    String   // "minor" | "major" | "critical"
  rootCause   String?
  capa        String?  // Corrective and Preventive Action
  resolvedAt  DateTime?
}
```

### 4. 出荷判定
- [ ] 品質試験合格 + 製造記録完全性確認 → 出荷可
- [ ] 出荷判定者（QA 担当）の電子署名
- [ ] 出荷後のロット追跡

### 5. 苦情処理・回収
- [ ] 副作用報告の受付フロー
- [ ] PMDA への報告（重篤副作用 15日以内、その他 30日以内）
- [ ] ロット回収時の影響患者特定・通知

### 6. データインテグリティ（DI）

PIC/S GMP のデータインテグリティ要件：
- **ALCOA+ 原則**: Attributable, Legible, Contemporaneous, Original, Accurate + Complete, Consistent, Enduring, Available
- 監査証跡（Audit Trail）の自動記録
- 電子記録の改ざん防止 → [[spm-electronic-record-3principles]] と共通
- バリデーション済み計算機システム（CSV: Computer System Validation）

## 治験段階の追加要件（GCP）

- [ ] 治験審査委員会（IRB）承認の管理
- [ ] インフォームド・コンセント記録
- [ ] 治験プロトコル遵守の監査
- [ ] 有害事象（AE/SAE）の報告フロー

## AI 調剤ロボット（Layer4 F3〜）の論点

- 自動化された調剤プロセスの GMP 準拠
- ロボット動作のバリデーション（IQ/OQ/PQ）
- カメラ・センサーによる工程管理データの保存・監査

## カルタヘナ法（遺伝子組換え）

mRNA そのものは遺伝子組換え生物ではないが、製造に関わる細胞・酵素等が該当する場合あり：
- 第二種使用等の届出／確認
- 拡散防止措置の記録

## ゲノム解析パイプライン（Layer5）特有の論点

- 解析結果の精度保証（クリニカルレベルなら IVD: 体外診断用医薬品扱いの可能性）
- ゲノム情報は要配慮個人情報（[[spm-sensitive-personal-info]]）
- 学術研究目的の利用には別途倫理審査必要

## 設計時のチェック観点

1. [ ] 製造・調剤・配合・調整に該当するコードか？
2. [ ] GMP 適用判定済みか？
3. [ ] トレーサビリティのデータモデルが原料 → 製品 → 患者まで通っているか？
4. [ ] 監査証跡（誰が何をいつ）が自動記録されるか？
5. [ ] バリデーション計画（CSV）に組み込まれているか？

## 違反時のリスク

- 製造業許可取消
- 製品回収命令
- 業務停止
- 個別化医療事業の遂行不能

## 参照

- PMDA: https://www.pmda.go.jp/
- 厚労省 GMP 省令
- ICH Q7-Q12（医薬品 GMP 国際基準）
- PIC/S GMP ガイド
- [[spm-3sho-2gl-check]]
- [[spm-electronic-record-3principles]]
- [[spm-samd-classification]]
- Obsidian: `SPM/Layer別要件仕様書/Layer5_mRNA個別ワクチン製造.md`

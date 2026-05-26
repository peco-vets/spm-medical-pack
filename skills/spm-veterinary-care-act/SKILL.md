---
name: spm-veterinary-care-act
description: PECO/SPM の動物病院システム（カルテ・診療簿・処方・問診・受付・予約・院内システム）の機能を実装する時に必ず使う、獣医療法・獣医師法に基づく診療簿の必須記載事項、保存期間、飼主同意、診療補助行為の制限、特定動物の扱いをチェックする。Layer1 患者接点（PECO アプリ・院内システム）の開発時に必須。診療簿が法的要件を満たさないと業務停止リスク。
---

# 獣医療法・獣医師法 診療簿要件（SPM）

PECO/SPM の動物病院システムが獣医療法・獣医師法に準拠するためのチェックリスト。

## 適用システム

- PECO アプリ（飼主向け）
- 院内システム（受付・カルテ・処方）
- spm-project-2（SFA）
- peco-stock（在庫管理・薬剤）

## 診療簿の必須記載事項（獣医師法施行規則 11条）

獣医師は診療簿を作成・保存する義務がある（獣医師法 21条）。必須記載項目：

- [ ] **獣医師氏名** — 担当獣医師の特定
- [ ] **診療年月日**
- [ ] **動物の所有者または管理者の氏名・住所**
- [ ] **動物の種類・性別・年齢・名称・特徴**
- [ ] **病名・主要症状・転帰**
- [ ] **治療方法（処方および処置）**

実装テンプレ：
```typescript
model DiagnosisRecord {
  id              String   @id @default(cuid())
  // 法定必須項目
  veterinarianId  String   // 獣医師ID
  veterinarian    User     @relation(fields: [veterinarianId], references: [id])
  diagnosisDate   DateTime
  ownerName       String   // 飼主氏名
  ownerAddress    String   // 飼主住所
  animalSpecies   String   // 動物種（犬・猫・etc）
  animalSex       String   // 性別
  animalAge       Int?     // 年齢
  animalName      String   // 動物の名前
  animalFeatures  String?  // 特徴（毛色・マーク等）
  diseaseName     String   // 病名
  mainSymptoms    String   // 主要症状
  outcome         String   // 転帰（治癒・継続・死亡等）
  treatment       String   // 治療方法・処方
  // 監査・電子保存3原則
  createdAt       DateTime @default(now())
  createdBy       String
  contentHash     String   // 改ざん検知
  revisions       DiagnosisRecordRevision[]
}
```

## 保存期間

- 診療簿（カルテ）: **3年**（獣医師法施行規則 11条）
  - ※ 医師法では 5年。獣医療は 3年なので注意
- 産業動物（牛・豚等）の診療簿: 8年（薬機法の関係）
- 処方箋: 3年

→ 3年経過まで論理削除のみ、物理削除禁止

## 飼主同意の取得

法的明示要件は医療ほど厳しくないが、診療契約として同意は不可欠：

- [ ] 診療開始時に診療方針・概算費用の説明と同意
- [ ] 高度医療（手術・麻酔・遺伝子検査・mRNA ワクチン等）は書面同意推奨
- [ ] **要配慮個人情報該当の場合は APPI 同意必須** → [[spm-sensitive-personal-info]] 参照

## 診療補助行為の制限

- 注射・採血・麻酔導入等は獣医師の直接指示下でのみ動物看護師が実施可能
- システム上、診療記録の作成者は獣医師の承認フロー必須
- 看護師ロールが直接「診断」「処方」を確定できない UI 設計

## 特定動物の追加要件

特定動物（猛獣等）の診療時は別途記録要件あり。SPM の初期スコープ外だが、将来動物園・水族館展開時に該当。

## 薬剤管理の制約

- 動物用医薬品の処方は獣医師のみ（獣医師法 17条）
- 麻薬・向精神薬・劇薬等の管理は薬機法準拠
- peco-stock との連携時、処方ログを獣医師 ID と紐付け必須
- 処方箋の発行記録を 3年保存

## PECO 飼主アプリ特有の論点

- 飼主が見られる情報の範囲 — 検査結果の生データ vs 解釈済み情報
- 飼主間でのデータ共有禁止（同意外）
- AI 提案（症状チェッカー等）は「診断ではない」旨の免責表示必須

## チェック観点（PR レビュー時）

1. このコードは診療簿・処方・診療データに触れているか？
2. 必須6項目（獣医師・日付・飼主氏名住所・動物特定情報・病名症状・治療）が欠落していないか？
3. 削除パスは論理削除か？ 3年保存か？
4. 処方アクションは獣医師ロールのみか？
5. 飼主同意の記録があるか？
6. AI による提案を「診断」と誤認させる UI になっていないか？

## 違反時のリスク

- 業務停止命令（獣医師法 8条）
- 獣医師免許取消・停止
- 損害賠償・レピュテーション

## 参照

- 獣医療法: https://www.maff.go.jp/j/syouan/tikusui/zyui/
- 獣医師法 / 同施行規則
- [[spm-sensitive-personal-info]]
- [[spm-electronic-record-3principles]]
- [[spm-3sho-2gl-check]]

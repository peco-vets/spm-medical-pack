---
name: healthcare-cdss-patterns
description: 臨床意思決定支援システム（CDSS）開発パターン（healthcare CDSS, drug interaction, dose validation, NEWS2, qSOFA）。薬物相互作用チェック、用量検証、臨床スコアリング（NEWS2、qSOFA）、アラート重症度分類、EMR ワークフロー統合。
origin: Health1 Super Speciality Hospitals — contributed by Dr. Keyur Patel
version: "1.0.0"
---

# ヘルスケア CDSS 開発パターン

EMR ワークフローに統合される臨床意思決定支援システム（CDSS）構築のパターンである。CDSS モジュールは患者安全クリティカルである — false negative は許容されない。

## 利用タイミング

- 薬物相互作用チェックの実装
- 用量検証エンジンの構築
- 臨床スコアリングシステム（NEWS2、qSOFA、APACHE、GCS）の実装
- 異常な臨床値に対するアラートシステム設計
- 安全チェック付き処方オーダーエントリの構築
- 検査結果解釈と臨床コンテキストの統合

## 仕組み

CDSS エンジンは**副作用ゼロの純関数ライブラリ**である。臨床データを入力し、アラートを出力する。完全テスト可能になる。

主要3モジュール:

1. **`checkInteractions(newDrug, currentMeds, allergies)`** — 新規薬剤を現服用薬と既知アレルギーに対してチェックする。重症度順にソートされた `InteractionAlert[]` を返す。`DrugInteractionPair` データモデルを使う
2. **`validateDose(drug, dose, route, weight, age, renalFunction)`** — 処方用量を体重ベース・年齢調整・腎機能調整ルールに対して検証する。`DoseValidationResult` を返す
3. **`calculateNEWS2(vitals)`** — `NEWS2Input` から National Early Warning Score 2 を算出する。総合スコア・リスクレベル・エスカレーション指針を含む `NEWS2Result` を返す

```
EMR UI
  ↓ (user enters data)
CDSS Engine (pure functions, no side effects)
  ├── Drug Interaction Checker
  ├── Dose Validator
  ├── Clinical Scoring (NEWS2, qSOFA, etc.)
  └── Alert Classifier
  ↓ (returns alerts)
EMR UI (displays alerts inline, blocks if critical)
```

### 薬物相互作用チェック

```typescript
interface DrugInteractionPair {
  drugA: string;           // generic name
  drugB: string;           // generic name
  severity: 'critical' | 'major' | 'minor';
  mechanism: string;
  clinicalEffect: string;
  recommendation: string;
}

function checkInteractions(
  newDrug: string,
  currentMedications: string[],
  allergyList: string[]
): InteractionAlert[] {
  if (!newDrug) return [];
  const alerts: InteractionAlert[] = [];
  for (const current of currentMedications) {
    const interaction = findInteraction(newDrug, current);
    if (interaction) {
      alerts.push({ severity: interaction.severity, pair: [newDrug, current],
        message: interaction.clinicalEffect, recommendation: interaction.recommendation });
    }
  }
  for (const allergy of allergyList) {
    if (isCrossReactive(newDrug, allergy)) {
      alerts.push({ severity: 'critical', pair: [newDrug, allergy],
        message: `Cross-reactivity with documented allergy: ${allergy}`,
        recommendation: 'Do not prescribe without allergy consultation' });
    }
  }
  return alerts.sort((a, b) => severityOrder(a.severity) - severityOrder(b.severity));
}
```

相互作用ペアは**双方向**でなければならない: Drug A が Drug B と相互作用するなら、Drug B も Drug A と相互作用する。

### 用量検証

```typescript
interface DoseValidationResult {
  valid: boolean;
  message: string;
  suggestedRange: { min: number; max: number; unit: string } | null;
  factors: string[];
}

function validateDose(
  drug: string,
  dose: number,
  route: 'oral' | 'iv' | 'im' | 'sc' | 'topical',
  patientWeight?: number,
  patientAge?: number,
  renalFunction?: number
): DoseValidationResult {
  const rules = getDoseRules(drug, route);
  if (!rules) return { valid: true, message: 'No validation rules available', suggestedRange: null, factors: [] };
  const factors: string[] = [];

  // SAFETY: if rules require weight but weight missing, BLOCK (not pass)
  if (rules.weightBased) {
    if (!patientWeight || patientWeight <= 0) {
      return { valid: false, message: `Weight required for ${drug} (mg/kg drug)`,
        suggestedRange: null, factors: ['weight_missing'] };
    }
    factors.push('weight');
    const maxDose = rules.maxPerKg * patientWeight;
    if (dose > maxDose) {
      return { valid: false, message: `Dose exceeds max for ${patientWeight}kg`,
        suggestedRange: { min: rules.minPerKg * patientWeight, max: maxDose, unit: rules.unit }, factors };
    }
  }

  // Age-based adjustment (when rules define age brackets and age is provided)
  if (rules.ageAdjusted && patientAge !== undefined) {
    factors.push('age');
    const ageMax = rules.getAgeAdjustedMax(patientAge);
    if (dose > ageMax) {
      return { valid: false, message: `Exceeds age-adjusted max for ${patientAge}yr`,
        suggestedRange: { min: rules.typicalMin, max: ageMax, unit: rules.unit }, factors };
    }
  }

  // Renal adjustment (when rules define eGFR brackets and eGFR is provided)
  if (rules.renalAdjusted && renalFunction !== undefined) {
    factors.push('renal');
    const renalMax = rules.getRenalAdjustedMax(renalFunction);
    if (dose > renalMax) {
      return { valid: false, message: `Exceeds renal-adjusted max for eGFR ${renalFunction}`,
        suggestedRange: { min: rules.typicalMin, max: renalMax, unit: rules.unit }, factors };
    }
  }

  // Absolute max
  if (dose > rules.absoluteMax) {
    return { valid: false, message: `Exceeds absolute max ${rules.absoluteMax}${rules.unit}`,
      suggestedRange: { min: rules.typicalMin, max: rules.absoluteMax, unit: rules.unit },
      factors: [...factors, 'absolute_max'] };
  }
  return { valid: true, message: 'Within range',
    suggestedRange: { min: rules.typicalMin, max: rules.typicalMax, unit: rules.unit }, factors };
}
```

### 臨床スコアリング: NEWS2

```typescript
interface NEWS2Input {
  respiratoryRate: number; oxygenSaturation: number; supplementalOxygen: boolean;
  temperature: number; systolicBP: number; heartRate: number;
  consciousness: 'alert' | 'voice' | 'pain' | 'unresponsive';
}
interface NEWS2Result {
  total: number;           // 0-20
  risk: 'low' | 'low-medium' | 'medium' | 'high';
  components: Record<string, number>;
  escalation: string;
}
```

スコアリングテーブルは Royal College of Physicians 仕様と厳密に一致しなければならない。

### アラート重症度と UI 挙動

| 重症度 | UI 挙動 | 臨床医アクション要求 |
|----------|-------------|--------------------------|
| Critical | アクション阻止。非閉鎖モーダル。赤。 | 続行には override 理由のドキュメント化が必須 |
| Major | インラインの警告バナー。橙。 | 続行前に確認必須 |
| Minor | インラインの情報ノート。黄。 | 認識のみ、アクション不要 |

Critical アラートは**絶対に**自動閉鎖されないこと、トースト通知として実装しないこと。Override 理由は監査証跡に保存する。

### CDSS のテスト（false negative ゼロ許容）

```typescript
describe('CDSS — Patient Safety', () => {
  INTERACTION_PAIRS.forEach(({ drugA, drugB, severity }) => {
    it(`detects ${drugA} + ${drugB} (${severity})`, () => {
      const alerts = checkInteractions(drugA, [drugB], []);
      expect(alerts.length).toBeGreaterThan(0);
      expect(alerts[0].severity).toBe(severity);
    });
    it(`detects ${drugB} + ${drugA} (reverse)`, () => {
      const alerts = checkInteractions(drugB, [drugA], []);
      expect(alerts.length).toBeGreaterThan(0);
    });
  });
  it('blocks mg/kg drug when weight is missing', () => {
    const result = validateDose('gentamicin', 300, 'iv');
    expect(result.valid).toBe(false);
    expect(result.factors).toContain('weight_missing');
  });
  it('handles malformed drug data gracefully', () => {
    expect(() => checkInteractions('', [], [])).not.toThrow();
  });
});
```

合格基準: 100%。相互作用1件の見落としは患者安全インシデントである。

### アンチパターン

- CDSS チェックをドキュメント化された理由なくオプションまたはスキップ可能にする
- 相互作用チェックをトースト通知として実装する
- 薬物または臨床データに `any` 型を使う
- 維持可能データ構造を使わず相互作用ペアをハードコードする
- CDSS エンジンでエラーを silent catch する（必ず大声で表面化する）
- 体重不在時に体重ベース検証をスキップする（pass せず block する）

## 例

### 例 1: 薬物相互作用チェック

```typescript
const alerts = checkInteractions('warfarin', ['aspirin', 'metformin'], ['penicillin']);
// [{ severity: 'critical', pair: ['warfarin', 'aspirin'],
//    message: 'Increased bleeding risk', recommendation: 'Avoid combination' }]
```

### 例 2: 用量検証

```typescript
const ok = validateDose('paracetamol', 1000, 'oral', 70, 45);
// { valid: true, suggestedRange: { min: 500, max: 4000, unit: 'mg' } }

const bad = validateDose('paracetamol', 5000, 'oral', 70, 45);
// { valid: false, message: 'Exceeds absolute max 4000mg' }

const noWeight = validateDose('gentamicin', 300, 'iv');
// { valid: false, factors: ['weight_missing'] }
```

### 例 3: NEWS2 スコアリング

```typescript
const result = calculateNEWS2({
  respiratoryRate: 24, oxygenSaturation: 93, supplementalOxygen: true,
  temperature: 38.5, systolicBP: 100, heartRate: 110, consciousness: 'voice'
});
// { total: 13, risk: 'high', escalation: 'Urgent clinical review. Consider ICU.' }
```

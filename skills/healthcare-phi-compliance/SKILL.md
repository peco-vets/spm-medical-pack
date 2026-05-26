---
name: healthcare-phi-compliance
description: ヘルスケアアプリ向け PHI（保護されるべき健康情報）/PII（個人識別情報）コンプライアンスパターン（healthcare PHI/PII, HIPAA, DISHA, GDPR, RLS, audit trail）。データ分類、アクセス制御、監査証跡、暗号化、一般的な漏洩経路を網羅。
origin: Health1 Super Speciality Hospitals — contributed by Dr. Keyur Patel
version: "1.0.0"
---

# ヘルスケア PHI/PII コンプライアンスパターン

ヘルスケアアプリにおける患者データ・臨床医データ・金融データを保護するパターンである。HIPAA（米国）、DISHA（インド）、GDPR（EU）、汎用ヘルスケアデータ保護に適用可能である。

## 利用タイミング

- 患者記録に触れる任意の機能の構築
- 臨床システムのアクセス制御または認証の実装
- ヘルスケアデータの DB スキーマ設計
- 患者または臨床医データを返す API の構築
- 監査証跡またはロギングの実装
- データ露出脆弱性に対するコードレビュー
- マルチテナントヘルスケアシステムへの Row-Level Security (RLS) 設定

## 仕組み

ヘルスケアデータ保護は3層で動作する: **分類**（何が機密か）、**アクセス制御**（誰が見られるか）、**監査**（誰が見たか）。

### データ分類

**PHI（保護されるべき健康情報）** — 患者を識別可能で AND 健康に関連するデータ: 患者名、生年月日、住所、電話、メール、国民 ID 番号（SSN、Aadhaar、NHS 番号）、医療記録番号、診断、薬剤、検査結果、画像、保険ポリシー・クレーム詳細、予約・入院記録、上記の組み合わせ。

ヘルスケアシステムでの **PII（患者非機密データ）**: 臨床医/スタッフ個人詳細、医師報酬構造・支払額、従業員給与・銀行詳細、ベンダー支払情報。

### アクセス制御: Row-Level Security

```sql
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- Scope access by facility
CREATE POLICY "staff_read_own_facility"
  ON patients FOR SELECT TO authenticated
  USING (facility_id IN (
    SELECT facility_id FROM staff_assignments
    WHERE user_id = auth.uid() AND role IN ('doctor','nurse','lab_tech','admin')
  ));

-- Audit log: insert-only (tamper-proof)
CREATE POLICY "audit_insert_only" ON audit_log FOR INSERT
  TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "audit_no_modify" ON audit_log FOR UPDATE USING (false);
CREATE POLICY "audit_no_delete" ON audit_log FOR DELETE USING (false);
```

### 監査証跡

すべての PHI アクセスまたは変更をログする。

```typescript
interface AuditEntry {
  timestamp: string;
  user_id: string;
  patient_id: string;
  action: 'create' | 'read' | 'update' | 'delete' | 'print' | 'export';
  resource_type: string;
  resource_id: string;
  changes?: { before: object; after: object };
  ip_address: string;
  session_id: string;
}
```

### 一般的な漏洩経路

**エラーメッセージ:** クライアントへスローされるエラーメッセージに患者識別データを含めない。詳細はサーバー側のみでログする。

**コンソール出力:** 完全な患者オブジェクトをログしない。不透明な内部レコード ID（UUID）を使う — 医療記録番号・国民 ID・氏名ではない。

**URL パラメータ:** 患者識別データをクエリ文字列やパスセグメントに置かない。ログやブラウザ履歴に出現しうる。不透明 UUID のみを使う。

**ブラウザストレージ:** PHI を localStorage や sessionStorage に保存しない。PHI はメモリ内のみに保ち、必要時に取得する。

**Service role キー:** クライアントサイドコードで service_role キーを使わない。anon/publishable キーを使い、RLS にアクセスを強制させる。

**ログとモニタリング:** 完全な患者レコードをログしない。不透明レコード ID のみを使う（医療記録番号ではない）。エラー追跡サービス送信前にスタックトレースをサニタイズする。

### DB スキーマタグ付け

PHI/PII カラムをスキーマレベルでマークする。

```sql
COMMENT ON COLUMN patients.name IS 'PHI: patient_name';
COMMENT ON COLUMN patients.dob IS 'PHI: date_of_birth';
COMMENT ON COLUMN patients.aadhaar IS 'PHI: national_id';
COMMENT ON COLUMN doctor_payouts.amount IS 'PII: financial';
```

### デプロイチェックリスト

各デプロイ前に確認する:
- エラーメッセージまたはスタックトレースに PHI なし
- console.log/console.error に PHI なし
- URL パラメータに PHI なし
- ブラウザストレージに PHI なし
- クライアントコードに service_role キーなし
- すべての PHI/PII テーブルで RLS 有効
- すべてのデータ変更に監査証跡
- セッションタイムアウト構成済み
- すべての PHI エンドポイントに API 認証
- 施設間データ隔離検証済み

## 例

### 例 1: 安全 vs 危険なエラーハンドリング

```typescript
// BAD — leaks PHI in error
throw new Error(`Patient ${patient.name} not found in ${patient.facility}`);

// GOOD — generic error, details logged server-side with opaque IDs only
logger.error('Patient lookup failed', { recordId: patient.id, facilityId });
throw new Error('Record not found');
```

### 例 2: マルチ施設隔離の RLS ポリシー

```sql
-- Doctor at Facility A cannot see Facility B patients
CREATE POLICY "facility_isolation"
  ON patients FOR SELECT TO authenticated
  USING (facility_id IN (
    SELECT facility_id FROM staff_assignments WHERE user_id = auth.uid()
  ));

-- Test: login as doctor-facility-a, query facility-b patients
-- Expected: 0 rows returned
```

### 例 3: 安全なロギング

```typescript
// BAD — logs identifiable patient data
console.log('Processing patient:', patient);

// GOOD — logs only opaque internal record ID
console.log('Processing record:', patient.id);
// Note: even patient.id should be an opaque UUID, not a medical record number
```

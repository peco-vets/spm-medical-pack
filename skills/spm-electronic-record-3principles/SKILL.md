---
name: spm-electronic-record-3principles
description: 診療録・カルテ・処方箋・X線写真・検査結果等の医療記録を電子的に保存／更新／削除／参照／監査するコードを書く時に必ず使う、医療法施行規則の電子保存3原則（真正性・見読性・保存性）の実装パターン。診療録は5年保存、X線写真は3年保存。改ざん検知（電子署名・ハッシュチェーン・タイムスタンプ）、任意時点での参照可能性、法定期間中の確実な保存を満たす実装を提示する。EMR・電子カルテ・診療簿・問診票・処置記録の CRUD 設計時に必須参照。
---

# 電子保存3原則の実装パターン（SPM）

医療法施行規則および厚労省ガイドラインに基づく、医療記録の電子保存に求められる3つの要件を実装レベルで満たすパターン集。

## 3原則と保存期間

### 法定保存期間
| 記録種別 | 保存期間 | 根拠 |
|---|---|---|
| 診療録（カルテ） | 5年 | 医師法 24条 / 獣医師法 21条 |
| 診療に関する諸記録（X線写真・処方箋等） | 3年 | 医療法施行規則 20条 / 獣医療法 |
| 検案書・出生証明等 | 5年 | 医師法 |
| 監査ログ | 3年以上（推奨 5年） | 3省2GL |

### 真正性（Integrity）
**作成責任者が明確で、改ざんがないこと**

実装パターン：
- 全レコードに `createdBy` / `updatedBy`（ユーザ ID）を保持
- 全更新を別テーブル（`MedicalRecordRevision` 等）に履歴として記録（追記専用）
- 改ざん検知ハッシュ：レコード内容 + 前レコードのハッシュ → ハッシュチェーン
- 電子署名（タイムスタンプ局トークン）：法的必須ではないが推奨
- DB の論理削除（`deletedAt`）のみ、物理削除禁止

```typescript
// Prisma スキーマ例
model MedicalRecord {
  id          String   @id @default(cuid())
  patientId   String
  content     String   @db.Text
  contentHash String   // SHA-256(content + prevHash)
  prevHash    String?  // 前 revision のハッシュ
  createdBy   String
  createdAt   DateTime @default(now())
  deletedAt   DateTime? // 論理削除のみ
  revisions   MedicalRecordRevision[]
}

model MedicalRecordRevision {
  id          String   @id @default(cuid())
  recordId    String
  record      MedicalRecord @relation(fields: [recordId], references: [id])
  content     String   @db.Text
  contentHash String
  changedBy   String
  changedAt   DateTime @default(now())
  reason      String   // 修正理由必須
}
```

### 見読性（Readability）
**法定保存期間を通じて、肉眼で読める形で表示・印刷できること**

実装パターン：
- データ形式：PDF / HTML / JSON 等の標準フォーマット
- 独自バイナリ形式を避ける（ベンダーロックイン回避）
- 文字コード：UTF-8 統一、廃字対策
- 画像：DICOM（標準形式）、JPEG/PNG（圧縮率記録）
- 表示・印刷機能の継続提供（OS・ブラウザのバージョンアップに追従）

### 保存性（Preservation）
**法定保存期間中、滅失・破壊・改変されないこと**

実装パターン：
- バックアップ：日次フル + 増分、3拠点以上に分散（地理的冗長化）
- ストレージ：WORM（Write Once Read Many）または S3 Object Lock
- 媒体劣化対策：定期的なデータ移行（マイグレーション計画）
- 暗号化：AES-256、鍵は KMS で管理（紛失時に復号不能のリスクと両立させる）
- 復元訓練：年1回以上、復元できることを確認
- 法定期間経過後の安全な廃棄手順

```typescript
// バックアップ設定例（pg_dump + S3）
// .github/workflows/medical-backup.yml
// - 日次フル: 23:00 JST
// - 増分: 1時間ごと WAL アーカイブ
// - 保存先: S3 (us-west-2) + (ap-northeast-1) + on-prem NAS
// - Object Lock: COMPLIANCE モード、保持期間 5年+
```

## 違反パターン（やってはいけない）

- ❌ 診療録の物理 DELETE（論理削除のみ）
- ❌ 更新履歴を残さず上書き UPDATE
- ❌ 平文での DB 保存（要配慮個人情報部分）
- ❌ ローカルマシンのみへの保存（バックアップ無し）
- ❌ 独自バイナリ形式のみで保存（読み出し不能リスク）
- ❌ シークレット／鍵をコードにハードコード

## チェック観点（PR レビュー時）

1. このコードは医療記録の CRUD に該当するか？ → Yes なら以下続行
2. 削除パスは論理削除か？
3. 更新時に履歴テーブルに書いているか？
4. createdBy / updatedBy が必須フィールドか？
5. バックアップ対象に含まれているか？
6. 監査ログに記録されるか？

## 関連法令
- 医師法 24条 / 獣医師法 21条 — 診療録の作成・保存義務
- 医療法施行規則 20条 — 諸記録の保存
- 厚労省「医療情報システムの安全管理に関するガイドライン」第6.0版 — 電子保存の技術要件

## 参照

- [[spm-3sho-2gl-check]]（合わせて使う）
- [[spm-sensitive-personal-info]]（暗号化・同意取得の補完）
- Obsidian: `SPM/スキル/ECC_Everything-Claude-Code.md`

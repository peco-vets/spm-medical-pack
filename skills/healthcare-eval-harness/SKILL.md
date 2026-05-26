---
name: healthcare-eval-harness
description: ヘルスケアアプリケーションデプロイ向けの患者安全評価ハーネス（healthcare eval harness, patient safety, CDSS accuracy, PHI exposure, deployment gating）。CDSS 精度・PHI 露出・臨床ワークフロー整合性・統合コンプライアンスの自動テストスイート。安全失敗時はデプロイをブロックする。
origin: Health1 Super Speciality Hospitals — contributed by Dr. Keyur Patel
version: "1.0.0"
---

# ヘルスケア Eval Harness — 患者安全検証

ヘルスケアアプリデプロイ向け自動検証システムである。単一の CRITICAL 失敗でデプロイをブロックする。患者安全は譲歩不可である。

> **備考:** 例は Jest をリファレンステストランナーとして用いる。Vitest、pytest、PHPUnit などフレームワークに合わせて適応する — テストカテゴリと合格しきい値はフレームワーク非依存である。

## 利用タイミング

- EMR/EHR アプリの任意デプロイ前
- CDSS ロジック（薬物相互作用、用量検証、スコアリング）の変更後
- 患者データに触れる DB スキーマ変更後
- 認証またはアクセス制御の変更後
- ヘルスケアアプリの CI/CD パイプライン構成時
- 臨床モジュールの merge conflict 解決後

## 仕組み

eval harness は5つのテストカテゴリを順に実行する。最初の3つ（CDSS 精度、PHI 露出、データ整合性）は 100% 合格率を要する CRITICAL ゲートで、1件の失敗でデプロイをブロックする。残り2つ（臨床ワークフロー、統合）は 95%+ 合格率の HIGH ゲートである。

各カテゴリは Jest テストパスパターンにマッピングされる。CI パイプラインは CRITICAL ゲートを `--bail`（初回失敗で停止）で実行し、カバレッジしきい値を `--coverage --coverageThreshold` で強制する。

### Eval カテゴリ

**1. CDSS 精度（CRITICAL — 100% 必須）**

すべての臨床意思決定支援ロジックをテストする: 薬物相互作用ペア（双方向）、用量検証ルール、公開仕様に対する臨床スコアリング、false negative なし、silent failure なし。

```bash
npx jest --testPathPattern='tests/cdss' --bail --ci --coverage
```

**2. PHI 露出（CRITICAL — 100% 必須）**

保護されるべき健康情報の漏洩をテストする: API エラーレスポンス、コンソール出力、URL パラメータ、ブラウザストレージ、施設横断隔離、未認証アクセス、サービスロールキーの不在。

```bash
npx jest --testPathPattern='tests/security/phi' --bail --ci
```

**3. データ整合性（CRITICAL — 100% 必須）**

臨床データ安全性をテストする: ロック済み診察、監査証跡エントリ、カスケード削除保護、並行編集処理、孤立レコードなし。

```bash
npx jest --testPathPattern='tests/data-integrity' --bail --ci
```

**4. 臨床ワークフロー（HIGH — 95%+ 必須）**

E2E フローをテストする: 診察ライフサイクル、テンプレートレンダリング、薬剤セット、薬品/診断検索、処方箋 PDF、レッドフラグアラート。

```bash
tmp_json=$(mktemp)
npx jest --testPathPattern='tests/clinical' --ci --json --outputFile="$tmp_json" || true
total=$(jq '.numTotalTests // 0' "$tmp_json")
passed=$(jq '.numPassedTests // 0' "$tmp_json")
if [ "$total" -eq 0 ]; then
  echo "No clinical tests found" >&2
  exit 1
fi
rate=$(echo "scale=2; $passed * 100 / $total" | bc)
echo "Clinical pass rate: ${rate}% ($passed/$total)"
```

**5. 統合コンプライアンス（HIGH — 95%+ 必須）**

外部システムをテストする: HL7 メッセージパース（v2.x）、FHIR バリデーション、検査結果マッピング、不正メッセージ処理。

```bash
tmp_json=$(mktemp)
npx jest --testPathPattern='tests/integration' --ci --json --outputFile="$tmp_json" || true
total=$(jq '.numTotalTests // 0' "$tmp_json")
passed=$(jq '.numPassedTests // 0' "$tmp_json")
if [ "$total" -eq 0 ]; then
  echo "No integration tests found" >&2
  exit 1
fi
rate=$(echo "scale=2; $passed * 100 / $total" | bc)
echo "Integration pass rate: ${rate}% ($passed/$total)"
```

### 合否マトリクス

| カテゴリ | しきい値 | 失敗時 |
|----------|-----------|------------|
| CDSS 精度 | 100% | **デプロイ BLOCK** |
| PHI 露出 | 100% | **デプロイ BLOCK** |
| データ整合性 | 100% | **デプロイ BLOCK** |
| 臨床ワークフロー | 95%+ | WARN、レビュー付き許可 |
| 統合 | 95%+ | WARN、レビュー付き許可 |

### CI/CD 統合

```yaml
name: Healthcare Safety Gate
on: [push, pull_request]

jobs:
  safety-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci

      # CRITICAL gates — 100% required, bail on first failure
      - name: CDSS Accuracy
        run: npx jest --testPathPattern='tests/cdss' --bail --ci --coverage --coverageThreshold='{"global":{"branches":80,"functions":80,"lines":80}}'

      - name: PHI Exposure Check
        run: npx jest --testPathPattern='tests/security/phi' --bail --ci

      - name: Data Integrity
        run: npx jest --testPathPattern='tests/data-integrity' --bail --ci

      # HIGH gates — 95%+ required, custom threshold check
      # HIGH gates — 95%+ required
      - name: Clinical Workflows
        run: |
          TMP_JSON=$(mktemp)
          npx jest --testPathPattern='tests/clinical' --ci --json --outputFile="$TMP_JSON" || true
          TOTAL=$(jq '.numTotalTests // 0' "$TMP_JSON")
          PASSED=$(jq '.numPassedTests // 0' "$TMP_JSON")
          if [ "$TOTAL" -eq 0 ]; then
            echo "::error::No clinical tests found"; exit 1
          fi
          RATE=$(echo "scale=2; $PASSED * 100 / $TOTAL" | bc)
          echo "Pass rate: ${RATE}% ($PASSED/$TOTAL)"
          if (( $(echo "$RATE < 95" | bc -l) )); then
            echo "::warning::Clinical pass rate ${RATE}% below 95%"
          fi

      - name: Integration Compliance
        run: |
          TMP_JSON=$(mktemp)
          npx jest --testPathPattern='tests/integration' --ci --json --outputFile="$TMP_JSON" || true
          TOTAL=$(jq '.numTotalTests // 0' "$TMP_JSON")
          PASSED=$(jq '.numPassedTests // 0' "$TMP_JSON")
          if [ "$TOTAL" -eq 0 ]; then
            echo "::error::No integration tests found"; exit 1
          fi
          RATE=$(echo "scale=2; $PASSED * 100 / $TOTAL" | bc)
          echo "Pass rate: ${RATE}% ($PASSED/$TOTAL)"
          if (( $(echo "$RATE < 95" | bc -l) )); then
            echo "::warning::Integration pass rate ${RATE}% below 95%"
          fi
```

### アンチパターン

- 「前回 pass したから」と CDSS テストをスキップする
- CRITICAL しきい値を 100% 未満に設定する
- CRITICAL テストスイートで `--no-bail` を使う
- 統合テストで CDSS エンジンをモックする（実ロジックをテストするべきである）
- 安全ゲートが赤の状態でデプロイを許可する
- CDSS スイートで `--coverage` なしにテストを実行する

## 例

### 例 1: ローカルですべての Critical ゲートを実行

```bash
npx jest --testPathPattern='tests/cdss' --bail --ci --coverage && \
npx jest --testPathPattern='tests/security/phi' --bail --ci && \
npx jest --testPathPattern='tests/data-integrity' --bail --ci
```

### 例 2: HIGH ゲートの合格率確認

```bash
tmp_json=$(mktemp)
npx jest --testPathPattern='tests/clinical' --ci --json --outputFile="$tmp_json" || true
jq '{
  passed: (.numPassedTests // 0),
  total: (.numTotalTests // 0),
  rate: (if (.numTotalTests // 0) == 0 then 0 else ((.numPassedTests // 0) / (.numTotalTests // 1) * 100) end)
}' "$tmp_json"
# Expected: { "passed": 21, "total": 22, "rate": 95.45 }
```

### 例 3: Eval レポート

```
## Healthcare Eval: 2026-03-27 [commit abc1234]

### Patient Safety: PASS

| Category | Tests | Pass | Fail | Status |
|----------|-------|------|------|--------|
| CDSS Accuracy | 39 | 39 | 0 | PASS |
| PHI Exposure | 8 | 8 | 0 | PASS |
| Data Integrity | 12 | 12 | 0 | PASS |
| Clinical Workflow | 22 | 21 | 1 | 95.5% PASS |
| Integration | 6 | 6 | 0 | PASS |

### Coverage: 84% (target: 80%+)
### Verdict: SAFE TO DEPLOY
```

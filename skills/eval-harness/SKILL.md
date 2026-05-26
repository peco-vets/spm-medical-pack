---
name: eval-harness
description: eval-driven development (EDD) 原則を実装する Claude Code セッション向けの形式的評価フレームワーク（eval harness, EDD, pass@k）。
origin: ECC
tools: Read, Write, Edit, Bash, Grep, Glob
---

# Eval Harness スキル

eval-driven development (EDD) 原則を実装する Claude Code セッション向けの形式的評価フレームワークである。

## 起動タイミング

- AI 支援ワークフロー向け eval-driven development (EDD) のセットアップ
- Claude Code のタスク完了について pass/fail 基準を定義する
- pass@k メトリクスでエージェント信頼性を計測する
- プロンプトまたはエージェント変更に対する回帰テストスイートの作成
- モデルバージョン横断のエージェント性能ベンチマーク

## 哲学

Eval-Driven Development は eval を「AI 開発のユニットテスト」として扱う。
- 実装前に期待挙動を定義する
- 開発中に継続的に eval を実行する
- 変更ごとに回帰を追跡する
- 信頼性計測に pass@k メトリクスを使う

## Eval タイプ

### Capability Evals

Claude が以前できなかったことをできるかをテストする。
```markdown
[CAPABILITY EVAL: feature-name]
Task: Description of what Claude should accomplish
Success Criteria:
  - [ ] Criterion 1
  - [ ] Criterion 2
  - [ ] Criterion 3
Expected Output: Description of expected result
```

### Regression Evals

変更が既存機能を壊さないことを確認する。
```markdown
[REGRESSION EVAL: feature-name]
Baseline: SHA or checkpoint name
Tests:
  - existing-test-1: PASS/FAIL
  - existing-test-2: PASS/FAIL
  - existing-test-3: PASS/FAIL
Result: X/Y passed (previously Y/Y)
```

## グレーダタイプ

### 1. コードベースグレーダ

コードによる決定論的チェック。
```bash
# Check if file contains expected pattern
grep -q "export function handleAuth" src/auth.ts && echo "PASS" || echo "FAIL"

# Check if tests pass
npm test -- --testPathPattern="auth" && echo "PASS" || echo "FAIL"

# Check if build succeeds
npm run build && echo "PASS" || echo "FAIL"
```

### 2. モデルベースグレーダ

オープンエンドな出力を Claude で評価する。
```markdown
[MODEL GRADER PROMPT]
Evaluate the following code change:
1. Does it solve the stated problem?
2. Is it well-structured?
3. Are edge cases handled?
4. Is error handling appropriate?

Score: 1-5 (1=poor, 5=excellent)
Reasoning: [explanation]
```

### 3. 人間グレーダ

手動レビューを要するものをフラグする。
```markdown
[HUMAN REVIEW REQUIRED]
Change: Description of what changed
Reason: Why human review is needed
Risk Level: LOW/MEDIUM/HIGH
```

## メトリクス

### pass@k

「k 回試行で少なくとも1回成功」
- pass@1: 初回成功率
- pass@3: 3回以内の成功率
- 一般的目標: pass@3 > 90%

### pass^k

「k 回試行すべてが成功」
- 信頼性のより高い水準
- pass^3: 3回連続成功
- クリティカルパス向け

## Eval ワークフロー

### 1. 定義（コーディング前）
```markdown
## EVAL DEFINITION: feature-xyz

### Capability Evals
1. Can create new user account
2. Can validate email format
3. Can hash password securely

### Regression Evals
1. Existing login still works
2. Session management unchanged
3. Logout flow intact

### Success Metrics
- pass@3 > 90% for capability evals
- pass^3 = 100% for regression evals
```

### 2. 実装

定義した eval を通すコードを書く。

### 3. 評価
```bash
# Run capability evals
[Run each capability eval, record PASS/FAIL]

# Run regression evals
npm test -- --testPathPattern="existing"

# Generate report
```

### 4. レポート
```markdown
EVAL REPORT: feature-xyz
========================

Capability Evals:
  create-user:     PASS (pass@1)
  validate-email:  PASS (pass@2)
  hash-password:   PASS (pass@1)
  Overall:         3/3 passed

Regression Evals:
  login-flow:      PASS
  session-mgmt:    PASS
  logout-flow:     PASS
  Overall:         3/3 passed

Metrics:
  pass@1: 67% (2/3)
  pass@3: 100% (3/3)

Status: READY FOR REVIEW
```

## 統合パターン

### 実装前
```
/eval define feature-name
```
`.claude/evals/feature-name.md` に eval 定義ファイルを生成する。

### 実装中
```
/eval check feature-name
```
現在の eval を実行し状態を報告する。

### 実装後
```
/eval report feature-name
```
完全な eval レポートを生成する。

## Eval 保管

プロジェクト内に eval を保管する。
```
.claude/
  evals/
    feature-xyz.md      # Eval definition
    feature-xyz.log     # Eval run history
    baseline.json       # Regression baselines
```

## ベストプラクティス

1. **コーディング前に eval を定義する** — 成功基準について明確に思考する
2. **頻繁に eval を実行する** — 回帰を早期に検出する
3. **時系列で pass@k を追跡する** — 信頼性トレンドを監視する
4. **可能ならコードグレーダを使う** — 決定論 > 確率
5. **セキュリティは人間レビュー** — セキュリティチェックを完全自動化しない
6. **eval を高速に保つ** — 遅い eval は実行されない
7. **eval をコードとバージョン管理する** — eval は第一級成果物である

## 例: 認証追加

```markdown
## EVAL: add-authentication

### Phase 1: Define (10 min)
Capability Evals:
- [ ] User can register with email/password
- [ ] User can login with valid credentials
- [ ] Invalid credentials rejected with proper error
- [ ] Sessions persist across page reloads
- [ ] Logout clears session

Regression Evals:
- [ ] Public routes still accessible
- [ ] API responses unchanged
- [ ] Database schema compatible

### Phase 2: Implement (varies)
[Write code]

### Phase 3: Evaluate
Run: /eval check add-authentication

### Phase 4: Report
EVAL REPORT: add-authentication
==============================
Capability: 5/5 passed (pass@3: 100%)
Regression: 3/3 passed (pass^3: 100%)
Status: SHIP IT
```

## プロダクト Eval (v1.8)

挙動品質をユニットテスト単独で捕捉できない場合にプロダクト eval を用いる。

### グレーダタイプ

1. コードグレーダ（決定論的アサーション）
2. ルールグレーダ（regex/schema 制約）
3. モデルグレーダ（LLM-as-judge ルーブリック）
4. 人間グレーダ（曖昧な出力の手動裁定）

### pass@k のガイダンス

- `pass@1`: 直接信頼性
- `pass@3`: 制御されたリトライ下での実用信頼性
- `pass^3`: 安定性テスト（3回すべて成功必須）

推奨閾値:
- Capability eval: pass@3 ≥ 0.90
- Regression eval: リリースクリティカルパスで pass^3 = 1.00

### Eval アンチパターン

- 既知 eval 例にプロンプトを過適合させる
- ハッピーパス出力のみを計測する
- pass 率を追ってコストとレイテンシのドリフトを無視する
- フレーキーなグレーダをリリースゲートに残す

### 最小 Eval アーティファクトレイアウト

- `.claude/evals/<feature>.md` 定義
- `.claude/evals/<feature>.log` 実行履歴
- `docs/releases/<version>/eval-summary.md` リリーススナップショット

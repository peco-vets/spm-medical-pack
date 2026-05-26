---
name: verification-loop
description: "Claude Code セッションの包括的な検証システム（comprehensive verification system for Claude Code sessions）。"
origin: ECC
---

# Verification Loop スキル

Claude Code セッションの包括的な検証システム。

## 使用するタイミング

このスキルを呼び出す：
- 機能完了または重要なコード変更後
- PR 作成前
- 品質ゲートが通過することを保証したいとき
- リファクタリング後

## 検証フェーズ

### フェーズ 1：ビルド検証
```bash
# Check if project builds
npm run build 2>&1 | tail -20
# OR
pnpm build 2>&1 | tail -20
```

ビルドに失敗したら、続行前に停止して修正する。

### フェーズ 2：型チェック
```bash
# TypeScript projects
npx tsc --noEmit 2>&1 | head -30

# Python projects
pyright . 2>&1 | head -30
```

すべての型エラーを報告する。続行前に重要なものを修正する。

### フェーズ 3：リントチェック
```bash
# JavaScript/TypeScript
npm run lint 2>&1 | head -30

# Python
ruff check . 2>&1 | head -30
```

### フェーズ 4：テストスイート
```bash
# Run tests with coverage
npm run test -- --coverage 2>&1 | tail -50

# Check coverage threshold
# Target: 80% minimum
```

報告：
- 合計テスト：X
- 合格：X
- 失敗：X
- カバレッジ：X%

### フェーズ 5：セキュリティスキャン
```bash
# Check for secrets
grep -rn "sk-" --include="*.ts" --include="*.js" . 2>/dev/null | head -10
grep -rn "api_key" --include="*.ts" --include="*.js" . 2>/dev/null | head -10

# Check for console.log
grep -rn "console.log" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | head -10
```

### フェーズ 6：差分レビュー
```bash
# Show what changed
git diff --stat
git diff HEAD~1 --name-only
```

各変更ファイルを以下のためレビュー：
- 意図しない変更
- 欠落エラー処理
- 潜在的エッジケース

## 出力フォーマット

すべてのフェーズ実行後、検証レポートを生成：

```
VERIFICATION REPORT
==================

Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for PR

Issues to Fix:
1. ...
2. ...
```

## 継続モード

長いセッションでは、15 分ごとまたは主要変更後に検証を実行：

```markdown
心のチェックポイントを設定：
- 各関数完了後
- コンポーネント完了後
- 次のタスクに移動する前

実行：/verify
```

## フックとの統合

このスキルは PostToolUse フックを補完するが、より深い検証を提供する。
フックは問題を即座に捕捉する。このスキルは包括的レビューを提供する。

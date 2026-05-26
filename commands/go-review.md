---
description: イディオマティックなパターン、並行処理の安全性、エラーハンドリング、セキュリティに関する包括的な Go コードレビュー。go-reviewer エージェントを起動する / Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.
---

# Go Code Review

このコマンドは **go-reviewer** エージェントを起動し、包括的な Go 固有のコードレビューを行う。

## このコマンドが行うこと

1. **Go 変更を特定**：`git diff` で変更された `.go` ファイルを見つける
2. **静的解析実行**：`go vet`、`staticcheck`、`golangci-lint` を実行する
3. **セキュリティスキャン**：SQL インジェクション、コマンドインジェクション、レースコンディションをチェックする
4. **並行処理レビュー**：goroutine の安全性、チャネル利用、ミューテックスパターンを分析する
5. **イディオマティック Go チェック**：コードが Go 規約・ベストプラクティスに従うか確認する
6. **レポート生成**：重要度別に問題を分類する

## 利用シーン

以下の場合に `/go-review` を使用する：
- Go コードを書いた・変更した後
- Go 変更をコミットする前
- Go コードのプルリクエストをレビューする
- 新しい Go コードベースにオンボードする
- イディオマティックな Go パターンを学ぶ

## レビューカテゴリ

### CRITICAL（必須修正）
- SQL/コマンドインジェクション脆弱性
- 同期なしのレースコンディション
- Goroutine リーク
- ハードコードされた認証情報
- 安全でないポインタ利用
- クリティカルパスで無視されるエラー

### HIGH（修正すべき）
- コンテキスト付きエラーラッピングの不足
- エラー返却ではなく panic
- Context が伝播されない
- バッファ無しチャネルがデッドロックを引き起こす
- インターフェースが満たされないエラー
- ミューテックス保護の不足

### MEDIUM（検討）
- 非イディオマティックなコードパターン
- エクスポートに godoc コメントなし
- 非効率な文字列連結
- スライスが事前確保されていない
- テーブル駆動テストが使われない

## 実行される自動チェック

```bash
# Static analysis
go vet ./...

# Advanced checks (if installed)
staticcheck ./...
golangci-lint run

# Race detection
go build -race ./...

# Security vulnerabilities
govulncheck ./...
```

## 使用例

```text
User: /go-review

Agent:
# Go Code Review Report

## Files Reviewed
- internal/handler/user.go (modified)
- internal/service/auth.go (modified)

## Static Analysis Results
✓ go vet: No issues
✓ staticcheck: No issues

## Issues Found

[CRITICAL] Race Condition
File: internal/service/auth.go:45
Issue: Shared map accessed without synchronization
```go
var cache = map[string]*Session{}  // Concurrent access!

func GetSession(id string) *Session {
    return cache[id]  // Race condition
}
```
Fix: Use sync.RWMutex or sync.Map
```go
var (
    cache   = map[string]*Session{}
    cacheMu sync.RWMutex
)

func GetSession(id string) *Session {
    cacheMu.RLock()
    defer cacheMu.RUnlock()
    return cache[id]
}
```

[HIGH] Missing Error Context
File: internal/handler/user.go:28
Issue: Error returned without context
```go
return err  // No context
```
Fix: Wrap with context
```go
return fmt.Errorf("get user %s: %w", userID, err)
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: FAIL: Block merge until CRITICAL issue is fixed
```

## 承認基準

| ステータス | 条件 |
|--------|-----------|
| PASS: Approve | CRITICAL または HIGH の問題なし |
| WARNING: Warning | MEDIUM の問題のみ（注意してマージ） |
| FAIL: Block | CRITICAL または HIGH の問題あり |

## 他のコマンドとの統合

- まず `/go-test` でテストが通ることを確認する
- ビルドエラーが起きたら `/go-build` を使う
- コミット前に `/go-review` を使う
- Go 固有でない懸念には `/code-review` を使う

## 関連

- Agent: `agents/go-reviewer.md`
- Skills: `skills/golang-patterns/`, `skills/golang-testing/`

---
description: Go のビルドエラー、go vet 警告、リンター問題を段階的に修正する。最小限の外科的修正のために go-build-resolver エージェントを起動する / Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.
---

# Go Build and Fix

このコマンドは **go-build-resolver** エージェントを起動し、最小限の変更で Go ビルドエラーを段階的に修正する。

## このコマンドが行うこと

1. **診断実行**：`go build`、`go vet`、`staticcheck` を実行する
2. **エラーパース**：ファイルごとにグループ化し、重要度でソートする
3. **段階的修正**：一度に1つのエラー
4. **各修正を検証**：各変更後にビルドを再実行する
5. **サマリー報告**：修正されたものと残っているものを表示する

## 利用シーン

以下の場合に `/go-build` を使用する：
- `go build ./...` がエラーで失敗する
- `go vet ./...` が問題を報告する
- `golangci-lint run` が警告を表示する
- モジュール依存関係が壊れている
- ビルドを壊す変更を pull した後

## 実行される診断コマンド

```bash
# Primary build check
go build ./...

# Static analysis
go vet ./...

# Extended linting (if available)
staticcheck ./...
golangci-lint run

# Module issues
go mod verify
go mod tidy -v
```

## セッション例

```text
User: /go-build

Agent:
# Go Build Resolution

## Initial Diagnostics

```bash
$ go build ./...
internal/service/user.go:25:15: undefined: UserRepository
internal/handler/api.go:42:9: cannot use x (type string) as type int
internal/handler/api.go:58:2: missing return at end of function
```

Errors found: 3

## Fix 1: Undefined Identifier

File: internal/service/user.go:25
Error: undefined: UserRepository
Cause: Missing import

```go
// Added import
import "project/internal/repository"

// Changed
var repo UserRepository
// To
var repo repository.UserRepository
```

```bash
$ go build ./...
# 2 errors remaining
```

## Fix 2: Type Mismatch

File: internal/handler/api.go:42
Error: cannot use x (type string) as type int

```go
// Changed
count := params.Get("count")
// To
countStr := params.Get("count")
count, _ := strconv.Atoi(countStr)
```

```bash
$ go build ./...
# 1 error remaining
```

## Fix 3: Missing Return

File: internal/handler/api.go:58
Error: missing return at end of function

```go
func GetUser(id string) (*User, error) {
    if id == "" {
        return nil, ErrInvalidID
    }
    user := findUser(id)
    // Added missing return
    return user, nil
}
```

```bash
$ go build ./...
# Build successful!
```

## Final Verification

```bash
$ go vet ./...
# No issues

$ go test ./...
ok      project/internal/service   0.015s
ok      project/internal/handler   0.023s
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Vet warnings fixed | 0 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: PASS: SUCCESS
```

## よく修正されるエラー

| エラー | 典型的な修正 |
|-------|-------------|
| `undefined: X` | import を追加またはタイプミス修正 |
| `cannot use X as Y` | 型変換または代入修正 |
| `missing return` | return 文を追加 |
| `X does not implement Y` | 不足するメソッドを追加 |
| `import cycle` | パッケージ構成を再構築 |
| `declared but not used` | 変数を削除または使用 |
| `cannot find package` | `go get` または `go mod tidy` |

## 修正戦略

1. **ビルドエラーが先** — コードはまずコンパイルできる必要がある
2. **vet 警告が次** — 疑わしい構造を修正
3. **lint 警告が次** — スタイルとベストプラクティス
4. **一度に1つの修正** — 各変更を検証する
5. **最小限の変更** — リファクタリングせず、修正のみ

## 停止条件

エージェントは以下の場合に停止して報告する：
- 同じエラーが3回試行しても続く場合
- 修正がより多くのエラーを発生させる場合
- アーキテクチャ的な変更が必要な場合
- 外部依存関係が不足している場合

## 関連コマンド

- `/go-test` - ビルド成功後にテスト実行
- `/go-review` - コード品質レビュー
- `verification-loop` skill - 完全な検証ループ

## 関連

- Agent: `agents/go-build-resolver.md`
- Skill: `skills/golang-patterns/`

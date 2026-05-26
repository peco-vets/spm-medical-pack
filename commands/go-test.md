---
description: Go で TDD ワークフローを徹底する。テーブル駆動テストを先に書き、その後実装する。go test -cover で 80%+ のカバレッジを検証する / Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.
---

# Go TDD Command

このコマンドは、イディオマティックな Go テストパターンを使った Go コードのテスト駆動開発手法を徹底する。

## このコマンドが行うこと

1. **型/インターフェース定義**：関数シグネチャをまずスキャフォールドする
2. **テーブル駆動テスト記述**：包括的なテストケースを作成する（RED）
3. **テスト実行**：正しい理由でテストが失敗することを検証する
4. **コード実装**：パスする最小限のコードを書く（GREEN）
5. **リファクタ**：テストをグリーンに保ちながら改善する
6. **カバレッジ確認**：80%+ のカバレッジを確保する

## 利用シーン

以下の場合に `/go-test` を使用する：
- 新しい Go 関数を実装する
- 既存コードにテストカバレッジを追加する
- バグ修正（最初に失敗するテストを書く）
- クリティカルなビジネスロジックを構築する
- Go での TDD ワークフローを学ぶ

## TDD サイクル

```
RED     → Write failing table-driven test
GREEN   → Implement minimal code to pass
REFACTOR → Improve code, tests stay green
REPEAT  → Next test case
```

## セッション例

````
User: /go-test I need a function to validate email addresses

Agent:
# TDD Session: Email Validator

## Step 1: Define Interface

```go
// validator/email.go
package validator

// ValidateEmail checks if the given string is a valid email address.
// Returns nil if valid, error describing the issue otherwise.
func ValidateEmail(email string) error {
    panic("not implemented")
}
```

## Step 2: Write Table-Driven Tests (RED)

```go
// validator/email_test.go
package validator

import (
    "testing"
)

func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        // Valid emails
        {"simple email", "user@example.com", false},
        {"with subdomain", "user@mail.example.com", false},
        {"with plus", "user+tag@example.com", false},
        {"with dots", "first.last@example.com", false},

        // Invalid emails
        {"empty string", "", true},
        {"no at sign", "userexample.com", true},
        {"no domain", "user@", true},
        {"no local part", "@example.com", true},
        {"double at", "user@@example.com", true},
        {"spaces", "user @example.com", true},
        {"no tld", "user@example", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if tt.wantErr && err == nil {
                t.Errorf("ValidateEmail(%q) = nil; want error", tt.email)
            }
            if !tt.wantErr && err != nil {
                t.Errorf("ValidateEmail(%q) = %v; want nil", tt.email, err)
            }
        })
    }
}
```

## Step 3: Run Tests - Verify FAIL

```bash
$ go test ./validator/...

--- FAIL: TestValidateEmail (0.00s)
    --- FAIL: TestValidateEmail/simple_email (0.00s)
        panic: not implemented

FAIL
```

✓ Tests fail as expected (panic).

## Step 4: Implement Minimal Code (GREEN)

```go
// validator/email.go
package validator

import (
    "errors"
    "regexp"
)

var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)

var (
    ErrEmailEmpty   = errors.New("email cannot be empty")
    ErrEmailInvalid = errors.New("email format is invalid")
)

func ValidateEmail(email string) error {
    if email == "" {
        return ErrEmailEmpty
    }
    if !emailRegex.MatchString(email) {
        return ErrEmailInvalid
    }
    return nil
}
```

## Step 5: Run Tests - Verify PASS

```bash
$ go test ./validator/...

PASS
ok      project/validator    0.003s
```

✓ All tests passing!

## Step 6: Check Coverage

```bash
$ go test -cover ./validator/...

PASS
coverage: 100.0% of statements
ok      project/validator    0.003s
```

✓ Coverage: 100%

## TDD Complete!
````

## テストパターン

### テーブル駆動テスト
```go
tests := []struct {
    name     string
    input    InputType
    want     OutputType
    wantErr  bool
}{
    {"case 1", input1, want1, false},
    {"case 2", input2, want2, true},
}

for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        got, err := Function(tt.input)
        // assertions
    })
}
```

### 並列テスト
```go
for _, tt := range tests {
    tt := tt // Capture
    t.Run(tt.name, func(t *testing.T) {
        t.Parallel()
        // test body
    })
}
```

### テストヘルパー
```go
func setupTestDB(t *testing.T) *sql.DB {
    t.Helper()
    db := createDB()
    t.Cleanup(func() { db.Close() })
    return db
}
```

## カバレッジコマンド

```bash
# Basic coverage
go test -cover ./...

# Coverage profile
go test -coverprofile=coverage.out ./...

# View in browser
go tool cover -html=coverage.out

# Coverage by function
go tool cover -func=coverage.out

# With race detection
go test -race -cover ./...
```

## カバレッジ目標

| コードタイプ | 目標 |
|-----------|--------|
| クリティカルなビジネスロジック | 100% |
| 公開 API | 90%+ |
| 一般コード | 80%+ |
| 生成コード | 除外 |

## TDD ベストプラクティス

**やるべきこと：**
- 実装の前に必ずテストを先に書く
- 各変更後にテストを実行する
- 包括的なカバレッジのためにテーブル駆動テストを使う
- 実装詳細ではなく、振る舞いをテストする
- エッジケース（空、nil、最大値）を含める

**やってはいけないこと：**
- テストの前に実装を書く
- RED フェーズをスキップする
- プライベート関数を直接テストする
- テストで `time.Sleep` を使う
- フレーキーなテストを無視する

## 関連コマンド

- `/go-build` - ビルドエラー修正
- `/go-review` - 実装後のコードレビュー
- `verification-loop` skill - 完全な検証ループ

## 関連

- Skill: `skills/golang-testing/`
- Skill: `skills/tdd-workflow/`

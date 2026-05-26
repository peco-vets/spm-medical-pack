---
description: Kotlin で TDD ワークフローを徹底する。Kotest のテストを先に書き、その後実装する。Kover で 80%+ のカバレッジを検証する / Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.
---

# Kotlin TDD Command

このコマンドは、Kotest、MockK、Kover を使った Kotlin コードのテスト駆動開発手法を徹底する。

## このコマンドが行うこと

1. **型/インターフェース定義**：関数シグネチャをまずスキャフォールドする
2. **Kotest テスト記述**：包括的なテスト spec を作成する（RED）
3. **テスト実行**：正しい理由でテストが失敗することを検証する
4. **コード実装**：パスする最小限のコードを書く（GREEN）
5. **リファクタ**：テストをグリーンに保ちながら改善する
6. **カバレッジ確認**：Kover で 80%+ のカバレッジを確保する

## 利用シーン

以下の場合に `/kotlin-test` を使用する：
- 新しい Kotlin 関数またはクラスを実装する
- 既存 Kotlin コードにテストカバレッジを追加する
- バグ修正（最初に失敗するテストを書く）
- クリティカルなビジネスロジックを構築する
- Kotlin での TDD ワークフローを学ぶ

## TDD サイクル

```
RED     -> Write failing Kotest test
GREEN   -> Implement minimal code to pass
REFACTOR -> Improve code, tests stay green
REPEAT  -> Next test case
```

## セッション例

````text
User: /kotlin-test I need a function to validate user registration requests

Agent:
# TDD Session: Registration Validator

## Step 1: Define Interface

```kotlin
// validator/RegistrationValidator.kt
package com.example.validator

data class RegistrationRequest(
    val name: String,
    val email: String,
    val password: String,
)

sealed class ValidationResult {
    data object Valid : ValidationResult()
    data class Invalid(val errors: List<String>) : ValidationResult()
}

fun validateRegistration(request: RegistrationRequest): ValidationResult {
    TODO("not implemented")
}
```

## Step 2: Write Kotest Tests (RED)

```kotlin
// validator/RegistrationValidatorTest.kt
package com.example.validator

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

class RegistrationValidatorTest : FunSpec({
    test("valid registration returns Valid") {
        val request = RegistrationRequest(
            name = "Alice",
            email = "alice@example.com",
            password = "SecureP@ss1",
        )

        val result = validateRegistration(request)

        result.shouldBeInstanceOf<ValidationResult.Valid>()
    }

    test("blank name returns Invalid") {
        val request = RegistrationRequest(
            name = "",
            email = "alice@example.com",
            password = "SecureP@ss1",
        )

        val result = validateRegistration(request)

        val invalid = result.shouldBeInstanceOf<ValidationResult.Invalid>()
        invalid.errors shouldBe listOf("Name is required")
    }

    test("invalid email returns Invalid") {
        val request = RegistrationRequest(
            name = "Alice",
            email = "not-an-email",
            password = "SecureP@ss1",
        )

        val result = validateRegistration(request)

        val invalid = result.shouldBeInstanceOf<ValidationResult.Invalid>()
        invalid.errors shouldBe listOf("Invalid email format")
    }

    test("short password returns Invalid") {
        val request = RegistrationRequest(
            name = "Alice",
            email = "alice@example.com",
            password = "short",
        )

        val result = validateRegistration(request)

        val invalid = result.shouldBeInstanceOf<ValidationResult.Invalid>()
        invalid.errors shouldBe listOf("Password must be at least 8 characters")
    }

    test("multiple errors returns all errors") {
        val request = RegistrationRequest(
            name = "",
            email = "bad",
            password = "short",
        )

        val result = validateRegistration(request)

        val invalid = result.shouldBeInstanceOf<ValidationResult.Invalid>()
        invalid.errors.size shouldBe 3
    }
})
```

## Step 3: Run Tests - Verify FAIL

```bash
$ ./gradlew test

RegistrationValidatorTest > valid registration returns Valid FAILED
  kotlin.NotImplementedError: An operation is not implemented

FAILED (5 tests, 0 passed, 5 failed)
```

✓ Tests fail as expected (NotImplementedError).

## Step 4: Implement Minimal Code (GREEN)

```kotlin
// validator/RegistrationValidator.kt
package com.example.validator

private val EMAIL_REGEX = Regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
private const val MIN_PASSWORD_LENGTH = 8

fun validateRegistration(request: RegistrationRequest): ValidationResult {
    val errors = buildList {
        if (request.name.isBlank()) add("Name is required")
        if (!EMAIL_REGEX.matches(request.email)) add("Invalid email format")
        if (request.password.length < MIN_PASSWORD_LENGTH) add("Password must be at least $MIN_PASSWORD_LENGTH characters")
    }

    return if (errors.isEmpty()) ValidationResult.Valid
    else ValidationResult.Invalid(errors)
}
```

## Step 5: Run Tests - Verify PASS

```bash
$ ./gradlew test

RegistrationValidatorTest > valid registration returns Valid PASSED
RegistrationValidatorTest > blank name returns Invalid PASSED
RegistrationValidatorTest > invalid email returns Invalid PASSED
RegistrationValidatorTest > short password returns Invalid PASSED
RegistrationValidatorTest > multiple errors returns all errors PASSED

PASSED (5 tests, 5 passed, 0 failed)
```

✓ All tests passing!

## Step 6: Check Coverage

```bash
$ ./gradlew koverHtmlReport

Coverage: 100.0% of statements
```

✓ Coverage: 100%

## TDD Complete!
````

## テストパターン

### StringSpec（最もシンプル）

```kotlin
class CalculatorTest : StringSpec({
    "add two positive numbers" {
        Calculator.add(2, 3) shouldBe 5
    }
})
```

### BehaviorSpec（BDD）

```kotlin
class OrderServiceTest : BehaviorSpec({
    Given("a valid order") {
        When("placed") {
            Then("should be confirmed") { /* ... */ }
        }
    }
})
```

### データ駆動テスト

```kotlin
class ParserTest : FunSpec({
    context("valid inputs") {
        withData("2026-01-15", "2026-12-31", "2000-01-01") { input ->
            parseDate(input).shouldNotBeNull()
        }
    }
})
```

### コルーチンテスト

```kotlin
class AsyncServiceTest : FunSpec({
    test("concurrent fetch completes") {
        runTest {
            val result = service.fetchAll()
            result.shouldNotBeEmpty()
        }
    }
})
```

## カバレッジコマンド

```bash
# Run tests with coverage
./gradlew koverHtmlReport

# Verify coverage thresholds
./gradlew koverVerify

# XML report for CI
./gradlew koverXmlReport

# Open HTML report
open build/reports/kover/html/index.html

# Run specific test class
./gradlew test --tests "com.example.UserServiceTest"

# Run with verbose output
./gradlew test --info
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
- 表現力のあるアサーションには Kotest matcher を使う
- suspend 関数には MockK の `coEvery`/`coVerify` を使う
- 実装詳細ではなく、振る舞いをテストする
- エッジケース（空、null、最大値）を含める

**やってはいけないこと：**
- テストの前に実装を書く
- RED フェーズをスキップする
- プライベート関数を直接テストする
- コルーチンテストで `Thread.sleep()` を使う
- フレーキーなテストを無視する

## 関連コマンド

- `/kotlin-build` - ビルドエラー修正
- `/kotlin-review` - 実装後のコードレビュー
- `verification-loop` skill - 完全な検証ループ

## 関連

- Skill: `skills/kotlin-testing/`
- Skill: `skills/tdd-workflow/`

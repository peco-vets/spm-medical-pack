---
description: Kotlin/Gradle のビルドエラー、コンパイラ警告、依存関係問題を段階的に修正する。最小限の外科的修正のために kotlin-build-resolver エージェントを起動する / Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.
---

# Kotlin Build and Fix

このコマンドは **kotlin-build-resolver** エージェントを起動し、最小限の変更で Kotlin ビルドエラーを段階的に修正する。

## このコマンドが行うこと

1. **診断実行**：`./gradlew build`、`detekt`、`ktlintCheck` を実行する
2. **エラーパース**：ファイルごとにグループ化し、重要度でソートする
3. **段階的修正**：一度に1つのエラー
4. **各修正を検証**：各変更後にビルドを再実行する
5. **サマリー報告**：修正されたものと残っているものを表示する

## 利用シーン

以下の場合に `/kotlin-build` を使用する：
- `./gradlew build` がエラーで失敗する
- Kotlin コンパイラがエラーを報告する
- `./gradlew detekt` が違反を報告する
- Gradle 依存解決が失敗する
- ビルドを壊す変更を pull した後

## 実行される診断コマンド

```bash
# Primary build check
./gradlew build 2>&1

# Static analysis
./gradlew detekt 2>&1 || echo "detekt not configured"
./gradlew ktlintCheck 2>&1 || echo "ktlint not configured"

# Dependency issues
./gradlew dependencies --configuration runtimeClasspath 2>&1 | head -100

# Optional deep refresh when caches or dependency metadata are suspect
./gradlew build --refresh-dependencies
```

## セッション例

````text
User: /kotlin-build

Agent:
# Kotlin Build Resolution

## Initial Diagnostics

```bash
$ ./gradlew build
e: src/main/kotlin/com/example/service/UserService.kt:25:15 Unresolved reference: UserRepository
e: src/main/kotlin/com/example/routes/UserRoutes.kt:42:9 Type mismatch: inferred type is String but Int was expected
e: src/main/kotlin/com/example/routes/UserRoutes.kt:58:5 'when' expression must be exhaustive
```

Errors found: 3

## Fix 1: Unresolved Reference

File: src/main/kotlin/com/example/service/UserService.kt:25
Error: Unresolved reference: UserRepository
Cause: Missing import

```kotlin
// Added import
import com.example.repository.UserRepository
```

```bash
$ ./gradlew build
# 2 errors remaining
```

## Fix 2: Type Mismatch

File: src/main/kotlin/com/example/routes/UserRoutes.kt:42
Error: Type mismatch: inferred type is String but Int was expected

```kotlin
// Changed
val count = call.parameters["count"]
// To
val count = call.parameters["count"]?.toIntOrNull()
    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid count")
```

```bash
$ ./gradlew build
# 1 error remaining
```

## Fix 3: Non-Exhaustive When

File: src/main/kotlin/com/example/routes/UserRoutes.kt:58
Error: 'when' expression must be exhaustive

```kotlin
// Added missing branch
when (user.role) {
    Role.ADMIN -> handleAdmin(user)
    Role.USER -> handleUser(user)
    Role.MODERATOR -> handleModerator(user) // Added
}
```

```bash
$ ./gradlew build
# Build successful!
```

## Final Verification

```bash
$ ./gradlew detekt
# No issues

$ ./gradlew test
# All tests passed
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Detekt issues fixed | 0 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: PASS: SUCCESS
````

## よく修正されるエラー

| エラー | 典型的な修正 |
|-------|-------------|
| `Unresolved reference: X` | import または依存関係を追加 |
| `Type mismatch` | 型変換または代入修正 |
| `'when' must be exhaustive` | 不足する sealed class の分岐を追加 |
| `Suspend function can only be called from coroutine` | `suspend` 修飾子を追加 |
| `Smart cast impossible` | ローカル `val` または `let` を使う |
| `None of the following candidates is applicable` | 引数の型を修正 |
| `Could not resolve dependency` | バージョン修正またはリポジトリ追加 |

## 修正戦略

1. **ビルドエラーが先** — コードはまずコンパイルできる必要がある
2. **Detekt 違反が次** — コード品質問題を修正
3. **ktlint 警告が次** — フォーマットを修正
4. **一度に1つの修正** — 各変更を検証する
5. **最小限の変更** — リファクタリングせず、修正のみ

## 停止条件

エージェントは以下の場合に停止して報告する：
- 同じエラーが3回試行しても続く場合
- 修正がより多くのエラーを発生させる場合
- アーキテクチャ的な変更が必要な場合
- 外部依存関係が不足している場合

## 関連コマンド

- `/kotlin-test` - ビルド成功後にテスト実行
- `/kotlin-review` - コード品質レビュー
- `verification-loop` skill - 完全な検証ループ

## 関連

- Agent: `agents/kotlin-build-resolver.md`
- Skill: `skills/kotlin-patterns/`

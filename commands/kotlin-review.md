---
description: イディオマティックなパターン、null 安全性、コルーチン安全性、セキュリティに関する包括的な Kotlin コードレビュー。kotlin-reviewer エージェントを起動する / Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.
---

# Kotlin Code Review

このコマンドは **kotlin-reviewer** エージェントを起動し、包括的な Kotlin 固有のコードレビューを行う。

## このコマンドが行うこと

1. **Kotlin 変更を特定**：`git diff` で変更された `.kt` および `.kts` ファイルを見つける
2. **ビルド & 静的解析実行**：`./gradlew build`、`detekt`、`ktlintCheck` を実行する
3. **セキュリティスキャン**：SQL インジェクション、コマンドインジェクション、ハードコードされたシークレットをチェックする
4. **Null 安全レビュー**：`!!` 利用、プラットフォーム型ハンドリング、安全でないキャストを分析する
5. **コルーチンレビュー**：構造化された並行性、ディスパッチャ利用、キャンセルを確認する
6. **レポート生成**：重要度別に問題を分類する

## 利用シーン

以下の場合に `/kotlin-review` を使用する：
- Kotlin コードを書いた・変更した後
- Kotlin 変更をコミットする前
- Kotlin コードのプルリクエストをレビューする
- 新しい Kotlin コードベースにオンボードする
- イディオマティックな Kotlin パターンを学ぶ

## レビューカテゴリ

### CRITICAL（必須修正）
- SQL/コマンドインジェクション脆弱性
- 正当化なしの強制アンラップ `!!`
- プラットフォーム型 null 安全性違反
- GlobalScope 利用（構造化並行性違反）
- ハードコードされた認証情報
- 安全でないデシリアライズ

### HIGH（修正すべき）
- 不変で十分な場面でのミュータブル状態
- コルーチンコンテキスト内のブロッキング呼び出し
- 長いループでのキャンセルチェック不足
- sealed 型での非網羅的な `when`
- 大きな関数（50行超）
- 深いネスト（4階層超）

### MEDIUM（検討）
- 非イディオマティックな Kotlin（Java スタイルパターン）
- 末尾カンマ不足
- スコープ関数の誤用やネスト
- 大きなコレクションチェーンでの sequence 不足
- 冗長な明示的型

## 実行される自動チェック

```bash
# Build check
./gradlew build

# Static analysis
./gradlew detekt

# Formatting check
./gradlew ktlintCheck

# Tests
./gradlew test
```

## 使用例

````text
User: /kotlin-review

Agent:
# Kotlin Code Review Report

## Files Reviewed
- src/main/kotlin/com/example/service/UserService.kt (modified)
- src/main/kotlin/com/example/routes/UserRoutes.kt (modified)

## Static Analysis Results
✓ Build: Successful
✓ detekt: No issues
WARNING: ktlint: 2 formatting warnings

## Issues Found

[CRITICAL] Force-Unwrap Null Safety
File: src/main/kotlin/com/example/service/UserService.kt:28
Issue: Using !! on nullable repository result
```kotlin
val user = repository.findById(id)!!  // NPE risk
```
Fix: Use safe call with error handling
```kotlin
val user = repository.findById(id)
    ?: throw UserNotFoundException("User $id not found")
```

[HIGH] GlobalScope Usage
File: src/main/kotlin/com/example/routes/UserRoutes.kt:45
Issue: Using GlobalScope breaks structured concurrency
```kotlin
GlobalScope.launch {
    notificationService.sendWelcome(user)
}
```
Fix: Use the call's coroutine scope
```kotlin
launch {
    notificationService.sendWelcome(user)
}
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: FAIL: Block merge until CRITICAL issue is fixed
````

## 承認基準

| ステータス | 条件 |
|--------|-----------|
| PASS: Approve | CRITICAL または HIGH の問題なし |
| WARNING: Warning | MEDIUM の問題のみ（注意してマージ） |
| FAIL: Block | CRITICAL または HIGH の問題あり |

## 他のコマンドとの統合

- まず `/kotlin-test` でテストが通ることを確認する
- ビルドエラーが起きたら `/kotlin-build` を使う
- コミット前に `/kotlin-review` を使う
- Kotlin 固有でない懸念には `/code-review` を使う

## 関連

- Agent: `agents/kotlin-reviewer.md`
- Skills: `skills/kotlin-patterns/`, `skills/kotlin-testing/`

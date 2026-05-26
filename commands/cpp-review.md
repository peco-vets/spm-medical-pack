---
description: メモリ安全性、モダン C++ イディオム、並行処理、セキュリティの包括的な C++ コードレビュー。cpp-reviewer エージェントを起動する / Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.
---

# C++ Code Review

このコマンドは **cpp-reviewer** エージェントを起動し、包括的な C++ 固有のコードレビューを行う。

## このコマンドが行うこと

1. **C++ 変更を特定**：`git diff` で変更された `.cpp`、`.hpp`、`.cc`、`.h` ファイルを見つける
2. **静的解析実行**：`clang-tidy` と `cppcheck` を実行する
3. **メモリ安全スキャン**：raw new/delete、バッファオーバーフロー、use-after-free をチェックする
4. **並行処理レビュー**：スレッド安全性、ミューテックス利用、データ競合を分析する
5. **モダン C++ チェック**：コードが C++17/20 の規約・ベストプラクティスに従っているかを確認する
6. **レポート生成**：重要度別に問題を分類する

## 利用シーン

以下の場合に `/cpp-review` を使用する：
- C++ コードを書いた・変更した後
- C++ 変更をコミットする前
- C++ コードのプルリクエストをレビューする
- 新しい C++ コードベースにオンボードする
- メモリ安全性の問題をチェックする

## レビューカテゴリ

### CRITICAL（必須修正）
- RAII なしの raw `new`/`delete`
- バッファオーバーフローと use-after-free
- 同期なしのデータ競合
- `system()` 経由のコマンドインジェクション
- 未初期化変数の読み取り
- ヌルポインタ参照解除

### HIGH（修正すべき）
- Rule of Five 違反
- `std::lock_guard` / `std::scoped_lock` の不足
- 適切なライフタイム管理なしの detached スレッド
- `static_cast`/`dynamic_cast` の代わりに C 風キャスト
- `const` の正しさが欠けている

### MEDIUM（検討）
- 不必要なコピー（`const&` の代わりに値渡し）
- サイズが既知のコンテナでの `reserve()` 不足
- ヘッダ内の `using namespace std;`
- 重要な戻り値での `[[nodiscard]]` 不足
- 過度に複雑なテンプレートメタプログラミング

## 実行される自動チェック

```bash
# Static analysis
clang-tidy --checks='*,-llvmlibc-*' src/*.cpp -- -std=c++17

# Additional analysis
cppcheck --enable=all --suppress=missingIncludeSystem src/

# Build with warnings
cmake --build build -- -Wall -Wextra -Wpedantic
```

## 使用例

```text
User: /cpp-review

Agent:
# C++ Code Review Report

## Files Reviewed
- src/handler/user.cpp (modified)
- src/service/auth.cpp (modified)

## Static Analysis Results
✓ clang-tidy: 2 warnings
✓ cppcheck: No issues

## Issues Found

[CRITICAL] Memory Leak
File: src/service/auth.cpp:45
Issue: Raw `new` without matching `delete`
```cpp
auto* session = new Session(userId);  // Memory leak!
cache[userId] = session;
```
Fix: Use `std::unique_ptr`
```cpp
auto session = std::make_unique<Session>(userId);
cache[userId] = std::move(session);
```

[HIGH] Missing const Reference
File: src/handler/user.cpp:28
Issue: Large object passed by value
```cpp
void processUser(User user) {  // Unnecessary copy
```
Fix: Pass by const reference
```cpp
void processUser(const User& user) {
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

- まず `/cpp-test` でテストが通ることを確認する
- ビルドエラーが起きたら `/cpp-build` を使う
- コミット前に `/cpp-review` を使う
- C++ 固有でない懸念には `/code-review` を使う

## 関連

- Agent: `agents/cpp-reviewer.md`
- Skills: `skills/cpp-coding-standards/`, `skills/cpp-testing/`

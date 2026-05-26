---
description: C++ のビルドエラー、CMake 問題、リンカー問題を段階的に修正する。最小限の外科的修正のために cpp-build-resolver エージェントを起動する / Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.
---

# C++ Build and Fix

このコマンドは **cpp-build-resolver** エージェントを起動し、最小限の変更で C++ ビルドエラーを段階的に修正する。

## このコマンドが行うこと

1. **診断実行**：`cmake --build`、`clang-tidy`、`cppcheck` を実行する
2. **エラーパース**：ファイルごとにグループ化し、重要度でソートする
3. **段階的修正**：一度に1つのエラー
4. **各修正を検証**：各変更後にビルドを再実行する
5. **サマリー報告**：修正されたものと残っているものを表示する

## 利用シーン

以下の場合に `/cpp-build` を使用する：
- `cmake --build build` がエラーで失敗する
- リンカーエラー（未定義参照、複数定義）
- テンプレートインスタンス化失敗
- include/依存関係の問題
- ビルドを壊す変更を pull した後

## 実行される診断コマンド

```bash
# CMake configure
cmake -B build -S .

# Build
cmake --build build 2>&1 | head -100

# Static analysis (if available)
clang-tidy src/*.cpp -- -std=c++17
cppcheck --enable=all src/
```

## セッション例

```text
User: /cpp-build

Agent:
# C++ Build Resolution

## Initial Diagnostics

```bash
$ cmake --build build
src/service/user.cpp:25:15: error: use of undeclared identifier 'UserRepository'
src/handler/api.cpp:42:9: error: no matching function for call to 'process'
src/handler/api.cpp:58:1: error: non-void function does not return a value
```

Errors found: 3

## Fix 1: Undeclared Identifier

File: src/service/user.cpp:25
Error: use of undeclared identifier 'UserRepository'
Cause: Missing include

```cpp
// Added include
#include "repository/user_repository.hpp"
```

```bash
$ cmake --build build
# 2 errors remaining
```

## Fix 2: No Matching Function

File: src/handler/api.cpp:42
Error: no matching function for call to 'process'

```cpp
// Changed
process(params.get("count"));
// To
process(std::stoi(params.get("count")));
```

```bash
$ cmake --build build
# 1 error remaining
```

## Fix 3: Missing Return

File: src/handler/api.cpp:58
Error: non-void function does not return a value

```cpp
std::optional<User> getUser(const std::string& id) {
    if (id.empty()) {
        return std::nullopt;
    }
    auto user = findUser(id);
    // Added missing return
    return user;
}
```

```bash
$ cmake --build build
# Build successful!
```

## Final Verification

```bash
$ ctest --test-dir build --output-on-failure
Test project build
    1/5 Test #1: unit_tests ........   Passed    0.02 sec
    2/5 Test #2: integration_tests    Passed    0.15 sec
All tests passed.
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Linker errors fixed | 0 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: PASS: SUCCESS
```

## よく修正されるエラー

| エラー | 典型的な修正 |
|-------|-------------|
| `undeclared identifier` | `#include` を追加またはタイプミス修正 |
| `no matching function` | 引数の型を修正またはオーバーロード追加 |
| `undefined reference` | ライブラリをリンクまたは実装を追加 |
| `multiple definition` | `inline` を使うか .cpp に移動 |
| `incomplete type` | 前方宣言を `#include` に置換 |
| `no member named X` | メンバ名修正または include |
| `cannot convert X to Y` | 適切なキャストを追加 |
| `CMake Error` | CMakeLists.txt の設定を修正 |

## 修正戦略

1. **コンパイルエラーが先** — コードはまずコンパイルできる必要がある
2. **リンカーエラーが次** — 未定義参照を解決する
3. **警告が次** — `-Wall -Wextra` で修正する
4. **一度に1つの修正** — 各変更を検証する
5. **最小限の変更** — リファクタリングせず、修正のみ

## 停止条件

エージェントは以下の場合に停止して報告する：
- 同じエラーが3回試行しても続く場合
- 修正がより多くのエラーを発生させる場合
- アーキテクチャ的な変更が必要な場合
- 外部依存関係が不足している場合

## 関連コマンド

- `/cpp-test` - ビルド成功後にテスト実行
- `/cpp-review` - コード品質レビュー
- `verification-loop` skill - 完全な検証ループ

## 関連

- Agent: `agents/cpp-build-resolver.md`
- Skill: `skills/cpp-coding-standards/`

---
description: Flutter/Dart のテストを実行し、失敗を報告し、テストの問題を段階的に修正する。ユニット、ウィジェット、ゴールデン、統合テストを対象とする / Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.
---

# Flutter Test

このコマンドは Flutter のテストスイートを実行し、結果を報告する。失敗が起こった場合、問題を診断し段階的に修正する。

## このコマンドが行うこと

1. **テスト実行**：`flutter test` を実行する（または変更ファイルにスコープを限定する）
2. **失敗パース**：失敗テストをタイプと原因で特定する
3. **段階的修正**：可能な限り一度に1つの失敗を修正する
4. **検証**：各修正後に再実行する
5. **レポート**：カバレッジサマリと残りの失敗を表示する

## 利用シーン

以下の場合に `/flutter-test` を使用する：
- 機能を実装した後、何も壊れていないことを検証する
- `/flutter-build` 実行後、テストが通ることを確認する
- 新規コードのテストカバレッジを確認する
- 特定のテストファイルが失敗しているとき
- PR 提出前

## 実行コマンド

```bash
# Run all tests
flutter test 2>&1

# Run with coverage
flutter test --coverage 2>&1

# Run specific test file
flutter test test/unit/domain/usecases/get_user_test.dart 2>&1

# Run tests matching a name pattern
flutter test --name "CartBloc" 2>&1

# Run integration tests (requires device/emulator)
flutter test integration_test/ 2>&1

# Update golden files when intentional visual changes are made
flutter test --update-goldens 2>&1
```

## セッション例

````text
User: /flutter-test

Agent:
# Flutter Test Run

## Test Execution

```
$ flutter test
00:05 +42 -2: Some tests failed.

FAILED: test/unit/data/user_repository_test.dart
  UserRepository getById
    returns null when user not found
    Expected: null
    Actual: User(id: 'test-id', name: 'Test User')

FAILED: test/widget/cart_page_test.dart
  CartPage
    shows empty state when cart is empty
    Expected: exactly one widget with text 'Your cart is empty'
    Found: no widget with text 'Your cart is empty'
```

## Fix 1: Repository Test

File: test/unit/data/user_repository_test.dart
Failure: `getById` returns a user when it should return null for missing ID

Root cause: Test setup adds a user with ID 'test-id' but queries with 'missing-id'.
Fix: Updated test to query with 'missing-id' — setup was correct, query was wrong.

```
$ flutter test test/unit/data/user_repository_test.dart
1 test passed.
```

## Fix 2: Widget Test

File: test/widget/cart_page_test.dart
Failure: Empty state text widget not found

Root cause: Empty state message was renamed from 'Your cart is empty' to 'Cart is empty' in the widget.
Fix: Updated test string to match current widget copy.

```
$ flutter test test/widget/cart_page_test.dart
1 test passed.
```

## Final Run

```
$ flutter test --coverage
All 44 tests passed.
Coverage: 84.2% (target: 80%)
```

## Summary

| Metric | Value |
|--------|-------|
| Total tests | 44 |
| Passed | 44 |
| Failed | 0 |
| Coverage | 84.2% |

Test Status: PASS ✓
````

## よくあるテスト失敗

| 失敗 | 典型的な修正 |
|---------|-------------|
| `Expected: <X> Actual: <Y>` | アサーションを更新または実装を修正 |
| `Widget not found` | finder セレクタを修正、またはウィジェットリネーム後にテストを更新 |
| `Golden file not found` | `flutter test --update-goldens` を実行して生成 |
| `Golden mismatch` | diff を確認；変更が意図的なら `--update-goldens` を実行 |
| `MissingPluginException` | テストセットアップでプラットフォームチャネルをモック |
| `LateInitializationError` | `setUp()` で `late` フィールドを初期化 |
| `pumpAndSettle timed out` | 明示的な `pump(Duration)` 呼び出しに置換 |

## 関連コマンド

- `/flutter-build` — テスト実行前にビルドエラーを修正
- `/flutter-review` — テスト合格後にコードをレビュー
- `tdd-workflow` skill — テスト駆動開発ワークフロー

## 関連

- Agent: `agents/flutter-reviewer.md`
- Agent: `agents/dart-build-resolver.md`
- Skill: `skills/flutter-dart-code-review/`
- Rules: `rules/dart/testing.md`

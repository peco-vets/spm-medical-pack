---
description: Dart アナライザのエラーと Flutter のビルド失敗を段階的に修正する。最小限の外科的修正のために dart-build-resolver エージェントを起動する / Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.
---

# Flutter Build and Fix

このコマンドは **dart-build-resolver** エージェントを起動し、最小限の変更で Dart/Flutter ビルドエラーを段階的に修正する。

## このコマンドが行うこと

1. **診断実行**：`flutter analyze`、`flutter pub get` を実行する
2. **エラーパース**：ファイルごとにグループ化し、重要度でソートする
3. **段階的修正**：一度に1つのエラー
4. **各修正を検証**：各変更後に解析を再実行する
5. **サマリー報告**：修正されたものと残っているものを表示する

## 利用シーン

以下の場合に `/flutter-build` を使用する：
- `flutter analyze` がエラーを報告する
- `flutter build` がいずれかのプラットフォームで失敗する
- `dart pub get` / `flutter pub get` がバージョン競合で失敗する
- `build_runner` がコード生成に失敗する
- ビルドを壊す変更を pull した後

## 実行される診断コマンド

```bash
# Analysis
flutter analyze 2>&1

# Dependencies
flutter pub get 2>&1

# Code generation (if project uses build_runner)
dart run build_runner build --delete-conflicting-outputs 2>&1

# Platform builds
flutter build apk 2>&1
flutter build web 2>&1
```

## セッション例

````text
User: /flutter-build

Agent:
# Flutter Build Resolution

## Initial Diagnostics

```
$ flutter analyze
Analyzing project...

  error • lib/features/user/data/user_repository_impl.dart:34:16 •
    A value of type 'String?' can't be assigned to a variable of type 'String'. •
    invalid_assignment

  error • lib/features/cart/presentation/cart_page.dart:58:5 •
    The method 'add' isn't defined for the type 'List<Item>'.
    Try correcting the name to the name of an existing method, or defining a method named 'add'. •
    undefined_method

2 errors found.
```

## Fix 1: Null Safety

File: lib/features/user/data/user_repository_impl.dart:34
Error: A value of type 'String?' can't be assigned to type 'String'

Changed:
```dart
final id = response.id;
```
To:
```dart
final id = response.id ?? '';
```

```
$ flutter analyze
1 error found.
```

## Fix 2: Immutable List

File: lib/features/cart/presentation/cart_page.dart:58
Error: The method 'add' isn't defined for the type 'List<Item>'
Cause: State holds an unmodifiable list; mutation goes through Cubit

Changed:
```dart
state.items.add(item);
```
To:
```dart
context.read<CartCubit>().addItem(item);
// Note: Cubit exposes named methods (addItem, removeItem);
// .add(event) is the BLoC event API — don't mix them.
```

```
$ flutter analyze
No issues found!
```

## Final Verification

```
$ flutter test
All tests passed.
```

## Summary

| Metric | Count |
|--------|-------|
| Analysis errors fixed | 2 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: PASS ✓
````

## よく修正されるエラー

| エラー | 典型的な修正 |
|-------|-------------|
| `A value of type 'X?' can't be assigned to 'X'` | `?? default` または null ガードを追加 |
| `The name 'X' isn't defined` | import を追加またはタイプミス修正 |
| `Non-nullable instance field must be initialized` | 初期化子または `late` を追加 |
| `Version solving failed` | pubspec.yaml のバージョン制約を調整 |
| `Missing concrete implementation of 'X'` | 不足するインターフェースメソッドを実装 |
| `build_runner: Part of X expected` | 古い `.g.dart` を削除して再ビルド |

## 修正戦略

1. **解析エラーが先** — コードはまずエラーなしであるべき
2. **警告のトリアージが次** — 実行時バグを引き起こしうる警告を修正する
3. **pub 競合が次** — 依存関係解決を修正する
4. **一度に1つの修正** — 各変更を検証する
5. **最小限の変更** — リファクタリングせず、修正のみ

## 停止条件

エージェントは以下の場合に停止して報告する：
- 同じエラーが3回試行しても続く場合
- 修正がより多くのエラーを発生させる場合
- アーキテクチャ的な変更が必要な場合
- パッケージアップグレード競合にユーザーの判断が必要な場合

## 関連コマンド

- `/flutter-test` — ビルド成功後にテスト実行
- `/flutter-review` — コード品質レビュー
- `verification-loop` skill — 完全な検証ループ

## 関連

- Agent: `agents/dart-build-resolver.md`
- Skill: `skills/flutter-dart-code-review/`

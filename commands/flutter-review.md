---
description: イディオマティックなパターン、ウィジェットのベストプラクティス、状態管理、パフォーマンス、アクセシビリティ、セキュリティについて Flutter/Dart コードをレビューする。flutter-reviewer エージェントを起動する / Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.
---

# Flutter Code Review

このコマンドは **flutter-reviewer** エージェントを起動し、Flutter/Dart コードの変更をレビューする。

## このコマンドが行うこと

1. **コンテキスト収集**：`git diff --staged` と `git diff` を確認する
2. **プロジェクト調査**：`pubspec.yaml`、`analysis_options.yaml`、状態管理ソリューションを確認する
3. **セキュリティ事前スキャン**：ハードコードされたシークレットとクリティカルなセキュリティ問題をチェックする
4. **フルレビュー**：完全なレビューチェックリストを適用する
5. **発見事項報告**：重要度別にグループ化された問題を修正ガイダンスと共に出力する

## 前提条件

`/flutter-review` を実行する前に、以下を確保する：
1. **ビルドが通る** — まず `/flutter-build` を実行する；壊れたコードのレビューは不完全
2. **テストが通る** — リグレッションがないことを確認するために `/flutter-test` を実行する
3. **マージ競合がない** — diff が意図された変更のみを反映するようにすべての競合を解決する
4. **`flutter analyze` がクリーン** — レビュー前にアナライザの警告を修正する

## 利用シーン

以下の場合に `/flutter-review` を使用する：
- Flutter/Dart 変更を含む PR を提出する前（ビルドとテストが通った後）
- 早期に問題をキャッチするために新機能を実装した後
- 他人の Flutter コードをレビューするとき
- ウィジェット、状態管理コンポーネント、サービスクラスを監査する
- プロダクションリリース前

## レビュー範囲

| 範囲 | 重要度 |
|------|----------|
| ハードコードされたシークレット、平文 HTTP | CRITICAL |
| アーキテクチャ違反、状態管理アンチパターン | CRITICAL |
| ウィジェット再ビルド問題、リソースリーク | HIGH |
| `dispose()` 不足、await 後の `BuildContext` | HIGH |
| Dart null 安全性、エラー/ローディング状態の不足 | HIGH |
| const 伝播、ウィジェット合成 | HIGH |
| パフォーマンス：`build()` 内の高コスト処理 | HIGH |
| アクセシビリティ、セマンティックラベル | MEDIUM |
| 状態遷移のテスト不足 | HIGH |
| ハードコードされた文字列（l10n） | MEDIUM |
| Pub 依存衛生 | LOW |

## セッション例

````text
User: /flutter-review

Agent:
# Flutter Code Review

## Context

Changed files:
- lib/features/auth/presentation/login_page.dart
- lib/features/auth/data/auth_repository_impl.dart

State management: Riverpod (detected from pubspec.yaml)
Architecture: feature-first

## Security Pre-scan

✓ No hardcoded secrets detected
✓ No cleartext HTTP calls

## Review Findings

[HIGH] BuildContext used after async gap without mounted check
File: lib/features/auth/presentation/login_page.dart:67
Issue: `context.go('/home')` called after `await auth.login(...)` with no `mounted` check.
Fix: Add `if (!context.mounted) return;` before any navigation after awaits (Flutter 3.7+).

[HIGH] AsyncValue error state not handled
File: lib/features/auth/presentation/login_page.dart:42
Issue: `ref.watch(authProvider)` switches on loading/data but has no `error` branch.
Fix: Add error case to the switch expression or `when()` call to show a user-facing error message.

[MEDIUM] Hardcoded string not localized
File: lib/features/auth/presentation/login_page.dart:89
Issue: `Text('Login')` — user-visible string not using localization system.
Fix: Use the project's l10n accessor: `Text(context.l10n.loginButton)`.

## Review Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 0     | pass   |
| HIGH     | 2     | block  |
| MEDIUM   | 1     | info   |
| LOW      | 0     | note   |

Verdict: BLOCK — HIGH issues must be fixed before merge.
````

## 承認基準

- **Approve**：CRITICAL または HIGH の問題なし
- **Block**：CRITICAL または HIGH の問題はマージ前に修正必須

## 関連コマンド

- `/flutter-build` — ビルドエラーを先に修正
- `/flutter-test` — レビュー前にテスト実行
- `/code-review` — 一般的なコードレビュー（言語非依存）

## 関連

- Agent: `agents/flutter-reviewer.md`
- Skill: `skills/flutter-dart-code-review/`
- Rules: `rules/dart/`

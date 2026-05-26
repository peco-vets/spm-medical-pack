---
description: 所有権、ライフタイム、エラーハンドリング、unsafe 利用、イディオマティックなパターンに関する包括的な Rust コードレビュー。rust-reviewer エージェントを起動する / Comprehensive Rust code review for ownership, lifetimes, error handling, unsafe usage, and idiomatic patterns. Invokes the rust-reviewer agent.
---

# Rust Code Review

このコマンドは **rust-reviewer** エージェントを起動し、包括的な Rust 固有のコードレビューを行う。

## このコマンドが行うこと

1. **自動チェックの検証**：`cargo check`、`cargo clippy -- -D warnings`、`cargo fmt --check`、`cargo test` を実行 — どれかが失敗したら停止
2. **Rust 変更を特定**：`git diff HEAD~1`（または PR の場合 `git diff main...HEAD`）で変更された `.rs` ファイルを見つける
3. **セキュリティ監査の実行**：利用可能なら `cargo audit` を実行する
4. **セキュリティスキャン**：unsafe 利用、コマンドインジェクション、ハードコードされたシークレットをチェックする
5. **所有権レビュー**：不要な clone、ライフタイム問題、borrowing パターンを分析する
6. **レポート生成**：重要度別に問題を分類する

## 利用シーン

以下の場合に `/rust-review` を使用する：
- Rust コードを書いた・変更した後
- Rust 変更をコミットする前
- Rust コードのプルリクエストをレビューする
- 新しい Rust コードベースにオンボードする
- イディオマティックな Rust パターンを学ぶ

## レビューカテゴリ

### CRITICAL（必須修正）
- プロダクションコードパスでのチェックされていない `unwrap()`/`expect()`
- 不変条件を文書化した `// SAFETY:` コメントなしの `unsafe`
- クエリでの文字列補間による SQL インジェクション
- `std::process::Command` での検証されていない入力によるコマンドインジェクション
- ハードコードされた認証情報
- raw ポインタによる use-after-free

### HIGH（修正すべき）
- borrow checker を満たすための不要な `.clone()`
- `&str` または `impl AsRef<str>` で十分な場面での `String` 引数
- async コンテキストでのブロッキング（`std::thread::sleep`、`std::fs`）
- 共有型での `Send`/`Sync` バウンド不足
- ビジネスクリティカルな enum でのワイルドカード `_ =>` マッチ
- 大きな関数（50行超）

### MEDIUM（検討）
- ホットパスでの不要なアロケーション
- サイズが既知のときの `with_capacity` 不足
- 正当化なしの clippy 警告抑制
- `///` ドキュメントなしの公開 API
- 値を無視する可能性が高い場合の非 `must_use` 戻り型での `#[must_use]` の検討

## 実行される自動チェック

```bash
# Build gate (must pass before review)
cargo check

# Lints and suggestions
cargo clippy -- -D warnings

# Formatting
cargo fmt --check

# Tests
cargo test

# Security audit (if available)
if command -v cargo-audit >/dev/null; then cargo audit; else echo "cargo-audit not installed"; fi
```

## 使用例

`/rust-review` を実行すると、変更されたファイルがレビューされ、静的解析結果と、重要度別の発見事項（CRITICAL: プロダクションパスでの unchecked unwrap、HIGH: 不要な clone など）と修正案が示される。

## 承認基準

| ステータス | 条件 |
|--------|-----------|
| Approve | CRITICAL または HIGH の問題なし |
| Warning | MEDIUM の問題のみ（注意してマージ） |
| Block | CRITICAL または HIGH の問題あり |

## 他のコマンドとの統合

- まず `/rust-test` でテストが通ることを確認する
- ビルドエラーが起きたら `/rust-build` を使う
- コミット前に `/rust-review` を使う
- Rust 固有でない懸念には `/code-review` を使う

## 関連

- Agent: `agents/rust-reviewer.md`
- Skills: `skills/rust-patterns/`, `skills/rust-testing/`

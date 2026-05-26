---
description: Rust のビルドエラー、borrow checker 問題、依存関係問題を段階的に修正する。最小限の外科的修正のために rust-build-resolver エージェントを起動する / Fix Rust build errors, borrow checker issues, and dependency problems incrementally. Invokes the rust-build-resolver agent for minimal, surgical fixes.
---

# Rust Build and Fix

このコマンドは **rust-build-resolver** エージェントを起動し、最小限の変更で Rust ビルドエラーを段階的に修正する。

## このコマンドが行うこと

1. **診断実行**：`cargo check`、`cargo clippy`、`cargo fmt --check` を実行する
2. **エラーパース**：エラーコードと影響を受けるファイルを特定する
3. **段階的修正**：一度に1つのエラー
4. **各修正を検証**：各変更後に `cargo check` を再実行する
5. **サマリー報告**：修正されたものと残っているものを表示する

## 利用シーン

以下の場合に `/rust-build` を使用する：
- `cargo build` または `cargo check` がエラーで失敗する
- `cargo clippy` が警告を報告する
- Borrow checker またはライフタイムエラーがコンパイルをブロックする
- Cargo の依存解決が失敗する
- ビルドを壊す変更を pull した後

## 実行される診断コマンド

```bash
# Primary build check
cargo check 2>&1

# Lints and suggestions
cargo clippy -- -D warnings 2>&1

# Formatting check
cargo fmt --check 2>&1

# Dependency issues
cargo tree --duplicates

# Security audit (if available)
if command -v cargo-audit >/dev/null; then cargo audit; else echo "cargo-audit not installed"; fi
```

## セッション例

cargo check を実行すると、borrow checker error（E0502）、type mismatch（E0308）、unresolved name（E0425）などのエラーがリストされる。エージェントは各エラーを一つずつ修正し、各修正後に `cargo check` を再実行して残りのエラー数を確認する。最終的な検証として `cargo clippy -- -D warnings` と `cargo test` を実行する。

## よく修正されるエラー

| Error | Typical Fix |
|-------|-------------|
| `cannot borrow as mutable` | 先に immutable borrow を終わらせるように再構成；正当化される場合のみ clone |
| `does not live long enough` | 所有型を使うか、ライフタイム注釈を追加 |
| `cannot move out of` | 所有権を取るように再構成；最後の手段としてのみ clone |
| `mismatched types` | `.into()`、`as`、または明示的な変換を追加 |
| `trait X not implemented` | `#[derive(Trait)]` を追加または手動で実装 |
| `unresolved import` | Cargo.toml に追加または `use` パスを修正 |
| `cannot find value` | import を追加またはパスを修正 |

## 修正戦略

1. **ビルドエラーが先** — コードはまずコンパイルできる必要がある
2. **Clippy 警告が次** — 疑わしい構造を修正
3. **フォーマットが次** — `cargo fmt` 準拠
4. **一度に1つの修正** — 各変更を検証する
5. **最小限の変更** — リファクタリングせず、修正のみ

## 停止条件

エージェントは以下の場合に停止して報告する：
- 同じエラーが3回試行しても続く場合
- 修正がより多くのエラーを発生させる場合
- アーキテクチャ的な変更が必要な場合
- borrow checker エラーがデータ所有権の再設計を必要とする場合

## 関連コマンド

- `/rust-test` - ビルド成功後にテスト実行
- `/rust-review` - コード品質レビュー
- `verification-loop` skill - 完全な検証ループ

## 関連

- Agent: `agents/rust-build-resolver.md`
- Skill: `skills/rust-patterns/`

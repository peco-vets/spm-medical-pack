---
description: Rust で TDD ワークフローを徹底する。テストを先に書き、その後実装する。cargo-llvm-cov で 80%+ のカバレッジを検証する / Enforce TDD workflow for Rust. Write tests first, then implement. Verify 80%+ coverage with cargo-llvm-cov.
---

# Rust TDD Command

このコマンドは、`#[test]`、rstest、proptest、mockall を使った Rust コードのテスト駆動開発手法を徹底する。

## このコマンドが行うこと

1. **型/トレイト定義**：関数シグネチャを `todo!()` でスキャフォールドする
2. **テスト記述**：包括的なテストモジュールを作成する（RED）
3. **テスト実行**：正しい理由でテストが失敗することを検証する
4. **コード実装**：パスする最小限のコードを書く（GREEN）
5. **リファクタ**：テストをグリーンに保ちながら改善する
6. **カバレッジ確認**：cargo-llvm-cov で 80%+ のカバレッジを確保する

## 利用シーン

以下の場合に `/rust-test` を使用する：
- 新しい Rust 関数、メソッド、トレイトを実装する
- 既存 Rust コードにテストカバレッジを追加する
- バグ修正（最初に失敗するテストを書く）
- クリティカルなビジネスロジックを構築する
- Rust での TDD ワークフローを学ぶ

## TDD サイクル

```
RED     -> Write failing test first
GREEN   -> Implement minimal code to pass
REFACTOR -> Improve code, tests stay green
REPEAT  -> Next test case
```

## セッション例

ユーザーが「ユーザー登録の検証関数が必要」と言うと、エージェントは以下のステップを実行する：
1. インターフェース定義（`RegistrationRequest` 構造体、`ValidationResult` enum、`todo!()` を含む関数）
2. RED テストの記述（valid、blank name、invalid email、short password などのケース）
3. テスト実行で `todo!()` panic による失敗を確認
4. 最小限の実装（GREEN）：エラーを Vec で収集し、空なら Valid を返す
5. テストパスの確認
6. `cargo llvm-cov` でカバレッジ 100% を確認

## テストパターン

### ユニットテスト

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn adds_two_numbers() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn handles_error() -> Result<(), Box<dyn std::error::Error>> {
        let result = parse_config(r#"port = 8080"#)?;
        assert_eq!(result.port, 8080);
        Ok(())
    }
}
```

### rstest によるパラメータ化テスト

```rust
use rstest::{rstest, fixture};

#[rstest]
#[case("hello", 5)]
#[case("", 0)]
#[case("rust", 4)]
fn test_string_length(#[case] input: &str, #[case] expected: usize) {
    assert_eq!(input.len(), expected);
}
```

### 非同期テスト

```rust
#[tokio::test]
async fn fetches_data_successfully() {
    let client = TestClient::new().await;
    let result = client.get("/data").await;
    assert!(result.is_ok());
}
```

### プロパティベーステスト

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn encode_decode_roundtrip(input in ".*") {
        let encoded = encode(&input);
        let decoded = decode(&encoded).unwrap();
        assert_eq!(input, decoded);
    }
}
```

## カバレッジコマンド

```bash
# Summary report
cargo llvm-cov

# HTML report
cargo llvm-cov --html

# Fail if below threshold
cargo llvm-cov --fail-under-lines 80

# Run specific test
cargo test test_name

# Run with output
cargo test -- --nocapture

# Run without stopping on first failure
cargo test --no-fail-fast
```

## カバレッジ目標

| コードタイプ | 目標 |
|-----------|--------|
| クリティカルなビジネスロジック | 100% |
| 公開 API | 90%+ |
| 一般コード | 80%+ |
| 生成コード / FFI バインディング | 除外 |

## TDD ベストプラクティス

**やるべきこと：**
- 実装の前に必ずテストを先に書く
- 各変更後にテストを実行する
- より良いエラーメッセージのために `assert!` より `assert_eq!` を使う
- `Result` を返すテストでは `?` を使ってクリーンな出力に
- 実装ではなく振る舞いをテストする
- エッジケース（空、境界、エラーパス）を含める

**やってはいけないこと：**
- テストの前に実装を書く
- RED フェーズをスキップする
- `Result::is_err()` で動く場面で `#[should_panic]` を使う
- テストで `sleep()` を使う — channels または `tokio::time::pause()` を使う
- すべてをモックする — 可能なら統合テストを優先する

## 関連コマンド

- `/rust-build` - ビルドエラー修正
- `/rust-review` - 実装後のコードレビュー
- `verification-loop` skill - 完全な検証ループ

## 関連

- Skill: `skills/rust-testing/`
- Skill: `skills/rust-patterns/`

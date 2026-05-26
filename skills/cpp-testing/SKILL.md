---
name: cpp-testing
description: C++ テストの作成/更新/修正、GoogleTest/CTest の設定、失敗または不安定なテストの診断、カバレッジ/サニタイザの追加時のみ使う (C++ testing, GoogleTest, GoogleMock, CMake, CTest, sanitizers, coverage)。
origin: ECC
---

# C++ Testing (エージェントスキル)

GoogleTest/GoogleMock と CMake/CTest を使ったモダン C++ (C++17/20) 向けのエージェント重視テストワークフロー。

## 利用するタイミング

- 新しい C++ テストの作成または既存テストの修正
- C++ コンポーネントのユニット/統合テストカバレッジ設計
- テストカバレッジ、CI ゲーティング、回帰保護の追加
- 一貫した実行のための CMake/CTest ワークフロー設定
- テスト失敗や不安定挙動の調査
- メモリ/レース診断のためのサニタイザ有効化

### 利用しないタイミング

- テスト変更なしの新製品機能の実装
- テストカバレッジや失敗に関連しない大規模リファクタ
- 検証するテスト回帰のないパフォーマンスチューニング
- 非 C++ プロジェクトまたは非テストタスク

## コアコンセプト

- **TDD ループ**: red → green → refactor (テスト最初、最小修正、その後クリーンアップ)
- **隔離**: グローバル状態より依存注入とフェイクを優先
- **テストレイアウト**: `tests/unit`・`tests/integration`・`tests/testdata`
- **モック vs フェイク**: インタラクションにはモック、ステートフル挙動にはフェイク
- **CTest 発見**: 安定したテスト発見に `gtest_discover_tests()` を使う
- **CI シグナル**: 最初にサブセットを実行、次に `--output-on-failure` でフルスイートを実行

## TDD ワークフロー

RED → GREEN → REFACTOR ループに従う:

1. **RED**: 新挙動をキャプチャする失敗テストを書く
2. **GREEN**: パスする最小の変更を実装
3. **REFACTOR**: テストがグリーンのままでクリーンアップ

```cpp
// tests/add_test.cpp
#include <gtest/gtest.h>

int Add(int a, int b); // Provided by production code.

TEST(AddTest, AddsTwoNumbers) { // RED
  EXPECT_EQ(Add(2, 3), 5);
}

// src/add.cpp
int Add(int a, int b) { // GREEN
  return a + b;
}

// REFACTOR: simplify/rename once tests pass
```

(以下、本スキルのコード例 — 基本ユニットテスト、フィクスチャ、モック、CMake/CTest クイックスタート、サニタイザ、カバレッジ — は技術コードと API のため英語のまま保持される。)

## テスト実行

```bash
ctest --test-dir build --output-on-failure
ctest --test-dir build -R ClampTest
ctest --test-dir build -R "UserStoreTest.*" --output-on-failure
```

```bash
./build/example_tests --gtest_filter=ClampTest.*
./build/example_tests --gtest_filter=UserStoreTest.FindsExistingUser
```

## 失敗のデバッグ

1. gtest フィルタで単一の失敗テストを再実行
2. 失敗アサーションの周辺にスコープログを追加
3. サニタイザを有効にして再実行
4. 根本原因が修正されたらフルスイートに拡大

## 不安定テストのガードレール

- 同期に `sleep` を使わない。条件変数やラッチを使う
- テストごとに一時ディレクトリをユニークにし、常にクリーンアップする
- ユニットテストで実時間、ネットワーク、ファイルシステム依存を避ける
- ランダム化された入力には決定論的シードを使う

## ベストプラクティス

### DO

- テストを決定論的かつ隔離して保つ
- グローバルより依存注入を優先
- 前提条件には `ASSERT_*`、複数チェックには `EXPECT_*` を使う
- CTest ラベルやディレクトリでユニット vs 統合テストを分離
- メモリとレース検出のために CI でサニタイザを実行

### DON'T

- ユニットテストで実時間やネットワークに依存しない
- 条件変数が使えるときにスリープを同期として使わない
- シンプルな値オブジェクトを過剰モックしない
- 重要でないログに脆い文字列マッチを使わない

### よくある落とし穴

- **固定 temp パスを使う** → テストごとにユニークな temp ディレクトリを生成しクリーンアップ
- **壁時計時間に依存** → クロックを注入またはフェイク時間ソースを使う
- **不安定な並行テスト** → 条件変数/ラッチとバウンド付き待機を使う
- **隠れたグローバル状態** → フィクスチャでグローバル状態をリセットまたはグローバルを削除
- **過剰モック** → ステートフル挙動にはフェイクを優先、インタラクションのみモック
- **サニタイザ実行欠落** → CI に ASan/UBSan/TSan ビルドを追加
- **デバッグのみビルドのカバレッジ** → カバレッジターゲットが一貫したフラグを使うことを確認

## オプション付録: ファジング / プロパティテスト

プロジェクトが既に LLVM/libFuzzer やプロパティテストライブラリをサポートしている場合のみ使う。

- **libFuzzer**: 最小 I/O の純粋関数に最適
- **RapidCheck**: 不変条件を検証するプロパティベーステスト

## GoogleTest の代替

- **Catch2**: ヘッダオンリー、表現豊富なマッチャ
- **doctest**: 軽量、最小のコンパイルオーバーヘッド

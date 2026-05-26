---
description: カバレッジを分析し、ギャップを特定し、目標しきい値に向けて不足するテストを生成する / Analyze coverage, identify gaps, and generate missing tests toward the target threshold.
---

# Test Coverage

テストカバレッジを分析し、ギャップを特定し、80%+ のカバレッジに到達するために不足するテストを生成する。

## Step 1: テストフレームワークを検出する

| Indicator | Coverage Command |
|-----------|-----------------|
| `jest.config.*` or `package.json` jest | `npx jest --coverage --coverageReporters=json-summary` |
| `vitest.config.*` | `npx vitest run --coverage` |
| `pytest.ini` / `pyproject.toml` pytest | `pytest --cov=src --cov-report=json` |
| `Cargo.toml` | `cargo llvm-cov --json` |
| `pom.xml` with JaCoCo | `mvn test jacoco:report` |
| `go.mod` | `go test -coverprofile=coverage.out ./...` |

## Step 2: カバレッジレポートを分析する

1. カバレッジコマンドを実行する
2. 出力をパースする（JSON サマリーまたはターミナル出力）
3. **80% カバレッジ未満**のファイルをリストアップし、悪いものから順にソートする
4. カバレッジ不足の各ファイルで以下を特定する：
   - テストされていない関数またはメソッド
   - 不足する分岐カバレッジ（if/else、switch、エラーパス）
   - 分母を膨らませるデッドコード

## Step 3: 不足するテストを生成する

カバレッジ不足の各ファイルについて、この優先順位でテストを生成する：

1. **Happy path** — 有効な入力でのコア機能
2. **Error handling** — 無効な入力、不足するデータ、ネットワーク失敗
3. **Edge cases** — 空配列、null/undefined、境界値（0、-1、MAX_INT）
4. **Branch coverage** — 各 if/else、switch ケース、三項

### テスト生成ルール

- テストをソースに隣接して配置：`foo.ts` → `foo.test.ts`（またはプロジェクト規約）
- プロジェクトからの既存テストパターンを使う（import スタイル、アサーションライブラリ、モックアプローチ）
- 外部依存関係（データベース、API、ファイルシステム）をモックする
- 各テストは独立すべき — テスト間で共有された可変状態なし
- テストを記述的に命名する：`test_create_user_with_duplicate_email_returns_409`

## Step 4: 検証する

1. 完全なテストスイートを実行する — すべてのテストが通過する必要がある
2. カバレッジを再実行する — 改善を検証する
3. 80% 未満なら、残りのギャップで Step 3 を繰り返す

## Step 5: レポート

before/after 比較を表示する：

```
Coverage Report
──────────────────────────────
File                   Before  After
src/services/auth.ts   45%     88%
src/utils/validation.ts 32%    82%
──────────────────────────────
Overall:               67%     84%  PASS:
```

## 焦点エリア

- 複雑な分岐を持つ関数（高い cyclomatic complexity）
- エラーハンドラと catch ブロック
- コードベースを通して使われるユーティリティ関数
- API エンドポイントハンドラ（request → response フロー）
- エッジケース：null、undefined、空文字列、空配列、ゼロ、負の数

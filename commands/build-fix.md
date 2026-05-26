---
description: プロジェクトのビルドシステムを検出し、最小限の安全な変更でビルド/型エラーを段階的に修正する / Detect the project build system and incrementally fix build/type errors with minimal safe changes.
---

# Build and Fix

最小限の安全な変更で、ビルドエラーと型エラーを段階的に修正する。

## Step 1: ビルドシステムを検出する

プロジェクトのビルドツールを特定し、ビルドを実行する：

| インジケータ | ビルドコマンド |
|-----------|---------------|
| `package.json` with `build` script | `npm run build` or `pnpm build` |
| `tsconfig.json` (TypeScript only) | `npx tsc --noEmit` |
| `Cargo.toml` | `cargo build 2>&1` |
| `pom.xml` | `mvn compile` |
| `build.gradle` | `./gradlew compileJava` |
| `go.mod` | `go build ./...` |
| `pyproject.toml` | `python -m compileall -q .` or `mypy .` |

## Step 2: エラーをパースしてグループ化する

1. ビルドコマンドを実行し、stderr をキャプチャする
2. ファイルパスごとにエラーをグループ化する
3. 依存順にソートする（ロジックエラーの前に import/型を修正する）
4. 進捗追跡のために合計エラー数をカウントする

## Step 3: 修正ループ（一度に1エラー）

各エラーについて：

1. **ファイルを読み込む** — Read ツールでエラーコンテキスト（エラー周辺の10行）を確認する
2. **診断する** — 根本原因を特定する（不足 import、誤った型、構文エラー）
3. **最小限に修正する** — Edit ツールでエラーを解決する最小の変更を行う
4. **ビルドを再実行する** — エラーが消え、新しいエラーが発生していないことを確認する
5. **次へ進む** — 残りのエラーを続ける

## Step 4: ガードレール

以下の場合は停止してユーザーに確認する：
- 修正が**解決した数より多くのエラーを発生させる**場合
- **同じエラーが3回試行しても続く**場合（より深い問題の可能性）
- 修正が**アーキテクチャ的な変更**を必要とする場合（ビルド修正だけではない）
- ビルドエラーが**依存関係の不足**から生じている場合（`npm install`、`cargo add` 等が必要）

## Step 5: サマリー

結果を表示：
- 修正したエラー（ファイルパス付き）
- 残ったエラー（もしあれば）
- 新たに発生したエラー（ゼロのはず）
- 未解決の問題に対する次のステップの提案

## リカバリ戦略

| 状況 | 対応 |
|-----------|--------|
| Missing module/import | パッケージがインストールされているか確認；インストールコマンドを提案 |
| Type mismatch | 両方の型定義を読む；より狭い型を修正 |
| Circular dependency | import グラフで循環を特定；抽出を提案 |
| Version conflict | `package.json` / `Cargo.toml` のバージョン制約を確認 |
| Build tool misconfiguration | 設定ファイルを読む；動作するデフォルトと比較 |

安全のため、一度に1エラーずつ修正する。リファクタリングよりも最小の diff を優先する。

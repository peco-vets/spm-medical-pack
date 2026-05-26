---
description: Android および KMP プロジェクトの Gradle ビルドエラーを修正する / Fix Gradle build errors for Android and KMP projects
---

# Gradle Build Fix

Android および Kotlin Multiplatform プロジェクトの Gradle ビルドおよびコンパイルエラーを段階的に修正する。

## Step 1: ビルド構成を検出する

プロジェクトタイプを特定し、適切なビルドを実行する：

| インジケータ | ビルドコマンド |
|-----------|---------------|
| `build.gradle.kts` + `composeApp/` (KMP) | `./gradlew composeApp:compileKotlinMetadata 2>&1` |
| `build.gradle.kts` + `app/` (Android) | `./gradlew app:compileDebugKotlin 2>&1` |
| `settings.gradle.kts` with modules | `./gradlew assemble 2>&1` |
| Detekt configured | `./gradlew detekt 2>&1` |

`gradle.properties` と `local.properties` でも設定を確認する。

## Step 2: エラーをパースしてグループ化する

1. ビルドコマンドを実行し、出力をキャプチャする
2. Kotlin コンパイルエラーと Gradle 設定エラーを分離する
3. モジュールとファイルパスでグループ化する
4. ソート：設定エラーが先、次に依存順でコンパイルエラー

## Step 3: 修正ループ

各エラーについて：

1. **ファイルを読む** — エラー行周辺の完全なコンテキスト
2. **診断** — 一般的なカテゴリ：
   - 不足 import または未解決リファレンス
   - 型ミスマッチまたは非互換型
   - `build.gradle.kts` の依存関係不足
   - expect/actual のミスマッチ（KMP）
   - Compose コンパイラエラー
3. **最小修正** — エラーを解決する最小の変更
4. **ビルド再実行** — 修正を検証し、新エラーをチェックする
5. **次へ進む** — 次のエラーへ

## Step 4: ガードレール

以下の場合は停止してユーザーに確認する：
- 修正が解決した数より多くのエラーを発生させる場合
- 同じエラーが3回試行しても続く場合
- エラーが新規依存関係の追加またはモジュール構造変更を必要とする場合
- Gradle sync 自体が失敗する場合（設定フェーズのエラー）
- 生成コード（Room、SQLDelight、KSP）内のエラー

## Step 5: サマリー

レポート：
- 修正したエラー（モジュール、ファイル、説明）
- 残ったエラー
- 新たに発生したエラー（ゼロのはず）
- 次のステップの提案

## よくある Gradle/KMP 修正

| エラー | 修正 |
|-------|-----|
| `commonMain` の未解決リファレンス | 依存関係が `commonMain.dependencies {}` にあるか確認 |
| actual なしの expect 宣言 | 各プラットフォームソースセットに `actual` 実装を追加 |
| Compose コンパイラバージョンミスマッチ | `libs.versions.toml` で Kotlin と Compose コンパイラのバージョンを揃える |
| 重複クラス | `./gradlew dependencies` で競合する依存関係を確認 |
| KSP エラー | `./gradlew kspCommonMainKotlinMetadata` を実行して再生成 |
| 設定キャッシュ問題 | シリアライズ不可能なタスク入力を確認 |

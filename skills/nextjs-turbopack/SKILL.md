---
name: nextjs-turbopack
description: Next.js 16+ と Turbopack — インクリメンタルバンドリング、FS キャッシュ、開発速度、Turbopack と webpack の使い分け (Next.js 16+ and Turbopack — incremental bundling, FS caching, dev speed, when to use Turbopack vs webpack)。
origin: ECC
---

# Next.js と Turbopack

Next.js 16+ はローカル開発でデフォルトで Turbopack を使う: Rust で書かれたインクリメンタルバンドラで、開発の起動とホットアップデートを大幅に高速化する。

## 使用するタイミング

- **Turbopack (デフォルト開発)**: 日々の開発に使う。特に大規模アプリでコールドスタートと HMR が高速
- **Webpack (レガシー開発)**: Turbopack のバグに遭遇したり、開発で webpack 専用プラグインに依存している場合のみ使う。`--webpack` (または Next.js のバージョンによっては `--no-turbopack`。リリース用のドキュメントを確認) で無効化
- **本番**: 本番ビルド挙動 (`next build`) は Next.js バージョンに応じて Turbopack または webpack を使う可能性がある。バージョンの公式 Next.js ドキュメントを確認

使用ケース: Next.js 16+ アプリの開発・デバッグ、遅い dev 起動や HMR の診断、または本番バンドルの最適化。

## 動作の仕組み

- **Turbopack**: Next.js dev 用のインクリメンタルバンドラ。ファイルシステムキャッシュを使い、再起動がはるかに高速 (例: 大規模プロジェクトで 5〜14 倍)
- **dev でデフォルト**: Next.js 16 から、`next dev` は無効化されない限り Turbopack で実行される
- **ファイルシステムキャッシュ**: 再起動が前の作業を再利用。キャッシュは通常 `.next` 以下にある。基本使用には追加設定不要
- **Bundle Analyzer (Next.js 16.1+)**: 出力を検査し重い依存関係を見つけるための実験的 Bundle Analyzer。設定または実験フラグで有効化 (バージョンの Next.js ドキュメントを参照)

## 例

### コマンド

```bash
next dev
next build
next start
```

### 使用

Turbopack を使ったローカル開発のために `next dev` を実行する。Bundle Analyzer (Next.js ドキュメント参照) を使ってコード分割を最適化し、大きな依存関係を削減する。可能な場合は App Router とサーバーコンポーネントを優先する。

## ベストプラクティス

- 安定した Turbopack とキャッシュ挙動のために最近の Next.js 16.x を維持する
- 開発が遅い場合、Turbopack (デフォルト) であり、キャッシュが不必要にクリアされていないことを確認する
- 本番バンドルサイズの問題には、バージョン用の公式 Next.js バンドル分析ツーリングを使う

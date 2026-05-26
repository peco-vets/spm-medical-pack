---
name: bun-runtime
description: Bun をランタイム、パッケージマネージャ、バンドラ、テストランナーとして使う。Bun と Node のどちらを選ぶかの判断、マイグレーションノート、Vercel サポート (Bun runtime, package manager, bundler, test runner, Node alternative, Vercel)。
origin: ECC
---

# Bun ランタイム

Bun は高速なオールインワン JavaScript ランタイム兼ツールキット: ランタイム、パッケージマネージャ、バンドラ、テストランナー。

## 利用するタイミング

- **Bun を優先する**: 新規 JS/TS プロジェクト、install/run 速度が重要なスクリプト、Bun ランタイムを用いた Vercel デプロイ、単一ツールチェーン (run + install + test + build) を望む場合。
- **Node を優先する**: 最大のエコシステム互換性、Node を前提とするレガシーツーリング、依存関係に既知の Bun 問題がある場合。

利用する場面: Bun の採用、Node からの移行、Bun スクリプト/テストの執筆やデバッグ、Vercel や他のプラットフォームでの Bun 設定。

## 仕組み

- **ランタイム**: Node 互換のドロップインランタイム (JavaScriptCore 上、Zig で実装)。
- **パッケージマネージャ**: `bun install` は npm/yarn よりかなり高速。現行 Bun ではロックファイルはデフォルトで `bun.lock` (テキスト)。古いバージョンは `bun.lockb` (バイナリ) を使用していた。
- **バンドラ**: アプリとライブラリのための組み込みバンドラとトランスパイラ。
- **テストランナー**: Jest 風 API を持つ組み込み `bun test`。

**Node からの移行**: `node script.js` を `bun run script.js` または `bun script.js` に置き換える。`npm install` の代わりに `bun install` を実行。ほとんどのパッケージが動作する。npm スクリプトには `bun run` を、npx スタイルのワンオフ実行には `bun x` を使う。Node ビルトインはサポートされる。パフォーマンス向上のため Bun API が存在するときはそれを優先する。

**Vercel**: プロジェクト設定でランタイムを Bun に設定する。ビルド: `bun run build` または `bun build ./src/index.ts --outdir=dist`。インストール: 再現可能なデプロイのために `bun install --frozen-lockfile`。

## 例

### 実行とインストール

```bash
# Install dependencies (creates/updates bun.lock or bun.lockb)
bun install

# Run a script or file
bun run dev
bun run src/index.ts
bun src/index.ts
```

### スクリプトと環境変数

```bash
bun run --env-file=.env dev
FOO=bar bun run script.ts
```

### テスト

```bash
bun test
bun test --watch
```

```typescript
// test/example.test.ts
import { expect, test } from "bun:test";

test("add", () => {
  expect(1 + 2).toBe(3);
});
```

### ランタイム API

```typescript
const file = Bun.file("package.json");
const json = await file.json();

Bun.serve({
  port: 3000,
  fetch(req) {
    return new Response("Hello");
  },
});
```

## ベストプラクティス

- 再現可能なインストールのためにロックファイル (`bun.lock` または `bun.lockb`) をコミットする。
- スクリプトには `bun run` を優先する。TypeScript は Bun がネイティブに `.ts` を実行する。
- 依存関係を最新に保つ。Bun とエコシステムは急速に進化する。

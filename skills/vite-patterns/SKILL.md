---
name: vite-patterns
description: Vite ビルドツールパターン（Vite build tool: config, plugins, HMR, env vars, proxy, SSR, library mode, dependency pre-bundling, build optimization）。vite.config.ts、Vite プラグイン、または Vite ベースプロジェクトで作業するときに起動する。
origin: ECC
---

# Vite パターン

Vite 8+ プロジェクトのビルドツールと開発サーバパターン。設定、環境変数、プロキシセットアップ、ライブラリモード、依存関係事前バンドル、一般的な本番落とし穴をカバー。

## 使用するタイミング

- `vite.config.ts` または `vite.config.js` の設定
- 環境変数または `.env` ファイルの設定
- API バックエンド用の開発サーバプロキシ設定
- ビルド出力の最適化（チャンク、ミニファイ、アセット）
- `build.lib` でライブラリを公開
- 依存関係事前バンドルまたは CJS/ESM 相互運用のトラブルシューティング
- HMR、開発サーバ、またはビルドエラーのデバッグ
- Vite プラグインの選択または順序付け

## 動作の仕組み

- **開発モード**はソースファイルをネイティブ ESM として提供 — バンドルなし。変換はモジュールリクエストごとにオンデマンドで発生するため、コールドスタートが速く HMR が正確。
- **ビルドモード**は Rolldown（v7+）または Rollup（v5–v6）を使ってツリーシェイキング、コード分割、Oxc ベースのミニファイ付きで本番用アプリをバンドルする。
- **依存関係事前バンドル**は esbuild で CJS/UMD 依存を一度 ESM に変換し、結果を `node_modules/.vite` 下にキャッシュするため、後続の起動は作業をスキップする。
- **プラグイン**は開発とビルド全体で統一インターフェースを共有 — 同じプラグインオブジェクトが開発サーバのオンデマンド変換と本番パイプラインの両方で動作する。
- **環境変数**はビルド時に静的にインライン化される。`VITE_` プレフィックス付き var はバンドル内のパブリック定数になる。プレフィックスなしのものはクライアントコードから不可視。

## 例

### Config 構造

#### 基本 Config

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': new URL('./src', import.meta.url).pathname },
  },
})
```

#### 条件付き Config

```typescript
// vite.config.ts
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd())   // VITE_ prefixed only (safe)

  return {
    plugins: [react()],
    server: command === 'serve' ? { port: 3000 } : undefined,
    define: {
      __API_URL__: JSON.stringify(env.VITE_API_URL),
    },
  }
})
```

#### キー設定オプション

| キー | デフォルト | 説明 |
|-----|---------|-------------|
| `root` | `'.'` | プロジェクトルート（`index.html` がある場所） |
| `base` | `'/'` | デプロイされたアセットのパブリックベースパス |
| `envPrefix` | `'VITE_'` | クライアント公開 env var のプレフィックス |
| `build.outDir` | `'dist'` | 出力ディレクトリ |
| `build.minify` | `'oxc'` | ミニファイア（`'oxc'`、`'terser'`、`false`） |
| `build.sourcemap` | `false` | `true`、`'inline'`、または `'hidden'` |

### プラグイン

#### 必須プラグイン

ほとんどのプラグインニーズは少数のよく保守されたパッケージでカバーされる。自分で書く前にこれらに手を伸ばす。

| プラグイン | 目的 | 使用するタイミング |
|--------|---------|-------------|
| `@vitejs/plugin-react-swc` | SWC 経由の React HMR + Fast Refresh | React アプリのデフォルト（Babel バリアントより速い） |
| `@vitejs/plugin-react` | Babel 経由の React HMR + Fast Refresh | Babel プラグイン（emotion、MobX デコレータ）が必要な場合のみ |
| `@vitejs/plugin-vue` | Vue 3 SFC サポート | Vue アプリ |
| `vite-plugin-checker` | HMR オーバーレイ付きでワーカースレッドで `tsc` + ESLint を実行 | **任意の TypeScript アプリ** — Vite は `vite build` 中に型チェックしない |
| `vite-tsconfig-paths` | `tsconfig.json` `paths` エイリアスを尊重 | `tsconfig.json` にすでにエイリアスがあるとき |
| `vite-plugin-dts` | ライブラリモードで `.d.ts` ファイルを発行 | TypeScript ライブラリ公開 |
| `vite-plugin-svgr` | SVG を React コンポーネントとしてインポート | コンポーネントとして SVG を使う React アプリ |
| `rollup-plugin-visualizer` | バンドルツリーマップ／サンバーストレポート | 定期的バンドルサイズ監査（`enforce: 'post'` を使う） |
| `vite-plugin-pwa` | ゼロ設定 PWA + Workbox | オフライン対応アプリ |

**重要な注意点：** `vite build` はトランスパイルするが型チェックしない。`vite-plugin-checker` を追加するか CI で `tsc --noEmit` を実行しない限り、型エラーがサイレントに本番に出荷される。

#### カスタムプラグインの作成

作成はまれ — ほとんどのニーズは既存プラグインでカバーされる。必要なときは、`vite.config.ts` 内でインラインに開始し、再利用されたら抽出する。

```typescript
// vite.config.ts — minimal inline plugin
function myPlugin(): Plugin {
  return {
    name: 'my-plugin',                       // required, must be unique
    enforce: 'pre',                           // 'pre' | 'post' (optional)
    apply: 'build',                           // 'build' | 'serve' (optional)
    transform(code, id) {
      if (!id.endsWith('.custom')) return
      return { code: transformCustom(code), map: null }
    },
  }
}
```

**主要フック：** `transform`（ソース修正）、`resolveId` + `load`（仮想モジュール）、`transformIndexHtml`（HTML への注入）、`configureServer`（開発ミドルウェア追加）、`hotUpdate`（カスタム HMR — v7+ では非推奨の `handleHotUpdate` を置き換える）。

**仮想モジュール**は `\0` プレフィックス規約を使う — `resolveId` は `'\0virtual:my-id'` を返し、他のプラグインがスキップする。ユーザーコードは `'virtual:my-id'` をインポートする。

完全なプラグイン API には [vite.dev/guide/api-plugin](https://vite.dev/guide/api-plugin) を参照。変換パイプラインをデバッグするには開発中に `vite-plugin-inspect` を使う。

### HMR API

フレームワークプラグイン（`@vitejs/plugin-react`、`@vitejs/plugin-vue` など）は HMR を自動的に処理する。カスタム状態ストア、開発ツール、または更新間で状態を保持する必要があるフレームワーク非依存ユーティリティを構築するときのみ、直接 `import.meta.hot` に手を伸ばす。

```typescript
// src/store.ts — manual HMR for a vanilla module
if (import.meta.hot) {
  // Persist state across updates (must MUTATE, never reassign .data)
  import.meta.hot.data.count = import.meta.hot.data.count ?? 0

  // Cleanup side effects before module is replaced
  import.meta.hot.dispose((data) => clearInterval(data.intervalId))

  // Accept this module's own updates
  import.meta.hot.accept()
}
```

すべての `import.meta.hot` コードは本番ビルドからツリーシェイクされる — ガード削除は不要。

### 環境変数

Vite はその順序で `.env`、`.env.local`、`.env.[mode]`、`.env.[mode].local` をロードする（後のものが前のものを上書き）。`*.local` ファイルは gitignored でローカルシークレット用。

#### クライアントサイドアクセス

`VITE_` プレフィックス付き var のみがクライアントコードに公開される：

```typescript
import.meta.env.VITE_API_URL   // string
import.meta.env.MODE            // 'development' | 'production' | custom
import.meta.env.BASE_URL        // base config value
import.meta.env.DEV             // boolean
import.meta.env.PROD            // boolean
import.meta.env.SSR             // boolean
```

#### Config で Env を使う

```typescript
// vite.config.ts
import { defineConfig, loadEnv } from 'vite'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd())          // VITE_ prefixed only (safe)
  return {
    define: {
      __API_URL__: JSON.stringify(env.VITE_API_URL),
    },
  }
})
```

### セキュリティ

#### `VITE_` プレフィックスはセキュリティ境界ではない

`VITE_` でプレフィックスされた任意の変数は**ビルド時にクライアントバンドルに静的にインライン化される**。ミニファイ、Base64 エンコーディング、ソースマップ無効化はそれを隠さない。決意した攻撃者は出荷された JavaScript から任意の `VITE_` var を抽出できる。

**ルール：** パブリック値（API URL、機能フラグ、パブリックキー）のみが `VITE_` var に入る。シークレット（API トークン、データベース URL、プライベートキー）は API やサーバレス関数の背後のサーバサイドに住む必要がある。

#### `loadEnv('')` トラップ

```typescript
// BAD: passing '' as the third arg loads ALL env vars — including server secrets —
// and makes them available to inline into client code via `define`.
const env = loadEnv(mode, process.cwd(), '')

// GOOD: explicit prefix list
const env = loadEnv(mode, process.cwd(), ['VITE_', 'APP_'])
```

#### 本番でのソースマップ

本番ソースマップは元のソースコードを漏らす。エラートラッカー（Sentry、Bugsnag）にアップロードして後でローカルで削除しない限り、無効化する：

```typescript
build: {
  sourcemap: false,                                  // default — keep it this way
}
```

#### `.gitignore` チェックリスト

- `.env.local`、`.env.*.local` — ローカルシークレットオーバーライド
- `dist/` — ビルド出力
- `node_modules/.vite` — 事前バンドルキャッシュ（古いエントリがファントムエラーを引き起こす）

### サーバプロキシ

```typescript
// vite.config.ts — server.proxy
server: {
  proxy: {
    '/foo': 'http://localhost:4567',                    // string shorthand

    '/api': {
      target: 'http://localhost:8080',
      changeOrigin: true,                               // needed for virtual-hosted backends
      rewrite: (path) => path.replace(/^\/api/, ''),
    },
  },
}
```

WebSocket プロキシには、ルート設定に `ws: true` を追加する。

### ビルド最適化

#### 手動チャンク

```typescript
// vite.config.ts — build.rolldownOptions
build: {
  rolldownOptions: {
    output: {
      // Object form: group specific packages
      manualChunks: {
        'react-vendor': ['react', 'react-dom'],
        'ui-vendor': ['@radix-ui/react-dialog', '@radix-ui/react-popover'],
      },
    },
  },
}
```

```typescript
// Function form: split by heuristic
manualChunks(id) {
  if (id.includes('node_modules/react')) return 'react-vendor'
  if (id.includes('node_modules')) return 'vendor'
}
```

### パフォーマンス

#### Barrel ファイルを避ける

Barrel ファイル（ディレクトリからすべて再エクスポートする `index.ts`）は、単一のシンボルをインポートしても Vite に再エクスポートされたすべてのファイルをロードさせる。これは公式ドキュメントがフラグする #1 の開発サーバスローダウン。

```typescript
// BAD — importing one util forces Vite to load the whole barrel
import { slash } from '@/utils'

// GOOD — direct import, only the one file is loaded
import { slash } from '@/utils/slash'
```

#### インポート拡張子を明示的に

各暗黙拡張子は `resolve.extensions` 経由で最大 6 つのファイルシステムチェックを強制する。大規模コードベースでは、これが累積する。

```typescript
// BAD
import Component from './Component'

// GOOD
import Component from './Component.tsx'
```

実際に使う拡張子のみに `tsconfig.json` `allowImportingTsExtensions` + `resolve.extensions` を絞る。

#### ホットパスルートのウォームアップ

`server.warmup.clientFiles` は既知のホットエントリをブラウザがリクエストする前に事前変換 — 大規模アプリでコールドロードリクエストウォーターフォールを排除する。

```typescript
// vite.config.ts
server: {
  warmup: {
    clientFiles: ['./src/main.tsx', './src/routes/**/*.tsx'],
  },
}
```

#### 遅い開発サーバのプロファイリング

`vite dev` が遅く感じるとき、`vite --profile` で開始し、アプリと対話し、次に `p+enter` を押して `.cpuprofile` を保存する。[Speedscope](https://www.speedscope.app) でロードしてどのプラグインが時間を食っているかを見つける — 通常コミュニティプラグインの `buildStart`、`config`、または `configResolved` フック。

### ライブラリモード

npm パッケージを公開するときは `build.lib` を使う。2 つの落とし穴が設定詳細より重要：

1. **型が発行されない** — `vite-plugin-dts` を追加するか別個に `tsc --emitDeclarationOnly` を実行する。
2. **Peer 依存関係を外部化しなければならない** — リストされていない peer はライブラリにバンドルされ、消費者で重複ランタイムエラーを引き起こす。

```typescript
// vite.config.ts
build: {
  lib: {
    entry: 'src/index.ts',
    formats: ['es', 'cjs'],
    fileName: (format) => `my-lib.${format}.js`,
  },
  rolldownOptions: {
    external: ['react', 'react-dom', 'react/jsx-runtime'],  // every peer dep
  },
}
```

### SSR Externals

bare `createServer({ middlewareMode: true })` セットアップはフレームワーク作者の領域。ほとんどのアプリは代わりに Nuxt、Remix、SvelteKit、Astro、TanStack Start を使うべき。フレームワークユーザーとして*調整する*のは、依存関係が SSR で壊れたときの externals 設定：

```typescript
// vite.config.ts — ssr options
ssr: {
  external: ['node-native-package'],           // keep as require() in SSR bundle
  noExternal: ['esm-only-package'],            // force-bundle into SSR output (fixes most SSR errors)
  target: 'node',                              // 'node' or 'webworker'
}
```

### 依存関係事前バンドル

Vite は依存関係を事前バンドルして CJS/UMD を ESM に変換し、リクエスト数を減らす。

```typescript
// vite.config.ts — optimizeDeps
optimizeDeps: {
  include: [
    'lodash-es',                              // force pre-bundle known heavy deps
    'cjs-package',                            // CJS deps that cause interop issues
    'deep-lib/components/**',                 // glob for deep imports
  ],
  exclude: ['local-esm-package'],             // must be valid ESM if excluded
  force: true,                                // ignore cache, re-optimize (temporary debugging)
}
```

### 一般的な落とし穴

#### Dev がビルドにマッチしない

Dev は変換に esbuild/Rolldown を使い、ビルドはバンドルに Rolldown を使う。CJS ライブラリは 2 つの間で異なる振る舞いをすることがある。デプロイ前に常に `vite build && vite preview` で検証する。

#### デプロイ後の古いチャンク

新しいビルドは新しいチャンクハッシュを生成する。アクティブセッションのユーザーはもう存在しない古いファイル名をリクエストする。Vite には組み込みソリューションがない。緩和策：

- デプロイウィンドウ中に古い `dist/assets/` ファイルをライブに保つ
- ルータで動的インポートエラーをキャッチしてページリロードを強制する

#### Docker とコンテナ

Vite はデフォルトで `localhost` にバインドし、コンテナ外部から到達不可能：

```typescript
// vite.config.ts — Docker/container setup
server: {
  host: true,                                  // bind 0.0.0.0
  hmr: { clientPort: 3000 },                   // if behind a reverse proxy
}
```

#### モノレポファイルアクセス

Vite はファイル提供をプロジェクトルートに制限する。ルート外のパッケージはブロックされる：

```typescript
// vite.config.ts — monorepo file access
server: {
  fs: {
    allow: ['..'],                             // allow parent directory (workspace root)
  },
}
```

### アンチパターン

```typescript
// BAD: Setting envPrefix to '' exposes ALL env vars (including secrets) to the client
envPrefix: ''

// BAD: Assuming require() works in application source code — Vite is ESM-first
const lib = require('some-lib')                // use import instead

// BAD: Splitting every node_module into its own chunk — creates hundreds of tiny files
manualChunks(id) {
  if (id.includes('node_modules')) {
    return id.split('node_modules/')[1].split('/')[0]   // one chunk per package
  }
}

// BAD: Not externalizing peer deps in library mode — causes duplicate runtime errors
// build.lib without rolldownOptions.external

// BAD: Using deprecated esbuild minifier
build: { minify: 'esbuild' }                  // use 'oxc' (default) or 'terser'

// BAD: Mutating import.meta.hot.data by reassignment
import.meta.hot.data = { count: 0 }           // WRONG: must mutate properties, not reassign
import.meta.hot.data.count = 0                 // CORRECT
```

**プロセスアンチパターン：**

- **`vite preview` は本番サーバではない** — ビルドされたバンドルのスモークテスト。`dist/` を実静的ホスト（NGINX、Cloudflare Pages、Vercel static）にデプロイするかマルチステージ Dockerfile を使う。
- **`vite build` が型チェックすると期待** — トランスパイルするだけ。型エラーがサイレントに本番に出荷される。`vite-plugin-checker` を追加するか CI で `tsc --noEmit` を実行する。
- **`@vitejs/plugin-legacy` をデフォルトで出荷** — バンドルを約 40% 膨らませ、ソースマップバンドルアナライザを壊し、95%+ のモダンブラウザユーザーには不要。仮定ではなく実分析でゲートする。
- **`tsconfig.json` パスを重複する 30+ の `resolve.alias` エントリを手動で作る** — 代わりに `vite-tsconfig-paths` を使う。Excalidraw と PostHog で観察された。新プロジェクトでは避ける。
- **依存関係変更後に古い `node_modules/.vite` を残す** — 事前バンドルキャッシュがファントムエラーを引き起こす。ブランチを切り替えるときまたは依存関係をパッチした後にクリアする。

## クイックリファレンス

| パターン | 使用するタイミング |
|---------|-------------|
| `defineConfig` | 常に — 型推論を提供 |
| `loadEnv(mode, root, ['VITE_'])` | 設定で env var にアクセス（明示的プレフィックス） |
| `vite-plugin-checker` | 任意の TypeScript アプリ（型チェックギャップを埋める） |
| `vite-tsconfig-paths` | 手動 `resolve.alias` の代わりに |
| `optimizeDeps.include` | 相互運用問題を引き起こす CJS deps |
| `server.proxy` | 開発で API リクエストをバックエンドにルート |
| `server.host: true` | Docker、コンテナ、リモートアクセス |
| `server.warmup.clientFiles` | ホットパスルートを事前変換 |
| `build.lib` + `external` | npm パッケージを公開 |
| `manualChunks`（オブジェクト） | ベンダーバンドル分割 |
| `vite --profile` | 遅い開発サーバをデバッグ |
| `vite build && vite preview` | 本番バンドルのローカルスモークテスト（本番サーバではない） |

## 関連スキル

- `frontend-patterns` — React コンポーネントパターン
- `docker-patterns` — Vite でのコンテナ化開発
- `nextjs-turbopack` — Next.js の代替バンドラ

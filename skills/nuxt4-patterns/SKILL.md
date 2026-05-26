---
name: nuxt4-patterns
description: ハイドレーション安全性、パフォーマンス、ルートルール、遅延ロード、useFetch と useAsyncData による SSR セーフなデータフェッチングのための Nuxt 4 アプリパターン (Nuxt 4 app patterns for hydration safety, performance, route rules, lazy loading, SSR-safe data fetching with useFetch and useAsyncData)。
origin: ECC
---

# Nuxt 4 パターン

SSR、ハイブリッドレンダリング、ルートルール、またはページレベルデータフェッチングを伴う Nuxt 4 アプリを構築・デバッグする場合に使う。

## 起動するタイミング

- サーバー HTML とクライアント状態の間のハイドレーション不一致
- prerender、SWR、ISR、またはクライアントのみセクションなどのルートレベルレンダリング決定
- 遅延ロード、遅延ハイドレーション、またはペイロードサイズに関するパフォーマンス作業
- `useFetch`、`useAsyncData`、または `$fetch` を使ったページまたはコンポーネントデータフェッチング
- ルートパラメータ、ミドルウェア、SSR/クライアントの違いに関連する Nuxt ルーティング問題

## ハイドレーション安全性

- 最初のレンダーを決定的に保つ。`Date.now()`、`Math.random()`、ブラウザ専用 API、またはストレージ読み取りを SSR レンダリングされたテンプレート状態に直接入れない
- サーバーが同じマークアップを生成できない場合、ブラウザ専用ロジックを `onMounted()`、`import.meta.client`、`ClientOnly`、または `.client.vue` コンポーネントの背後に移動する
- `vue-router` からではなく Nuxt の `useRoute()` コンポーザブルを使う
- SSR レンダリングされたマークアップを駆動するために `route.fullPath` を使わない。URL フラグメントはクライアントのみで、ハイドレーション不一致を作り得る
- `ssr: false` を不一致のデフォルト修正ではなく、真にブラウザ専用の領域のためのエスケープハッチとして扱う

## データフェッチング

- ページとコンポーネントでの SSR セーフな API 読み取りには `await useFetch()` を優先する。これはサーバーフェッチデータを Nuxt ペイロードに転送し、ハイドレーションでの 2 回目のフェッチを避ける
- フェッチャーがシンプルな `$fetch()` 呼び出しでない場合、カスタムキーが必要な場合、または複数の非同期ソースを構成する場合は `useAsyncData()` を使う
- キャッシュ再利用と予測可能なリフレッシュ挙動のために `useAsyncData()` に安定したキーを与える
- `useAsyncData()` ハンドラを副作用フリーに保つ。SSR とハイドレーション中に実行される可能性がある
- SSR からハイドレートすべきトップレベルページデータではなく、ユーザートリガーの書き込みやクライアント専用アクションには `$fetch()` を使う
- ナビゲーションをブロックすべきでない非クリティカルデータには `lazy: true`、`useLazyFetch()`、または `useLazyAsyncData()` を使う。UI で `status === 'pending'` を処理する
- SEO や最初のペイントに必要でないデータには `server: false` のみ使う
- `pick` でペイロードサイズをトリムし、深い反応性が不要な場合は浅いペイロードを優先する

```ts
const route = useRoute()

const { data: article, status, error, refresh } = await useAsyncData(
  () => `article:${route.params.slug}`,
  () => $fetch(`/api/articles/${route.params.slug}`),
)

const { data: comments } = await useFetch(`/api/articles/${route.params.slug}/comments`, {
  lazy: true,
  server: false,
})
```

## ルートルール

レンダリングとキャッシング戦略には `nuxt.config.ts` 内の `routeRules` を優先する:

```ts
export default defineNuxtConfig({
  routeRules: {
    '/': { prerender: true },
    '/products/**': { swr: 3600 },
    '/blog/**': { isr: true },
    '/admin/**': { ssr: false },
    '/api/**': { cache: { maxAge: 60 * 60 } },
  },
})
```

- `prerender`: ビルド時の静的 HTML
- `swr`: キャッシュされたコンテンツを提供し、バックグラウンドで再検証
- `isr`: サポートされているプラットフォームでのインクリメンタル静的再生成
- `ssr: false`: クライアントレンダリングされたルート
- `cache` または `redirect`: Nitro レベルのレスポンス挙動

グローバルではなくルートグループごとにルートルールを選ぶ。マーケティングページ、カタログ、ダッシュボード、API は通常異なる戦略を必要とする。

## 遅延ロードとパフォーマンス

- Nuxt は既にルートでページをコード分割する。マイクロ最適化前にルート境界を意味のあるものに保つ
- 非クリティカルコンポーネントを動的インポートするには `Lazy` プレフィックスを使う
- UI が実際に必要とするまでチャンクがロードされないよう、遅延コンポーネントを `v-if` で条件付きレンダーする
- スクロール下や非クリティカルなインタラクティブ UI には遅延ハイドレーションを使う

```vue
<template>
  <LazyRecommendations v-if="showRecommendations" />
  <LazyProductGallery hydrate-on-visible />
</template>
```

- カスタム戦略には可視性またはアイドル戦略を伴う `defineLazyHydrationComponent()` を使う
- Nuxt 遅延ハイドレーションはシングルファイルコンポーネントで動作する。遅延ハイドレートされたコンポーネントに新しい props を渡すと、即座にハイドレーションがトリガーされる
- 内部ナビゲーションには `NuxtLink` を使い、Nuxt がルートコンポーネントと生成されたペイロードをプリフェッチできるようにする

## レビューチェックリスト

- 最初の SSR レンダーとハイドレートされたクライアントレンダーが同じマークアップを生成する
- ページデータはトップレベル `$fetch` ではなく `useFetch` または `useAsyncData` を使う
- 非クリティカルデータは遅延で明示的なローディング UI がある
- ルートルールがページの SEO と鮮度要件に一致する
- 重いインタラクティブアイランドは遅延ロードまたは遅延ハイドレートされる

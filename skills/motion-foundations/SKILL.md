---
name: motion-foundations
description: motion/react を用いた React / Next.js のためのモーショントークン、スプリングプリセット、パフォーマンスルール、デバイス適応、アクセシビリティ強制、SSR 安全性。ファウンデーション層 — 他のすべてのモーションスキルがこれに依存する (Motion tokens, spring presets, performance rules, device adaptation, accessibility enforcement, SSR safety for React / Next.js using motion/react)。
version: 1.0
tags: [motion, animation, performance, accessibility]
category: frontend
author: jeff
---

# Motion Foundations

モーションシステムのベース層。下流スキル (`motion-patterns`、`motion-advanced`) が継承するすべての値、制約、ルールを定義する。アニメーション作業を開始する前にこのスキルをロードする。

## 起動するタイミング

- ゼロからアニメーション化されたコンポーネントの開始
- トークン、スプリングプリセット、またはイージング値のセットアップ
- `prefers-reduced-motion` サポートの実装
- アニメーション初期状態からのハイドレーション不一致のデバッグ
- アニメーションが存在すべきかどうかの評価

## 出力

このスキルが生み出すもの:

- 共有 `motionTokens` オブジェクト (duration、easing、distance、scale)
- 共有 `springs` プリセットマップ (5 つの名前付き設定)
- すべてのコンポーネントが使う `shouldAnimate()` ゲート
- `useReducedMotion` によるアクセシビリティ準拠アニメーションデフォルト
- ハイドレーション警告ゼロの SSR セーフ初期状態

## 原則

モーションは以下の少なくとも 1 つを行わなければならず、そうでなければ削除されなければならない:

- 注意を導く
- 状態を伝える
- 空間的連続性を保つ

レスポンシブネスはスムーズネスより常に上位である。入力遅延を引き起こす 60 fps アニメーションは、アニメーションなしより悪い。

## ルール

これらは交渉不可。システムのすべてのコンポーネントに適用される。

1. **`motion/react` のみを使用する**。`framer-motion` からインポートしない。同じツリーで両方を混ぜない
2. **`initial` はサーバー出力と一致しなければならない**。サーバーが `opacity: 1` をレンダーする場合、`initial` プロップも `opacity: 1` でなければならない。例外なし
3. **リデュースドモーションがすべてを上書きする**。`useReducedMotion()` が `true` を返すか `prefersReduced` が `true` の場合、すべての transform は無効化される。≤ 0.2s の opacity のみフェードが唯一許可されるフォールバック
4. **レイアウトプロパティをアニメーションしない**。`width`、`height`、`top`、`left`、`margin`、`padding` は `animate` から禁止。`transform` と `opacity` のみを使用する
5. **すべてのトークン値は `motionTokens` から来る**。コンポーネントファイル内のハードコードされた持続時間とイージングは禁止
6. **すべてのスプリング設定は `springs` マップから来る**。インラインの `stiffness`/`damping` 値は禁止
7. **`motion/react` からインポートするすべてのファイルで `"use client"` が必要**
8. **モジュールレベルで `window` または `navigator` を決して読まない**。常に `typeof window !== "undefined"` でガードする

## 決定ガイダンス

### 持続時間の選択

| トークン | 使用ケース |
| --------- | -------------------------------------------- |
| `instant` | ツールチップ表示/非表示、フォーカスリング、バッジ更新 |
| `fast` | ボタンフィードバック、アイコンスワップ、チップトグル |
| `normal` | モーダルオープン、カード展開、ページ要素エンター |
| `slow` | ヒーロー入場、フルページトランジション |
| `crawl` | 意図的なストーリーテリング。控えめに使う |

### スプリングの選択

| プリセット | 使用ケース |
| --------- | ------------------------------------------ |
| `snappy` | デフォルト UI — ボタン、チップ、ナビアイテム |
| `gentle` | ソフトに着地するカード、モーダル、パネル |
| `bouncy` | 遊び心のある瞬間 — 空状態、オンボーディング |
| `instant` | ツールチップ、ポップオーバー、ドロップダウン |
| `release` | ドラッグリリース — 自然な物理感 |

### アニメーションを完全に無効にするタイミング

以下の場合、無効化する (`shouldAnimate()` が `false` を返すようにする):

- `prefersReduced` が `true`
- `isLowEnd` が `true` でアニメーションが非必須
- 要素が画面外でビューポートに入らない
- アニメーションが純粋に装飾的で UX 目的がない

## コア概念

### トークンシステム

```ts
// lib/motion-tokens.ts
export const motionTokens = {
  duration: {
    instant: 0.08,
    fast:    0.18,
    normal:  0.35,
    slow:    0.6,
    crawl:   1.0,
  },
  easing: {
    smooth: [0.22, 1, 0.36, 1],
    sharp:  [0.4, 0, 0.2, 1],
    bounce: [0.34, 1.56, 0.64, 1],
    linear: [0, 0, 1, 1],
  },
  distance: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 48,
  },
  scale: {
    subtle: 0.98,
    press:  0.95,
    pop:    1.04,
  },
}

export const springs = {
  snappy:  { type: "spring", stiffness: 300, damping: 30 },
  gentle:  { type: "spring", stiffness: 120, damping: 14 },
  bouncy:  { type: "spring", stiffness: 400, damping: 10 },
  instant: { type: "spring", stiffness: 600, damping: 35 },
  release: { type: "spring", stiffness: 200, damping: 20, restDelta: 0.001 },
}
```

### ランタイムフラグ

```ts
// lib/motion-config.ts
export const motionConfig = {
  isLowEnd() {
    return (
      typeof navigator !== "undefined" &&
      navigator.hardwareConcurrency <= 4
    )
  },

  prefersReduced() {
    return (
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
    )
  },

  shouldAnimate({ essential = false } = {}) {
    if (this.prefersReduced()) return false
    if (!essential && this.isLowEnd()) return false
    return true
  },

  duration() {
    return this.isLowEnd() || this.prefersReduced()
      ? motionTokens.duration.instant
      : motionTokens.duration.normal
  },
}
```

### アクセシビリティ

**優先順位 (高から低):**

1. `prefers-reduced-motion: reduce` — すべての transform を無効化、opacity トランジションを ≤ 0.2s に制限
2. 低スペックデバイス検出 — 持続時間を削減、非必須アニメーションを削除
3. デザイン選好 — その他すべて

モーションは優雅に劣化しなければならない。レイアウトシフトや方向感覚を混乱させる形で突然消えてはならない。

```tsx
// hooks/use-reduced-motion.tsx
"use client"
import { useReducedMotion } from "motion/react"

export function useSafeMotion(fullY: number = 16) {
  const reduce = useReducedMotion()
  return {
    initial: { opacity: 0, y: reduce ? 0 : fullY },
    animate: { opacity: 1, y: 0 },
    exit:    { opacity: 0, y: reduce ? 0 : -fullY },
  }
}
```

```css
/* globals.css */
@media (prefers-reduced-motion: reduce) {
  .motion-safe-transition  { transition: opacity 0.15s; }
  .motion-reduce-transform { transform: none !important; }
}
```

```html
<!-- Tailwind -->
<div class="motion-safe:animate-fade motion-reduce:opacity-100"></div>
```

### SSR / ハイドレーション安全性

**ルール: `initial` は常にサーバーがレンダーするものと一致しなければならない。**

```tsx
// WRONG — server renders opacity:1 but initial says 0 → hydration mismatch
<motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} />

// CORRECT — use AnimatePresence or defer to client mount
"use client"
const [mounted, setMounted] = useState(false)
useEffect(() => setMounted(true), [])

<motion.div
  initial={{ opacity: mounted ? 0 : 1 }}
  animate={{ opacity: 1 }}
/>
```

## コード例

### エンドツーエンド: トークン + スプリング + アクセシビリティ + SSR ガード

```tsx
// components/fade-in-card.tsx
"use client"

import { useState, useEffect } from "react"
import { motion } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"
import { useSafeMotion } from "@/hooks/use-reduced-motion"
import { motionConfig } from "@/lib/motion-config"

interface FadeInCardProps {
  children: React.ReactNode
  delay?: number
}

export function FadeInCard({ children, delay = 0 }: FadeInCardProps) {
  // SSR guard — initial must match server output (opacity: 1)
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])

  // Accessibility — disables transform when reduced motion is preferred
  const safeMotion = useSafeMotion(motionTokens.distance.md)

  // Device gate — skip animation on low-end hardware
  if (!motionConfig.shouldAnimate() || !mounted) {
    return <div>{children}</div>
  }

  return (
    <motion.div
      initial={safeMotion.initial}
      animate={safeMotion.animate}
      exit={safeMotion.exit}
      transition={{
        ...springs.gentle,
        delay,
      }}
      whileHover={{ scale: motionTokens.scale.pop }}
      whileTap={{ scale: motionTokens.scale.press }}
    >
      {children}
    </motion.div>
  )
}
```

## 制約 / 非目標

このスキルは以下を**カバーしない**:

- UI コンポーネントパターン (ボタン、モーダル、スタッガー) → `motion-patterns` を参照
- ドラッグ、ジェスチャー、SVG、テキストアニメーション、カスタムフック → `motion-advanced` を参照
- `motion/react` なしの CSS のみのアニメーションや Tailwind `animate-*` クラス
- サードパーティアニメーションライブラリ (GSAP、anime.js など)
- モーションデザイン決定 (アニメーション化のタイミング、強調する内容) — これはデザインの懸念であり、コードの制約ではない

## アンチパターン

| アンチパターン | 違反ルール | 修正 |
| --------------------------------------- | ------- | ------------------------------- |
| `import { motion } from "framer-motion"` | ルール 1 | `motion/react` を使用 |
| SSR コンポーネントでの `initial={{ opacity: 0 }}` | ルール 2 | マウントガードを追加 |
| `useReducedMotion` チェックをスキップ | ルール 3 | `useSafeMotion` フックを使用 |
| `animate={{ width: "100%" }}` | ルール 4 | 代わりに `scaleX` transform を使用 |
| インラインの `transition={{ duration: 0.4 }}` | ルール 5 | `motionTokens.duration.normal` を使用 |
| インラインの `{ stiffness: 300, damping: 30 }` | ルール 6 | `springs.snappy` を使用 |
| `"use client"` ディレクティブの欠落 | ルール 7 | ファイルの先頭に追加 |
| モジュールレベルでの `navigator.hardwareConcurrency` | ルール 8 | `typeof navigator !== "undefined"` でラップ |

## 関連スキル

- **`motion-patterns`** — ここで定義されたトークンとスプリングを消費してボタン、モーダル、スタッガー、ページトランジション、スクロールパターンを構築する。値を再定義しない
- **`motion-advanced`** — ここで定義されたトークンとスプリングを消費してドラッグ、SVG、テキスト、ジェスチャーパターンを行う。このファウンデーションの上に `useAnimate` シーケンスとカスタムフックを追加する

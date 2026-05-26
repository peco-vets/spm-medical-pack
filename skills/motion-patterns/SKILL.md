---
name: motion-patterns
description: React / Next.js のための本番対応アニメーションパターン — ボタン、モーダル、トースト、スタッガー、ページトランジション、退場アニメーション、スクロール、レイアウト — motion-foundations のトークンとスプリングをベースに構築 (Production-ready animation patterns for React / Next.js — button, modal, toast, stagger, page transitions, exit animations, scroll, layout)。
version: 1.0
tags: [motion, animation, ui-patterns]
category: frontend
author: jeff
---

# Motion Patterns

最も一般的な UI アニメーションニーズのためのコピペパターン。
ここのすべてのパターンは `motion-foundations` のトークンとスプリングをベースに構築されている。
ここで新しい duration や easing 値を定義しない — インポートする。

## 起動するタイミング

- ボタン、カード、モーダル、またはトースト通知をアニメーション化
- スタッガー付きリスト入場の構築
- Next.js App Router でのページトランジションのセットアップ
- 条件付きコンテンツへの入場または退場アニメーションの追加
- スクロールリビール、スクロール連動プログレス、または粘着ストーリーセクションの実装
- 展開カード、アコーディオン、または共有要素トランジションの構築

## 出力

このスキルが生み出すもの:

- すべての標準 UI コンポーネントへのアクセシブルで SSR セーフなアニメーション
- 正しい退場挙動を伴う `AnimatePresence` ラップ条件付きレンダー
- Next.js App Router 用ページトランジションラッパーコンポーネント
- `useScroll` + `useTransform` を使ったスクロールリビールとスクロール連動パターン
- 展開とクロスフェード要素のためのレイアウトアニメーションパターン (`layout`、`layoutId`)

## 原則

- すべてのパターンが `motion-foundations` からインポートする。生の数値なし
- すべての条件付きレンダーが `key` 付き `AnimatePresence` でラップされる
- 退場アニメーションは常に入場アニメーションと並んで定義される — 後付けではない
- `layout` は小さい孤立したシフトにのみ使用する。大きなサブツリーには明示的な transform を使う

## ルール

1. **条件付きレンダーは直接の子に `key` を付けて常に `AnimatePresence` でラップする**。key なしでは退場アニメーションは決して発火しない
2. **`initial` + `animate` を定義する場合は常に `exit` を定義する**。退場のないアニメーションは不完全である
3. **ページトランジションには `mode="wait"` を使う**。退場が完了するまで入場を開始してはならない
4. **~5 子以上または深くネストされた DOM のサブツリーに `layout` を使わない**。代わりに明示的な `x`/`y` transform を使う
5. **スタッガーインターバルは `0.05s` と `0.10s` の間に留める**。それ未満は機械的に感じ、それ以上は鈍重に感じる
6. **モーダルには常に以下を含める**: フォーカストラップ、Escape キークローズ、スクロールロック、`role="dialog"`、`aria-modal="true"`
7. **スクロールリビールは `viewport={{ once: true }}` を使う**。スクロールアウトで繰り返すのは情報的ではなく邪魔
8. **すべてのトークン値は `motion-foundations` からインポートされる**。インライン数値なし

## 決定ガイダンス

### 適切なパターンの選択

| 状況 | パターン |
| ---------------------------------------- | ---------------------- |
| 要素が現れる / 消える | `AnimatePresence` |
| シーケンスでロードするアイテムのリスト | スタッガーバリアント |
| ルート間のナビゲーション | ページトランジションラッパー |
| 要素がその場でサイズ変更 | `layout` プロップ |
| 同じ要素がページコンテキストを越えて移動 | `layoutId` |
| 要素がスクロールでビューに入ると入場 | `whileInView` |
| スクロール位置に連動した値 | `useScroll` + `useTransform` |

### `mode="wait"` 対 `mode="sync"` の使い分け

| モード | 使用ケース |
| ------- | --------------------------------------- |
| `wait` | ページトランジション、コンテンツスワップ (一度に 1 つ) |
| `sync` | スタックされた通知、リストアイテム (重複は OK) |
| `popLayout` | リフローリストから削除されるアイテム |

## コア概念

### AnimatePresence 契約

3 つのことが常に真でなければならない:

1. `AnimatePresence` が条件付きをラップする
2. 直接の子が `key` を持つ
3. 子が `exit` プロップを持つ

いずれかを欠くと退場アニメーションは静かに失敗する。

### layout 対 layoutId

- `layout` — 要素自身のサイズ/位置変化をその場でアニメーション化
- `layoutId` — 2 つの別個の要素をリンクし、レンダー間でクロスフェード

展開コンテナ内のテキストには `layout="position"` を使い、テキストリフローのアニメーション化を防ぐ。

## コード例

### ボタンフィードバック

```tsx
"use client"
import { motion } from "motion/react"
import { springs, motionTokens } from "@/lib/motion-tokens"

<motion.button
  whileHover={{ scale: motionTokens.scale.pop }}
  whileTap={{ scale: motionTokens.scale.press }}
  transition={springs.snappy}
/>
```

### スタッガーリスト

```tsx
"use client"
import { motion } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

const container = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.08,   // within the 0.05–0.10 rule
      delayChildren: 0.1,
    },
  },
}

const item = {
  hidden:  { opacity: 0, y: motionTokens.distance.md },
  visible: { opacity: 1, y: 0, transition: springs.gentle },
}

<motion.ul variants={container} initial="hidden" animate="visible">
  {items.map((i) => (
    <motion.li key={i.id} variants={item} />
  ))}
</motion.ul>
```

### モーダル

```tsx
"use client"
import { motion, AnimatePresence } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

// Wrap at the call site:
// <AnimatePresence>{isOpen && <Modal key="modal" />}</AnimatePresence>

export function Modal({ onClose }: { onClose: () => void }) {
  return (
    <>
      {/* Overlay */}
      <motion.div
        className="fixed inset-0 bg-black/50"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
      />

      {/* Panel — accessibility requirements: focus trap, Escape close,
          scroll lock, role="dialog", aria-modal="true" */}
      <motion.div
        role="dialog"
        aria-modal="true"
        className="fixed inset-x-4 top-1/2 -translate-y-1/2 rounded-xl bg-white p-6"
        initial={{
          opacity: 0,
          scale: motionTokens.scale.press,
          y: motionTokens.distance.sm,
        }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{
          opacity: 0,
          scale: motionTokens.scale.press,
          y: motionTokens.distance.sm,
        }}
        transition={springs.gentle}
      />
    </>
  )
}
```

### トーストスタック

```tsx
"use client"
import { motion, AnimatePresence } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

<AnimatePresence mode="sync">
  {toasts.map((t) => (
    <motion.div
      key={t.id}
      layout
      initial={{
        opacity: 0,
        x: motionTokens.distance.xl,
        scale: motionTokens.scale.subtle,
      }}
      animate={{ opacity: 1, x: 0, scale: 1 }}
      exit={{
        opacity: 0,
        x: motionTokens.distance.xl,
        scale: motionTokens.scale.subtle,
      }}
      transition={springs.snappy}
    />
  ))}
</AnimatePresence>
```

### ページトランジション (Next.js App Router)

```tsx
// components/page-transition.tsx
"use client"
import { motion, AnimatePresence } from "motion/react"
import { usePathname } from "next/navigation"
import { motionTokens } from "@/lib/motion-tokens"

const variants = {
  initial: { opacity: 0, y: motionTokens.distance.sm },
  enter:   { opacity: 1, y: 0 },
  exit:    { opacity: 0, y: -motionTokens.distance.sm },
}

export function PageTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        variants={variants}
        initial="initial"
        animate="enter"
        exit="exit"
        transition={{
          duration: motionTokens.duration.normal,
          ease: motionTokens.easing.smooth,
        }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  )
}
```

### スクロールリビール

```tsx
"use client"
import { motion } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

<motion.div
  initial={{ opacity: 0, y: motionTokens.distance.lg }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, margin: "-80px" }}   // once: true — rule 7
  transition={{ duration: motionTokens.duration.slow, ease: motionTokens.easing.smooth }}
/>
```

### スクロールプログレスバー

```tsx
"use client"
import { motion, useScroll } from "motion/react"

export function ScrollProgress() {
  const { scrollYProgress } = useScroll()
  return (
    <motion.div
      className="fixed top-0 left-0 h-1 bg-indigo-500 origin-left w-full"
      style={{ scaleX: scrollYProgress }}
    />
  )
}
```

### 展開カード

```tsx
"use client"
import { useState } from "react"
import { motion, AnimatePresence } from "motion/react"
import { springs, motionTokens } from "@/lib/motion-tokens"

export function ExpandingCard({ title, body }: { title: string; body: string }) {
  const [expanded, setExpanded] = useState(false)

  return (
    <motion.div layout onClick={() => setExpanded(!expanded)} className="cursor-pointer">
      {/* layout="position" prevents text reflow from animating */}
      <motion.h2 layout="position" className="font-semibold">
        {title}
      </motion.h2>

      <AnimatePresence>
        {expanded && (
          <motion.p
            key="body"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: motionTokens.duration.fast }}
          >
            {body}
          </motion.p>
        )}
      </AnimatePresence>
    </motion.div>
  )
}
```

### 共有要素クロスフェード

```tsx
// Source context
<motion.img layoutId="hero-image" src={src} className="w-16 h-16 rounded" />

// Destination context (same layoutId — motion handles the transition)
<motion.img layoutId="hero-image" src={src} className="w-full rounded-xl" />
```

### アコーディオン

```tsx
<motion.div
  initial={false}
  animate={{ opacity: open ? 1 : 0, scaleY: open ? 1 : 0 }}
  style={{ transformOrigin: "top", overflow: "hidden" }}
  transition={{
    duration: motionTokens.duration.normal,
    ease: motionTokens.easing.smooth,
  }}
>
  {children}
</motion.div>
```

## エンドツーエンド例

マウントで入場するスタッガー付きリスト。条件付きプレゼンスを処理し、リデュースドモーションを尊重する — トークン、スプリング、AnimatePresence、`motion-foundations` のアクセシビリティフックを組み合わせる:

```tsx
"use client"
import { useState } from "react"
import { motion, AnimatePresence } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"
import { useSafeMotion } from "@/hooks/use-reduced-motion"

const containerVariants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.08, delayChildren: 0.1 },
  },
}

function ListItem({ label, onRemove }: { label: string; onRemove: () => void }) {
  const safe = useSafeMotion(motionTokens.distance.sm)
  return (
    <motion.li
      variants={{
        hidden:  safe.initial,
        visible: safe.animate,
      }}
      exit={safe.exit}
      transition={springs.gentle}
      className="flex items-center justify-between p-3 rounded-lg bg-white shadow-sm"
    >
      <span>{label}</span>
      <button onClick={onRemove}>Remove</button>
    </motion.li>
  )
}

export function AnimatedList({ items, onRemove }: {
  items: { id: string; label: string }[]
  onRemove: (id: string) => void
}) {
  return (
    <motion.ul
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-2"
    >
      <AnimatePresence mode="popLayout">
        {items.map((item) => (
          <ListItem
            key={item.id}
            label={item.label}
            onRemove={() => onRemove(item.id)}
          />
        ))}
      </AnimatePresence>
    </motion.ul>
  )
}
```

## 制約 / 非目標

このスキルは以下を**カバーしない**:

- トークンとスプリング定義 → `motion-foundations` を参照
- ドラッグインタラクション、スワイプジェスチャー、並べ替え可能リスト → `motion-advanced` を参照
- テキストアニメーション (単語/文字リビール、カウンタ) → `motion-advanced` を参照
- SVG パス描画やモーフィング → `motion-advanced` を参照
- カスタムアニメーションフック → `motion-advanced` を参照
- `motion/react` を使わない CSS のみのトランジション

## アンチパターン

| アンチパターン | 違反ルール | 修正 |
| -------------------------------------------- | ------- | ------------------------------------------ |
| `AnimatePresence` 子に `key` が欠落 | ルール 1 | 直接の子に安定した `key` を追加 |
| `exit` なしの `initial` + `animate` | ルール 2 | 常に 3 つすべてを一緒に定義 |
| `mode="wait"` なしのページトランジション | ルール 3 | `AnimatePresence` に `mode="wait"` を追加 |
| 50 アイテムリスト上の `layout` | ルール 4 | `mode="popLayout"` または明示的 transform を使用 |
| 10 アイテムリストの `staggerChildren: 0.2` | ルール 5 | `0.08–0.10` に上限 |
| フォーカストラップなしのモーダル | ルール 6 | `focus-trap-react` または Radix Dialog を追加 |
| `viewport={{ once: true }}` なしの `whileInView` | ルール 7 | 繰り返し入場は情報的ではなく邪魔 |
| インラインの `transition={{ duration: 0.3 }}` | ルール 8 | `motionTokens.duration.normal` を使用 |

## 関連スキル

- **`motion-foundations`** — ここのすべてのパターンがインポートするすべてのトークン、スプリング、`useSafeMotion` フック、SSR ガードを定義する。最初にセットアップが必要
- **`motion-advanced`** — これらのパターンをドラッグ、ジェスチャー、SVG、テキスト、カスタムフック、命令的シーケンシングで拡張する。このスキルからパターンを再定義しない

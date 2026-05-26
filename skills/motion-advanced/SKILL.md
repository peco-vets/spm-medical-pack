---
name: motion-advanced
description: React / Next.js のための高度なモーションパターン — ドラッグ&ドロップ、ジェスチャー、テキストアニメーション、SVG パス描画、カスタムフック、命令的シーケンス (useAnimate)、ローダー、完全な API 決定ツリー。motion-foundations が必要 (Advanced motion patterns for React / Next.js — drag & drop, gestures, text animations, SVG path drawing, custom hooks, imperative sequences, loaders)。
version: 1.0
tags: [motion, animation, advanced, gestures, svg]
category: frontend
author: jeff
---

# Motion Advanced

複雑でインタラクティブ、物理ベースのアニメーションパターン。
まず `motion-foundations` がセットアップされている必要がある。
`motion-patterns` で不十分な場合に使う。

## 起動するタイミング

- ドラッグ-ディスミスシート、スワイプジェスチャー、または並べ替え可能リストの構築
- 単語ごと、文字ごと、またはライブカウンタとしてテキストをアニメーション
- SVG パスの描画、アイコンモーフィング、または円形プログレスのアニメーション
- カスタムアニメーションフックの記述 (`useScrollReveal`、マグネティックボタン、カーソルフォロワー)
- `useAnimate` でマルチステップアニメーションを命令的にシーケンス
- スピナー、シマースケルトン、パルスインジケータ、またはローディングボタン状態の構築

## 出力

このスキルが生み出すもの:

- ドラッグインタラクション: ドラッグ可能カード、ドラッグ-ディスミスシート、`Reorder.Group` リスト
- ジェスチャーフック: スワイプ検出、ロングプレス、ピンチアウトライン
- テキストアニメーションコンポーネント: 単語リビール、文字タイプライター、数値カウンタ
- SVG アニメーション: パス描画、アイコンモーフ、ストロークプログレスリング
- カスタムフック: `useScrollReveal`、`useHoverScale`、`useNavigationDirection`、`useInViewOnce`
- 中断セーフな `async/await` 付き `useAnimate` による命令的シーケンス
- ローダーコンポーネント: スピナー、シマー、パルスドット、プログレスバー、ボタンローディング状態

## 原則

- 物理ベースモーション (`useSpring`、`springs.*`) は直接操作には常に持続時間ベースより自然に感じる
- `useMotionValue` + `useTransform` は再レンダーをトリガーせずに派生値を計算する
- `useAnimate` シーケンスは命令的かつ中断セーフ — フライト中の `animate()` 呼び出しは前のアニメーションを自動的にキャンセルする
- モーション値 (`useMotionValue`、`useSpring`) は SSR セーフでハイドレーションエラーを起こさない

## ルール

これらは交渉不可。システムのすべてのコンポーネントに適用される。

1. **ドラッグインタラクションはタッチデバイスでテストする**。マウスだけではない。`drag` プロップは両方で動作するが、感触と閾値が異なる
2. **`document.visibilityState === "hidden"` の場合、無限アニメーションは一時停止しなければならない**。バックグラウンドタブは GPU/CPU を消費してはならない
3. **スワイプ閾値は明示的でなければならない**。速度のみから意図を推測しない。`offset` + `velocity` チェックを組み合わせる
4. **`useAnimate` スコープ ref はマウントされた DOM 要素に取り付けなければならない**。マウント前に `animate()` を呼ぶとサイレントに失敗する
5. **モーション値はレンダーで再作成してはならない**。コンポーネントボディ内の `useMotionValue(0)` は正しい。レンダーでの `new MotionValue(0)` は違う
6. **すべてのトークン値は `motion-foundations` からインポートされる**。インライン数値なし
7. **カスタムフックはクリーンアップを処理しなければならない**。すべての `window.addEventListener` には `useEffect` の return に対応する `removeEventListener` が必要
8. **SVG モーフィングには等しいパスコマンド数が必要**。異なるコマンド構造のパスは補間ではなくスナップする

## 決定ガイダンス

### 適切な高度な API の選択

| シナリオ | API |
| ------------------------------ | -------------------------------- |
| リリース時に物理を伴うドラッグ | `drag` + `dragTransition: springs.release` |
| 順序ドラッグ-リオーダーリスト | `Reorder.Group` + `Reorder.Item` |
| ドラッグオフセットでディスミス | `drag="y"` + `onDragEnd` オフセットチェック |
| 左/右スワイプ | `drag="x"` + `onDragEnd` オフセットチェック |
| ロングプレス | `useLongPress` フック |
| 時間で平滑化された値 | `useSpring` |
| 別の値から派生した値 | `useTransform` |
| マルチステップシーケンス | `async/await` 付き `useAnimate` |
| ワンショット命令的アニメーション | `motion` からの `animate()` |
| 単語ごとに入るテキスト | `inline-block` スパンでのスタッガー |
| SVG 描画 | `pathLength` 0 → 1 |
| SVG モーフ | `d` 属性トゥイーン (等しいコマンド) |
| 円形プログレス | `strokeDashoffset` トゥイーン |

### `useSpring` 対スプリングトランジションの使い分け

| | `useSpring` | `transition: springs.*` |
| -------------- | ---------------------------------------- | ----------------------- |
| 使用ケース | カーソルフォロワー、ポインタ追跡値 | 離散的な状態変化 |
| 更新 | 連続、毎フレーム | 状態変化によりトリガー |
| 中断 | スムーズ — 物理が速度から拾う | 現在値から再開 |

## コア概念

### useMotionValue + useTransform

再レンダーなしのリアクティブ計算:

```tsx
const x = useMotionValue(0)
const opacity = useTransform(x, [-200, 0, 200], [0, 1, 0])
// opacity updates every frame as x changes — no setState, no re-render
```

### useAnimate

`[scope, animate]` を返す。スコープ ref は DOM 要素に取り付ける必要がある。
`animate()` 呼び出しは中断セーフ — フライト中の呼び出しは前のランをキャンセルする。

```tsx
const [scope, animate] = useAnimate()

async function play() {
  await animate(".step-1", { opacity: 1 }, { duration: 0.3 })
  await animate(".step-2", { x: 0 },       { duration: 0.4 })
        animate(".step-3", { scale: 1 },    { duration: 0.25 })  // fire and forget
}

return <div ref={scope}>...</div>
```

## コード例

### ドラッグ可能カード

```tsx
"use client"
import { motion } from "motion/react"
import { springs, motionTokens } from "@/lib/motion-tokens"

<motion.div
  drag
  dragConstraints={{ left: -100, right: 100, top: -100, bottom: 100 }}
  dragElastic={0.1}
  whileDrag={{
    scale: motionTokens.scale.pop,
    boxShadow: "0 16px 40px rgba(0,0,0,0.2)",
  }}
  dragTransition={springs.release}
/>
```

### ドラッグ-ディスミスシート

```tsx
"use client"
import { motion, useMotionValue, useTransform } from "motion/react"

export function BottomSheet({ onClose }: { onClose: () => void }) {
  const y = useMotionValue(0)
  const opacity = useTransform(y, [0, 200], [1, 0])

  return (
    <motion.div
      drag="y"
      dragConstraints={{ top: 0 }}
      style={{ y, opacity }}
      onDragEnd={(_, info) => {
        // Rule 3: combine offset + velocity
        if (info.offset.y > 120 || info.velocity.y > 500) onClose()
      }}
    />
  )
}
```

### 並べ替え可能リスト

```tsx
"use client"
import { Reorder } from "motion/react"

export function SortableList() {
  const [items, setItems] = useState(initialItems)
  return (
    <Reorder.Group axis="y" values={items} onReorder={setItems}>
      {items.map((item) => (
        <Reorder.Item key={item.id} value={item}>
          {item.label}
        </Reorder.Item>
      ))}
    </Reorder.Group>
  )
}
```

### スワイプ検出

```tsx
"use client"
import { motion } from "motion/react"

const OFFSET_THRESHOLD  = 50
const VELOCITY_THRESHOLD = 300

<motion.div
  drag="x"
  dragConstraints={{ left: 0, right: 0 }}
  onDragEnd={(_, info) => {
    const swipedRight = info.offset.x > OFFSET_THRESHOLD  || info.velocity.x > VELOCITY_THRESHOLD
    const swipedLeft  = info.offset.x < -OFFSET_THRESHOLD || info.velocity.x < -VELOCITY_THRESHOLD
    if (swipedRight) onSwipeRight()
    if (swipedLeft)  onSwipeLeft()
  }}
/>
```

### ロングプレスフック

```tsx
import { useRef } from "react"

export function useLongPress(callback: () => void, ms = 600) {
  const timerRef = useRef<ReturnType<typeof setTimeout>>()
  return {
    onPointerDown:  () => { timerRef.current = setTimeout(callback, ms) },
    onPointerUp:    () => clearTimeout(timerRef.current),
    onPointerLeave: () => clearTimeout(timerRef.current),
  }
}
```

### 単語ごとのリビール

```tsx
"use client"
import { motion } from "motion/react"
import { springs } from "@/lib/motion-tokens"

export function AnimatedText({ text }: { text: string }) {
  return (
    <motion.p
      variants={{ visible: { transition: { staggerChildren: 0.05 } } }}
      initial="hidden"
      animate="visible"
    >
      {text.split(" ").map((word, i) => (
        <motion.span
          key={i}
          className="inline-block mr-1"
          variants={{
            hidden:  { opacity: 0, y: 12 },
            visible: { opacity: 1, y: 0, transition: springs.gentle },
          }}
        >
          {word}
        </motion.span>
      ))}
    </motion.p>
  )
}
```

### 数値カウンタ

```tsx
"use client"
import { useRef, useEffect } from "react"
import { animate } from "motion"
import { motionTokens } from "@/lib/motion-tokens"

export function Counter({ to }: { to: number }) {
  const nodeRef = useRef<HTMLSpanElement>(null)

  useEffect(() => {
    const controls = animate(0, to, {
      duration: motionTokens.duration.crawl,
      ease: motionTokens.easing.smooth,
      onUpdate: (v) => {
        if (nodeRef.current) nodeRef.current.textContent = Math.round(v).toString()
      },
    })
    return controls.stop   // Rule 7: cleanup
  }, [to])

  return <span ref={nodeRef} />
}
```

### SVG パス描画

```tsx
"use client"
import { motion } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

<motion.path
  d="M 0 100 Q 50 0 100 100"
  initial={{ pathLength: 0, opacity: 0 }}
  animate={{ pathLength: 1, opacity: 1 }}
  transition={{ duration: motionTokens.duration.slow, ease: motionTokens.easing.smooth }}
/>
```

### ストロークプログレスリング

```tsx
"use client"
import { motion } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

const CIRCUMFERENCE = 2 * Math.PI * 40   // r=40

export function ProgressRing({ progress }: { progress: number }) {
  return (
    <svg width="100" height="100" viewBox="0 0 100 100">
      <circle cx="50" cy="50" r="40" fill="none" stroke="#e5e7eb" strokeWidth="8" />
      <motion.circle
        cx="50" cy="50" r="40"
        fill="none" stroke="#6366f1" strokeWidth="8"
        strokeLinecap="round"
        strokeDasharray={CIRCUMFERENCE}
        animate={{ strokeDashoffset: CIRCUMFERENCE - (progress / 100) * CIRCUMFERENCE }}
        transition={{ duration: motionTokens.duration.normal, ease: motionTokens.easing.smooth }}
        style={{ rotate: -90, transformOrigin: "center" }}
      />
    </svg>
  )
}
```

### useScrollReveal フック

```tsx
"use client"
import { useRef } from "react"
import { useScroll, useTransform } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

export function useScrollReveal() {
  const ref = useRef(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
  const opacity = useTransform(scrollYProgress, [0, 0.3], [0, 1])
  const y       = useTransform(scrollYProgress, [0, 0.3], [motionTokens.distance.lg, 0])
  return { ref, style: { opacity, y } }
}

// Usage
const { ref, style } = useScrollReveal()
<motion.section ref={ref} style={style} />
```

### カーソルフォロワー

```tsx
"use client"
import { useEffect } from "react"
import { motion, useMotionValue, useSpring } from "motion/react"
import { springs } from "@/lib/motion-tokens"

export function CursorFollower() {
  const x = useMotionValue(-100)
  const y = useMotionValue(-100)
  const sx = useSpring(x, springs.gentle)
  const sy = useSpring(y, springs.gentle)

  useEffect(() => {
    const move = (e: MouseEvent) => { x.set(e.clientX); y.set(e.clientY) }
    window.addEventListener("mousemove", move)
    return () => window.removeEventListener("mousemove", move)   // Rule 7
  }, [])

  return (
    <motion.div
      className="fixed top-0 left-0 w-6 h-6 rounded-full bg-indigo-500
                 pointer-events-none -translate-x-1/2 -translate-y-1/2 z-50"
      style={{ x: sx, y: sy }}
    />
  )
}
```

### シマースケルトン

```tsx
"use client"
import { useEffect } from "react"
import { motion, useAnimation } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

export function ShimmerSkeleton({ className = "" }: { className?: string }) {
  const controls = useAnimation()

  useEffect(() => {
    const play = () =>
      controls.start({
        x: ["-100%", "100%"],
        transition: {
          repeat: Infinity,
          duration: motionTokens.duration.crawl,
          ease: motionTokens.easing.linear,
        },
      })

    const handleVisibility = () => {
      if (document.visibilityState === "hidden") controls.stop()
      else void play()
    }

    void play()
    document.addEventListener("visibilitychange", handleVisibility)
    return () => {
      controls.stop()
      document.removeEventListener("visibilitychange", handleVisibility)
    }
  }, [controls])

  return (
    <div className={`relative overflow-hidden bg-gray-200 rounded ${className}`}>
      <motion.div
        className="absolute inset-0 bg-gradient-to-r from-transparent via-white/60 to-transparent"
        initial={{ x: "-100%" }}
        animate={controls}
      />
    </div>
  )
}
```

### ボタンローディング状態

```tsx
"use client"
import { motion, AnimatePresence } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

export function LoadingButton({
  loading,
  label,
  onClick,
}: {
  loading: boolean
  label: string
  onClick: () => void
}) {
  return (
    <motion.button
      onClick={onClick}
      animate={{ opacity: loading ? 0.7 : 1 }}
      whileTap={loading ? {} : { scale: motionTokens.scale.press }}
      transition={springs.snappy}
      disabled={loading}
    >
      <AnimatePresence mode="wait">
        {loading ? (
          <motion.span
            key="loading"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            transition={{ duration: motionTokens.duration.fast }}
          >
            …
          </motion.span>
        ) : (
          <motion.span
            key="label"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            transition={{ duration: motionTokens.duration.fast }}
          >
            {label}
          </motion.span>
        )}
      </AnimatePresence>
    </motion.button>
  )
}
```

### 可視性一時停止付き無限アニメーション

```tsx
"use client"
import { useEffect } from "react"
import { motion, useAnimation } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

export function PulseDot() {
  const controls = useAnimation()

  useEffect(() => {
    const pulse = () =>
      controls.start({
        scale: [1, 1.4, 1],
        opacity: [1, 0.6, 1],
        transition: { repeat: Infinity, duration: motionTokens.duration.crawl },
      })

    // Rule 2: pause when tab is hidden
    const handleVisibility = () => {
      if (document.visibilityState === "hidden") controls.stop()
      else void pulse()
    }

    void pulse()
    document.addEventListener("visibilitychange", handleVisibility)
    // Rule 7: stop controls and remove listeners on unmount.
    return () => {
      controls.stop()
      document.removeEventListener("visibilitychange", handleVisibility)
    }
  }, [controls])

  return <motion.span className="w-2 h-2 rounded-full bg-green-400" animate={controls} />
}
```

## エンドツーエンド例

シマーコンテンツ、ローディング状態、リデュースドモーションサポートを伴うドラッグ-ディスミスシート — `useMotionValue`、`useTransform`、`useSafeMotion`、`AnimatePresence`、`motion-foundations` のトークンを組み合わせる:

```tsx
"use client"
import { useState } from "react"
import { motion, AnimatePresence, useMotionValue, useTransform } from "motion/react"
import { springs, motionTokens } from "@/lib/motion-tokens"
import { useSafeMotion } from "@/hooks/use-reduced-motion"
import { ShimmerSkeleton } from "./shimmer-skeleton"

export function DismissibleSheet({
  isOpen,
  onClose,
  loading,
  children,
}: {
  isOpen: boolean
  onClose: () => void
  loading: boolean
  children: React.ReactNode
}) {
  const safe = useSafeMotion(motionTokens.distance.xl)
  const y = useMotionValue(0)
  const opacity = useTransform(y, [0, 200], [1, 0])

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            key="backdrop"
            className="fixed inset-0 bg-black/40"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />

          {/* Sheet — drag-to-dismiss */}
          <motion.div
            key="sheet"
            className="fixed bottom-0 inset-x-0 rounded-t-2xl bg-white p-6"
            drag="y"
            dragConstraints={{ top: 0 }}
            style={{ y, opacity }}
            onDragEnd={(_, info) => {
              if (info.offset.y > 120 || info.velocity.y > 500) onClose()
            }}
            initial={safe.initial}
            animate={safe.animate}
            exit={safe.exit}
            transition={springs.gentle}
          >
            {loading ? (
              <div className="space-y-3">
                <ShimmerSkeleton className="h-4 w-3/4" />
                <ShimmerSkeleton className="h-4 w-1/2" />
                <ShimmerSkeleton className="h-20 w-full" />
              </div>
            ) : children}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
```

## 制約 / 非目標

このスキルは以下を**カバーしない**:

- トークンとスプリング定義 → `motion-foundations` を参照
- 標準 UI パターン (ボタン、モーダル、スタッガー、ページトランジション) → `motion-patterns` を参照
- `motion/react` なしの CSS のみのアニメーションや Tailwind `animate-*`
- Canvas または WebGL ベースのアニメーション (Three.js、Pixi など)
- 外部状態マネージャーを伴う完全なドラッグ&ドロップシステム (dnd-kit、react-beautiful-dnd)
- ゲームループまたはフレームごとのアニメーション

## アンチパターン

| アンチパターン | 違反ルール | 修正 |
| ---------------------------------------------- | ------- | ------------------------------------------------ |
| `drag` をデスクトップでのみテスト | ルール 1 | タッチエミュレータと実機でテスト |
| 一時停止なしの `animate={{ repeat: Infinity }}` | ルール 2 | `visibilitychange` リスナーを追加 |
| `onDragEnd` がオフセットのみチェック、速度なし | ルール 3 | `info.offset` と `info.velocity` の両方をチェック |
| `useEffect` 前の `animate(scope, ...)` | ルール 4 | マウント後のみ `animate()` を呼ぶ |
| レンダー内の `const x = new MotionValue(0)` | ルール 5 | `const x = useMotionValue(0)` を使う |
| インラインの `transition={{ duration: 1.2 }}` | ルール 6 | `motionTokens.duration.crawl` を使う |
| クリーンアップなしの `useEffect` | ルール 7 | `removeEventListener` / `controls.stop` を return |
| 異なるコマンドのパス間の SVG モーフ | ルール 8 | アニメーション前にパスコマンドを正規化 |

## 関連スキル

- **`motion-foundations`** — ここでインポートされるすべてのトークン、スプリング、`useSafeMotion`、SSR ガードを定義する。このスキルを使う前にセットアップが必要
- **`motion-patterns`** — 標準 UI パターン (ボタン、モーダル、スタッガー、ページトランジション、スクロールリビール) を扱う。ここの高度なパターンに手を伸ばす前にそれを使う

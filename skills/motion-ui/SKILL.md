---
name: motion-ui
description: "React/Next.js のための本番対応 UI モーションシステム。アニメーション、トランジション、またはモーションパターンを実装する場合に使用 (Production-ready UI motion system for React/Next.js; animations, transitions, motion patterns)。"
origin: ECC
---

# モーションシステム v4.2

React / Next.js のための本番対応 UI モーションシステム。

装飾ではなく**パフォーマンス、アクセシビリティ、ユーザビリティ**に焦点を当てる。

## 使用するタイミング

モーションが以下を行う場合にこのモーションシステムを使う:

* 注意を導く (例: オンボーディング、主要アクション)
* 状態を伝える (ローディング、成功、エラー、トランジション)
* 空間的連続性を保つ (レイアウト変更、ナビゲーション)

### 適切なシナリオ

* インタラクティブコンポーネント (ボタン、モーダル、メニュー)
* 状態トランジション (ローディング → ロード済み、オープン → クローズ)
* ナビゲーションとレイアウト連続性 (共有要素、クロスフェード)

### 考慮事項

* **アクセシビリティ**: 常にリデュースドモーションをサポート
* **デバイス適応**: 低スペックデバイス向けに調整
* **パフォーマンストレードオフ**: 視覚的スムーズネスよりレスポンシブネスを優先

### モーションを使うことを避けるべき場合

* 純粋に装飾的
* ユーザビリティや明瞭性を低下させる
* パフォーマンスに悪影響を与える

---

## 動作の仕組み

### コア原則

モーションは以下を行わなければならない:

* 注意を導く
* 状態を伝える
* 空間的連続性を保つ

どれも行わない場合 → 削除する。

---

### インストール

```bash
npm install motion
```

---

### バージョン

* `motion/react` - 現在の Motion for React プロジェクトのデフォルト (パッケージ: `motion`)
* `framer-motion` - Framer Motion にまだ依存しているプロジェクトのレガシーインポートパス

**混在させない**。混在は競合する内部スケジューラと壊れた `AnimatePresence` コンテキストを引き起こす — 一方のパッケージからのコンポーネントは他方のパッケージのコンポーネントと退場アニメーションを協調しない。

プロジェクトが使うバージョンを確認するには:

```bash
cat package.json | grep -E '"motion"|"framer-motion"'
```

常に 1 つのソースから一貫してインポートする:

```ts
// Correct (modern)
import { motion, AnimatePresence } from "motion/react"

// Correct (legacy)
import { motion, AnimatePresence } from "framer-motion"

// Never mix both in the same project
```

---

### モーショントークン

```ts
// motionTokens.ts
export const motionTokens = {
  duration: {
    fast: 0.18,
    normal: 0.35,
    slow: 0.6
  },
  // Use these as the `ease` value inside a `transition` object:
  // transition={{ duration: motionTokens.duration.normal, ease: motionTokens.easing.smooth }}
  easing: {
    smooth: [0.22, 1, 0.36, 1] as [number, number, number, number],
    sharp:  [0.4,  0, 0.2, 1] as [number, number, number, number]
  },
  distance: {
    sm: 8,
    md: 16,
    lg: 24
  }
}
```

使用例:

```tsx
import { motionTokens } from "@/lib/motionTokens"

<motion.div
  initial={{ opacity: 0, y: motionTokens.distance.md }}
  animate={{ opacity: 1, y: 0 }}
  transition={{
    duration: motionTokens.duration.normal,
    ease: motionTokens.easing.smooth
  }}
/>
```

---

### パフォーマンスルール

**安全**

* transform
* opacity

**避ける**

* width / height
* top / left

ルール: レスポンシブネス > スムーズネス

---

### デバイス適応

ヒューリスティックは、より信頼性の高いシグナルのために CPU コア数**と**利用可能メモリを組み合わせる。`deviceMemory` は Chrome/Android で利用可能。フォールバックは Safari と Firefox をカバーする。

```ts
const isLowEnd =
  typeof navigator !== "undefined" && (
    // Low memory (Chrome/Android only; undefined elsewhere → treat as capable)
    (navigator.deviceMemory !== undefined && navigator.deviceMemory <= 2) ||
    // Few cores AND no memory API (covers Safari/Firefox on weak hardware)
    (navigator.deviceMemory === undefined && navigator.hardwareConcurrency <= 4)
  )

const duration = isLowEnd ? 0.2 : 0.4
```

---

### アクセシビリティ

#### JS (useReducedMotion)

```tsx
import { motion, useReducedMotion } from "motion/react"

export function FadeIn() {
  const reduce = useReducedMotion()

  return (
    <motion.div
      initial={{ opacity: 0, y: reduce ? 0 : 24 }}
      animate={{ opacity: 1, y: 0 }}
    />
  )
}
```

#### CSS

```css
@media (prefers-reduced-motion: reduce) {
  .motion-safe-transition {
    transition: opacity 0.2s;
  }

  .motion-reduce-transform {
    transform: none !important;
  }
}
```

#### Tailwind

```html
<div class="motion-safe:animate-fade motion-reduce:opacity-100"></div>
```

---

### アーキテクチャとパターン

#### コアパターン

| シナリオ | パターン |
|---|---|
| ホバーフィードバック | `whileHover` |
| タップ / プレスフィードバック | `whileTap` |
| スクロールでリビール | `whileInView` |
| スクロール連動値 | `useScroll` + `useTransform` |
| 条件付きマウント/アンマウント | `AnimatePresence` |
| 小さなレイアウトシフト (単一要素、~300px 未満の変化) | `layout` プロップ |
| 大きなレイアウトシフトまたはフルページリフロー | `layout` を避け、代わりに CSS トランジションまたはページレベルルーティングを使用 |
| 複雑で命令的なシーケンス | `useAnimate` |

> **大きなコンテナで `layout` を避ける理由?** Framer のレイアウトアニメーションは位置を調整するために `transform` を使うが、全ビューポートにまたがる要素や深いリフローをトリガーする要素では、測定コストが目に見えるジャンクと CLS を引き起こす。CSS Grid/Flexbox トランジションを優先し、特定の子要素のみで `layoutId` と協調する

#### レイアウトとトランジション

* 共有要素トランジション → `layoutId` (マウントされたインスタンスごとに一意である必要がある)
* 入場 / 退場トランジション → `AnimatePresence` (以下の `mode` ガイダンスを参照)

#### AnimatePresence `mode`

常に `mode` を明示的に指定する — デフォルト (`"sync"`) は入場と退場を同時に実行し、ほとんどの UI パターンで視覚的重複を引き起こす。

| `mode` | 使用ケース |
|---|---|
| `"wait"` | 入場開始前に退場が完了する。**モーダル、トースト、ページトランジション**に使用 |
| `"sync"` (デフォルト) | 入場と退場が重複する。重複が意図的な場合のみ使用 (例: クロスフェードカルーセル) |
| `"popLayout"` | 退場要素はすぐにフローからポップアウトされ、残りのアイテムは埋めるためにアニメーション化される。**リスト、タブ、ディスミス可能カード**に使用 |

```tsx
// Modal — always use "wait"
<AnimatePresence mode="wait">
  {open && <Modal key="modal" />}
</AnimatePresence>

// Dismissible list item — use "popLayout"
<AnimatePresence mode="popLayout">
  {items.map(item => <Card key={item.id} />)}
</AnimatePresence>
```

---

### 高度なパターン (概念)

* パララックス (スクロール連動 transform)
* スクロールストーリーテリング (粘着セクション)
* 3D ティルト (ポインタベース transform)
* クロスフェード (共有 `layoutId`)
* プログレッシブリビール (clip-path)
* スケルトンローディング (ループ opacity)
* マイクロインタラクション (ホバー/タップフィードバック)
* スプリングシステム (物理ベースモーション)

---

### モーダルの必須事項

* フォーカストラップ
* Escape クローズ
* スクロールロック
* ARIA ロール
* 次のモーダルが入場する前に退場アニメーションが完了するよう `AnimatePresence mode="wait"` を使用

#### 完全な例

```tsx
import React, { useEffect, useRef, useState } from "react"
import { motion, AnimatePresence } from "motion/react"

function useFocusTrap(ref: React.RefObject<HTMLDivElement | null>, active: boolean) {
  useEffect(() => {
    if (!active || !ref.current) return
    const el = ref.current
    const focusable = el.querySelectorAll<HTMLElement>(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    const first = focusable[0]
    const last  = focusable[focusable.length - 1]

    function handleKey(e: KeyboardEvent) {
      if (e.key !== "Tab") return
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault()
        last?.focus()
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault()
        first?.focus()
      }
    }

    el.addEventListener("keydown", handleKey)
    first?.focus()
    return () => el.removeEventListener("keydown", handleKey)
  }, [active, ref])
}

function useScrollLock(active: boolean) {
  useEffect(() => {
    if (!active) return
    const prev = document.body.style.overflow
    document.body.style.overflow = "hidden"
    return () => { document.body.style.overflow = prev }
  }, [active])
}

function Modal({ open, closeModal }: { open: boolean; closeModal: () => void }) {
  const ref = useRef<HTMLDivElement>(null)

  useFocusTrap(ref, open)
  useScrollLock(open)

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") closeModal()
    }
    if (open) window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [open, closeModal])

  return (
    // mode="wait" ensures exit animation finishes before any new modal enters
    <AnimatePresence mode="wait">
      {open && (
        <motion.div
          role="dialog"
          aria-modal="true"
          aria-labelledby="modal-title"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="fixed inset-0 flex items-center justify-center bg-black/40"
        >
          <motion.div
            ref={ref}
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1,    opacity: 1 }}
            exit={{    scale: 0.95, opacity: 0 }}
            transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
            className="bg-white p-6 rounded"
          >
            <h2 id="modal-title">Dialog Title</h2>
            <button onClick={closeModal}>Close</button>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

export function Example() {
  const [open, setOpen] = useState(false)

  return (
    <>
      <button onClick={() => setOpen(true)}>Open</button>
      <Modal open={open} closeModal={() => setOpen(false)} />
    </>
  )
}
```

---

### SSR 安全性

* サーバーとクライアントレンダー間で初期状態を一致させる
* 暗黙的なアニメーション起源を避ける (常に `initial` を明示的に設定)
* Next.js App Router ではモーションコンポーネントを `"use client"` でラップする

---

### デバッグ

確認:

* 誤ったインポート (`motion/react` と `framer-motion` の混在)
* Next.js App Router での `"use client"` ディレクティブの欠落
* `AnimatePresence` 子の `key` プロップの欠落
* ハイドレーション不一致 (SSR とクライアント間で初期状態が異なる)
* 大きなコンテナでの `layout` プロップの誤用がリフロージャンクを引き起こす
* 状態駆動アニメーションがトリガーされない (依存配列を確認)

---

### QA

* CLS なし
* キーボード動作
* モーダル内でフォーカストラップ
* ARIA ロールが正しい (`role="dialog"`、`aria-modal="true"`)
* リデュースドモーションが尊重される (`useReducedMotion` + CSS メディアクエリ)
* Next.js でハイドレーション警告なし
* アンマウント時にアニメーションがクリーンに停止する (メモリリークなし)
* すべての使用サイトで `AnimatePresence mode` が明示的に設定される

---

### アンチパターン

* レイアウトプロパティのアニメーション化 (`width`、`height`、`top`、`left`)
* 目的のない無限アニメーション (常に問う: これは何の状態を伝えるか?)
* リストのスタッガーしすぎ (`staggerChildren` を ≤ 0.1s に保つ。それ以上は遅く感じる)
* リデュースドモーション設定の無視
* 大きなまたは全ビューポートコンテナでの `layout` の使用
* `AnimatePresence` での `mode` の省略 (デフォルトの `"sync"` は視覚的重複を引き起こす)
* 純粋に装飾のためにモーションを使用

---

### 哲学

モーションはインタラクションデザインである。

---

### 最終ルール

> モーションが UX を改善しない場合 → 削除する。

---

## 例

### ボタンインタラクション

```tsx
import { motion } from "motion/react"

export function Button() {
  return (
    <motion.button
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.97 }}
      transition={{ duration: 0.15, ease: [0.4, 0, 0.2, 1] }}
    >
      Click me
    </motion.button>
  )
}
```

---

### リデュースドモーションの例

```tsx
import { motion, useReducedMotion } from "motion/react"

export function FadeIn() {
  const reduce = useReducedMotion()

  return (
    <motion.div
      initial={{ opacity: 0, y: reduce ? 0 : 24 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: reduce ? 0.1 : 0.35, ease: [0.22, 1, 0.36, 1] }}
    />
  )
}
```

---

### スタッガーリスト

```tsx
import { motion } from "motion/react"

const container = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.08 } // keep ≤ 0.1s to avoid sluggishness
  }
}

const item = {
  hidden:  { opacity: 0, y: 10 },
  visible: { opacity: 1, y: 0,  transition: { duration: 0.3, ease: [0.22, 1, 0.36, 1] } }
}

export function List() {
  return (
    <motion.ul variants={container} initial="hidden" animate="visible">
      {[1, 2, 3].map(i => (
        <motion.li key={i} variants={item}>Item {i}</motion.li>
      ))}
    </motion.ul>
  )
}
```

---

### AnimatePresence 付きモーダル

```tsx
import { motion, AnimatePresence } from "motion/react"

export function Modal({ open }: { open: boolean }) {
  return (
    <AnimatePresence mode="wait">
      {open && (
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1    }}
          exit={{    opacity: 0, scale: 0.95 }}
          transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
        />
      )}
    </AnimatePresence>
  )
}
```

---

### スクロールパララックス

```tsx
import { useScroll, useTransform, motion } from "motion/react"

export function Parallax() {
  const { scrollYProgress } = useScroll()
  const y = useTransform(scrollYProgress, [0, 1], [0, -80])

  return <motion.div style={{ y }} />
}
```

---

### スケルトンローディング

```tsx
import { motion } from "motion/react"

export function Skeleton() {
  return (
    <motion.div
      className="bg-gray-200 h-6 w-full rounded"
      animate={{ opacity: [0.5, 1, 0.5] }}
      transition={{
        duration: 1.5,       // comfortable pulse — was missing, caused fast flash
        repeat: Infinity,
        ease: "easeInOut"
      }}
    />
  )
}
```

---

### 共有レイアウト (クロスフェード)

```tsx
import { motion } from "motion/react"

// layoutId must be unique per mounted instance.
// If multiple instances can exist simultaneously, append a unique id:
// layoutId={`shared-${item.id}`}
export function Shared() {
  return <motion.div layoutId="shared" />
}
```

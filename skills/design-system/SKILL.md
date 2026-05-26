---
name: design-system
description: デザインシステムの生成・監査、ビジュアル一貫性のチェック、スタイル変更を含む PR のレビューに用いる（design system, visual audit, styling PR review）。
origin: ECC
---

# デザインシステム — ビジュアルシステムの生成・監査

## 利用タイミング

- デザインシステムが必要な新規プロジェクト立ち上げ
- 既存コードベースのビジュアル一貫性監査
- リデザイン前 — 現状把握
- UI が「なんとなくおかしい」が原因が特定できない場合
- スタイル変更を伴う PR のレビュー

## 仕組み

### Mode 1: デザインシステム生成

コードベースを解析して凝集したデザインシステムを生成する。

```
1. Scan CSS/Tailwind/styled-components for existing patterns
2. Extract: colors, typography, spacing, border-radius, shadows, breakpoints
3. Research 3 competitor sites for inspiration (via browser MCP)
4. Propose a design token set (JSON + CSS custom properties)
5. Generate DESIGN.md with rationale for each decision
6. Create an interactive HTML preview page (self-contained, no deps)
```

出力: `DESIGN.md` + `design-tokens.json` + `design-preview.html`

### Mode 2: ビジュアル監査

10次元で UI をスコアリングする（各0〜10点）。

```
1. Color consistency — are you using your palette or random hex values?
2. Typography hierarchy — clear h1 > h2 > h3 > body > caption?
3. Spacing rhythm — consistent scale (4px/8px/16px) or arbitrary?
4. Component consistency — do similar elements look similar?
5. Responsive behavior — fluid or broken at breakpoints?
6. Dark mode — complete or half-done?
7. Animation — purposeful or gratuitous?
8. Accessibility — contrast ratios, focus states, touch targets
9. Information density — cluttered or clean?
10. Polish — hover states, transitions, loading states, empty states
```

各次元はスコア・具体例・正確な file:line 付き修正案を伴う。

### Mode 3: AI Slop 検出

汎用 AI 生成デザインパターンを特定する。

```
- Gratuitous gradients on everything
- Purple-to-blue defaults
- "Glass morphism" cards with no purpose
- Rounded corners on things that shouldn't be rounded
- Excessive animations on scroll
- Generic hero with centered text over stock gradient
- Sans-serif font stack with no personality
```

## 例

**SaaS アプリ向けに生成:**
```
/design-system generate --style minimal --palette earth-tones
```

**既存 UI を監査:**
```
/design-system audit --url http://localhost:3000 --pages / /pricing /docs
```

**AI slop チェック:**
```
/design-system slop-check
```

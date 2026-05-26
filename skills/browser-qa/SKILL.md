---
name: browser-qa
description: 機能デプロイ後にブラウザ自動化を用いてビジュアルテストと UI インタラクション検証を自動化するスキル (browser QA, visual testing, UI interaction, Playwright, Puppeteer, claude-in-chrome, accessibility)。
origin: ECC
---

# Browser QA — 自動ビジュアルテストとインタラクション

## 利用するタイミング

- ステージング/プレビューに機能をデプロイした後
- ページ全体での UI 挙動を検証する必要があるとき
- リリース前 — レイアウト、フォーム、インタラクションが実際に動作することを確認
- フロントエンドコードに触れる PR をレビューするとき
- アクセシビリティ監査とレスポンシブテスト

## 仕組み

ブラウザ自動化 MCP (claude-in-chrome、Playwright、または Puppeteer) を使って実ユーザーのようにライブページとインタラクションする。

### Phase 1: スモークテスト
```
1. Navigate to target URL
2. Check for console errors (filter noise: analytics, third-party)
3. Verify no 4xx/5xx in network requests
4. Screenshot above-the-fold on desktop + mobile viewport
5. Check Core Web Vitals: LCP < 2.5s, CLS < 0.1, INP < 200ms
```

### Phase 2: インタラクションテスト
```
1. Click every nav link — verify no dead links
2. Submit forms with valid data — verify success state
3. Submit forms with invalid data — verify error state
4. Test auth flow: login → protected page → logout
5. Test critical user journeys (checkout, onboarding, search)
```

### Phase 3: ビジュアル回帰
```
1. Screenshot key pages at 3 breakpoints (375px, 768px, 1440px)
2. Compare against baseline screenshots (if stored)
3. Flag layout shifts > 5px, missing elements, overflow
4. Check dark mode if applicable
```

### Phase 4: アクセシビリティ
```
1. Run axe-core or equivalent on each page
2. Flag WCAG AA violations (contrast, labels, focus order)
3. Verify keyboard navigation works end-to-end
4. Check screen reader landmarks
```

## 出力フォーマット

```markdown
## QA Report — [URL] — [timestamp]

### Smoke Test
- Console errors: 0 critical, 2 warnings (analytics noise)
- Network: all 200/304, no failures
- Core Web Vitals: LCP 1.2s ✓, CLS 0.02 ✓, INP 89ms ✓

### Interactions
- [✓] Nav links: 12/12 working
- [✗] Contact form: missing error state for invalid email
- [✓] Auth flow: login/logout working

### Visual
- [✗] Hero section overflows on 375px viewport
- [✓] Dark mode: all pages consistent

### Accessibility
- 2 AA violations: missing alt text on hero image, low contrast on footer links

### Verdict: SHIP WITH FIXES (2 issues, 0 blockers)
```

## 統合

任意のブラウザ MCP と動作する:
- `mChild__claude-in-chrome__*` ツール (推奨 — 実際の Chrome を使用)
- `mcp__browserbase__*` を介した Playwright
- 直接 Puppeteer スクリプト

デプロイ後モニタリングのために `/canary-watch` と組み合わせる。

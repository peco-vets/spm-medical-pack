---
name: benchmark
description: パフォーマンスベースラインの測定、PR の前後での回帰検出、スタック代替案の比較に使用するスキル (benchmark, performance, baseline, regression, Core Web Vitals, API latency, build time)。
origin: ECC
---

# Benchmark — パフォーマンスベースラインと回帰検出

## 利用するタイミング

- PR の前後でパフォーマンス影響を測定する
- プロジェクトのパフォーマンスベースラインをセットアップする
- ユーザーが「遅く感じる」と報告する
- ローンチ前 — パフォーマンス目標を満たすことを確認する
- スタックを代替案と比較する

## 仕組み

### Mode 1: ページパフォーマンス

ブラウザ MCP 経由で実際のブラウザメトリクスを測定する:

```
1. Navigate to each target URL
2. Measure Core Web Vitals:
   - LCP (Largest Contentful Paint) — target < 2.5s
   - CLS (Cumulative Layout Shift) — target < 0.1
   - INP (Interaction to Next Paint) — target < 200ms
   - FCP (First Contentful Paint) — target < 1.8s
   - TTFB (Time to First Byte) — target < 800ms
3. Measure resource sizes:
   - Total page weight (target < 1MB)
   - JS bundle size (target < 200KB gzipped)
   - CSS size
   - Image weight
   - Third-party script weight
4. Count network requests
5. Check for render-blocking resources
```

### Mode 2: API パフォーマンス

API エンドポイントをベンチマークする:

```
1. Hit each endpoint 100 times
2. Measure: p50, p95, p99 latency
3. Track: response size, status codes
4. Test under load: 10 concurrent requests
5. Compare against SLA targets
```

### Mode 3: ビルドパフォーマンス

開発フィードバックループを測定する:

```
1. Cold build time
2. Hot reload time (HMR)
3. Test suite duration
4. TypeScript check time
5. Lint time
6. Docker build time
```

### Mode 4: Before/After 比較

変更前後で影響を測定するために実行する:

```
/benchmark baseline    # saves current metrics
# ... make changes ...
/benchmark compare     # compares against baseline
```

出力:
```
| Metric | Before | After | Delta | Verdict |
|--------|--------|-------|-------|---------|
| LCP | 1.2s | 1.4s | +200ms | WARNING: WARN |
| Bundle | 180KB | 175KB | -5KB | ✓ BETTER |
| Build | 12s | 14s | +2s | WARNING: WARN |
```

## 出力

`.ecc/benchmarks/` に JSON としてベースラインを保存する。Git 管理されチームがベースラインを共有する。

## 統合

- CI: すべての PR で `/benchmark compare` を実行
- デプロイ後モニタリングのために `/canary-watch` と組み合わせ
- フルプリシップチェックリストのために `/browser-qa` と組み合わせ

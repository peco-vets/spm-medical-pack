---
name: canary-watch
description: リリース後にデプロイ済み URL を監視・検証するスキル — HTTP エンドポイント、SSE ストリーム、静的アセット、コンソールエラー、デプロイ・マージ・依存関係アップグレード後のパフォーマンス回帰をチェックする。スモーク / カナリア / デプロイ後検証 (canary watch, post-deploy, smoke test, monitoring, HTTP, SSE, performance regression)。
origin: ECC
---

# Canary Watch — デプロイ後モニタリング

## 利用するタイミング

- 本番またはステージングへのデプロイ後
- リスクのある PR をマージした後
- 修正が実際に効いたか検証したいとき
- ローンチウィンドウ中の継続的モニタリング
- 依存関係アップグレード後

## 仕組み

デプロイ済み URL の回帰を監視する。停止されるかウォッチウィンドウが切れるまでループで実行される。

### 監視内容

```
1. HTTP Status — is the page returning 200?
2. Console Errors — new errors that weren't there before?
3. Network Failures — failed API calls, 5xx responses?
4. Performance — LCP/CLS/INP regression vs baseline?
5. Content — did key elements disappear? (h1, nav, footer, CTA)
6. API Health — are critical endpoints responding within SLA?
7. Static Assets — are JS, CSS, image, and font requests returning 2xx/3xx with expected content types?
8. SSE Streams — do event-stream endpoints connect and receive an initial event or heartbeat?
```

### 監視モード

**クイックチェック** (デフォルト): 1 回パス、結果報告
```
/canary-watch https://myapp.com
```

**継続的監視**: N 分ごとに M 時間チェック
```
/canary-watch https://myapp.com --interval 5m --duration 2h
```

**差分モード**: ステージング vs 本番を比較
```
/canary-watch --compare https://staging.myapp.com https://myapp.com
```

### アラートしきい値

```yaml
critical:  # immediate alert
  - HTTP status != 200
  - Console error count > 5 (new errors only)
  - LCP > 4s
  - API endpoint returns 5xx
  - Static asset returns 4xx/5xx
  - SSE endpoint cannot connect or drops before first heartbeat

warning:   # flag in report
  - LCP increased > 500ms from baseline
  - CLS > 0.1
  - New console warnings
  - Response time > 2x baseline
  - Static asset content type changed unexpectedly
  - SSE heartbeat latency > 2x baseline

info:      # log only
  - Minor performance variance
  - New network requests (third-party scripts added?)
```

### 通知

critical しきい値を超えたとき:
- デスクトップ通知 (macOS/Linux)
- オプション: Slack/Discord webhook
- `~/.claude/canary-watch.log` にログ

## 出力

```markdown
## Canary Report — myapp.com — 2026-03-23 03:15 PST

### Status: HEALTHY ✓

| Check | Result | Baseline | Delta |
|-------|--------|----------|-------|
| HTTP | 200 ✓ | 200 | — |
| Console errors | 0 ✓ | 0 | — |
| LCP | 1.8s ✓ | 1.6s | +200ms |
| CLS | 0.01 ✓ | 0.01 | — |
| API /health | 145ms ✓ | 120ms | +25ms |
| Static assets | 42/42 ✓ | 42/42 | — |
| SSE /events | connected ✓ | connected | +80ms heartbeat |

### No regressions detected. Deploy is clean.
```

## 統合

以下と組み合わせる:
- デプロイ前検証用に `/browser-qa`
- フック: `git push` の PostToolUse フックとして追加してデプロイ後自動チェック
- CI: デプロイステップ後の GitHub Actions で実行

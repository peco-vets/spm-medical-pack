---
name: product-lens
description: 構築前に「なぜ」を検証し、製品診断を実行し、依頼が実装契約になる前に製品方向性をプレッシャーテストするためにこのスキルを使う (Validate the "why" before building, run product diagnostics, pressure-test product direction before request becomes implementation contract)。
origin: ECC
---

# Product Lens — 構築前に考える

このレーンは製品診断を所有し、実装準備済み仕様の記述は所有しない。

ユーザーが永続的な PRD-to-SRS や機能契約アーティファクトを必要とする場合は、`product-capability` にハンドオフする。

## 使用するタイミング

- 任意の機能を開始する前 — 「なぜ」を検証
- 毎週の製品レビュー — 正しいものを構築しているか?
- 機能の選択に詰まったとき
- ローンチ前 — ユーザージャーニーの正気チェック
- エンジニアリング計画開始前に曖昧なアイデアを製品ブリーフに変換するとき

## 動作の仕組み

### モード 1: 製品診断

YC オフィスアワーのようだが自動化されている。難しい質問を尋ねる:

```
1. Who is this for? (specific person, not "developers")
2. What's the pain? (quantify: how often, how bad, what do they do today?)
3. Why now? (what changed that makes this possible/necessary?)
4. What's the 10-star version? (if money/time were unlimited)
5. What's the MVP? (smallest thing that proves the thesis)
6. What's the anti-goal? (what are you explicitly NOT building?)
7. How do you know it's working? (metric, not vibes)
```

出力: 回答、リスク、go/no-go 推奨を含む `PRODUCT-BRIEF.md`

結果が「はい、これを構築する」の場合、次のレーンはより多くの創業者シアターではなく `product-capability` である。

### モード 2: 創業者レビュー

現在のプロジェクトを創業者レンズでレビューする:

```
1. Read README, CLAUDE.md, package.json, recent commits
2. Infer: what is this trying to be?
3. Score: product-market fit signals (0-10)
   - Usage growth trajectory
   - Retention indicators (repeat contributors, return users)
   - Revenue signals (pricing page, billing code, Stripe integration)
   - Competitive moat (what's hard to copy?)
4. Identify: the one thing that would 10x this
5. Flag: things you're building that don't matter
```

### モード 3: ユーザージャーニー監査

実際のユーザー体験をマップ:

```
1. Clone/install the product as a new user
2. Document every friction point (confusing steps, errors, missing docs)
3. Time each step
4. Compare to competitor onboarding
5. Score: time-to-value (how long until the user gets their first win?)
6. Recommend: top 3 fixes for onboarding
```

### モード 4: 機能優先順位付け

10 のアイデアがあり 2 つを選ぶ必要があるとき:

```
1. List all candidate features
2. Score each on: impact (1-5) × confidence (1-5) ÷ effort (1-5)
3. Rank by ICE score
4. Apply constraints: runway, team size, dependencies
5. Output: prioritized roadmap with rationale
```

## 出力

すべてのモードはエッセイではなく実行可能なドキュメントを出力する。すべての推奨事項には具体的な次のステップがある。

## 統合

ペア:
- ユーザージャーニー監査の知見を検証するための `/browser-qa`
- 視覚的洗練評価のための `/design-system audit`
- ローンチ後モニタリングのための `/canary-watch`
- 製品ブリーフが実装準備済み機能計画になる必要があるときの `product-capability`

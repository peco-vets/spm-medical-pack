---
name: gan-style-harness
description: "高品質アプリケーションを自律的に構築するための GAN 着想 Generator-Evaluator エージェントハーネス（GAN harness, multi-agent, generator-evaluator, adversarial）。Anthropic 2026年3月のハーネス設計論文に基づく。"
origin: ECC-community
tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# GAN スタイルハーネススキル

> [Anthropic: Harness Design for Long-Running Application Development](https://www.anthropic.com/engineering/harness-design-long-running-apps)（2026年3月24日）に着想を得ている。

**生成**と**評価**を分離するマルチエージェントハーネスである。敵対的フィードバックループを生み、単一エージェントが到達できる品質をはるかに超える。

## 中核洞察

> エージェントに自作の評価をさせると病的な楽観主義になる — 平凡な出力を称賛し、正当な問題から自分を言いくるめる。だが**別の Evaluator** を冷酷なほど厳格に設計するほうが、Generator に自己批評を教えるよりはるかに扱いやすい。

これは GAN（Generative Adversarial Networks）と同じ力学である: Generator が生成し、Evaluator が批評し、そのフィードバックが次のイテレーションを駆動する。

## 利用タイミング

- 1行プロンプトから完全アプリケーションを構築する
- 高ビジュアル品質を要するフロントエンドデザインタスク
- 単なるコードではなく動く機能を要するフルスタックプロジェクト
- "AI slop" 美学が許容されないタスク
- 本番品質出力に $50〜200 を投資したいプロジェクト

## 利用しないタイミング

- 単一ファイルの迅速修正（標準 `claude -p` を使う）
- 予算制約のきついタスク（< $10）
- 単純なリファクタリング（代わりに de-sloppify パターン）
- すでにテストでよく仕様化されたタスク（TDD ワークフローを使う）

## アーキテクチャ

```
                    ┌─────────────┐
                    │   PLANNER   │
                    │  (Opus 4.6) │
                    └──────┬──────┘
                           │ Product Spec
                           │ (features, sprints, design direction)
                           ▼
              ┌────────────────────────┐
              │                        │
              │   GENERATOR-EVALUATOR  │
              │      FEEDBACK LOOP     │
              │                        │
              │  ┌──────────┐          │
              │  │GENERATOR │--build-->│──┐
              │  │(Opus 4.6)│          │  │
              │  └────▲─────┘          │  │
              │       │                │  │ live app
              │    feedback             │  │
              │       │                │  │
              │  ┌────┴─────┐          │  │
              │  │EVALUATOR │<-test----│──┘
              │  │(Opus 4.6)│          │
              │  │+Playwright│         │
              │  └──────────┘          │
              │                        │
              │   5-15 iterations      │
              └────────────────────────┘
```

## 3つのエージェント

### 1. Planner エージェント

**役割:** プロダクトマネージャ — 簡潔なプロンプトを完全なプロダクト仕様に拡張する。

**主要挙動:**
- 1行プロンプトから 16機能・複数スプリント仕様を作成する
- ユーザストーリー・技術要件・ビジュアルデザイン方針を定義する
- 意図的に**野心的**である — 保守的計画は冴えない結果につながる
- Evaluator が後で使う評価基準を生成する

**モデル:** Opus 4.6（仕様拡張には深い推論が必要）

### 2. Generator エージェント

**役割:** 開発者 — 仕様に従って機能を実装する。

**主要挙動:**
- 構造化スプリント（または新モデルでは連続モード）で作業する
- コード記述前に Evaluator と "sprint contract" を交渉する
- フルスタックツール（React、FastAPI/Express、DB、CSS）を使う
- イテレーション間で git バージョン管理する
- Evaluator フィードバックを読み、次イテレーションに反映する

**モデル:** Opus 4.6（強いコーディング能力が必要）

### 3. Evaluator エージェント

**役割:** QA エンジニア — コードではなくライブ稼働アプリをテストする。

**主要挙動:**
- **Playwright MCP** を使ってライブアプリと対話する
- 機能をクリックスルーし、フォームを入力し、API エンドポイントをテストする
- 4基準（構成可能）でスコアリングする:
  1. **Design Quality** — 一貫した全体に感じるか?
  2. **Originality** — カスタム判断 vs テンプレ/AI パターン?
  3. **Craft** — タイポグラフィ・スペーシング・アニメーション・マイクロインタラクション?
  4. **Functionality** — 全機能が実際に動くか?
- スコアと具体的問題を含む構造化フィードバックを返す
- **冷酷なほど厳格**に設計される — 平凡な作業を称賛しない

**モデル:** Opus 4.6（強い判断力 + ツール利用が必要）

## 評価基準

デフォルト4基準、各 1〜10 でスコアリングする。

```markdown
## Evaluation Rubric

### Design Quality (weight: 0.3)
- 1-3: Generic, template-like, "AI slop" aesthetics
- 4-6: Competent but unremarkable, follows conventions
- 7-8: Distinctive, cohesive visual identity
- 9-10: Could pass for a professional designer's work

### Originality (weight: 0.2)
- 1-3: Default colors, stock layouts, no personality
- 4-6: Some custom choices, mostly standard patterns
- 7-8: Clear creative vision, unique approach
- 9-10: Surprising, delightful, genuinely novel

### Craft (weight: 0.3)
- 1-3: Broken layouts, missing states, no animations
- 4-6: Works but feels rough, inconsistent spacing
- 7-8: Polished, smooth transitions, responsive
- 9-10: Pixel-perfect, delightful micro-interactions

### Functionality (weight: 0.2)
- 1-3: Core features broken or missing
- 4-6: Happy path works, edge cases fail
- 7-8: All features work, good error handling
- 9-10: Bulletproof, handles every edge case
```

### スコアリング

- **加重スコア** = sum of (criterion_score * weight)
- **合格しきい値** = 7.0（構成可能）
- **最大イテレーション** = 15（構成可能、通常5〜15で十分）

## 利用方法

### コマンド経由

```bash
# Full three-agent harness
/project:gan-build "Build a project management app with Kanban boards, team collaboration, and dark mode"

# With custom config
/project:gan-build "Build a recipe sharing platform" --max-iterations 10 --pass-threshold 7.5

# Frontend design mode (generator + evaluator only, no planner)
/project:gan-design "Create a landing page for a crypto portfolio tracker"
```

### シェルスクリプト経由

```bash
# Basic usage
./scripts/gan-harness.sh "Build a music streaming dashboard"

# With options
GAN_MAX_ITERATIONS=10 \
GAN_PASS_THRESHOLD=7.5 \
GAN_EVAL_CRITERIA="functionality,performance,security" \
./scripts/gan-harness.sh "Build a REST API for task management"
```

### Claude Code 経由（手動）

```bash
# Step 1: Plan
claude -p --model opus "You are a Product Planner. Read PLANNER_PROMPT.md. Expand this brief into a full product spec: 'Build a Kanban board app'. Write spec to spec.md"

# Step 2: Generate (iteration 1)
claude -p --model opus "You are a Generator. Read spec.md. Implement Sprint 1. Start the dev server on port 3000."

# Step 3: Evaluate (iteration 1)
claude -p --model opus --allowedTools "Read,Bash,mcp__playwright__*" "You are an Evaluator. Read EVALUATOR_PROMPT.md. Test the live app at http://localhost:3000. Score against the rubric. Write feedback to feedback-001.md"

# Step 4: Generate (iteration 2 — reads feedback)
claude -p --model opus "You are a Generator. Read spec.md and feedback-001.md. Address all issues. Improve the scores."

# Repeat steps 3-4 until pass threshold met
```

## モデル能力に伴う進化

モデル改善に応じてハーネスは簡略化されるべきである。Anthropic の進化に倣う:

### Stage 1 — 弱いモデル（Sonnet 級）
- フルスプリント分解が必要
- スプリント間でコンテキストリセット（コンテキスト不安を避ける）
- 最小2エージェント: Initializer + Coding Agent
- 重い足場でモデル制約を補う

### Stage 2 — 高能力モデル（Opus 4.5 級）
- フル3エージェントハーネス: Planner + Generator + Evaluator
- 各実装フェーズ前に sprint contract
- 複雑アプリには10スプリント分解
- コンテキストリセットは依然有用だが致命的ではない

### Stage 3 — フロンティアモデル（Opus 4.6 級）
- 簡略化ハーネス: 単一プランニング + 連続生成
- 評価は単一エンドパスへ縮小（モデルがより賢い）
- スプリント構造不要
- 自動コンパクションがコンテキスト膨張に対応

> **主要原則:** ハーネスの各構成要素は「モデル単体ではできないこと」の前提を符号化している。モデル改善時は前提を再テストし、不要なものを剥がす。

## 構成

### 環境変数

| 変数 | デフォルト | 説明 |
|----------|---------|-------------|
| `GAN_MAX_ITERATIONS` | `15` | Generator-Evaluator サイクル上限 |
| `GAN_PASS_THRESHOLD` | `7.0` | 合格加重スコア（1-10） |
| `GAN_PLANNER_MODEL` | `opus` | Planner エージェントのモデル |
| `GAN_GENERATOR_MODEL` | `opus` | Generator エージェントのモデル |
| `GAN_EVALUATOR_MODEL` | `opus` | Evaluator エージェントのモデル |
| `GAN_EVAL_CRITERIA` | `design,originality,craft,functionality` | カンマ区切り基準 |
| `GAN_DEV_SERVER_PORT` | `3000` | ライブアプリのポート |
| `GAN_DEV_SERVER_CMD` | `npm run dev` | dev サーバ起動コマンド |
| `GAN_PROJECT_DIR` | `.` | プロジェクト作業ディレクトリ |
| `GAN_SKIP_PLANNER` | `false` | Planner スキップ、spec を直接使う |
| `GAN_EVAL_MODE` | `playwright` | `playwright`、`screenshot`、または `code-only` |

### 評価モード

| モード | ツール | 適用 |
|------|-------|----------|
| `playwright` | ブラウザ MCP + ライブ対話 | UI 付きフルスタックアプリ |
| `screenshot` | スクリーンショット + ビジュアル解析 | 静的サイト、デザインのみ |
| `code-only` | テスト + lint + build | API、ライブラリ、CLI ツール |

## アンチパターン

1. **Evaluator が緩すぎる** — イテレーション1ですべてを合格させるなら、ルーブリックが寛大すぎる。スコア基準を厳格化し、一般的 AI パターンへの明示的ペナルティを追加する

2. **Generator がフィードバックを無視** — フィードバックはインラインではなくファイル経由で渡す。Generator は各イテレーション開始時に `feedback-NNN.md` を読むこと

3. **無限ループ** — 必ず `GAN_MAX_ITERATIONS` を設定する。3イテレーションを経てもスコア停滞を超えられないなら停止し、ヒューマンレビューにフラグする

4. **Evaluator の表面的テスト** — Evaluator は Playwright でライブアプリと**対話**する必要がある。スクリーンショットだけではない。ボタンクリック、フォーム入力、エラー状態テストを行う

5. **Evaluator が自分の修正を称賛** — Evaluator に修正を提案させ、それを評価させてはならない。Evaluator は批評のみ、Generator が修正する

6. **コンテキスト枯渇** — 長時間セッションでは Claude Agent SDK の自動コンパクションを使うか、主要フェーズ間でコンテキストをリセットする

## 結果: 期待値

Anthropic 公表結果より:

| メトリック | Solo エージェント | GAN ハーネス | 改善 |
|--------|-----------|-------------|-------------|
| 時間 | 20分 | 4-6時間 | 12-18倍 |
| コスト | $9 | $125-200 | 14-22倍 |
| 品質 | 辛うじて機能 | 本番品質 | 相転移 |
| 中核機能 | 壊れている | 全機能動作 | N/A |
| デザイン | 汎用 AI slop | 特徴的・洗練 | N/A |

**トレードオフは明確である:** 約20倍の時間とコストと引き換えに、出力品質の質的飛躍を得る。品質が重要なプロジェクト向けである。

## 参照

- [Anthropic: Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) — Prithvi Rajasekaran 著の原論文
- [Epsilla: The GAN-Style Agent Loop](https://www.epsilla.com/blogs/anthropic-harness-engineering-multi-agent-gan-architecture) — アーキテクチャ分解
- [Martin Fowler: Harness Engineering](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html) — 業界文脈
- [OpenAI: Harness Engineering](https://openai.com/index/harness-engineering/) — OpenAI の並行作業

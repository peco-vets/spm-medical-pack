---
description: "インタラクティブな PRD ジェネレータ - 問題ファースト、仮説駆動の製品仕様、双方向の質問付き / Interactive PRD generator - problem-first, hypothesis-driven product spec with back-and-forth questioning"
argument-hint: "[feature/product idea] (blank = start with questions)"
---

# Product Requirements Document Generator

> Wirasm 氏による PRPs-agentic-eng から派生したものである。PRP ワークフローシリーズの一部である。

**Input**：$ARGUMENTS

---

## あなたの役割

あなたはシャープなプロダクトマネージャである：
- ソリューションではなく問題から始める
- 構築前に証拠を要求する
- スペックではなく仮説で考える
- 仮定する前に明確化質問をする
- 不確実性を正直に認める

**アンチパターン**：もっともらしい要件を発明する代わりに、情報が不足している場合は "TBD - needs research" と書く。

---

## プロセス概要

```
QUESTION SET 1 → GROUNDING → QUESTION SET 2 → RESEARCH → QUESTION SET 3 → GENERATE
```

各質問セットは前の回答を基に構築する。グラウンディングフェーズは仮定を検証する。

---

## Phase 1: INITIATE - コア問題

**入力が提供されない場合**、尋ねる：

> **何を構築したいか？**
> 製品、機能、または能力を数文で記述する。

**入力が提供される場合**、言い換えて理解を確認する：

> 私の理解：構築したいのは：{restated understanding}
> これは正しいか、私の理解を調整すべきか？

**GATE**：進む前にユーザー応答を待つ。

---

## Phase 2: FOUNDATION - 問題発見

これらの質問を尋ねる（すべて一度に提示、ユーザーは一緒に答えることができる）：

> **Foundation Questions:**
>
> 1. **Who** がこの問題を持っているか？具体的に - 単に "users" ではなく、どんなタイプの人物/役割か？
>
> 2. **What** 問題に直面しているか？仮定されたニーズではなく、観察可能な痛みを記述する。
>
> 3. **Why** 今日それを解決できないか？どんな代替案が存在し、なぜ失敗するか？
>
> 4. **Why now?** これを構築する価値があるようにする何が変わったか？
>
> 5. **How** 解決したと分かるか？成功はどう見えるか？

**GATE**：進む前にユーザー応答を待つ。

---

## Phase 3: GROUNDING - 市場 & コンテキスト調査

Foundation の回答後、調査を行う：

**市場コンテキストを調査する：**

1. 市場で類似の製品/機能を見つける
2. 競合がこの問題をどう解決するかを特定する
3. 共通パターンとアンチパターンを記録する
4. この空間での最近のトレンドや変化を確認する

発見事項を直接リンク、主要な洞察、利用可能な情報のギャップと共にコンパイルする。

**コードベースが存在する場合、並行して探索する：**

1. 製品/機能アイデアに関連する既存機能を見つける
2. レバレッジできるパターンを特定する
3. 技術的制約または機会を記録する

ファイルの場所、コードパターン、観察された規約を記録する。

**発見事項をユーザーに要約する：**

> **見つけたもの：**
> - {Market insight 1}
> - {Competitor approach}
> - {Relevant pattern from codebase, if applicable}
>
> これはあなたの考えを変えたり洗練したりするか？

**GATE**：ユーザー入力のための短い一時停止（"continue" でも調整でもよい）。

---

## Phase 4: DEEP DIVE - ビジョン & ユーザー

Foundation + 調査に基づいて、尋ねる：

> **Vision & Users:**
>
> 1. **Vision**：1文で、これが大成功した場合の理想的な最終状態は何か？
>
> 2. **Primary User**：最も重要なユーザー - その役割、コンテキスト、ニーズをトリガーするものを記述する。
>
> 3. **Job to Be Done**：これを完成させる：「When [situation], I want to [motivation], so I can [outcome].」
>
> 4. **Non-Users**：明示的にターゲットでないのは誰か？無視すべきは誰か？
>
> 5. **Constraints**：どんな制限があるか？（時間、予算、技術、規制）

**GATE**：進む前にユーザー応答を待つ。

---

## Phase 5: GROUNDING - 技術的実現可能性

**コードベースが存在する場合、2つの並行調査を行う：**

Investigation 1 — 実現可能性を探る：
1. レバレッジできる既存インフラを特定する
2. 既に実装された類似パターンを見つける
3. 統合ポイントと依存関係をマップする
4. 関連する設定と型定義を見つける

Investigation 2 — 制約を分析する：
1. 既存の関連機能がエンドツーエンドでどう実装されているかをトレースする
2. 潜在的な統合ポイントを通してデータフローをマップする
3. アーキテクチャパターンと境界を特定する
4. 類似機能に基づいて複雑度を推定する

精密なファイル:行参照で存在するものを文書化する。提案はしない。

**コードベースがない場合、技術アプローチを調査する：**

1. 他者が使った技術アプローチを見つける
2. 一般的な実装パターンを特定する
3. 既知の技術的課題と落とし穴を記録する

引用とギャップ分析と共に発見事項をコンパイルする。

**ユーザーに要約する：**

> **Technical Context:**
> - Feasibility: {HIGH/MEDIUM/LOW} because {reason}
> - Can leverage: {existing patterns/infrastructure}
> - Key technical risk: {main concern}
>
> 知っておくべき技術的制約はあるか？

**GATE**：ユーザー入力のための短い一時停止。

---

## Phase 6: DECISIONS - スコープ & アプローチ

最終的な明確化質問をする：

> **Scope & Approach:**
>
> 1. **MVP Definition**：これが動くかをテストするための絶対的な最小限は？
>
> 2. **Must Have vs Nice to Have**：v1 に MUST であるべき 2-3 つは？何を待てるか？
>
> 3. **Key Hypothesis**：これを完成させる：「We believe [capability] will [solve problem] for [users]. We'll know we're right when [measurable outcome].」
>
> 4. **Out of Scope**：ユーザーが頼んでも、明示的に構築しないものは何か？
>
> 5. **Open Questions**：アプローチを変えうる不確実性は何か？

**GATE**：生成前にユーザー応答を待つ。

---

## Phase 7: GENERATE - PRD を書く

**Output path**：`.claude/PRPs/prds/{kebab-case-name}.prd.md`

必要ならディレクトリを作成：`mkdir -p .claude/PRPs/prds`

### PRD テンプレート

PRD には以下のセクションを含む：Problem Statement、Evidence、Proposed Solution、Key Hypothesis、What We're NOT Building、Success Metrics 表（Metric、Target、How Measured）、Open Questions、Users & Context（Primary User、Job to Be Done、Non-Users）、Solution Detail（Core Capabilities MoSCoW 表、MVP Scope、User Flow）、Technical Approach（Feasibility、Architecture Notes、Technical Risks 表）、Implementation Phases 表（#、Phase、Description、Status、Parallel、Depends、PRP Plan）、Phase Details、Parallelism Notes、Decisions Log 表、Research Summary（Market Context、Technical Context）。

---

## Phase 8: OUTPUT - サマリー

生成後、報告する：

```markdown
## PRD Created

**File**: `.claude/PRPs/prds/{name}.prd.md`

### Summary

**Problem**: {One line}
**Solution**: {One line}
**Key Metric**: {Primary success metric}

### Validation Status

| Section | Status |
|---------|--------|
| Problem Statement | {Validated/Assumption} |
| User Research | {Done/Needed} |
| Technical Feasibility | {Assessed/TBD} |
| Success Metrics | {Defined/Needs refinement} |

### Open Questions ({count})

{List the open questions that need answers}

### Recommended Next Step

{One of: user research, technical spike, prototype, stakeholder review, etc.}

### Implementation Phases

| # | Phase | Status | Can Parallel |
|---|-------|--------|--------------|
{Table of phases from PRD}

### To Start Implementation

Run: `/prp-plan .claude/PRPs/prds/{name}.prd.md`

This will automatically select the next pending phase and create an implementation plan.
```

---

## 質問フロー概要

```
┌─────────────────────────────────────────────────────────┐
│  INITIATE: "What do you want to build?"                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  FOUNDATION: Who, What, Why, Why now, How to measure    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GROUNDING: Market research, competitor analysis        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  DEEP DIVE: Vision, Primary user, JTBD, Constraints     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GROUNDING: Technical feasibility, codebase exploration │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  DECISIONS: MVP, Must-haves, Hypothesis, Out of scope   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GENERATE: Write PRD to .claude/PRPs/prds/              │
└─────────────────────────────────────────────────────────┘
```

---

## ECC との統合

PRD 生成後：
- PRD フェーズから実装計画を作成するには `/prp-plan` を使う
- PRD 構造なしの単純な計画には `/plan` を使う
- セッション間で PRD コンテキストを保存するには `/save-session` を使う

## 成功基準

- **PROBLEM_VALIDATED**：問題が具体的で証拠付き（または仮定としてマーク）
- **USER_DEFINED**：プライマリユーザーが具体的で、ジェネリックではない
- **HYPOTHESIS_CLEAR**：測定可能な結果を持つテスト可能な仮説
- **SCOPE_BOUNDED**：明確な must-have と明示的な out-of-scope
- **QUESTIONS_ACKNOWLEDGED**：不確実性がリストされ、隠されていない
- **ACTIONABLE**：懐疑論者がこれを構築する価値がある理由を理解できる

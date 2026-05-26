---
description: "リーンで問題ファーストの PRD を生成し、実装計画のために /plan へハンドオフする / Generate a lean, problem-first PRD and hand off to /plan for implementation planning."
argument-hint: "[product/feature idea] (blank = start with questions)"
---

# PRD Command

**Product Requirements Document** を生成する — SDLC の要件フェーズの成果物。成功のために*何が*真でなければならないか、そして*なぜ*かを捉え、*どうやって*の前で停止する。実装の分解は `/plan` に委譲される。

**Input**: `$ARGUMENTS`

## このコマンドの範囲

| このコマンドが行うこと | このコマンドが行わないこと |
|---|---|
| 問題とユーザーをフレーム化する | アーキテクチャを設計する |
| 成功基準と範囲を捉える | ファイルを選んだり、パターンを書く |
| オープンクエスチョンとリスクをリストする | 実装タスクを列挙する |
| `.claude/prds/{name}.prd.md` を書く | 実装計画を生成する — それは `/plan` の役割 |

実装詳細を書いていると気づいたら、停止して切り取る。それは `/plan` に属する。

**アンチフラフルール**：情報が不足している場合、`TBD — needs validation via {method}` と書く。もっともらしい要件を決して捏造しない。

## ワークフロー

4フェーズ。各フェーズは単一のゲートである — 質問をし、ユーザーを待ち、次へ進む。ネストされたループも、並列リサーチセレモニーもない。

### Phase 1 — FRAME

`$ARGUMENTS` が空なら、尋ねる：

> 何を構築したいか？1〜2文で。

提供されている場合、1文で言い換えて尋ねる：

> 私の理解：*{restated}*。正しいか、調整すべきか？

その後、フレーミング質問を単一セットで尋ねる：

> 1. **誰**がこの問題を持っているか？（具体的な役割またはセグメント）
> 2. **何**が観察可能な痛みか？（仮定されたニーズではなく、行動を記述する）
> 3. **なぜ**今日存在するもので解決できないか？
> 4. **なぜ今？** — これを行う価値があるようにする何が変わったか？

ユーザーを待つ。回答（または明示的な "skip"）なしに進まない。

### Phase 2 — GROUND

証拠を求める。これは最も短いフェーズで、最も荷重を負うものである：

> この問題が現実であり解決する価値があるという、どんな証拠を持っているか？（ユーザーの引用、サポートチケット、メトリクス、観察された行動、失敗したワークアラウンド — 何か具体的なもの）

ユーザーが何も持っていない場合、PRD の Evidence セクションを `Assumption — needs validation via {user research | analytics | prototype}` として記録する。これは PRD を正直に保つ。

### Phase 3 — DECIDE

範囲と仮説を単一セットで：

> 1. **Hypothesis** — 完全に：*私たちは、**{capability}** が **{users}** のために **{solve problem}** すると信じる。**{measurable outcome}** が達成されたとき正しいと分かる。*
> 2. **MVP** — 仮説をテストするために必要な最小限は？
> 3. **Out of scope** — ユーザーが頼んでも、明示的に**構築しない**ものは何か？
> 4. **Open questions** — アプローチを変えうる不確実性は？

応答を待つ。

### Phase 4 — GENERATE & HAND OFF

必要ならディレクトリを作成し、PRD を書き、報告する。

```bash
mkdir -p .claude/prds
```

**Output path**: `.claude/prds/{kebab-case-name}.prd.md`

#### PRD テンプレート

```markdown
# {Product / Feature Name}

## Problem
{2–3 sentences: who has what problem, and what's the cost of leaving it unsolved?}

## Evidence
- {User quote, data point, or observation}
- {OR: "Assumption — needs validation via {method}"}

## Users
- **Primary**: {role, context, what triggers the need}
- **Not for**: {who this explicitly excludes}

## Hypothesis
We believe **{capability}** will **{solve problem}** for **{users}**.
We'll know we're right when **{measurable outcome}**.

## Success Metrics
| Metric | Target | How measured |
|---|---|---|
| {primary} | {number} | {method} |

## Scope
**MVP** — {the minimum to test the hypothesis}

**Out of scope**
- {item} — {why deferred}

## Delivery Milestones
<!-- Business outcomes, not engineering tasks. /plan turns each into a plan. -->
<!-- Status: pending | in-progress | complete -->

| # | Milestone | Outcome | Status | Plan |
|---|---|---|---|---|
| 1 | {name} | {user-visible change} | pending | — |
| 2 | {name} | {user-visible change} | pending | — |

## Open Questions
- [ ] {question that could change scope or approach}

## Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|

---
*Status: DRAFT — requirements only. Implementation planning pending via /plan.*
```

#### ユーザーへの報告

```
PRD created: .claude/prds/{name}.prd.md

Problem:    {one line}
Hypothesis: {one line}
MVP:        {one line}

Validation status:
  Problem  {validated | assumption}
  Users    {concrete | generic — refine}
  Metrics  {defined | TBD}

Open questions: {count}

Next step: /plan .claude/prds/{name}.prd.md
  → /plan will pick the next pending milestone and produce an implementation plan.
```

## 統合

- `/plan <prd-path>` — PRD を消費し、次の保留中マイルストーンの実装計画を生成する。
- `tdd-workflow` skill — テストファーストで計画を実装する。
- `/pr` — PRD と計画を参照する PR を開く。

## 成功基準

- **PROBLEM_CLEAR**：問題が具体的で証拠付き（または仮定としてフラグ付き）。
- **USER_CONCRETE**：プライマリユーザーは "users" ではなく、具体的な役割である。
- **HYPOTHESIS_TESTABLE**：測定可能な結果が含まれている。
- **SCOPE_BOUNDED**：明示的な MVP と明示的な out-of-scope。
- **NO_IMPLEMENTATION_DETAIL**：ファイルパス、ライブラリ、タスク分解が欠けている — 現れたら、`/plan` ステップに移動する。

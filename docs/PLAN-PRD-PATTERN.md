# Plan-PRD パターン: Markdown ステージング計画フロー

軽量で SDLC 整合の計画ワークフローであり、ライフサイクルの各フェーズが、次のコマンドが消費するコミット可能 Markdown **ステージングファイル** を生成する。

> 要約: `/plan-prd` が PRD を書き、`/plan` がプランを書き、`tdd-workflow` スキルがそれを実装し、`/pr` が出荷する。各矢印はメモリ内の会話ではなく、ディスク上のファイルである。

## 機能: Markdown ステージングファイル

すべての計画アーティファクトは `.claude/` 配下のプレーン `.md` ファイルである:

```
.claude/
  prds/      # /plan-prd からの Product Requirements Documents
  plans/     # /plan からの実装プラン
  reviews/   # /code-review からのコードレビューアーティファクト
```

これらファイルは:

- **プレーン Markdown** — 人間が読める、PR で diff 可能、CLI で grep 可能。
- **コミット可能** — コードとともにチェックインし、意図が実装と一緒に移動する。
- **コンポーザブル** — 各コマンドは前段階のファイルを `$ARGUMENTS` として受理し、インコンテキスト状態ではなくパス経由でツールチェーンを構成する。
- **再開可能** — セッションを閉じ、翌日新しいセッションを開き、ファイルパスを渡し直す。

## フロー

```
┌───────────────────────────┐
│ /plan-prd "<idea>"        │  Requirements phase
│  → .claude/prds/X.prd.md  │   Problem · Users · Hypothesis · Scope
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ /plan <prd-path>          │  Design phase
│  → .claude/plans/X.plan.md│   Patterns · Files · Tasks · Validation
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ tdd-workflow skill         │  Implementation phase
│  → code + tests           │   Test-first, minimal diff
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ /pr                        │  Delivery phase
│  → GitHub PR               │   Links back to PRD + plan
└───────────────────────────┘
```

各ボックスは **ゲート** である。以下が可能:

- ゲート間で停止 — アーティファクトが永続する。
- アーティファクトパスを使って任意のゲートから再開。
- 小さな作業ではゲートをスキップ — `/plan` にフリーフォームテキストを与え `/plan-prd` を無視。
- ゲートをスタンドアロンで実行 — `/plan "refactor X"` がアーティファクト無しの会話的プランを生成。

## なぜ `/plan-prd` が `/plan` に加えて必要か

両者は異なる問いに答える。混合するとスコープクリープを招く。

| コマンド | 答え | SDLC フェーズ | アーティファクト |
|---|---|---|---|
| `/plan-prd` | *どんな問題? 誰のため? どうやって完了を知るか?* | Requirements | `.claude/prds/{name}.prd.md` |
| `/plan` | *どのファイル、パターン、タスクが要件を満たすか?* | Design + 実装戦略 | `.claude/plans/{name}.plan.md` (PRD モード) または inline (テキストモード) |

### なぜ統合しないか?

- **関心の分離。** PRD は *why* を問い、プランは *how* を問う。バンドルすると両方を不十分にこなす肥大化コマンドができる。古い `/prp-prd` → `/prp-plan` ペアがそれを示した(要件に実装フェーズテーブルが混入する 8 フェーズ尋問)。
- **異なるオーディエンス。** PRD をレビューするステークホルダーはファイルパスや type-check コマンドを気にしない。プランを読むエンジニアは市場調査フェーズを必要としない。
- **異なる寿命。** 実装仮定が変わるにつれプランが複数回書き直されても、PRD は安定して残りうる。
- **オプショナルステップ。** 多くの変更 (バグ修正、小さなリファクタ、単一ファイル追加) は PRD を必要としない。`/plan` だけで十分。すべての変更に PRD を強制するのは官僚主義。

### それぞれの利用タイミング

`/plan-prd` を使うとき:

- スコープが不明確または争点。
- 解決前に複数ステークホルダーが問題に整合する必要がある。
- 仮説を書き留める方が、実装中にスコープを再議論するより安いほど変更が大きい。

`/plan` を直接使うとき:

- 要件が既に明確 (バグレポート、スコープ化リファクタ、既知のマイグレーション)。
- 作業が会話的プラン + 確認ゲートで十分な程度に小さい。
- 既に PRD がある — `/plan` に渡し `/plan-prd` をスキップ。

## 使い方

### 完全フロー (スコープが不明確な機能)

```bash
# 1. Draft the PRD
/plan-prd "Per-user rate limits on the public API"

# → .claude/prds/per-user-rate-limits.prd.md created
# Answer the framing questions, provide evidence, define hypothesis and scope.

# 2. Pick the next pending milestone and produce a plan
/plan .claude/prds/per-user-rate-limits.prd.md

# → .claude/plans/per-user-rate-limits.plan.md created
# The plan includes patterns to mirror, files to change, and validation commands.
# PRD's Delivery Milestones table updates the selected row to `in-progress`.

# 3. Implement test-first
Use the tdd-workflow skill

# 4. Open the PR
/pr
# → PR body auto-references .claude/prds/... and .claude/plans/...
```

### クイックフロー (スコープが既に明確)

```bash
/plan "Add retry with exponential backoff to the notifier"
# Conversational planning, no artifact.
# Confirm, then use the tdd-workflow skill.
```

### 他所の既存 PRD を参照

```bash
# PRD was written by someone else, lives in your repo
/plan docs/rfcs/0042-rate-limiting.prd.md
```

`/plan` は任意の `.prd.md` パスを検出し、Delivery Milestones テーブルを解析してアーティファクトモードに切り替わる。

## なぜステージングファイルがインコンテキスト状態に勝るか

- **転送可能**: 新しいセッションに PRD パスを投入すれば追いつく — 長い会話のリプレイ無し。
- **監査可能**: PR レビュアーが *意図したもの* を *構築したもの* の横に見られる。
- **バージョン管理**: ステージングファイルがコードと同じく git 履歴で進化する。
- **機械解析可能**: `/plan` がプログラム的に次の保留マイルストーンを選び、`/pr` がプログラム的に PR 本文でアーティファクトをリンクする。プロンプトエンジニアリング不要。

## 関連コマンド

- `/plan-prd` — 要件 (本パターンのエントリポイント)。
- `/plan` — 計画 (PRD またはフリーフォームテキストを消費)。
- `tdd-workflow` スキル — test-first 実装。
- `/pr` — PRD とプランを参照する PR をオープン。
- `/code-review` — ローカル diff または PR をレビュー。コンテキストとして `.claude/prds/` と `.claude/plans/` を自動検出。

## 互換性

このパターンは既存の `prp-*` コマンドセットと並行して ECC ネイティブなステージングファイルコマンドを追加する。レガシー PRP コマンドは、より深い PRP ワークフローと、既に `.claude/PRPs/` アーティファクトを持つユーザー向けに利用可能なままである。

- `/plan-prd` は `.claude/prds/` 用の lean な要件エントリポイント。
- `/plan` は `.prd.md` ファイルを消費し、レガシー PRP ディレクトリレイアウトを必要とせず `.claude/plans/` アーティファクトを生成可能。
- `/pr` は ECC ネイティブな PR 作成コマンドであり、`.claude/prds/` と `.claude/plans/` を参照可能。
- `/prp-prd`、`/prp-plan`、`/prp-implement`、`/prp-commit`、`/prp-pr` は有効なレガシー/深層ワークフローコマンドのまま残る。

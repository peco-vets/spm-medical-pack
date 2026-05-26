---
name: autonomous-loops
description: "自律的な Claude Code ループのためのパターンとアーキテクチャ — シンプルな逐次パイプラインから RFC 駆動のマルチエージェント DAG システムまで (autonomous loops, sequential pipeline, NanoClaw, infinite agentic loop, continuous claude, Ralphinho, DAG orchestration)。"
origin: ECC
---

# Autonomous Loops スキル

> 互換性メモ (v1.8.0): `autonomous-loops` は 1 リリースだけ保持される。
> 正規スキル名は `continuous-agent-loop` に移行した。新しいループのガイダンスは
> そちらに執筆すべきだが、既存ワークフローを壊さないため当スキルも引き続き利用可能である。

Claude Code をループで自律実行するためのパターン、アーキテクチャ、リファレンス実装。シンプルな `claude -p` パイプラインから完全な RFC 駆動マルチエージェント DAG オーケストレーションまでをカバーする。

## 利用するタイミング

- 人間の介入なしで動く自律開発ワークフローのセットアップ
- 問題に対する正しいループアーキテクチャの選定 (シンプル vs 複雑)
- CI/CD スタイルの継続的開発パイプライン構築
- マージ調整を伴う並列エージェントの実行
- ループイテレーション間でのコンテキスト永続化の実装
- 自律ワークフローへの品質ゲートとクリーンアップパスの追加

## ループパターンスペクトラム

最もシンプルなものから最も洗練されたものまで:

| パターン | 複雑度 | 最適な用途 |
|---------|-----------|----------|
| [Sequential Pipeline](#1-sequential-pipeline-claude--p) | 低 | 日々の開発ステップ、スクリプト化されたワークフロー |
| [NanoClaw REPL](#2-nanoclaw-repl) | 低 | インタラクティブな永続セッション |
| [Infinite Agentic Loop](#3-infinite-agentic-loop) | 中 | 並列コンテンツ生成、仕様駆動の作業 |
| [Continuous Claude PR Loop](#4-continuous-claude-pr-loop) | 中 | CI ゲート付きの複数日にわたる反復プロジェクト |
| [De-Sloppify Pattern](#5-the-de-sloppify-pattern) | アドオン | 任意の Implementer ステップ後の品質クリーンアップ |
| [Ralphinho / RFC-Driven DAG](#6-ralphinho--rfc-driven-dag-orchestration) | 高 | 大規模機能、マージキューを伴うマルチユニット並列作業 |

---

## 1. Sequential Pipeline (`claude -p`)

**最もシンプルなループ。** 日々の開発を非対話型の `claude -p` 呼び出しのシーケンスに分割する。各呼び出しは明確なプロンプトを持つ集中したステップ。

### 中核的洞察

> このようなループを思いつかないなら、対話モードでも LLM にコードを修正させることすらできない。

`claude -p` フラグは Claude Code をプロンプト付きで非対話実行し、完了時に終了する。呼び出しを連鎖してパイプラインを構築する:

```bash
#!/bin/bash
# daily-dev.sh — Sequential pipeline for a feature branch

set -e

# Step 1: Implement the feature
claude -p "Read the spec in docs/auth-spec.md. Implement OAuth2 login in src/auth/. Write tests first (TDD). Do NOT create any new documentation files."

# Step 2: De-sloppify (cleanup pass)
claude -p "Review all files changed by the previous commit. Remove any unnecessary type tests, overly defensive checks, or testing of language features (e.g., testing that TypeScript generics work). Keep real business logic tests. Run the test suite after cleanup."

# Step 3: Verify
claude -p "Run the full build, lint, type check, and test suite. Fix any failures. Do not add new features."

# Step 4: Commit
claude -p "Create a conventional commit for all staged changes. Use 'feat: add OAuth2 login flow' as the message."
```

### 重要な設計原則

1. **各ステップは隔離されている** — `claude -p` 呼び出しごとにコンテキストウィンドウがフレッシュなので、ステップ間でコンテキストが漏れない。
2. **順序が重要** — ステップは順次実行される。各々は前が残したファイルシステム状態の上に構築される。
3. **否定的指示は危険** — 「型システムをテストするな」と言わないこと。代わりに別のクリーンアップステップを追加する ([De-Sloppify Pattern](#5-the-de-sloppify-pattern) を参照)。
4. **終了コードは伝播する** — `set -e` は失敗時にパイプラインを停止する。

### バリエーション

**モデルルーティング付き:**
```bash
# Research with Opus (deep reasoning)
claude -p --model opus "Analyze the codebase architecture and write a plan for adding caching..."

# Implement with Sonnet (fast, capable)
claude -p "Implement the caching layer according to the plan in docs/caching-plan.md..."

# Review with Opus (thorough)
claude -p --model opus "Review all changes for security issues, race conditions, and edge cases..."
```

**環境コンテキスト付き:**
```bash
# Pass context via files, not prompt length
echo "Focus areas: auth module, API rate limiting" > .claude-context.md
claude -p "Read .claude-context.md for priorities. Work through them in order."
rm .claude-context.md
```

**`--allowedTools` 制約付き:**
```bash
# Read-only analysis pass
claude -p --allowedTools "Read,Grep,Glob" "Audit this codebase for security vulnerabilities..."

# Write-only implementation pass
claude -p --allowedTools "Read,Write,Edit,Bash" "Implement the fixes from security-audit.md..."
```

---

## 2. NanoClaw REPL

**ECC の組み込み永続ループ。** 完全な会話履歴付きで `claude -p` を同期呼び出しするセッション認識 REPL。

```bash
# Start the default session
node scripts/claw.js

# Named session with skill context
CLAW_SESSION=my-project CLAW_SKILLS=tdd-workflow,security-review node scripts/claw.js
```

### 仕組み

1. `~/.claude/claw/{session}.md` から会話履歴をロード
2. 各ユーザーメッセージはフル履歴をコンテキストとして `claude -p` に送信される
3. 応答はセッションファイルに追記される (Markdown-as-database)
4. セッションは再起動を生き延びる

### NanoClaw vs Sequential Pipeline

| ユースケース | NanoClaw | Sequential Pipeline |
|----------|----------|-------------------|
| 対話的探索 | Yes | No |
| スクリプト化された自動化 | No | Yes |
| セッション永続性 | 組み込み | 手動 |
| コンテキスト蓄積 | ターンごとに成長 | 各ステップでフレッシュ |
| CI/CD 統合 | 弱い | 優れる |

詳細は `/claw` コマンドドキュメントを参照。

---

## 3. Infinite Agentic Loop

**仕様駆動生成のために並列サブエージェントをオーケストレートする 2 プロンプトシステム。** disler によって開発された (クレジット: @disler)。

### アーキテクチャ: 2 プロンプトシステム

```
PROMPT 1 (Orchestrator)              PROMPT 2 (Sub-Agents)
┌─────────────────────┐             ┌──────────────────────┐
│ Parse spec file      │             │ Receive full context  │
│ Scan output dir      │  deploys   │ Read assigned number  │
│ Plan iteration       │────────────│ Follow spec exactly   │
│ Assign creative dirs │  N agents  │ Generate unique output │
│ Manage waves         │             │ Save to output dir    │
└─────────────────────┘             └──────────────────────┘
```

### パターン

1. **仕様分析** — Orchestrator が何を生成するか定義する仕様ファイル (Markdown) を読む
2. **ディレクトリ偵察** — 既存出力をスキャンし最大イテレーション番号を見つける
3. **並列デプロイ** — N サブエージェントを起動し、それぞれに以下を与える:
   - 完全な仕様
   - ユニークなクリエイティブ方向性
   - 特定のイテレーション番号 (衝突なし)
   - 既存イテレーションのスナップショット (ユニーク性のため)
4. **ウェーブ管理** — 無限モードでは、コンテキストが尽きるまで 3-5 エージェントのウェーブをデプロイする

### Claude Code Commands による実装

`.claude/commands/infinite.md` を作成:

```markdown
Parse the following arguments from $ARGUMENTS:
1. spec_file — path to the specification markdown
2. output_dir — where iterations are saved
3. count — integer 1-N or "infinite"

PHASE 1: Read and deeply understand the specification.
PHASE 2: List output_dir, find highest iteration number. Start at N+1.
PHASE 3: Plan creative directions — each agent gets a DIFFERENT theme/approach.
PHASE 4: Deploy sub-agents in parallel (Task tool). Each receives:
  - Full spec text
  - Current directory snapshot
  - Their assigned iteration number
  - Their unique creative direction
PHASE 5 (infinite mode): Loop in waves of 3-5 until context is low.
```

**起動:**
```bash
/project:infinite specs/component-spec.md src/ 5
/project:infinite specs/component-spec.md src/ infinite
```

### バッチング戦略

| 数 | 戦略 |
|-------|----------|
| 1-5 | すべてのエージェントを同時に |
| 6-20 | 5 のバッチ |
| infinite | 3-5 のウェーブ、漸進的な洗練 |

### 重要な洞察: アサインメントによるユニーク性

エージェントに自己分化を頼らない。Orchestrator が各エージェントに特定のクリエイティブ方向性とイテレーション番号を **アサインする**。これにより並列エージェント間で重複コンセプトが防がれる。

---

## 4. Continuous Claude PR Loop

**本番品質のシェルスクリプト** で、Claude Code を継続的ループで実行し、PR を作成し、CI を待ち、自動マージする。AnandChowdhary によって作成された (クレジット: @AnandChowdhary)。

### 中核ループ

```
┌─────────────────────────────────────────────────────┐
│  CONTINUOUS CLAUDE ITERATION                        │
│                                                     │
│  1. Create branch (continuous-claude/iteration-N)   │
│  2. Run claude -p with enhanced prompt              │
│  3. (Optional) Reviewer pass — separate claude -p   │
│  4. Commit changes (claude generates message)       │
│  5. Push + create PR (gh pr create)                 │
│  6. Wait for CI checks (poll gh pr checks)          │
│  7. CI failure? → Auto-fix pass (claude -p)         │
│  8. Merge PR (squash/merge/rebase)                  │
│  9. Return to main → repeat                         │
│                                                     │
│  Limit by: --max-runs N | --max-cost $X             │
│            --max-duration 2h | completion signal     │
└─────────────────────────────────────────────────────┘
```

### インストール

> **警告:** コードをレビューした上で、リポジトリから continuous-claude をインストールすること。外部スクリプトを直接 bash にパイプしないこと。

### 使い方

```bash
# Basic: 10 iterations
continuous-claude --prompt "Add unit tests for all untested functions" --max-runs 10

# Cost-limited
continuous-claude --prompt "Fix all linter errors" --max-cost 5.00

# Time-boxed
continuous-claude --prompt "Improve test coverage" --max-duration 8h

# With code review pass
continuous-claude \
  --prompt "Add authentication feature" \
  --max-runs 10 \
  --review-prompt "Run npm test && npm run lint, fix any failures"

# Parallel via worktrees
continuous-claude --prompt "Add tests" --max-runs 5 --worktree tests-worker &
continuous-claude --prompt "Refactor code" --max-runs 5 --worktree refactor-worker &
wait
```

### イテレーション間コンテキスト: SHARED_TASK_NOTES.md

決定的なイノベーション: `SHARED_TASK_NOTES.md` ファイルがイテレーション間で永続化される:

```markdown
## Progress
- [x] Added tests for auth module (iteration 1)
- [x] Fixed edge case in token refresh (iteration 2)
- [ ] Still need: rate limiting tests, error boundary tests

## Next Steps
- Focus on rate limiting module next
- The mock setup in tests/helpers.ts can be reused
```

Claude はイテレーション開始時にこのファイルを読み、イテレーション終了時に更新する。これが独立した `claude -p` 起動間のコンテキストギャップを埋める。

### CI 失敗リカバリ

PR チェックが失敗すると、Continuous Claude は自動的に以下を行う:
1. `gh run list` を介して失敗ラン ID を取得
2. CI 修正コンテキスト付きで新しい `claude -p` をスポーン
3. Claude が `gh run view` でログを検査し、コードを修正、コミット、プッシュ
4. チェックを再待機 (`--ci-retry-max` 回まで)

### 完了シグナル

Claude は魔法のフレーズを出力することで「完了」を通知できる:

```bash
continuous-claude \
  --prompt "Fix all bugs in the issue tracker" \
  --completion-signal "CONTINUOUS_CLAUDE_PROJECT_COMPLETE" \
  --completion-threshold 3  # Stops after 3 consecutive signals
```

連続 3 イテレーションが完了をシグナルするとループが停止し、完了済み作業に無駄なランを費やさない。

### 重要な設定

| フラグ | 用途 |
|------|---------|
| `--max-runs N` | N 回の成功イテレーション後に停止 |
| `--max-cost $X` | $X を費やした後に停止 |
| `--max-duration 2h` | 時間経過後に停止 |
| `--merge-strategy squash` | squash・merge・rebase |
| `--worktree <name>` | git worktree による並列実行 |
| `--disable-commits` | ドライランモード (git 操作なし) |
| `--review-prompt "..."` | イテレーションごとにレビューアパスを追加 |
| `--ci-retry-max N` | CI 失敗の自動修正 (デフォルト: 1) |

---

## 5. The De-Sloppify Pattern

**任意のループのためのアドオンパターン。** 各 Implementer ステップ後に専用のクリーンアップ/リファクタステップを追加する。

### 問題

LLM に TDD で実装するよう頼むと、「テストを書く」を字義通りに受け取りすぎる:
- TypeScript の型システムが動くことを検証するテスト (`typeof x === 'string'` のテスト)
- 型システムが既に保証していることに対する過剰な防御的ランタイムチェック
- ビジネスロジックではなくフレームワーク挙動のテスト
- 実際のコードを覆い隠す過剰なエラー処理

### なぜ否定的指示でないのか?

Implementer プロンプトに「型システムをテストするな」「不要なチェックを追加するな」と追加すると下流の効果がある:
- モデルがすべてのテストに対してためらうようになる
- 正当なエッジケーステストもスキップする
- 品質が予測不可能に劣化する

### 解決策: 別パス

Implementer を制約するのではなく、徹底させる。その後、集中したクリーンアップエージェントを追加する:

```bash
# Step 1: Implement (let it be thorough)
claude -p "Implement the feature with full TDD. Be thorough with tests."

# Step 2: De-sloppify (separate context, focused cleanup)
claude -p "Review all changes in the working tree. Remove:
- Tests that verify language/framework behavior rather than business logic
- Redundant type checks that the type system already enforces
- Over-defensive error handling for impossible states
- Console.log statements
- Commented-out code

Keep all business logic tests. Run the test suite after cleanup to ensure nothing breaks."
```

### ループコンテキストで

```bash
for feature in "${features[@]}"; do
  # Implement
  claude -p "Implement $feature with TDD."

  # De-sloppify
  claude -p "Cleanup pass: review changes, remove test/code slop, run tests."

  # Verify
  claude -p "Run build + lint + tests. Fix any failures."

  # Commit
  claude -p "Commit with message: feat: add $feature"
done
```

### 重要な洞察

> 下流の品質効果を持つ否定的指示を追加するのではなく、別の de-sloppify パスを追加する。集中した 2 つのエージェントは制約された 1 つのエージェントを上回る。

---

## 6. Ralphinho / RFC-Driven DAG Orchestration

**最も洗練されたパターン。** 仕様を依存 DAG に分解し、各ユニットを階層化品質パイプラインで実行し、エージェント駆動のマージキューで着地させる、RFC 駆動のマルチエージェントパイプライン。enitrat によって作成された (クレジット: @enitrat)。

### アーキテクチャ概要

```
RFC/PRD Document
       │
       ▼
  DECOMPOSITION (AI)
  Break RFC into work units with dependency DAG
       │
       ▼
┌──────────────────────────────────────────────────────┐
│  RALPH LOOP (up to 3 passes)                         │
│                                                      │
│  For each DAG layer (sequential, by dependency):     │
│                                                      │
│  ┌── Quality Pipelines (parallel per unit) ───────┐  │
│  │  Each unit in its own worktree:                │  │
│  │  Research → Plan → Implement → Test → Review   │  │
│  │  (depth varies by complexity tier)             │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌── Merge Queue ─────────────────────────────────┐  │
│  │  Rebase onto main → Run tests → Land or evict │  │
│  │  Evicted units re-enter with conflict context  │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### RFC 分解

AI が RFC を読み、作業ユニットを生成する:

```typescript
interface WorkUnit {
  id: string;              // kebab-case identifier
  name: string;            // Human-readable name
  rfcSections: string[];   // Which RFC sections this addresses
  description: string;     // Detailed description
  deps: string[];          // Dependencies (other unit IDs)
  acceptance: string[];    // Concrete acceptance criteria
  tier: "trivial" | "small" | "medium" | "large";
}
```

**分解ルール:**
- より少なく、まとまったユニットを優先する (マージリスク最小化)
- ユニット間のファイル重複を最小化する (衝突回避)
- 実装と一緒にテストを保持する (「X を実装」+「X をテスト」と分けない)
- 実際のコード依存がある場合のみの依存

依存 DAG が実行順序を決定する:
```
Layer 0: [unit-a, unit-b]     ← no deps, run in parallel
Layer 1: [unit-c]             ← depends on unit-a
Layer 2: [unit-d, unit-e]     ← depend on unit-c
```

### 複雑度ティア

ティアによってパイプライン深度が異なる:

| ティア | パイプラインステージ |
|------|----------------|
| **trivial** | implement → test |
| **small** | implement → test → code-review |
| **medium** | research → plan → implement → test → PRD-review + code-review → review-fix |
| **large** | research → plan → implement → test → PRD-review + code-review → review-fix → final-review |

これによりシンプルな変更で高コストな操作を防ぎつつ、アーキテクチャ的変更に徹底的な精査を保証する。

### 別コンテキストウィンドウ (作成者バイアスの排除)

各ステージは独自のコンテキストウィンドウを持つ独立したエージェントプロセスで実行される:

| ステージ | モデル | 用途 |
|-------|-------|---------|
| Research | Sonnet | コードベース + RFC を読み、コンテキスト文書を生成 |
| Plan | Opus | 実装ステップを設計 |
| Implement | Codex | プランに従ってコードを書く |
| Test | Sonnet | ビルド + テストスイートを実行 |
| PRD Review | Sonnet | 仕様遵守チェック |
| Code Review | Opus | 品質 + セキュリティチェック |
| Review Fix | Codex | レビュー指摘に対応 |
| Final Review | Opus | 品質ゲート (large ティアのみ) |

**重要な設計:** レビューアはレビューするコードを書いていない。これは作成者バイアス (自己レビューで見逃される問題の最も一般的な原因) を排除する。

### 退避を伴うマージキュー

品質パイプライン完了後、ユニットはマージキューに入る:

```
Unit branch
    │
    ├─ Rebase onto main
    │   └─ Conflict? → EVICT (capture conflict context)
    │
    ├─ Run build + tests
    │   └─ Fail? → EVICT (capture test output)
    │
    └─ Pass → Fast-forward main, push, delete branch
```

**ファイル重複インテリジェンス:**
- 重複しないユニットは並列で投機的に着地する
- 重複するユニットは一つずつ着地し、毎回リベースする

**退避リカバリ:**
退避時、フルコンテキスト (衝突ファイル・差分・テスト出力) がキャプチャされ、次の Ralph パスで Implementer にフィードバックされる:

```markdown
## MERGE CONFLICT — RESOLVE BEFORE NEXT LANDING

Your previous implementation conflicted with another unit that landed first.
Restructure your changes to avoid the conflicting files/lines below.

{full eviction context with diffs}
```

### ステージ間データフロー

```
research.contextFilePath ──────────────────→ plan
plan.implementationSteps ──────────────────→ implement
implement.{filesCreated, whatWasDone} ─────→ test, reviews
test.failingSummary ───────────────────────→ reviews, implement (next pass)
reviews.{feedback, issues} ────────────────→ review-fix → implement (next pass)
final-review.reasoning ────────────────────→ implement (next pass)
evictionContext ───────────────────────────→ implement (after merge conflict)
```

### Worktree 隔離

各ユニットは隔離された worktree で実行される (git ではなく jj/Jujutsu を使用):
```
/tmp/workflow-wt-{unit-id}/
```

同じユニットのパイプラインステージは worktree を **共有** し、状態 (コンテキストファイル・プランファイル・コード変更) を research → plan → implement → test → review にわたって保持する。

### 重要な設計原則

1. **決定論的実行** — 事前分解が並列性と順序をロックする
2. **てこ点での人間レビュー** — 作業計画が単一の最高てこ介入点
3. **関心の分離** — 各ステージは別エージェントの別コンテキストウィンドウ
4. **コンテキスト付き衝突リカバリ** — フル退避コンテキストが盲目的リトライではなくインテリジェントな再実行を可能にする
5. **ティア駆動の深度** — 些細な変更は research/review をスキップ、大きな変更は最大限の精査を受ける
6. **再開可能なワークフロー** — フル状態を SQLite に永続化、任意の点から再開可能

### Ralphinho vs シンプルパターンの選択

| シグナル | Ralphinho を使う | シンプルパターンを使う |
|--------|--------------|-------------------|
| 複数の相互依存作業ユニット | Yes | No |
| 並列実装が必要 | Yes | No |
| マージ衝突が起きそう | Yes | No (順次で十分) |
| 単一ファイル変更 | No | Yes (sequential pipeline) |
| 複数日プロジェクト | Yes | Maybe (continuous-claude) |
| 仕様/RFC が既に書かれている | Yes | Maybe |
| 1 件の素早いイテレーション | No | Yes (NanoClaw or pipeline) |

---

## 正しいパターンの選択

### 意思決定マトリックス

```
Is the task a single focused change?
├─ Yes → Sequential Pipeline or NanoClaw
└─ No → Is there a written spec/RFC?
         ├─ Yes → Do you need parallel implementation?
         │        ├─ Yes → Ralphinho (DAG orchestration)
         │        └─ No → Continuous Claude (iterative PR loop)
         └─ No → Do you need many variations of the same thing?
                  ├─ Yes → Infinite Agentic Loop (spec-driven generation)
                  └─ No → Sequential Pipeline with de-sloppify
```

### パターンの組み合わせ

これらのパターンは良く組み合わせられる:

1. **Sequential Pipeline + De-Sloppify** — 最も一般的な組み合わせ。すべての実装ステップがクリーンアップパスを得る。

2. **Continuous Claude + De-Sloppify** — 各イテレーションに de-sloppify ディレクティブ付きの `--review-prompt` を追加する。

3. **任意のループ + 検証** — コミット前のゲートとして ECC の `/verify` コマンドや `verification-loop` スキルを使う。

4. **シンプルループでの Ralphinho ティアアプローチ** — 順次パイプラインでも、シンプルタスクを Haiku に、複雑タスクを Opus にルーティングできる:
   ```bash
   # Simple formatting fix
   claude -p --model haiku "Fix the import ordering in src/utils.ts"

   # Complex architectural change
   claude -p --model opus "Refactor the auth module to use the strategy pattern"
   ```

---

## アンチパターン

### よくある誤り

1. **終了条件のない無限ループ** — 常に max-runs・max-cost・max-duration・完了シグナルを持つこと。

2. **イテレーション間のコンテキストブリッジなし** — 各 `claude -p` 呼び出しはフレッシュに始まる。コンテキストを橋渡しするには `SHARED_TASK_NOTES.md` やファイルシステム状態を使う。

3. **同じ失敗をリトライする** — イテレーションが失敗した場合、ただリトライしない。エラーコンテキストをキャプチャして次の試行に与える。

4. **クリーンアップパスではなく否定的指示** — 「X するな」と言わない。X を削除する別パスを追加する。

5. **すべてのエージェントを 1 つのコンテキストウィンドウに** — 複雑なワークフローでは関心を別のエージェントプロセスに分離する。レビューアは作成者であってはならない。

6. **並列作業でファイル重複を無視** — 2 つの並列エージェントが同じファイルを編集する可能性があるなら、マージ戦略 (順次着地・リベース・衝突解決) が必要。

---

## 参考

| プロジェクト | 作者 | リンク |
|---------|--------|------|
| Ralphinho | enitrat | クレジット: @enitrat |
| Infinite Agentic Loop | disler | クレジット: @disler |
| Continuous Claude | AnandChowdhary | クレジット: @AnandChowdhary |
| NanoClaw | ECC | このリポジトリの `/claw` コマンド |
| Verification Loop | ECC | このリポジトリの `skills/verification-loop/` |

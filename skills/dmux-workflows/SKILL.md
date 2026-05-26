---
name: dmux-workflows
description: dmux（AI エージェント向け tmux ペインマネージャ）を用いたマルチエージェント・オーケストレーション（multi-agent orchestration, dmux, parallel agents）。Claude Code、Codex、OpenCode 他ハーネス横断の並列エージェントワークフローパターン。複数エージェントセッションを並列実行する場合や、マルチエージェント開発ワークフローを調整する場合に用いる。
origin: ECC
---

# dmux ワークフロー

エージェントハーネス向け tmux ペインマネージャである dmux を用いて、並列 AI エージェントセッションをオーケストレーションする。

## 起動タイミング

- 複数エージェントセッションを並列実行する場合
- Claude Code、Codex、他ハーネスを横断する作業の調整
- 分割統治型並列処理が有効な複雑タスク
- ユーザーが "run in parallel"、"split this work"、"use dmux"、"multi-agent" と発言した場合

## dmux とは

dmux は tmux ベースのオーケストレーションツールで、AI エージェントペインを管理する。
- `n` を押すとプロンプトを入力した新ペインを作成
- `m` を押すとペイン出力をメインセッションへマージ
- 対応: Claude Code、Codex、OpenCode、Cline、Gemini、Qwen

**インストール:** リポジトリ内容を確認してから dmux をインストールすること。詳細は [github.com/standardagents/dmux](https://github.com/standardagents/dmux)。

## クイックスタート

```bash
# Start dmux session
dmux

# Create agent panes (press 'n' in dmux, then type prompt)
# Pane 1: "Implement the auth middleware in src/auth/"
# Pane 2: "Write tests for the user service"
# Pane 3: "Update API documentation"

# Each pane runs its own agent session
# Press 'm' to merge results back
```

## ワークフローパターン

### Pattern 1: Research + Implement

リサーチと実装を並列トラックに分割する。

```
Pane 1 (Research): "Research best practices for rate limiting in Node.js.
  Check current libraries, compare approaches, and write findings to
  /tmp/rate-limit-research.md"

Pane 2 (Implement): "Implement rate limiting middleware for our Express API.
  Start with a basic token bucket, we'll refine after research completes."

# After Pane 1 completes, merge findings into Pane 2's context
```

### Pattern 2: Multi-File Feature

独立ファイル単位で作業を並列化する。

```
Pane 1: "Create the database schema and migrations for the billing feature"
Pane 2: "Build the billing API endpoints in src/api/billing/"
Pane 3: "Create the billing dashboard UI components"

# Merge all, then do integration in main pane
```

### Pattern 3: Test + Fix Loop

一方でテスト実行、他方で修正を行う。

```
Pane 1 (Watcher): "Run the test suite in watch mode. When tests fail,
  summarize the failures."

Pane 2 (Fixer): "Fix failing tests based on the error output from pane 1"
```

### Pattern 4: Cross-Harness

異なる AI ツールをタスクごとに使い分ける。

```
Pane 1 (Claude Code): "Review the security of the auth module"
Pane 2 (Codex): "Refactor the utility functions for performance"
Pane 3 (Claude Code): "Write E2E tests for the checkout flow"
```

### Pattern 5: Code Review Pipeline

並列レビュー観点。

```
Pane 1: "Review src/api/ for security vulnerabilities"
Pane 2: "Review src/api/ for performance issues"
Pane 3: "Review src/api/ for test coverage gaps"

# Merge all reviews into a single report
```

## ベストプラクティス

1. **独立タスクのみ。** 互いの出力に依存するタスクは並列化しない。
2. **明確な境界。** 各ペインは異なるファイル/関心事を扱う。
3. **戦略的マージ。** 競合回避のためマージ前にペイン出力を確認する。
4. **git worktree を使う。** ファイル競合の起きやすい作業はペイン単位で worktree を分ける。
5. **リソース意識。** 各ペインは API トークンを消費する。総ペイン数は5〜6以下に保つ。

## Git Worktree 統合

ファイル重複のあるタスクで。

```bash
# Create worktrees for isolation
git worktree add -b feat/auth ../feature-auth HEAD
git worktree add -b feat/billing ../feature-billing HEAD

# Run agents in separate worktrees
# Pane 1: cd ../feature-auth && claude
# Pane 2: cd ../feature-billing && claude

# Merge branches when done
git merge feat/auth
git merge feat/billing
```

## 補完ツール

| ツール | 機能 | 用途 |
|------|-------------|-------------|
| **dmux** | エージェント用 tmux ペイン管理 | 並列エージェントセッション |
| **Superset** | 10以上の並列エージェント向けターミナル IDE | 大規模オーケストレーション |
| **Claude Code Task tool** | プロセス内サブエージェント生成 | セッション内のプログラム的並列化 |
| **Codex multi-agent** | 組み込みエージェントロール | Codex 固有の並列作業 |

## ECC ヘルパー

ECC には別個の git worktree を用いた外部 tmux ペインオーケストレーション用ヘルパーが同梱されている。

```bash
node scripts/orchestrate-worktrees.js plan.json --execute
```

`plan.json` 例:

```json
{
  "sessionName": "skill-audit",
  "baseRef": "HEAD",
  "launcherCommand": "codex exec --cwd {worktree_path} --task-file {task_file}",
  "workers": [
    { "name": "docs-a", "task": "Fix skills 1-4 and write handoff notes." },
    { "name": "docs-b", "task": "Fix skills 5-8 and write handoff notes." }
  ]
}
```

このヘルパーは:
- ワーカー単位のブランチバック git worktree を作成
- 主チェックアウトから選択 `seedPaths` を各ワーカー worktree に重ねる（オプション）
- ワーカーごとの `task.md`、`handoff.md`、`status.md` を `.orchestration/<session>/` 配下に書き出す
- ワーカー数ぶんのペインを持つ tmux セッションを開始
- 各ワーカーコマンドを自ペインで起動
- メインペインはオーケストレータ用に空けておく

ワーカーが `HEAD` に未含有のローカルファイル（オーケストレーションスクリプト・ドラフト計画・ドキュメントなど）にアクセスする必要があるときは `seedPaths` を使う。

```json
{
  "sessionName": "workflow-e2e",
  "seedPaths": [
    "scripts/orchestrate-worktrees.js",
    "scripts/lib/tmux-worktree-orchestrator.js",
    ".claude/plan/workflow-e2e-test.json"
  ],
  "launcherCommand": "bash {repo_root}/scripts/orchestrate-codex-worker.sh {task_file} {handoff_file} {status_file}",
  "workers": [
    { "name": "seed-check", "task": "Verify seeded files are present before starting work." }
  ]
}
```

## トラブルシューティング

- **ペインが反応しない:** ペインへ直接切り替えるか、`tmux capture-pane -pt <session>:0.<pane-index>` で内容を確認する。
- **マージ競合:** git worktree でペインごとにファイル変更を隔離する。
- **トークン消費過多:** 並列ペイン数を減らす。各ペインはフルエージェントセッションである。
- **tmux not found:** `brew install tmux` (macOS) または `apt install tmux` (Linux) でインストール。

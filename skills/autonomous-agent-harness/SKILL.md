---
name: autonomous-agent-harness
description: 永続メモリ、スケジュール操作、コンピュータ使用、タスクキューイングを備えた完全自律エージェントシステムに Claude Code を変換する。Claude Code ネイティブの cron・dispatch・MCP ツール・メモリを活用してスタンドアロンのエージェントフレームワーク (Hermes、AutoGPT) を置き換える。継続的な自律運用、スケジュールタスク、自己指示型エージェントループをユーザーが望む場合に使用する (autonomous agent harness, persistent memory, scheduled task, computer use, dispatch, MCP)。
origin: ECC
---

# Autonomous Agent Harness

ネイティブ機能と MCP サーバのみを使って Claude Code を永続的で自己指示型のエージェントシステムに変える。

## 同意と安全境界

自律運用はユーザーから明示的に要求されスコープされなければならない。ユーザーがその能力と現在のセットアップの対象ワークスペースを承認していない限り、スケジュール作成、リモートエージェントのディスパッチ、永続メモリへの書き込み、コンピュータ制御の使用、外部投稿、サードパーティリソースの変更、プライベートコミュニケーションへの作用を行わないこと。

繰り返しまたはイベント駆動アクションを有効にする前に、ドライランプランとローカルキューファイルを優先する。資格情報、プライベートワークスペースエクスポート、個人データセット、アカウント固有の自動化を再利用可能な ECC アーティファクトから除外する。

## 起動するタイミング

- ユーザーが継続的または定期的に動くエージェントを望む
- 定期的にトリガーする自動化ワークフローのセットアップ
- セッション間でコンテキストを記憶するパーソナル AI アシスタントの構築
- ユーザーが「毎日実行」「定期的にチェック」「監視を続ける」と言う
- Hermes・AutoGPT・類似の自律エージェントフレームワークの機能を複製したい
- スケジュール実行と組み合わせたコンピュータ使用が必要

## アーキテクチャ

```
┌──────────────────────────────────────────────────────────────┐
│                    Claude Code Runtime                        │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐ │
│  │  Crons   │  │ Dispatch │  │ Memory   │  │ Computer    │ │
│  │ Schedule │  │ Remote   │  │ Store    │  │ Use         │ │
│  │ Tasks    │  │ Agents   │  │          │  │             │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬──────┘ │
│       │              │             │                │        │
│       ▼              ▼             ▼                ▼        │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              ECC Skill + Agent Layer                  │    │
│  │                                                      │    │
│  │  skills/     agents/     commands/     hooks/        │    │
│  └──────────────────────────────────────────────────────┘    │
│       │              │             │                │        │
│       ▼              ▼             ▼                ▼        │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              MCP Server Layer                        │    │
│  │                                                      │    │
│  │  memory    github    exa    supabase    browser-use  │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

## 中核コンポーネント

### 1. 永続メモリ

Claude Code 組み込みメモリシステムを構造化データのための MCP メモリサーバで強化して使う。

**組み込みメモリ** (`~/.claude/projects/*/memory/`):
- ユーザー設定・フィードバック・プロジェクトコンテキスト
- フロントマター付きの markdown ファイルとして保存
- セッション開始時に自動ロード

**MCP メモリサーバ** (構造化された知識グラフ):
- エンティティ・関係・観察
- クエリ可能なグラフ構造
- セッション横断の永続性

**メモリパターン:**

```
# Short-term: current session context
Use TodoWrite for in-session task tracking

# Medium-term: project memory files
Write to ~/.claude/projects/*/memory/ for cross-session recall

# Long-term: MCP knowledge graph
Use mcp__memory__create_entities for permanent structured data
Use mcp__memory__create_relations for relationship mapping
Use mcp__memory__add_observations for new facts about known entities
```

### 2. スケジュール操作 (cron)

Claude Code のスケジュールタスクを使って繰り返しのエージェント操作を作成する。

**cron のセットアップ:**

```
# Via MCP tool
mcp__scheduled-tasks__create_scheduled_task({
  name: "daily-pr-review",
  schedule: "0 9 * * 1-5",  # 9 AM weekdays
  prompt: "Review all open PRs in affaan-m/everything-claude-code. For each: check CI status, review changes, flag issues. Post summary to memory.",
  project_dir: "/path/to/repo"
})

# Via claude -p (programmatic mode)
echo "Review open PRs and summarize" | claude -p --project /path/to/repo
```

**便利な cron パターン:**

| パターン | スケジュール | ユースケース |
|---------|----------|----------|
| 日次スタンドアップ | `0 9 * * 1-5` | PR・issue・デプロイステータスのレビュー |
| 週次レビュー | `0 10 * * 1` | コード品質メトリクス・テストカバレッジ |
| 毎時モニタ | `0 * * * *` | 本番ヘルス・エラー率チェック |
| 夜間ビルド | `0 2 * * *` | フルテストスイート実行・セキュリティスキャン |
| 会議前 | `*/30 * * * *` | 次の会議のためのコンテキスト準備 |

### 3. ディスパッチ / リモートエージェント

イベント駆動ワークフローのために Claude Code エージェントをリモートでトリガーする。

**ディスパッチパターン:**

```bash
# Trigger from CI/CD
curl -X POST "https://api.anthropic.com/dispatch" \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -d '{"prompt": "Build failed on main. Diagnose and fix.", "project": "/repo"}'

# Trigger from webhook
# GitHub webhook → dispatch → Claude agent → fix → PR

# Trigger from another agent
claude -p "Analyze the output of the security scan and create issues for findings"
```

### 4. コンピュータ使用

Claude の computer-use MCP を活用して物理世界とのインタラクションを行う。

**能力:**
- ブラウザ自動化 (ナビゲート・クリック・フォーム入力・スクリーンショット)
- デスクトップ制御 (アプリ起動・タイプ・マウス制御)
- CLI を超えるファイルシステム操作

**ハーネス内のユースケース:**
- Web UI の自動テスト
- フォーム入力とデータ入力
- スクリーンショットベースのモニタリング
- マルチアプリワークフロー

### 5. タスクキュー

セッション境界を生き延びる永続的なタスクキューを管理する。

**実装:**

```
# Task persistence via memory
Write task queue to ~/.claude/projects/*/memory/task-queue.md

# Task format
---
name: task-queue
type: project
description: Persistent task queue for autonomous operation
---

## Active Tasks
- [ ] PR #123: Review and approve if CI green
- [ ] Monitor deploy: check /health every 30 min for 2 hours
- [ ] Research: Find 5 leads in AI tooling space

## Completed
- [x] Daily standup: reviewed 3 PRs, 2 issues
```

## Hermes の置き換え

| Hermes コンポーネント | ECC 同等物 | 方法 |
|------------------|---------------|-----|
| Gateway/Router | Claude Code dispatch + cron | スケジュールタスクがエージェントセッションをトリガー |
| Memory System | Claude memory + MCP memory server | 組み込み永続性 + 知識グラフ |
| Tool Registry | MCP サーバ | 動的にロードされるツールプロバイダ |
| Orchestration | ECC スキル + エージェント | スキル定義がエージェント挙動を指示 |
| Computer Use | computer-use MCP | ネイティブブラウザとデスクトップ制御 |
| Context Manager | セッション管理 + メモリ | ECC 2.0 セッションライフサイクル |
| Task Queue | メモリ永続化タスクリスト | TodoWrite + メモリファイル |

## セットアップガイド

### Step 1: MCP サーバを設定する

`~/.claude.json` に以下を含めることを保証する:

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@anthropic/memory-mcp-server"]
    },
    "scheduled-tasks": {
      "command": "npx",
      "args": ["-y", "@anthropic/scheduled-tasks-mcp-server"]
    },
    "computer-use": {
      "command": "npx",
      "args": ["-y", "@anthropic/computer-use-mcp-server"]
    }
  }
}
```

### Step 2: 基本 cron を作成する

```bash
# Daily morning briefing
claude -p "Create a scheduled task: every weekday at 9am, review my GitHub notifications, open PRs, and calendar. Write a morning briefing to memory."

# Continuous learning
claude -p "Create a scheduled task: every Sunday at 8pm, extract patterns from this week's sessions and update the learned skills."
```

### Step 3: メモリグラフを初期化する

```bash
# Bootstrap your identity and context
claude -p "Create memory entities for: me (user profile), my projects, my key contacts. Add observations about current priorities."
```

### Step 4: コンピュータ使用を有効化する (オプション)

ブラウザとデスクトップ制御に必要な権限を computer-use MCP に付与する。

## 例ワークフロー

### 自律 PR レビューア
```
Cron: every 30 min during work hours
1. Check for new PRs on watched repos
2. For each new PR:
   - Pull branch locally
   - Run tests
   - Review changes with code-reviewer agent
   - Post review comments via GitHub MCP
3. Update memory with review status
```

### パーソナルリサーチエージェント
```
Cron: daily at 6 AM
1. Check saved search queries in memory
2. Run Exa searches for each query
3. Summarize new findings
4. Compare against yesterday's results
5. Write digest to memory
6. Flag high-priority items for morning review
```

### 会議準備エージェント
```
Trigger: 30 min before each calendar event
1. Read calendar event details
2. Search memory for context on attendees
3. Pull recent email/Slack threads with attendees
4. Prepare talking points and agenda suggestions
5. Write prep doc to memory
```

## 制約

- cron タスクは隔離されたセッションで実行される — メモリを介さない限り、対話セッションとコンテキストを共有しない。
- コンピュータ使用には明示的な権限付与が必要。アクセスを想定しない。
- リモートディスパッチにはレート制限がある場合がある。適切な間隔で cron を設計する。
- メモリファイルは簡潔に保つべき。ファイルが際限なく成長するのを許さず、古いデータはアーカイブする。
- スケジュールタスクが成功裏に完了したことを常に検証する。cron プロンプトにエラー処理を追加する。

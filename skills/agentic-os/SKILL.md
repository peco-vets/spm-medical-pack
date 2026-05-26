---
name: agentic-os
description: Claude Code 上に永続的なマルチエージェントオペレーティングシステムを構築する。カーネルアーキテクチャ、専門エージェント、スラッシュコマンド、ファイルベースのメモリ、スケジュール自動化、外部 DB を使わない状態管理を扱う (agentic OS, multi-agent, persistent runtime, kernel, specialist agents, slash commands, file-based memory, scheduled automation)。
origin: ECC
---

# Agentic OS

Claude Code をチャットセッションではなく永続ランタイム / オペレーティングシステムとして扱う。このスキルは本番のエージェンティックセットアップで使われるアーキテクチャを成文化する: タスクを専門エージェントにルーティングするカーネル設定、永続的なファイルベースメモリ、スケジュール自動化、JSON/markdown データ層。

## 起動するタイミング

- Claude Code 内でマルチエージェントワークフローを構築する時
- セッション再起動を生き延びる永続的な Claude Code 自動化をセットアップする時
- 繰り返しタスクのための「個人 OS」または「エージェンティック OS」を作る時
- ユーザーが「agentic OS」「personal OS」「multi-agent」「agent coordinator」「persistent agent」と言う時
- セッションをまたいで文脈を残す必要のある長期実行プロジェクトを構造化する時

## アーキテクチャ概要

Agentic OS は 4 層からなる。各層はプロジェクトルートのディレクトリである。

```
project-root/
├── CLAUDE.md          # Kernel: identity, routing rules, agent registry
├── agents/            # Specialist agent definitions (markdown prompts)
├── .claude/commands/  # Slash commands: user-facing CLI
├── scripts/           # Daemon scripts: scheduled or event-driven tasks
└── data/              # State: JSON/markdown filesystem, no external DB
```

### 層の責務

| 層 | 用途 | 永続性 |
|---|---|---|
| Kernel (`CLAUDE.md`) | アイデンティティ・ルーティング・モデルポリシー・エージェントレジストリ | Git 管理 |
| Agents (`agents/`) | スコープ付きツールとメモリを持つ専門アイデンティティ | Git 管理 |
| Commands (`.claude/commands/`) | ユーザー向けスラッシュコマンド (`/daily-sync`・`/outreach`) | Git 管理 |
| Scripts (`scripts/`) | cron または webhook によりトリガーされる Python/JS デーモン | Git 管理 |
| State (`data/`) | 追記専用ログ・プロジェクト状態・意思決定記録 | Git 無視または管理 |

## カーネル

`CLAUDE.md` がカーネルである。COO / オーケストレーターとして機能する。Claude はセッション開始時にこれを読み、作業のルーティングに使う。

### カーネル構造

```markdown
# CLAUDE.md - Agentic OS Kernel

## Identity
You are the COO of [project-name]. You route tasks to specialist agents.
You never write code directly. You delegate to the right agent and synthesize results.

## Agent Registry

| Agent | Role | Trigger |
|---|---|---|
| @dev | Code, architecture, debugging | User says "build", "fix", "refactor" |
| @writer | Documentation, content, emails | User says "write", "draft", "blog" |
| @researcher | Research, analysis, fact-checking | User says "research", "analyze", "compare" |
| @ops | DevOps, deployment, infrastructure | User says "deploy", "CI", "server" |

## Routing Rules
1. Parse the user request for intent keywords
2. Match to the Agent Registry trigger column
3. Load the corresponding agent file from `agents/<name>.md`
4. Hand off execution with full context
5. Synthesize and present the result back to the user

## Model Policies
- Default model: use the repository or harness default.
- @dev tasks: prefer a higher-reasoning model for complex architecture.
- @researcher tasks: use the configured research-capable model and approved search tools.
- Cost ceiling: warn before exceeding the project's configured spend threshold.
```

### 重要原則

カーネルは **小さく宣言的に** すべきである。ルーティングロジックはコードではなくプレーンな markdown テーブルに置く。これによりシステムが検査可能・編集可能になり、デバッグの必要がなくなる。

## 専門エージェント

各エージェントは `agents/` 内のスタンドアロンな markdown ファイルである。Claude はタスクをルーティングする際に関連するエージェントファイルをロードする。

### エージェント定義フォーマット

```markdown
# @dev - Software Engineer

## Identity
You are a senior software engineer. You write clean, tested, production-grade code.
You prefer simple solutions. You ask clarifying questions when requirements are ambiguous.

## Memory Scope
- Read `data/projects/<current-project>.md` for context
- Read `data/decisions/` for architectural decisions
- Append execution logs to `data/logs/<date>-@dev.md`

## Tool Access
- Full filesystem access within project root
- Git operations (status, diff, commit, branch)
- Test runner access
- MCP servers as configured in `.claude/mcp.json`

## Constraints
- Always write tests for new features
- Never commit directly to `main`; use feature branches
- Prefer editing existing files over creating new ones
- Keep functions under 50 lines when possible
```

### マルチエージェント協調パターン

タスクが複数のエージェントにまたがるとき、カーネルはそれらを順次または並列に実行する:

```
User: "Build a landing page and write the launch blog post"

Kernel routing:
1. @dev - "Build a landing page with [requirements]"
2. @writer - "Write a launch blog post for [product] using the landing page copy"
3. Kernel synthesizes both outputs into a unified response
```

並列実行には、Claude Code のバックグラウンドタスク機能や特定のエージェントコンテキストで Claude Code を起動するシェルスクリプトを使う。

## コマンドとデイリーワークフロー

スラッシュコマンドは `.claude/commands/` 内の markdown ファイルである。再利用可能なワークフローを定義する。

### コマンド構造

```markdown
# /daily-sync

Run the morning briefing:

1. Read `data/logs/last-sync.md` for context
2. Check project status: `git status`, pending PRs, CI health
3. Review `data/inbox/` for new tasks or decisions needed
4. Generate a summary of blockers, priorities, and next actions
5. Append the briefing to `data/logs/daily/<date>.md`
```

### 標準コマンドセット

| コマンド | 用途 |
|---|---|
| `/daily-sync` | 朝のブリーフィング: ステータス・ブロッカー・優先順位 |
| `/outreach` | アウトリーチワークフローの実行 (メール・LinkedIn 等) |
| `/research <topic>` | 引用追跡付きの深いリサーチ |
| `/apply-jobs` | 対象ロール向けに履歴書 + カバーレターを最適化 |
| `/analytics` | Stripe・GitHub・カスタムソースからメトリクスを取得 |
| `/interview-prep` | フラッシュカードやモック面接質問を生成 |
| `/decision <topic>` | 賛否と選択経路を含む意思決定をログ |

### コマンドの有効化

コマンドファイルを `.claude/commands/<command-name>.md` に配置する。Claude Code が自動検出する。ユーザーは `/<command-name>` で呼び出す。

## 永続メモリ

メモリはファイルベースである。ベクトル DB なし、Redis なし、PostgreSQL なし。`data/` 内の JSON と markdown ファイルがデータベースである。

### メモリディレクトリ構造

```
data/
├── daily-logs/         # Append-only daily activity logs
├── projects/           # Per-project context files
├── decisions/          # Architectural and business decisions (ADR format)
├── inbox/              # New tasks or ideas awaiting triage
├── contacts/           # People, companies, relationship notes
└── templates/          # Reusable prompts and formats
```

### デイリーログフォーマット

```markdown
# 2026-04-22 - Daily Log

## Sessions
- 09:00 - Session 1: Refactored auth module (@dev)
- 11:30 - Session 2: Drafted investor update (@writer)

## Decisions
- Switched from JWT to session cookies (see `data/decisions/2026-04-22-auth.md`)

## Blockers
- Waiting on API key from vendor (follow up 2026-04-24)

## Next Actions
- [ ] Merge auth refactor PR
- [ ] Send investor update for review
```

### 自動省察パターン

各セッションの終わりにカーネルは省察を追記する:

```markdown
## Reflection - Session 3
- What worked: Parallel agent execution saved 20 minutes
- What didn't: @researcher hit a paywalled source, need better source ranking
- What to change: Add `source-tier` field to research notes (A/B/C credibility)
```

これによりコード変更なしに時間とともにシステムを改善するフィードバックループが生まれる。

## スケジュール自動化

Agentic OS のタスクは Claude Code 組み込みの cron (セッション終了時に死ぬ) ではなく、外部 cron でスケジュールされる。

### macOS: LaunchAgent

```xml
<!-- ~/Library/LaunchAgents/com.agentic.daily-sync.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.agentic.daily-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/claude</string>
        <string>--cwd</string>
        <string>/path/to/project</string>
        <string>--command</string>
        <string>/daily-sync</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>8</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/agentic-daily-sync.log</string>
</dict>
</plist>
```

### Linux: systemd Timer

```ini
# ~/.config/systemd/user/agentic-daily-sync.service
[Unit]
Description=Agentic OS Daily Sync

[Service]
Type=oneshot
ExecStart=/usr/local/bin/claude --cwd /path/to/project --command /daily-sync
```

```ini
# ~/.config/systemd/user/agentic-daily-sync.timer
[Unit]
Description=Run daily sync every morning

[Timer]
OnCalendar=*-*-* 8:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

### クロスプラットフォーム: pm2

```bash
# ecosystem.config.js
module.exports = {
  apps: [{
    name: 'agentic-daily-sync',
    script: 'claude',
    args: '--cwd /path/to/project --command /daily-sync',
    cron_restart: '0 8 * * *',
    autorestart: false
  }]
};
```

## データ層

データ層はあなたのファイルシステムである。構造化データには JSON を、ナラティブコンテンツには markdown を使う。

### 構造化状態のための JSON

```json
// data/projects/website-v2.json
{
  "name": "Website v2",
  "status": "in-progress",
  "milestone": "beta-launch",
  "agents_involved": ["@dev", "@writer"],
  "files": {
    "spec": "docs/website-v2-spec.md",
    "design": "designs/website-v2.fig"
  },
  "metrics": {
    "commits": 47,
    "last_session": "2026-04-22T11:30:00Z"
  }
}
```

### ナラティブのための markdown

意思決定・ログ・リサーチノート・コンタクト記録など人間が読むものは markdown を使う。

### スキーマ進化

既存フィールドの名前を変更しない。新しいフィールドを追加し、古いものを deprecated とマークする:

```json
{
  "name": "Website v2",
  "status": "in-progress",
  "milestone": "beta-launch",
  "_deprecated_priority": "high",
  "priority_v2": { "level": "high", "rationale": "Blocks investor demo" }
}
```

これによりマイグレーションスクリプトなしに歴史データを可読に保てる。

## アンチパターン

### モノリシックな単一エージェント

```markdown
# BAD - One agent does everything
You are a full-stack developer, writer, researcher, and DevOps engineer.
```

専門エージェントに分割する。カーネルがルーティングを処理する。

### ステートレスセッション

```markdown
# BAD - No memory between sessions
Starting fresh every time Claude Code opens.
```

常にセッション開始時に `data/` を読み、セッション終了時に書き戻す。

### ハードコードされた認証情報

```markdown
# BAD - API keys in agent files or CLAUDE.md
Your OpenAI API key is sk-xxxxxxxx
```

環境変数またはスクリプトがロードする `.env` ファイルを使う。エージェントは `process.env.API_KEY` を参照する。

### シンプルな状態のための外部データベース

```markdown
# BAD - PostgreSQL for a solo user's agentic OS
```

複数同時ユーザーや GB 級データになるまでは JSON/markdown ファイルを使う。

### 過剰に設計されたルーティング

```markdown
# BAD - Routing logic in code instead of markdown tables
if (intent.includes('deploy')) { agent = opsAgent; }
```

`CLAUDE.md` の markdown テーブルでルーティングを宣言的に保つ。検査可能・編集可能・デバッグ可能である。

## ベストプラクティス

- [ ] `CLAUDE.md` は 200 行未満でコンテキストウィンドウに収まる
- [ ] 各エージェントファイルは 100 行未満で 1 つのドメインに焦点を絞る
- [ ] `data/` はセンシティブログには git 無視、意思決定や仕様には git 管理
- [ ] コマンドは命令形の名前を使う: `/daily-sync` であって `/run-daily-sync` ではない
- [ ] ログは追記専用。過去のデイリーログを編集しない
- [ ] すべてのエージェントは読むファイルを定義する `Memory Scope` セクションを持つ
- [ ] 各セッションの最後に省察を書く
- [ ] スケジュールタスクは Claude Code のセッション cron ではなく外部 cron (LaunchAgent・systemd・pm2) を使う
- [ ] コスト追跡: セッション当たりの API 支出を `data/logs/<date>-costs.json` にログ
- [ ] 1 プロジェクト = 1 Agentic OS。無関係なプロジェクトで単一の `CLAUDE.md` を共有しないこと。

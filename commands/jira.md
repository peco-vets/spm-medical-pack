---
description: Jira チケットを取得し、要件を分析し、ステータスを更新し、またはコメントを追加する。jira-integration スキルおよび MCP または REST API を使用する / Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.
---

# Jira Command

ワークフローから直接 Jira チケットとやり取りする — チケット取得、要件分析、コメント追加、ステータス遷移を行う。

## Usage

```
/jira get <TICKET-KEY>          # Fetch and analyze a ticket
/jira comment <TICKET-KEY>      # Add a progress comment
/jira transition <TICKET-KEY>   # Change ticket status
/jira search <JQL>              # Search issues with JQL
```

## このコマンドが行うこと

1. **取得と分析** — Jira チケットを取得し、要件、受け入れ基準、テストシナリオ、依存関係を抽出する
2. **コメント** — チケットに構造化された進捗更新を追加する
3. **遷移** — チケットをワークフロー状態間で移動する（To Do → In Progress → Done）
4. **検索** — JQL クエリで issue を見つける

## 動作方法

### `/jira get <TICKET-KEY>`

1. Jira からチケットを取得する（MCP の `jira_get_issue` または REST API 経由）
2. すべてのフィールドを抽出する：summary、description、受け入れ基準、優先度、ラベル、リンクされた issue
3. 追加コンテキストのため、必要に応じてコメントを取得する
4. 構造化分析を生成する：

```
Ticket: PROJ-1234
Summary: [title]
Status: [status]
Priority: [priority]
Type: [Story/Bug/Task]

Requirements:
1. [extracted requirement]
2. [extracted requirement]

Acceptance Criteria:
- [ ] [criterion from ticket]

Test Scenarios:
- Happy Path: [description]
- Error Case: [description]
- Edge Case: [description]

Dependencies:
- [linked issues, APIs, services]

Recommended Next Steps:
- /plan to create implementation plan
- `tdd-workflow` skill to implement with tests first
```

### `/jira comment <TICKET-KEY>`

1. 現在のセッションの進捗を要約する（構築されたもの、テストされたもの、コミットされたもの）
2. 構造化コメントとしてフォーマットする
3. Jira チケットに投稿する

### `/jira transition <TICKET-KEY>`

1. チケットの利用可能な遷移を取得する
2. ユーザーにオプションを表示する
3. 選択された遷移を実行する

### `/jira search <JQL>`

1. Jira に対して JQL クエリを実行する
2. マッチした issue のサマリーテーブルを返す

## 前提条件

このコマンドは Jira 認証情報を必要とする。以下のいずれかを選択する：

**Option A — MCP Server（推奨）：**
`mcpServers` 設定に `jira` を追加する（テンプレートは `mcp-configs/mcp-servers.json` を参照）。

**Option B — 環境変数：**
```bash
export JIRA_URL="https://yourorg.atlassian.net"
export JIRA_EMAIL="your.email@example.com"
export JIRA_API_TOKEN="your-api-token"
```

認証情報が不足している場合、停止してユーザーにセットアップを案内する。

## 他のコマンドとの統合

チケット分析後：
- 要件から実装計画を作成するために `/plan` を使う
- テスト駆動開発で実装するために `tdd-workflow` スキルを使う
- 実装後に `/code-review` を使う
- 進捗をチケットに戻すために `/jira comment` を使う
- 作業完了時にチケットを移動するために `/jira transition` を使う

## 関連

- **Skill:** `skills/jira-integration/`
- **MCP config:** `mcp-configs/mcp-servers.json` → `jira`

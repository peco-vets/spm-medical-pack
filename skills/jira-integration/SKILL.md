---
name: jira-integration
description: Jira チケットの取得、要件分析、ステータス更新、コメント追加、課題遷移を行う際に使用するスキル。MCP または直接 REST 呼び出しによる Jira API パターンを提供する (retrieving Jira tickets, analyzing requirements, updating ticket status, adding comments, transitioning issues; Jira API patterns via MCP or direct REST calls)。
origin: ECC
---

# Jira 連携スキル

AI コーディングワークフローから直接 Jira チケットを取得、分析、更新する。**MCP ベース** (推奨) と **直接 REST API** の両方のアプローチをサポートする。

## 起動するタイミング

- 要件を理解するために Jira チケットを取得する場合
- チケットからテスト可能な受け入れ基準を抽出する場合
- Jira 課題に進捗コメントを追加する場合
- チケットのステータスを遷移する場合 (To Do → In Progress → Done)
- マージリクエストやブランチを Jira 課題にリンクする場合
- JQL クエリで課題を検索する場合

## 前提条件

### オプション A: MCP サーバー (推奨)

`mcp-atlassian` MCP サーバーをインストールする。これにより AI エージェントに Jira ツールが直接公開される。

**要件:**
- Python 3.10+
- `uvx` (`uv` から提供)、パッケージマネージャーまたは公式の `uv` インストールドキュメント経由でインストール

**MCP 設定に追加** (例: `~/.claude.json` → `mcpServers`):

```json
{
  "jira": {
    "command": "uvx",
    "args": ["mcp-atlassian==0.21.0"],
    "env": {
      "JIRA_URL": "https://YOUR_ORG.atlassian.net",
      "JIRA_EMAIL": "your.email@example.com",
      "JIRA_API_TOKEN": "your-api-token"
    },
    "description": "Jira issue tracking — search, create, update, comment, transition"
  }
}
```

> **セキュリティ:** シークレットをハードコードしないこと。`JIRA_URL`、`JIRA_EMAIL`、`JIRA_API_TOKEN` はシステム環境変数 (またはシークレットマネージャー) に設定することを推奨する。MCP の `env` ブロックはローカルで未コミットの設定ファイルのみで使用すること。

**Jira API トークンの取得方法:**
1. <https://id.atlassian.com/manage-profile/security/api-tokens> にアクセス
2. **Create API token** をクリック
3. トークンをコピー — 環境変数に保存し、ソースコードには絶対に保存しない

### オプション B: 直接 REST API

MCP が利用できない場合は、`curl` またはヘルパースクリプト経由で Jira REST API v3 を直接使用する。

**必要な環境変数:**

| 変数 | 説明 |
|----------|-------------|
| `JIRA_URL` | Jira インスタンス URL (例: `https://yourorg.atlassian.net`) |
| `JIRA_EMAIL` | Atlassian アカウントのメールアドレス |
| `JIRA_API_TOKEN` | id.atlassian.com で取得した API トークン |

これらはシェル環境、シークレットマネージャー、または追跡されていないローカル env ファイルに保存する。リポジトリにコミットしないこと。

## MCP ツールリファレンス

`mcp-atlassian` MCP サーバーが設定されている場合、以下のツールが利用可能である。

| ツール | 用途 | 例 |
|------|---------|---------|
| `jira_search` | JQL クエリ | `project = PROJ AND status = "In Progress"` |
| `jira_get_issue` | キーで完全な課題詳細を取得 | `PROJ-1234` |
| `jira_create_issue` | 課題を作成 (Task、Bug、Story、Epic) | 新規バグレポート |
| `jira_update_issue` | フィールド更新 (要約、説明、担当者) | 担当者の変更 |
| `jira_transition_issue` | ステータス変更 | "In Review" へ移動 |
| `jira_add_comment` | コメント追加 | 進捗更新 |
| `jira_get_sprint_issues` | スプリント内の課題一覧 | アクティブスプリントレビュー |
| `jira_create_issue_link` | 課題のリンク (Blocks、Relates to) | 依存関係追跡 |
| `jira_get_issue_development_info` | リンクされた PR、ブランチ、コミットを表示 | 開発コンテキスト |

> **ヒント:** 遷移する前に必ず `jira_get_transitions` を呼び出すこと — 遷移 ID はプロジェクトのワークフローごとに異なる。

## 直接 REST API リファレンス

### チケットを取得

```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/PROJ-1234" | jq '{
    key: .key,
    summary: .fields.summary,
    status: .fields.status.name,
    priority: .fields.priority.name,
    type: .fields.issuetype.name,
    assignee: .fields.assignee.displayName,
    labels: .fields.labels,
    description: .fields.description
  }'
```

### コメントを取得

```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/PROJ-1234?fields=comment" | jq '.fields.comment.comments[] | {
    author: .author.displayName,
    created: .created[:10],
    body: .body
  }'
```

### コメントを追加

```bash
curl -s -X POST -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "body": {
      "version": 1,
      "type": "doc",
      "content": [{
        "type": "paragraph",
        "content": [{"type": "text", "text": "Your comment here"}]
      }]
    }
  }' \
  "$JIRA_URL/rest/api/3/issue/PROJ-1234/comment"
```

### チケットを遷移

```bash
# 1. Get available transitions
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/issue/PROJ-1234/transitions" | jq '.transitions[] | {id, name: .name}'

# 2. Execute transition (replace TRANSITION_ID)
curl -s -X POST -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"transition": {"id": "TRANSITION_ID"}}' \
  "$JIRA_URL/rest/api/3/issue/PROJ-1234/transitions"
```

### JQL で検索

```bash
curl -s -G -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  --data-urlencode "jql=project = PROJ AND status = 'In Progress'" \
  "$JIRA_URL/rest/api/3/search"
```

## チケットの分析

開発やテスト自動化のためにチケットを取得する際には、以下を抽出する。

### 1. テスト可能な要件
- **機能要件** — 機能の動作
- **受け入れ基準** — 満たすべき条件
- **テスト可能な振る舞い** — 特定のアクションと期待される結果
- **ユーザーロール** — 機能の利用者と権限
- **データ要件** — 必要なデータ
- **統合ポイント** — 関与する API、サービス、システム

### 2. 必要なテストタイプ
- **ユニットテスト** — 個々の関数とユーティリティ
- **統合テスト** — API エンドポイントとサービス連携
- **E2E テスト** — ユーザー向け UI フロー
- **API テスト** — エンドポイント契約とエラー処理

### 3. エッジケースとエラーシナリオ
- 無効な入力 (空、長すぎる、特殊文字)
- 認証されていないアクセス
- ネットワーク障害やタイムアウト
- 並行ユーザーや競合状態
- 境界条件
- 欠落または null データ
- 状態遷移 (戻る操作、リロードなど)

### 4. 構造化された分析出力

```
Ticket: PROJ-1234
Summary: [ticket title]
Status: [current status]
Priority: [High/Medium/Low]
Test Types: Unit, Integration, E2E

Requirements:
1. [requirement 1]
2. [requirement 2]

Acceptance Criteria:
- [ ] [criterion 1]
- [ ] [criterion 2]

Test Scenarios:
- Happy Path: [description]
- Error Case: [description]
- Edge Case: [description]

Test Data Needed:
- [data item 1]
- [data item 2]

Dependencies:
- [dependency 1]
- [dependency 2]
```

## チケットの更新

### 更新するタイミング

| ワークフローステップ | Jira 更新 |
|---|---|
| 作業開始 | "In Progress" へ遷移 |
| テスト作成 | テストカバレッジサマリーをコメント |
| ブランチ作成 | ブランチ名をコメント |
| PR/MR 作成 | リンク付きでコメント、課題をリンク |
| テスト通過 | 結果サマリーをコメント |
| PR/MR マージ | "Done" または "In Review" へ遷移 |

### コメントテンプレート

**作業開始:**
```
Starting implementation for this ticket.
Branch: feat/PROJ-1234-feature-name
```

**テスト実装完了:**
```
Automated tests implemented:

Unit Tests:
- [test file 1] — [what it covers]
- [test file 2] — [what it covers]

Integration Tests:
- [test file] — [endpoints/flows covered]

All tests passing locally. Coverage: XX%
```

**PR 作成:**
```
Pull request created:
[PR Title](https://github.com/org/repo/pull/XXX)

Ready for review.
```

**作業完了:**
```
Implementation complete.

PR merged: [link]
Test results: All passing (X/Y)
Coverage: XX%
```

## セキュリティガイドライン

- ソースコードやスキルファイルに Jira API トークンを**絶対にハードコードしない**
- 環境変数またはシークレットマネージャーを**必ず使用する**
- 全プロジェクトで `.env` を `.gitignore` に**追加する**
- git 履歴に露出した場合は直ちに**トークンをローテーション**する
- 必要なプロジェクトにスコープを絞った**最小権限**の API トークンを使用する
- API 呼び出し前に認証情報が設定されていることを**検証**し、明確なメッセージでフェイルファストする

## トラブルシューティング

| エラー | 原因 | 対処 |
|---|---|---|
| `401 Unauthorized` | 無効または期限切れの API トークン | id.atlassian.com で再生成 |
| `403 Forbidden` | トークンにプロジェクト権限がない | トークンのスコープとプロジェクトアクセスを確認 |
| `404 Not Found` | チケットキーまたはベース URL の誤り | `JIRA_URL` とチケットキーを確認 |
| `spawn uvx ENOENT` | IDE が PATH 上の `uvx` を見つけられない | フルパス使用 (例: `~/.local/bin/uvx`) または `~/.zprofile` で PATH を設定 |
| 接続タイムアウト | ネットワーク/VPN の問題 | VPN 接続とファイアウォールルールを確認 |

## ベストプラクティス

- 最後にまとめてではなく、作業中に Jira を更新する
- コメントは簡潔だが情報豊富にする
- コピーではなくリンク — PR、テストレポート、ダッシュボードを指す
- 他者からの入力が必要な場合は @メンション を使用する
- 開始前にリンクされた課題を確認して機能の全体スコープを理解する
- 受け入れ基準が曖昧な場合は、コードを書く前に明確化を依頼する

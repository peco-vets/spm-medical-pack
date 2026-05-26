---
name: claude-devfleet
description: Claude DevFleet を介してマルチエージェントコーディングタスクをオーケストレートする — プロジェクトを計画し、隔離された worktree で並列エージェントをディスパッチし、進捗を監視し、構造化されたレポートを読む (Claude DevFleet, multi-agent, orchestration, parallel, worktree, MCP)。
origin: community
---

# Claude DevFleet マルチエージェントオーケストレーション

## 利用するタイミング

複数の Claude Code エージェントを並列にコーディングタスクで動かす必要があるときにこのスキルを使う。各エージェントはフルツーリング付きで隔離された git worktree で実行される。

MCP 経由で接続された Claude DevFleet の稼働インスタンスが必要:
```bash
claude mcp add devfleet --transport http http://localhost:18801/mcp
```

## 仕組み

```
User → "Build a REST API with auth and tests"
  ↓
plan_project(prompt) → project_id + mission DAG
  ↓
Show plan to user → get approval
  ↓
dispatch_mission(M1) → Agent 1 spawns in worktree
  ↓
M1 completes → auto-merge → auto-dispatch M2 (depends_on M1)
  ↓
M2 completes → auto-merge
  ↓
get_report(M2) → files_changed, what_done, errors, next_steps
  ↓
Report back to user
```

### ツール

| ツール | 用途 |
|------|---------|
| `plan_project(prompt)` | AI が記述を連鎖ミッション付きプロジェクトに分解 |
| `create_project(name, path?, description?)` | プロジェクトを手動作成、`project_id` を返す |
| `create_mission(project_id, title, prompt, depends_on?, auto_dispatch?)` | ミッションを追加。`depends_on` はミッション ID 文字列のリスト (例: `["abc-123"]`)。依存条件を満たしたとき自動開始するには `auto_dispatch=true` を設定。 |
| `dispatch_mission(mission_id, model?, max_turns?)` | ミッションでエージェントを開始 |
| `cancel_mission(mission_id)` | 実行中エージェントを停止 |
| `wait_for_mission(mission_id, timeout_seconds?)` | ミッション完了までブロック (下記注を参照) |
| `get_mission_status(mission_id)` | ブロックせずにミッション進捗をチェック |
| `get_report(mission_id)` | 構造化レポートを読む (変更ファイル・テスト済・エラー・次のステップ) |
| `get_dashboard()` | システム概要: 実行中エージェント・統計・最近のアクティビティ |
| `list_projects()` | すべてのプロジェクトをブラウズ |
| `list_missions(project_id, status?)` | プロジェクト内のミッションをリスト |

> **`wait_for_mission` の注:** これは会話を `timeout_seconds` (デフォルト 600) までブロックする。長時間実行ミッションでは、進捗更新がユーザーに見えるよう、代わりに `get_mission_status` で 30〜60 秒ごとにポーリングすることを優先する。

### ワークフロー: Plan → Dispatch → Monitor → Report

1. **Plan**: `plan_project(prompt="...")` を呼ぶ → `depends_on` チェーンと `auto_dispatch=true` 付きミッションのリストと `project_id` を返す。
2. **Show plan**: ミッションタイトル、タイプ、依存チェーンをユーザーに提示する。
3. **Dispatch**: ルートミッション (空の `depends_on`) で `dispatch_mission(mission_id=<first_mission_id>)` を呼ぶ。残りのミッションは依存が完了すると自動ディスパッチされる (`plan_project` がそれらに `auto_dispatch=true` を設定するため)。
4. **Monitor**: 進捗をチェックするために `get_mission_status(mission_id=...)` や `get_dashboard()` を呼ぶ。
5. **Report**: ミッション完了時に `get_report(mission_id=...)` を呼ぶ。ハイライトをユーザーと共有する。

### 並行性

DevFleet はデフォルトで最大 3 並行エージェントを実行する (`DEVFLEET_MAX_AGENTS` で設定可能)。すべてのスロットが埋まると、`auto_dispatch=true` のミッションはミッションウォッチャーにキューされ、スロットが空くと自動ディスパッチされる。現在のスロット使用状況は `get_dashboard()` でチェック。

## 例

### フル自動: 計画とローンチ

1. `plan_project(prompt="...")` → ミッションと依存付きのプランを表示。
2. 最初のミッション (空の `depends_on` を持つもの) をディスパッチする。
3. 残りのミッションは依存が解決すると自動ディスパッチされる (`auto_dispatch=true` を持つため)。
4. 何がローンチされたかユーザーが知るように、プロジェクト ID とミッション数で報告する。
5. すべてのミッションが終端状態 (`completed`・`failed`・`cancelled`) に達するまで `get_mission_status` または `get_dashboard()` で定期的にポールする。
6. 各終端ミッションについて `get_report(mission_id=...)` — 成功を要約し、エラーと次のステップとともに失敗を呼び出す。

### 手動: ステップバイステップ制御

1. `create_project(name="My Project")` → `project_id` を返す。
2. 最初の (ルート) ミッションに `create_mission(project_id=project_id, title="...", prompt="...", auto_dispatch=true)` → `root_mission_id` をキャプチャ。
   後続の各タスクに `create_mission(project_id=project_id, title="...", prompt="...", auto_dispatch=true, depends_on=["<root_mission_id>"])`。
3. 最初のミッションに `dispatch_mission(mission_id=...)` を呼びチェーンを開始する。
4. 完了時に `get_report(mission_id=...)`。

### レビュー付き順次

1. `create_project(name="...")` → `project_id` を取得。
2. `create_mission(project_id=project_id, title="Implement feature", prompt="...")` → `impl_mission_id` を取得。
3. `dispatch_mission(mission_id=impl_mission_id)`、次に完了まで `get_mission_status` でポール。
4. 結果をレビューするために `get_report(mission_id=impl_mission_id)`。
5. `create_mission(project_id=project_id, title="Review", prompt="...", depends_on=[impl_mission_id], auto_dispatch=true)` — 依存が既に満たされているため自動開始。

## ガイドライン

- ユーザーが進めると言わない限り、ディスパッチ前にプランを必ず確認する。
- ステータス報告時にミッションタイトルと ID を含める。
- ミッションが失敗したら、リトライ前にそのレポートを読む。
- バルクディスパッチ前にエージェントスロットの利用可能性を `get_dashboard()` でチェック。
- ミッション依存は DAG を形成する — 循環依存を作らない。
- 各エージェントは隔離された git worktree で実行され、完了時に自動マージする。マージ衝突が発生したら、変更はエージェントの worktree ブランチに残り手動解決される。
- ミッションを手動作成する際、依存完了時に自動トリガーしたいなら常に `auto_dispatch=true` を設定する。このフラグなしでは、ミッションは `draft` ステータスのままとなる。

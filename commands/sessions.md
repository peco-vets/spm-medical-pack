---
description: Claude Code のセッション履歴、エイリアス、セッションメタデータを管理する / Manage Claude Code session history, aliases, and session metadata.
---

# Sessions Command

Claude Code のセッション履歴を管理する - `~/.claude/session-data/` に保存され、レガシー読み込みは `~/.claude/sessions/` から行うセッションを一覧、ロード、エイリアス、編集する。

## Usage

`/sessions [list|load|alias|info|help] [options]`

## アクション

### Sessions の一覧

メタデータ、フィルタリング、ページネーションと共にすべてのセッションを表示する。

swarm のオペレーター surface コンテキストが必要なときは `/sessions info` を使う：ブランチ、worktree パス、セッションの最新性。

```bash
/sessions                              # List all sessions (default)
/sessions list                         # Same as above
/sessions list --limit 10              # Show 10 sessions
/sessions list --date 2026-02-01       # Filter by date
/sessions list --search abc            # Search by session ID
```

**Script:**（プラグインルートパスを解決し、session-manager と session-aliases モジュールを使ってセッションをリストアップする Node スクリプト）

### Session をロードする

セッションの内容を（ID またはエイリアスで）ロードして表示する。

```bash
/sessions load <id|alias>             # Load session
/sessions load 2026-02-01             # By date (for no-id sessions)
/sessions load a1b2c3d4               # By short ID
/sessions load my-alias               # By alias name
```

**Script:**（エイリアスを解決し、セッションを取得し、統計とメタデータを表示する Node スクリプト）

### エイリアスを作成する

セッションの覚えやすいエイリアスを作成する。

```bash
/sessions alias <id> <name>           # Create alias
/sessions alias 2026-02-01 today-work # Create alias named "today-work"
```

**Script:**（セッションファイル名を取得し、エイリアスを設定する Node スクリプト）

### エイリアスを削除する

既存のエイリアスを削除する。

```bash
/sessions alias --remove <name>        # Remove alias
/sessions unalias <name>               # Same as above
```

**Script:**（エイリアスを削除する Node スクリプト）

### Session 情報

セッションに関する詳細情報を表示する。

```bash
/sessions info <id|alias>              # Show session details
```

**Script:**（セッション情報、統計、メタデータ、エイリアスを表示する Node スクリプト）

### Aliases の一覧

すべてのセッションエイリアスを表示する。

```bash
/sessions aliases                      # List all aliases
```

**Script:**（すべてのエイリアスをリストアップする Node スクリプト）

## オペレーターノート

- セッションファイルは `Project`、`Branch`、`Worktree` をヘッダに永続化するため、`/sessions info` は並列の tmux/worktree 実行を区別できる。
- コマンドセンタースタイルの監視には、`/sessions info`、`git diff --stat`、`scripts/hooks/cost-tracker.js` が出力するコストメトリクスを組み合わせる。

## 引数

$ARGUMENTS:
- `list [options]` - セッションをリストアップ
  - `--limit <n>` - 表示する最大セッション数（デフォルト：50）
  - `--date <YYYY-MM-DD>` - 日付でフィルタ
  - `--search <pattern>` - セッション ID で検索
- `load <id|alias>` - セッション内容をロード
- `alias <id> <name>` - セッションのエイリアスを作成
- `alias --remove <name>` - エイリアスを削除
- `unalias <name>` - `--remove` と同じ
- `info <id|alias>` - セッション統計を表示
- `aliases` - すべてのエイリアスをリスト
- `help` - このヘルプを表示

## 例

```bash
# List all sessions
/sessions list

# Create an alias for today's session
/sessions alias 2026-02-01 today

# Load session by alias
/sessions load today

# Show session info
/sessions info today

# Remove alias
/sessions alias --remove today

# List all aliases
/sessions aliases
```

## 注意事項

- セッションは `~/.claude/session-data/` に markdown ファイルとして保存され、レガシー読み込みは `~/.claude/sessions/` から行われる
- エイリアスは `~/.claude/session-aliases.json` に保存される
- セッション ID は短縮可能（通常は最初の 4-8 文字で十分にユニーク）
- 頻繁に参照するセッションにはエイリアスを使う

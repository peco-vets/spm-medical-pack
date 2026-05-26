---
description: hookify システムのヘルプを取得する / Get help with the hookify system
---

包括的な hookify ドキュメントを表示する。

## フックシステム概要

Hookify は、不要な振る舞いを防ぐために Claude Code のフックシステムと統合するルールファイルを作成する。

### イベントタイプ

- `bash`：Bash ツール利用時にトリガーされ、コマンドパターンとマッチする
- `file`：Write/Edit ツール利用時にトリガーされ、ファイルパスとマッチする
- `stop`：セッション終了時にトリガーされる
- `prompt`：ユーザーメッセージ送信時にトリガーされ、入力パターンとマッチする
- `all`：すべてのイベントでトリガーされる

### ルールファイル形式

ファイルは `.claude/hookify.{name}.local.md` として保存される：

```yaml
---
name: descriptive-name
enabled: true
event: bash|file|stop|prompt|all
action: block|warn
pattern: "regex pattern to match"
---
Message to display when rule triggers.
Supports multiple lines.
```

### コマンド

- `/hookify [description]` は新しいルールを作成し、説明が与えられない場合は会話を自動分析する
- `/hookify-list` は設定済みルールをリスト表示する
- `/hookify-configure` はルールのオン/オフを切り替える

### パターン Tips

- 正規表現構文を使用する
- `bash` の場合、完全なコマンド文字列に対してマッチする
- `file` の場合、ファイルパスに対してマッチする
- デプロイ前にパターンをテストする

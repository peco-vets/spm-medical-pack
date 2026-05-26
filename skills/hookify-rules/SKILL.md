---
name: hookify-rules
description: ユーザーが hookify ルールを作成、hook ルールを記述、hookify を構成、hookify ルールを追加、または hookify ルール構文・パターンの案内を求めるときに用いる（hookify, hook rules, regex patterns）。
---

# Hookify ルールの書き方

## 概要

Hookify ルールは YAML フロントマター付きの Markdown ファイルで、監視するパターンと一致時に表示するメッセージを定義する。ルールは `.claude/hookify.{rule-name}.local.md` ファイルに保存される。

## ルールファイル形式

### 基本構造

```markdown
---
name: rule-identifier
enabled: true
event: bash|file|stop|prompt|all
pattern: regex-pattern-here
---

Message to show Claude when this rule triggers.
Can include markdown formatting, warnings, suggestions, etc.
```

### フロントマターフィールド

| フィールド | 必須 | 値 | 説明 |
|-------|----------|--------|-------------|
| name | Yes | kebab-case 文字列 | ユニーク識別子（verb-first: warn-*、block-*、require-*） |
| enabled | Yes | true/false | 削除せずトグル |
| event | Yes | bash/file/stop/prompt/all | どのフックイベントで起動するか |
| action | No | warn/block | warn（デフォルト）はメッセージ表示、block は操作阻止 |
| pattern | Yes* | regex 文字列 | マッチパターン（*または複雑ルールでは conditions を使う） |

### 高度な形式（複数条件）

```markdown
---
name: warn-env-api-keys
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.env$
  - field: new_text
    operator: contains
    pattern: API_KEY
---

You're adding an API key to a .env file. Ensure this file is in .gitignore!
```

**イベント別 condition フィールド:**
- bash: `command`
- file: `file_path`、`new_text`、`old_text`、`content`
- prompt: `user_prompt`

**演算子:** `regex_match`、`contains`、`equals`、`not_contains`、`starts_with`、`ends_with`

ルール起動には全条件のマッチが必要である。

## イベントタイプガイド

### bash イベント
Bash コマンドパターンに一致:
- 危険コマンド: `rm\s+-rf`、`dd\s+if=`、`mkfs`
- 権限昇格: `sudo\s+`、`su\s+`
- 権限問題: `chmod\s+777`

### file イベント
Edit/Write/MultiEdit 操作に一致:
- デバッグコード: `console\.log\(`、`debugger`
- セキュリティリスク: `eval\(`、`innerHTML\s*=`
- 機密ファイル: `\.env$`、`credentials`、`\.pem$`

### stop イベント
完了チェックとリマインダ。パターン `.*` は常にマッチする。

### prompt イベント
ワークフロー強制のためユーザープロンプト内容にマッチ。

## パターン記述のコツ

### Regex の基本
- 特殊文字エスケープ: `.` → `\.`、`(` → `\(`
- `\s` 空白、`\d` 数字、`\w` ワード文字
- `+` 1以上、`*` 0以上、`?` オプション
- `|` OR 演算子

### 一般的な落とし穴
- **広すぎる**: `log` は "login"、"dialog" に一致する — `console\.log\(` を使う
- **特定すぎる**: `rm -rf /tmp` — `rm\s+-rf` を使う
- **YAML エスケープ**: 引用なしパターンを使う。引用文字列では `\\s` が必要

### テスト
```bash
python3 -c "import re; print(re.search(r'your_pattern', 'test text'))"
```

## ファイル構成

- **場所**: プロジェクトルートの `.claude/` ディレクトリ
- **命名**: `.claude/hookify.{descriptive-name}.local.md`
- **Gitignore**: `.gitignore` に `.claude/*.local.md` を追加

## コマンド

- `/hookify [description]` - 新規ルール作成（引数なしなら会話を自動解析）
- `/hookify-list` - 全ルールを表形式で表示
- `/hookify-configure` - ルールを対話的に on/off
- `/hookify-help` - 完全ドキュメント

## クイックリファレンス

最小有効ルール:
```markdown
---
name: my-rule
enabled: true
event: bash
pattern: dangerous_command
---
Warning message here
```

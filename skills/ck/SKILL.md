---
name: ck
description: Claude Code のプロジェクトごとの永続メモリ。セッション開始時にプロジェクトコンテキストを自動ロード、git アクティビティ付きでセッションを追跡、ネイティブメモリに書き込む。コマンドは決定論的な Node.js スクリプトを実行する — モデルバージョン間で挙動が一貫する (ck, context keeper, persistent memory, session, project context)。
origin: community
version: 2.0.0
author: sreedhargs89
repo: https://github.com/sreedhargs89/context-keeper
---

# ck — Context Keeper

あなたは **Context Keeper** アシスタントである。ユーザーが任意の `/ck:*` コマンドを呼び出したら、対応する Node.js スクリプトを実行し、その stdout をユーザーにそのまま提示する。
スクリプトは `~/.claude/skills/ck/commands/` にある (`~` は `$HOME` で展開)。

---

## データレイアウト

```
~/.claude/ck/
├── projects.json              ← path → {name, contextDir, lastUpdated}
└── contexts/<name>/
    ├── context.json           ← SOURCE OF TRUTH (structured JSON, v2)
    └── CONTEXT.md             ← generated view — do not hand-edit
```

---

## コマンド

### `/ck:init` — プロジェクトを登録
```bash
node "$HOME/.claude/skills/ck/commands/init.mjs"
```
スクリプトは自動検出された情報を JSON で出力する。確認ドラフトとして提示する:
```
Here's what I found — confirm or edit anything:
Project:     <name>
Description: <description>
Stack:       <stack>
Goal:        <goal>
Do-nots:     <constraints or "None">
Repo:        <repo or "none">
```
ユーザー承認を待つ。任意の編集を適用する。次に確認済み JSON を save.mjs --init にパイプする:
```bash
echo '<confirmed-json>' | node "$HOME/.claude/skills/ck/commands/save.mjs" --init
```
確認済み JSON スキーマ: `{"name":"...","path":"...","description":"...","stack":["..."],"goal":"...","constraints":["..."],"repo":"..." }`

---

### `/ck:save` — セッション状態を保存
**これは LLM 分析を必要とする唯一のコマンドである。** 現在の会話を分析する:
- `summary`: 1 文、最大 10 語、達成したこと
- `leftOff`: 能動的に作業されていたもの (特定のファイル/機能/バグ)
- `nextSteps`: 具体的な次のステップの順序付き配列
- `decisions`: このセッションで行われた決定の `{what, why}` 配列
- `blockers`: 現在のブロッカー配列 (なければ空配列)
- `goal`: このセッションで変わった **場合のみ** 更新された goal 文字列、そうでなければ省略

ユーザーにドラフトサマリを表示する: `"Session: '<summary>' — save this? (yes / edit)"`
確認を待つ。次に save.mjs にパイプ:
```bash
echo '<json>' | node "$HOME/.claude/skills/ck/commands/save.mjs"
```
JSON スキーマ (厳密): `{"summary":"...","leftOff":"...","nextSteps":["..."],"decisions":[{"what":"...","why":"..."}],"blockers":["..."]}`
スクリプトの stdout 確認をそのまま表示する。

---

### `/ck:resume [name|number]` — フルブリーフィング
```bash
node "$HOME/.claude/skills/ck/commands/resume.mjs" [arg]
```
出力をそのまま表示する。次に尋ねる: 「Continue from here? Or has anything changed?」
ユーザーが変更を報告したら → 即座に `/ck:save` を実行。

---

### `/ck:info [name|number]` — クイックスナップショット
```bash
node "$HOME/.claude/skills/ck/commands/info.mjs" [arg]
```
出力をそのまま表示する。フォローアップ質問なし。

---

### `/ck:list` — ポートフォリオビュー
```bash
node "$HOME/.claude/skills/ck/commands/list.mjs"
```
出力をそのまま表示する。ユーザーが番号や名前で返信したら → `/ck:resume` を実行。

---

### `/ck:forget [name|number]` — プロジェクトを削除
最初にプロジェクト名を解決する (必要なら `/ck:list` を実行)。
尋ねる: `"This will permanently delete context for '<name>'. Are you sure? (yes/no)"`
yes なら:
```bash
node "$HOME/.claude/skills/ck/commands/forget.mjs" [name]
```
確認をそのまま表示する。

---

### `/ck:migrate` — v1 データを v2 に変換
```bash
node "$HOME/.claude/skills/ck/commands/migrate.mjs"
```
最初にドライラン:
```bash
node "$HOME/.claude/skills/ck/commands/migrate.mjs" --dry-run
```
出力をそのまま表示する。すべての v1 CONTEXT.md + meta.json ファイルを v2 context.json に移行する。オリジナルは `meta.json.v1-backup` としてバックアップされる — 何も削除されない。

---

## SessionStart フック

`~/.claude/skills/ck/hooks/session-start.mjs` のフックは、セッション開始時にプロジェクトコンテキストを自動ロードするために `~/.claude/settings.json` に登録されなければならない:

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "node \"~/.claude/skills/ck/hooks/session-start.mjs\"" }] }
    ]
  }
}
```

フックはセッション当たり約 100 トークンを注入する (コンパクトな 5 行サマリ)。未保存セッション、最後の保存以降の git アクティビティ、CLAUDE.md との goal ミスマッチも検出する。

---

## ルール

- Bash 呼び出しでは常に `~` を `$HOME` として展開する。
- コマンドは大文字小文字を区別しない: `/CK:SAVE`、`/ck:save`、`/Ck:Save` はすべて機能する。
- スクリプトがコード 1 で終了したら、その stdout をエラーメッセージとして表示する。
- `context.json` や `CONTEXT.md` を直接編集しない — 常にスクリプトを使う。
- `projects.json` が不正なら、ユーザーに伝えそれを `{}` にリセットすることを提案する。

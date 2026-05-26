---
description: ~/.claude/session-data/ から最新のセッションファイルを読み込み、前回のセッションが終了したところからフルコンテキストで作業を再開する / Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.
---

# Resume Session Command

最後に保存されたセッション状態をロードし、いかなる作業をする前にも完全に方向付ける。
このコマンドは `/save-session` のカウンターパートである。

## 利用シーン

- 前日からの作業を続けるために新しいセッションを開始する
- コンテキスト制限により新しいセッションを開始した後
- 別のソースからセッションファイルを引き継ぐ場合（ファイルパスを提供するだけ）
- セッションファイルがあり、進む前に Claude にそれを完全に吸収させたいとき

## Usage

```
/resume-session                                                      # loads most recent file in ~/.claude/session-data/
/resume-session 2024-01-15                                           # loads most recent session for that date
/resume-session ~/.claude/session-data/2024-01-15-abc123de-session.tmp  # loads a current short-id session file
/resume-session ~/.claude/sessions/2024-01-15-session.tmp               # loads a specific legacy-format file
```

## プロセス

### Step 1: セッションファイルを見つける

引数が提供されない場合：

1. `~/.claude/session-data/` を確認する
2. 最も最近変更された `*-session.tmp` ファイルを選ぶ
3. フォルダが存在しないか、マッチするファイルがない場合、ユーザーに通知：
   ```
   No session files found in ~/.claude/session-data/
   Run /save-session at the end of a session to create one.
   ```
   その後停止する。

引数が提供される場合：

- 日付（`YYYY-MM-DD`）のように見える場合、まず `~/.claude/session-data/`、次にレガシーの
  `~/.claude/sessions/` で `YYYY-MM-DD-session.tmp`（レガシー形式）または
  `YYYY-MM-DD-<shortid>-session.tmp`（現行形式）にマッチするファイルを検索し、
  その日付の最も最近変更されたバリアントをロードする
- ファイルパスのように見える場合、そのファイルを直接読む
- 見つからない場合、明確に報告して停止する

### Step 2: セッションファイル全体を読む

完全なファイルを読む。まだ要約しない。

### Step 3: 理解を確認する

この正確な形式で構造化されたブリーフィングで応答する：

```
SESSION LOADED: [actual resolved path to the file]
════════════════════════════════════════════════

PROJECT: [project name / topic from file]

WHAT WE'RE BUILDING:
[2-3 sentence summary in your own words]

CURRENT STATE:
PASS: Working: [count] items confirmed
 In Progress: [list files that are in progress]
 Not Started: [list planned but untouched]

WHAT NOT TO RETRY:
[list every failed approach with its reason — this is critical]

OPEN QUESTIONS / BLOCKERS:
[list any blockers or unanswered questions]

NEXT STEP:
[exact next step if defined in the file]
[if not defined: "No next step defined — recommend reviewing 'What Has NOT Been Tried Yet' together before starting"]

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

### Step 4: ユーザーを待つ

自動的に作業を開始してはならない。ファイルに触れてはならない。ユーザーが次に何をするか言うのを待つ。

セッションファイルで次のステップが明確に定義されており、ユーザーが "continue" や "yes" などと言ったら — その正確な次のステップで進む。

次のステップが定義されていない場合 — ユーザーにどこから始めるか尋ね、必要に応じて "What Has NOT Been Tried Yet" セクションからアプローチを提案する。

---

## エッジケース

**同じ日付に複数のセッション**（`2024-01-15-session.tmp`、`2024-01-15-abc123de-session.tmp`）：
レガシーの no-id 形式か現行の short-id 形式かに関係なく、その日付の最も最近変更されたマッチするファイルをロードする。

**セッションファイルが存在しないファイルを参照している：**
ブリーフィング中に注記する — 「WARNING: `path/to/file.ts` referenced in session but not found on disk.」

**セッションファイルが7日以上前のもの：**
ギャップを注記する — 「WARNING: This session is from N days ago (threshold: 7 days). Things may have changed.」 — その後通常通り進む。

**ユーザーが直接ファイルパスを提供（例：チームメイトから転送）：**
それを読み、同じブリーフィングプロセスに従う — ソースに関係なくフォーマットは同じ。

**セッションファイルが空または不正：**
報告する：「Session file found but appears empty or unreadable. You may need to create a new one with /save-session.」

---

## 出力例

ブリーフィングは PROJECT、WHAT WE'RE BUILDING、CURRENT STATE（Working、In Progress、Not Started）、WHAT NOT TO RETRY（失敗したアプローチとその理由）、OPEN QUESTIONS / BLOCKERS、NEXT STEP（次の具体的な作業）を含む。例えば JWT 認証の途中で、register エンドポイントと JWT 生成は完成しているが、login ルートで httpOnly cookie の設定が未完了、Next-Auth と localStorage は試したが失敗、といった具合に。

---

## 注意事項

- ロード時にセッションファイルを変更しない — それは読み取り専用の歴史的記録である
- ブリーフィングフォーマットは固定 — 空でもセクションをスキップしない
- 「What Not To Retry」は常に表示しなければならず、"None" と書く場合でも — 見逃すには重要すぎる
- 再開後、ユーザーは新しいセッション終了時に再度 `/save-session` を実行して新しい日付付きファイルを作成したい場合がある

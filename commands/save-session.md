---
description: 現在のセッション状態を ~/.claude/session-data/ の日付付きファイルに保存し、将来のセッションで完全なコンテキストで作業を再開できるようにする / Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.
---

# Save Session Command

このセッションで起こったすべて — 何が構築されたか、何が動いたか、何が失敗したか、何が残っているか — を捕捉し、次のセッションがこのセッションが終わった正確な場所から続けられるように日付付きファイルに書き出す。

## 利用シーン

- Claude Code を閉じる前の作業セッションの終わり
- コンテキスト制限に達する前に（最初にこれを実行し、その後新しいセッションを開始する）
- 覚えておきたい複雑な問題を解決した後
- 将来のセッションにコンテキストを引き継ぐ必要があるとき

## プロセス

### Step 1: コンテキストを集める

ファイルを書く前に集める：

- このセッション中に変更されたすべてのファイルを読む（git diff または会話から思い出す）
- 議論、試行、決定されたことをレビューする
- 遭遇したエラーとそれらがどう解決されたか（または解決されなかったか）を記録する
- 関連する場合、現在のテスト/ビルドステータスを確認する

### Step 2: sessions フォルダが存在しなければ作成する

ユーザーの Claude ホームディレクトリに正式なセッションフォルダを作成する：

```bash
mkdir -p ~/.claude/session-data
```

### Step 3: セッションファイルを書く

今日の実際の日付と、`session-manager.js` の `SESSION_FILENAME_REGEX` で強制されるルールを満たす short-id を使って `~/.claude/session-data/YYYY-MM-DD-<short-id>-session.tmp` を作成する：

- 互換性文字：文字 `a-z` / `A-Z`、数字 `0-9`、ハイフン `-`、アンダースコア `_`
- 互換性最小長：1文字
- 新ファイル用の推奨スタイル：衝突を避けるために8文字以上の小文字、数字、ハイフン

有効な例：`abc123de`、`a1b2c3d4`、`frontend-worktree-1`、`ChezMoi_2`
新ファイルでは避ける：`A`、`test_id1`、`ABC123de`

完全に有効なファイル名の例：`2024-01-15-abc123de-session.tmp`

レガシーのファイル名 `YYYY-MM-DD-session.tmp` も依然として有効だが、新しいセッションファイルは同日衝突を避けるために short-id 形式を優先すべきである。

### Step 4: 下記すべてのセクションでファイルを埋める

すべてのセクションを正直に書く。セクションをスキップしてはならない — セクションが本当に内容を持たない場合は "Nothing yet" または "N/A" と書く。不完全なファイルは正直な空のセクションより悪い。

### Step 5: ファイルをユーザーに表示する

書いた後、完全な内容を表示して尋ねる：

```
Session saved to [actual resolved path to the session file]

Does this look accurate? Anything to correct or add before we close?
```

確認を待つ。要求された場合は編集する。

---

## セッションファイル形式

ファイルには以下のセクションを含む：

- **# Session: YYYY-MM-DD**（Started、Last Updated、Project、Topic）
- **What We Are Building**：機能、バグ修正、タスクを 1-3 段落で記述（このセッションのゼロメモリで、誰でも目標を理解できるようにする）
- **What WORKED (with evidence)**：確認された動作物のみをリスト、各項目について何が動作するか確認した方法を含める
- **What Did NOT Work (and why)**：試した各失敗したアプローチを、次のセッションが再試行しないように正確な理由付きで（最も重要なセクション）
- **What Has NOT Been Tried Yet**：有望だが試されていないアプローチ、会話からのアイデア、探求する価値のある代替案
- **Current State of Files**：このセッションで触れたすべてのファイルとその正確な状態（Complete / In Progress / Broken / Not Started）
- **Decisions Made**：アーキテクチャ選択、受け入れたトレードオフ、選ばれたアプローチとその理由
- **Blockers & Open Questions**：次のセッションが対処または調査する必要のある未解決事項
- **Exact Next Step**：再開する際に行う最も重要な単一のこと、ゼロ思考で開始できるように正確に
- **Environment & Setup Notes**：関連する場合のみ、プロジェクトを実行するために必要なコマンド、必要な env vars、実行する必要のあるサービスなど

## 出力例

例えば JWT 認証のセッションでは、「What We Are Building」では Next.js アプリ用のユーザー認証システム（httpOnly cookie に保存される JWT、SSR と互換性のあるセッション永続化）を説明する。「What WORKED」では `/api/auth/register` エンドポイントが Postman で 200 を返すこと、JWT 生成のユニットテストが合格することを記録する。「What Did NOT Work」では Next-Auth が Prisma adapter と衝突したこと、localStorage が SSR ハイドレーションミスマッチを引き起こしたことを記録する。「Exact Next Step」では具体的にどのファイルでどのコードを書くかを指示する。

---

## 注意事項

- 各セッションは独自のファイルを取得する — 前のセッションのファイルに追加しない
- 「What Did NOT Work」セクションが最もクリティカル — それなしでは将来のセッションは盲目的に失敗したアプローチを再試行する
- ユーザーが（最後だけでなく）セッション中に保存するよう求めた場合、これまでに分かっていることを保存し、進行中のアイテムを明確にマークする
- このファイルは次のセッションの開始時に `/resume-session` で Claude が読むことを意図している
- 正式なグローバルセッションストア：`~/.claude/session-data/` を使う
- 新しいセッションファイルには short-id ファイル名形式（`YYYY-MM-DD-<short-id>-session.tmp`）を優先する

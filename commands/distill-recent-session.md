---
description: 直近のセッションログ（~/.claude/session-logs/ 配下の最新ファイル）と transcript を読み取って、新しい開発ルール候補を LLM で抽出する。抽出結果は ~/.claude/proposed-rules.md に追記され、ごうさんが承認したものだけ /save-rule で CLAUDE.md 本体に反映する semi-automatic flow（Layer B）。session ended / セッション終わり / ルール抽出 / 蓄積 / 振り返り のキーワードで起動。
argument-hint: [--apply-all で全候補を自動承認、デフォルトは承認待ちキュー]
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep"]
---

# /distill-recent-session — セッションログからルール候補を抽出

直前の Claude Code セッションで何が起きたかを読み解き、「次から守るべき新しいルール」の候補を抽出する。 候補は `~/.claude/proposed-rules.md` に追記され、 ごうさんが個別に承認した後に CLAUDE.md へ取り込む。

## 動作

### Step 1: 最新セッションログを特定

```bash
LATEST=$(ls -t ~/.claude/session-logs/*.md 2>/dev/null | head -1)
if [ -z "$LATEST" ]; then
  echo "❌ セッションログがありません。Stop hook が動いていない可能性があります。"
  exit 1
fi
```

### Step 2: ログから transcript_path を取得し、両方を読込

```bash
TRANSCRIPT=$(grep '^transcript:' "$LATEST" | sed 's/transcript: //')
```

セッションログ本体と transcript（あれば）を Read で読み取り。

### Step 3: ルール候補を抽出（LLM 推論）

セッションの内容を見て、以下のパターンに該当するものを抽出する：

- **再発エラーへの対処** — 同じエラーが複数回出て、最終的に解決した方法
- **明示的な指摘** — ごうさんが「これはダメ」「次からこうして」と言った内容
- **重複コードの整理** — 同じ修正を複数箇所にした場合、その共通パターン
- **設定変更** — `.eslintrc`、`tsconfig.json`、`prisma/schema.prisma` 等の変更
- **新ライブラリ採用** — npm install 系のコマンドで新規依存追加
- **コマンド系の発見** — npx tsc, npx next build 等のレビュープロセス追加

### Step 4: 抽出結果を `~/.claude/proposed-rules.md` に追記

```markdown
## 提案 [2026-MM-DD HH:MM]

セッション: <session_id>
作業内容サマリー: <一文>

### 候補ルール

1. **[カテゴリ: コーディング規約]** TypeScript: useEffect の依存配列に空配列を入れる時はコメントで意図明示
   - 根拠: セッション内で2回同じ警告対応をした
   - 信頼度: 中

2. **[カテゴリ: セキュリティ]** API ルートで request.json() の前に Content-Type 検証
   - 根拠: ごうさんが明示的に「これ必須にしたい」と言及
   - 信頼度: 高

3. ...

### 次のアクション

承認する候補：
- ごうさんが個別に `/save-rule <候補>` で取り込み
- または `/distill-recent-session --apply-all` で全件 CLAUDE.md に反映（信頼度 高 のみ）
```

### Step 5: 完了通知

```
✅ N 件のルール候補を抽出して ~/.claude/proposed-rules.md に追記しました。

レビュー: cat ~/.claude/proposed-rules.md | tail -50
承認:     /save-rule <ルール本文>
一括承認: /distill-recent-session --apply-all（信頼度 高 のみ自動反映）
```

## `--apply-all` モード

引数に `--apply-all` がある場合：
- 信頼度「高」のもののみを CLAUDE.md に自動追記
- 信頼度「中・低」は引き続きキューに残す
- 追記後、proposed-rules.md には「承認済み: ✅」マークを付ける

## 注意

- このコマンドはセッションが**終わってから**実行する。途中で実行しても直前のセッションを見るので問題ないが、現在進行中の文脈は見えない。
- transcript が長大な場合は最後の 100 ターン程度に限定する（コスト抑制）。
- 抽出は完全自動ではない。最終的に CLAUDE.md に書くかは人間判断。

## 関連

- [[/save-rule]] — 手動キャプチャ版（即座に CLAUDE.md へ）
- [[/distill-weekly]] — 週次バッチ版（複数セッション + git log 横断）
- Stop hook: `spm:session:log` がセッション終了時に自動でログを生成

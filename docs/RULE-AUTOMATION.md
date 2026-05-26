# CLAUDE.md 自動アップデート 3層フロー

spm-medical-pack に搭載された「CLAUDE.md が腐らずに進化する」ための3層仕組み。

## 全体像

```
┌────────────────────────────────────────────────────────────────────┐
│                       3層 CLAUDE.md 進化フロー                       │
└────────────────────────────────────────────────────────────────────┘

  開発作業
      │
      │  (1) 「これルール化」と思った瞬間
      ▼
  ┌────────────────────┐
  │  Layer C           │
  │  /save-rule        │ ─────────► CLAUDE.md に即追記（即時反映）
  │  手動キャプチャ      │
  └────────────────────┘

      │
      │  (2) セッション中の挙動を自動記録
      ▼
  ┌────────────────────┐
  │  Layer B (Stop hook)│
  │  spm:session:log   │ ─────────► ~/.claude/session-logs/YYYY-MM-DD_HHMMSS.md
  │  自動ログ蓄積        │            (LLM呼出なし、軽量)
  └────────────────────┘

      │
      │  (3) セッション終わったら手動でルール抽出
      ▼
  ┌────────────────────────────────┐
  │  /distill-recent-session       │
  │  直近ログから LLM 抽出           │ ─► ~/.claude/proposed-rules.md
  │                                │    (候補キュー、要承認)
  └────────────────────────────────┘

      │
      │  (4) 週次で複数セッション + git log を横断
      ▼
  ┌────────────────────────────────┐
  │  Layer D                       │
  │  /distill-weekly               │ ─► ~/.claude/proposed-rules.md
  │  週次バッチ（推奨：cron で自動化） │    (横断的パターン)
  └────────────────────────────────┘

      │
      │  (5) 候補レビュー → 承認
      ▼
  ┌────────────────────────────────┐
  │  /save-rule <承認したルール>      │ ─► CLAUDE.md 本体に反映
  │  または                          │
  │  /distill-weekly --apply-high  │ ─► 信頼度高のみ自動反映
  └────────────────────────────────┘
```

## 各層の役割と使い分け

### Layer C: `/save-rule`（手動キャプチャ）

**いつ使う**：
- 「あ、これはルール化したい」と思った瞬間
- レビューで「次から守って」と指摘した時
- 新しい技術選定が決まった時

**例**：
```
/save-rule TypeScript で any 型禁止
/save-rule API ルートには必ず JWT 認証 --category セキュリティ
/save-rule 診療録は物理削除禁止、論理削除のみ --category 医療法対応
```

**特徴**：
- 即時反映、確実
- カテゴリ自動判定（指定もOK）
- 100% 人間が意図したものだけ追加される

### Layer B: Stop hook + `/distill-recent-session`（セミ自動）

**いつ起きる**：
- Stop hook はセッション終わるたびに**自動**で発火、`~/.claude/session-logs/` にログを残す
- ごうさんが手動で `/distill-recent-session` を実行 → LLM が直近ログを分析してルール候補を提案

**例の使い方**：
```
(セッション中、いろんな修正をする)
(セッション終了)

# 翌セッション or 後で：
/distill-recent-session

# 出力例：
✅ 3 件のルール候補を ~/.claude/proposed-rules.md に追記

# レビュー後、欲しいものだけ：
/save-rule API ルートで request.json() の前に Content-Type 検証
```

**特徴**：
- セッション終了時にログだけ自動保存（軽量）
- LLM 抽出は手動トリガで明示的に
- 承認フローで誤検出ブロック

### Layer D: `/distill-weekly`（週次バッチ・横断分析）

**いつ実行する**：
- 週1回、定期レビュー時
- 月次振り返り
- スプリント終わり

**何を見るか**：
- 過去 7 日分の全セッションログ
- 全 SPM リポ（9つ）の git log
- → 横断的に「繰り返しパターン」を発見

**例**：
```
/distill-weekly

# 出力例：
✅ 期間: 2026-05-18 〜 2026-05-25 (23 セッション + 45 コミット)
   候補: 8件（高 3 / 中 3 / 低 2）

# 高信頼度を一括反映：
/distill-weekly --apply-high
```

**特徴**：
- 1セッション単体では見えない「3回繰り返した」「複数リポ共通」が見える
- トークン消費は大きい（数万〜10万）が週1で抑えられる
- 信頼度高のみ自動反映で安全

### 定期実行のセットアップ

`/schedule` 機能で `/distill-weekly` を毎週月曜朝に自動化：

```
/schedule "0 9 * * 1" "/distill-weekly"
```

## 運用ベストプラクティス

### 1. 開発中の思いつきは Layer C で即捕捉
セッション中に「これ大事」と気づいたらその場で `/save-rule`。後で忘れる。

### 2. セッション終わったら Layer B 抽出を週に2-3回
全部のセッションでやる必要なし。「大きな作業した日」「設計変えた日」だけでも十分。

### 3. Layer D は週次定期で横断的に
個別作業では気づかない「みんなが同じ修正してる」を捕まえる。

### 4. proposed-rules.md は月1で大掃除
肥大化するので、月初に：
- 承認済みは削除
- 60日以上 pending のものは削除（その時点でルール化不要と判断）

### 5. CLAUDE.md 自体も棚卸し
四半期に1回、`/distill-weekly --review-claude-md` 等で：
- 古いルール削除
- 重複統合
- セクション再編

## 設定ファイル一覧

| ファイル / ディレクトリ | 役割 |
|---|---|
| `~/.claude/CLAUDE.md` | グローバルメモリ（毎セッション自動ロード） |
| `~/.claude/session-logs/` | Stop hook が蓄積するセッションログ |
| `~/.claude/proposed-rules.md` | 候補キュー（承認待ち） |
| `spm-medical-pack/commands/save-rule.md` | Layer C |
| `spm-medical-pack/commands/distill-recent-session.md` | Layer B-bridge |
| `spm-medical-pack/commands/distill-weekly.md` | Layer D |
| `spm-medical-pack/scripts/hooks/spm/session-log.sh` | Stop hook 実体 |
| `spm-medical-pack/hooks/hooks.json` の `spm:session:log` | Stop hook 登録 |

## トラブルシュート

### Stop hook が動いていない
- `~/.claude/session-logs/` に新しいファイルが出来ない場合
- 確認：`cat ~/.claude/plugins/marketplaces/spm-medical-pack/hooks/hooks.json | grep spm:session:log`
- 手動テスト：`echo '{"session_id":"test"}' | ~/.claude/plugins/marketplaces/spm-medical-pack/scripts/hooks/spm/session-log.sh`

### /save-rule がカテゴリを間違える
- 明示的に `--category` 指定で回避
- 例：`/save-rule X X X --category セキュリティ`

### /distill-recent-session が「ログが無い」
- Stop hook が動いていないかもしれない（上記参照）
- ログが古い場合は `ls -lt ~/.claude/session-logs/ | head -3` で確認

### CLAUDE.md が肥大化してきた
- `wc -l ~/.claude/CLAUDE.md` で行数確認
- 500 行超えたら棚卸し検討
- 重複・古いルールを Edit で整理

## 次の進化方向

将来的に：
- Stop hook 自体に LLM 呼出を入れて完全自動化（コスト次第）
- CLAUDE.md のサイズが大きくなったら「コンテキスト圧縮」スキル追加
- 複数 Mac で session-logs を同期するため Google Drive 化検討
- チーム共有用：proposed-rules.md を全員でレビューする仕組み

---
description: 過去 7 日分の Claude Code セッションログ + 全 SPM リポ（spm-project-2、spm-diagnosis、peco-stock、peco-ui、peco-property、spm-dev-agent、peco-ai-vets-dashboard、spm-brain、spm-pos）の git log を横断的に LLM レビューして、繰り返し出てくるパターン・暗黙ルールを抽出する。週次レビュー・月次レビュー・棚卸し・振り返り・ルール整理 のキーワードで起動。
argument-hint: [--days N で期間変更、デフォルト 7] [--apply-high で信頼度高を自動反映]
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep", "Glob"]
---

# /distill-weekly — 週次バッチ：複数セッション + git log を横断抽出

過去 7 日分の Claude Code 利用と全 SPM リポの実コミットを統合的に見て、「3回以上繰り返されている修正パターン」「複数リポで同じ問題が出ているケース」「明示されていないが慣習化している規約」等を発見し、CLAUDE.md に取り込むべきルール候補として提案する。

## 動作

### Step 1: 期間決定

引数 `--days N` で N 日前まで遡る。デフォルト 7 日。

```bash
DAYS=${ARG:-7}
SINCE=$(date -v-${DAYS}d +"%Y-%m-%d")
```

### Step 2: セッションログ集計

```bash
SESSION_LOGS=$(find ~/.claude/session-logs -name "*.md" -mtime -${DAYS} | sort)
SESSION_COUNT=$(echo "$SESSION_LOGS" | wc -l)
echo "対象期間: $SINCE 〜 今日 ($SESSION_COUNT セッション)"
```

各ログから「編集されたファイル一覧」「ツール呼出統計」を取得。

### Step 3: 全 SPM リポの git log 集計

```bash
REPOS=(spm-project-2 spm-diagnosis peco-stock peco-ui peco-property spm-dev-agent peco-ai-vets-dashboard spm-brain spm-pos)
for repo in "${REPOS[@]}"; do
  echo "=== $repo ==="
  cd ~/$repo
  git log --since="$SINCE" --pretty=format:"%h %ad %s" --date=short --all
done
```

コミットメッセージ・変更ファイルパターンから「繰り返しのテーマ」を抽出。

### Step 4: ルール候補の系統的抽出（LLM 推論）

以下の観点で横断分析：

#### A. 繰り返し修正パターン
- 同じ種類のバグ修正が複数コミットで出ている → 予防ルール化
- 例: 「型エラー修正」が3コミット → "Strict mode で常に型注釈" ルール化

#### B. 複数リポ共通の作業
- 全リポで同じ依存ライブラリの更新があった → 共通の依存管理ルール
- 例: zod v3 → v4 アップグレードが3リポで実施 → API バリデーション規約として明示

#### C. 暗黙化している慣習
- ファイル命名・ディレクトリ構造に共通パターン
- 例: 全リポで `src/lib/` 配下にユーティリティ → "ユーティリティは src/lib/ に集約" ルール化

#### D. テスト・レビュープロセスの追加
- 新しい CI/レビュー手順が複数回登場 → CLAUDE.md の自動レビュープロセス追記候補

#### E. 医療法・セキュリティ要件の進化
- 法令対応コミットが繰り返されている領域 → 医療法対応原則に新項目追加

### Step 5: 出力（マスタープロポーザル）

`~/.claude/proposed-rules.md` に**週次セクション**を追加：

```markdown
## 週次レビュー [2026-MM-DD] (対象期間: 2026-MM-DD 〜 2026-MM-DD)

セッション数: 23
全リポコミット数: 45
横断パターン: 8件抽出

### 候補ルール（信頼度別）

#### 🔴 信頼度: 高（明確な繰り返し or 明示的指摘）
1. **[医療法対応]** 診療データを扱う API は必ず `withAuditLog` ラッパーを使う
   - 根拠: 4 リポで同じ修正、3コミットで監査ログ漏れの fix
   - 影響範囲: spm-diagnosis、peco-stock、peco-ai-vets-dashboard
   - 推奨アクション: CLAUDE.md の「## APIルール」に追加

#### 🟡 信頼度: 中
2. **[コーディング規約]** Prisma クエリで `select` 必須（オーバーフェッチ防止）
   - 根拠: 2 リポでパフォーマンス改善コミット
   - 推奨: もう1〜2回繰り返し確認してから追加検討

#### 🟢 信頼度: 低（参考）
3. **[UI/UX]** Toast 表示は2秒以上にする
   - 根拠: 1 件の明示的指摘のみ
   - 推奨: /save-rule で個別判断

### 次のアクション
- 高信頼度ルール: `/distill-weekly --apply-high` で一括反映
- 個別反映: `/save-rule <ルール本文>`
```

### Step 6: 完了通知

```
✅ 週次レビュー完了。

期間: 2026-MM-DD 〜 今日 (N 日間)
分析対象: N セッション + N コミット
抽出した候補: N件（高 X / 中 Y / 低 Z）

レビュー: cat ~/.claude/proposed-rules.md | tail -100
一括反映: /distill-weekly --apply-high
個別反映: /save-rule <候補>
```

## `--apply-high` モード

引数に `--apply-high` がある場合：
- 信頼度「高」のもののみを CLAUDE.md に自動追記
- proposed-rules.md には「承認済み: ✅」マーク付ける
- 中・低はキューに残す

## 推奨運用：定期実行

`/schedule` でこのコマンドを週次自動実行：

```
/schedule "0 9 * * 1" "/distill-weekly"
```
（毎週月曜 9:00 に実行）

実行結果は次回起動時に「未確認の提案があります」として表示される。

## 注意

- 7日分のセッション・コミットを横断するので、トークン消費は大きい（数万〜10万トークン規模の入力）
- 信頼度判定は LLM の主観 — 最終承認は必ず人間
- proposed-rules.md は時間とともに肥大化するので、月1回程度のクリーンアップ推奨

## 関連

- [[/save-rule]] — 手動キャプチャ
- [[/distill-recent-session]] — 直近1セッションのみ
- ~/.claude/session-logs/ — Stop hook が蓄積するセッションログ
- ~/.claude/proposed-rules.md — 候補キュー

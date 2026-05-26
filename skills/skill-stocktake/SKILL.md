---
name: skill-stocktake
description: "Claude スキルとコマンドの品質を監査するときに使用する（audit Claude skills and commands for quality）。Quick Scan（変更されたスキルのみ）と Full Stocktake モードをサポートし、順次サブエージェントバッチ評価を行う。"
origin: ECC
---

# skill-stocktake

品質チェックリスト + AI 総合判断を使ってすべての Claude スキルとコマンドを監査するスラッシュコマンド（`/skill-stocktake`）。最近変更されたスキル向けの Quick Scan と、完全レビュー向けの Full Stocktake の 2 モードをサポートする。

## スコープ

このコマンドは**呼び出されたディレクトリに対して相対的に**以下のパスを対象とする：

| パス | 説明 |
|------|-------------|
| `~/.claude/skills/` | グローバルスキル（すべてのプロジェクト） |
| `{cwd}/.claude/skills/` | プロジェクトレベルスキル（ディレクトリが存在する場合） |

**フェーズ 1 の開始時に、コマンドはどのパスが見つかってスキャンされたかを明示的にリストする。**

### 特定プロジェクトのターゲティング

プロジェクトレベルスキルを含めるには、そのプロジェクトのルートディレクトリから実行する：

```bash
cd ~/path/to/my-project
/skill-stocktake
```

プロジェクトに `.claude/skills/` ディレクトリがない場合、グローバルスキルとコマンドのみが評価される。

## モード

| モード | トリガー | 期間 |
|------|---------|---------|
| Quick Scan | `results.json` が存在（デフォルト） | 5–10 分 |
| Full Stocktake | `results.json` が欠落、または `/skill-stocktake full` | 20–30 分 |

**結果キャッシュ：** `~/.claude/skills/skill-stocktake/results.json`

## Quick Scan フロー

前回実行以降に変更されたスキルのみを再評価する（5–10 分）。

1. `~/.claude/skills/skill-stocktake/results.json` を読む
2. 実行：`bash ~/.claude/skills/skill-stocktake/scripts/quick-diff.sh \
         ~/.claude/skills/skill-stocktake/results.json`
   （プロジェクトディレクトリは `$PWD/.claude/skills` から自動検出。必要な場合のみ明示的に渡す）
3. 出力が `[]` なら：「No changes since last run.」と報告して停止
4. 同じフェーズ 2 基準を使って変更されたファイルのみ再評価する
5. 前回結果から変更されていないスキルを引き継ぐ
6. diff のみ出力する
7. 実行：`bash ~/.claude/skills/skill-stocktake/scripts/save-results.sh \
         ~/.claude/skills/skill-stocktake/results.json <<< "$EVAL_RESULTS"`

## Full Stocktake フロー

### フェーズ 1 — インベントリ

実行：`bash ~/.claude/skills/skill-stocktake/scripts/scan.sh`

スクリプトはスキルファイルを列挙し、frontmatter を抽出し、UTC mtime を収集する。
プロジェクトディレクトリは `$PWD/.claude/skills` から自動検出。必要な場合のみ明示的に渡す。
スクリプト出力からスキャンサマリとインベントリテーブルを提示する：

```
Scanning:
  ✓ ~/.claude/skills/         (17 files)
  ✗ {cwd}/.claude/skills/    (not found — global skills only)
```

| Skill | 7d use | 30d use | Description |
|-------|--------|---------|-------------|

### フェーズ 2 — 品質評価

完全なインベントリとチェックリスト付きで Agent ツールサブエージェント（**general-purpose agent**）を起動する：

```text
Agent(
  subagent_type="general-purpose",
  prompt="
Evaluate the following skill inventory against the checklist.

[INVENTORY]

[CHECKLIST]

Return JSON for each skill:
{ \"verdict\": \"Keep\"|\"Improve\"|\"Update\"|\"Retire\"|\"Merge into [X]\", \"reason\": \"...\" }
"
)
```

サブエージェントは各スキルを読み、チェックリストを適用し、スキルごとの JSON を返す：

`{ "verdict": "Keep"|"Improve"|"Update"|"Retire"|"Merge into [X]", "reason": "..." }`

**チャンクガイダンス：** コンテキストを管理可能に保つため、サブエージェント呼び出しあたり約 20 スキルを処理する。各チャンク後に中間結果を `results.json`（`status: "in_progress"`）に保存する。

すべてのスキル評価後：`status: "completed"` を設定し、フェーズ 3 に進む。

**再開検出：** 起動時に `status: "in_progress"` が見つかった場合、最初の未評価スキルから再開する。

各スキルはこのチェックリストに対して評価される：

```
- [ ] Content overlap with other skills checked
- [ ] Overlap with MEMORY.md / CLAUDE.md checked
- [ ] Freshness of technical references verified (use WebSearch if tool names / CLI flags / APIs are present)
- [ ] Usage frequency considered
```

判定基準：

| Verdict | Meaning |
|---------|---------|
| Keep | 有用かつ最新 |
| Improve | 維持する価値あり、ただし特定の改善が必要 |
| Update | 参照技術が古い（WebSearch で検証） |
| Retire | 低品質、陳腐化、またはコスト非対称 |
| Merge into [X] | 別のスキルとの実質的な重複。マージターゲットを名指す |

評価は**総合的 AI 判断** — 数値ルブリックではない。指針となる次元：
- **Actionability**：すぐに行動できるコード例、コマンド、ステップ
- **Scope fit**：名前、トリガー、コンテンツが整合、広すぎず狭すぎず
- **Uniqueness**：MEMORY.md／CLAUDE.md／別のスキルで置き換えられない価値
- **Currency**：技術参照が現在の環境で動作する

**Reason 品質要件** — `reason` フィールドは自己完結型で意思決定可能でなければならない：
- 「変更なし」だけ書かない — 常に核心エビデンスを再述する
- **Retire** の場合：(1) どの特定の欠陥が見つかったか、(2) 代わりに同じニーズをカバーするものは何かを述べる
  - 悪い例：`"Superseded"`
  - 良い例：`"disable-model-invocation: true already set; superseded by continuous-learning-v2 which covers all the same patterns plus confidence scoring. No unique content remains."`
- **Merge** の場合：ターゲットを名指し、何のコンテンツを統合するかを記述
  - 悪い例：`"Overlaps with X"`
  - 良い例：`"42-line thin content; Step 4 of chatlog-to-article already covers the same workflow. Integrate the 'article angle' tip as a note in that skill."`
- **Improve** の場合：必要な特定の変更を記述（どのセクション、何のアクション、関連する場合のターゲットサイズ）
  - 悪い例：`"Too long"`
  - 良い例：`"276 lines; Section 'Framework Comparison' (L80–140) duplicates ai-era-architecture-principles; delete it to reach ~150 lines."`
- **Keep**（Quick Scan で mtime のみ変更）：元の判定根拠を再述し、「変更なし」と書かない
  - 悪い例：`"Unchanged"`
  - 良い例：`"mtime updated but content unchanged. Unique Python reference explicitly imported by rules/python/; no overlap found."`

### フェーズ 3 — サマリテーブル

| Skill | 7d use | Verdict | Reason |
|-------|--------|---------|--------|

### フェーズ 4 — 統合

1. **Retire / Merge**：ユーザー確認前にファイルごとの詳細な正当化を提示する：
   - どの特定の問題が見つかったか（重複、陳腐化、壊れた参照など）
   - どの代替が同じ機能をカバーするか（Retire の場合：どの既存スキル／ルール、Merge の場合：ターゲットファイルと統合するコンテンツ）
   - 削除の影響（影響を受ける依存スキル、MEMORY.md 参照、またはワークフロー）
2. **Improve**：根拠付きの具体的な改善提案を提示：
   - 何を変更するかと理由（例：「セクション X／Y が python-patterns と重複するため 430→200 行にトリム」）
   - ユーザーが行動するかを決定
3. **Update**：チェック済みソースで更新されたコンテンツを提示
4. MEMORY.md の行数をチェック。> 100 行なら圧縮を提案

## 結果ファイルスキーマ

`~/.claude/skills/skill-stocktake/results.json`：

**`evaluated_at`**：評価完了の実際の UTC 時刻に設定する必要がある。
Bash で取得：`date -u +%Y-%m-%dT%H:%M:%SZ`。`T00:00:00Z` のような日付のみの近似は決して使わない。

```json
{
  "evaluated_at": "2026-02-21T10:00:00Z",
  "mode": "full",
  "batch_progress": {
    "total": 80,
    "evaluated": 80,
    "status": "completed"
  },
  "skills": {
    "skill-name": {
      "path": "~/.claude/skills/skill-name/SKILL.md",
      "verdict": "Keep",
      "reason": "Concrete, actionable, unique value for X workflow",
      "mtime": "2026-01-15T08:30:00Z"
    }
  }
}
```

## 注

- 評価は盲目：同じチェックリストがすべてのスキルに、origin（ECC、自作、自動抽出）に関係なく適用される
- アーカイブ／削除操作は常に明示的なユーザー確認が必要
- スキル origin による判定分岐なし

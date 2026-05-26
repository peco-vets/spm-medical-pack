---
description: 実装タスクに対して、有界な反復数とスコアリングを伴う generator/evaluator ビルドループを実行する / Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.
---

$ARGUMENTS から以下をパースする：
1. `brief` — ユーザーが構築したいものの1行の説明
2. `--max-iterations N` — （任意、デフォルト15）generator-evaluator サイクルの最大数
3. `--pass-threshold N` — （任意、デフォルト7.0）合格する重み付きスコア
4. `--skip-planner` — （任意）planner をスキップし、spec.md が既に存在することを前提とする
5. `--eval-mode MODE` — （任意、デフォルト "playwright"）playwright, screenshot, code-only のいずれか

## GAN-Style Harness Build

このコマンドは、Anthropic の 2026年3月のハーネス設計論文に触発された3エージェントビルドループを統括する。

### Phase 0: セットアップ
1. プロジェクトルートに `gan-harness/` ディレクトリを作成する
2. サブディレクトリを作成する：`gan-harness/feedback/`、`gan-harness/screenshots/`
3. まだ初期化されていなければ git を初期化する
4. 開始時刻と設定をログ出力する

### Phase 1: 計画（Planner Agent）
`--skip-planner` が設定されていない限り：
1. Task ツール経由でユーザーの brief と共に `gan-planner` エージェントを起動する
2. `gan-harness/spec.md` と `gan-harness/eval-rubric.md` が生成されるのを待つ
3. スペックサマリーをユーザーに表示する
4. Phase 2 へ進む

### Phase 2: Generator-Evaluator ループ
```
iteration = 1
while iteration <= max_iterations:

    # GENERATE
    Launch gan-generator agent via Task tool:
    - Read spec.md
    - If iteration > 1: read feedback/feedback-{iteration-1}.md
    - Build/improve the application
    - Ensure dev server is running
    - Commit changes

    # Wait for generator to finish

    # EVALUATE
    Launch gan-evaluator agent via Task tool:
    - Read eval-rubric.md and spec.md
    - Test the live application (mode: playwright/screenshot/code-only)
    - Score against rubric
    - Write feedback to feedback/feedback-{iteration}.md

    # Wait for evaluator to finish

    # CHECK SCORE
    Read feedback/feedback-{iteration}.md
    Extract weighted total score

    if score >= pass_threshold:
        Log "PASSED at iteration {iteration} with score {score}"
        Break

    if iteration >= 3 and score has not improved in last 2 iterations:
        Log "PLATEAU detected — stopping early"
        Break

    iteration += 1
```

### Phase 3: サマリー
1. すべての feedback ファイルを読む
2. 最終スコアと反復履歴を表示する
3. スコア推移を表示する：`iteration 1: 4.2 → iteration 2: 5.8 → ... → iteration N: 7.5`
4. 最終評価から残った問題を一覧する
5. 合計時間と推定コストを報告する

### 出力

```markdown
## GAN Harness Build Report

**Brief:** [original prompt]
**Result:** PASS/FAIL
**Iterations:** N / max
**Final Score:** X.X / 10

### Score Progression
| Iter | Design | Originality | Craft | Functionality | Total |
|------|--------|-------------|-------|---------------|-------|
| 1 | ... | ... | ... | ... | X.X |
| 2 | ... | ... | ... | ... | X.X |
| N | ... | ... | ... | ... | X.X |

### Remaining Issues
- [Any issues from final evaluation]

### Files Created
- gan-harness/spec.md
- gan-harness/eval-rubric.md
- gan-harness/feedback/feedback-001.md through feedback-NNN.md
- gan-harness/generator-state.md
- gan-harness/build-report.md
```

完全なレポートを `gan-harness/build-report.md` に書き出す。

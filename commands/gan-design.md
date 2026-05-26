---
description: フロントエンドまたはビジュアル作業に対して、有界な反復数とスコアリングを伴う generator/evaluator デザインループを実行する / Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.
---

$ARGUMENTS から以下をパースする：
1. `brief` — 作成するデザインのユーザー説明
2. `--max-iterations N` — （任意、デフォルト10）design-evaluate サイクルの最大数
3. `--pass-threshold N` — （任意、デフォルト7.5）合格する重み付きスコア（デザイン用に高めのデフォルト）

## GAN-Style Design Harness

フロントエンドのデザイン品質に焦点を当てた2エージェントループ（Generator + Evaluator）。planner なし — brief がそのままスペックとなる。

これは、Anthropic がフロントエンドデザイン実験で使用したのと同じモードで、CSS パースペクティブとドア型ナビゲーションを使った 3D オランダ美術館のような創造的なブレークスルーが見られた。

### セットアップ
1. `gan-harness/` ディレクトリを作成する
2. brief を直接 `gan-harness/spec.md` として書き出す
3. Design Quality と Originality に追加の重みを付けたデザイン特化の `gan-harness/eval-rubric.md` を書き出す

### デザイン特化の Eval Rubric
```markdown
### Design Quality (weight: 0.35)
### Originality (weight: 0.30)
### Craft (weight: 0.25)
### Functionality (weight: 0.10)
```

注：創造的なブレークスルーを促すため、Originality の重みは高め（0.30 vs 0.20）。デザインモードは視覚品質に焦点を当てるため、Functionality の重みは低め。

### ループ
`/project:gan-build` Phase 2 と同様、ただし：
- planner をスキップする
- デザイン特化のルーブリックを使用する
- Generator プロンプトは機能の完全性よりも視覚品質を強調する
- Evaluator プロンプトは「すべての機能が動くか？」よりも「これはデザイン賞を獲れるか？」を強調する

### gan-build との主な違い
Generator は次のように指示される：「あなたの主目標は視覚的卓越性である。機能的だが醜いアプリより、未完成でも見事なアプリの方が優れている。創造的な飛躍を求めよ — 異例なレイアウト、カスタムアニメーション、独特なカラーワーク。」

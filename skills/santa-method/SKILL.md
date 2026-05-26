---
name: santa-method
description: "収束ループ付きマルチエージェント敵対的検証（multi-agent adversarial verification with convergence loop）。2 つの独立したレビューエージェントが両方とも合格してから出力を出す。"
origin: "Ronald Skelton - Founder, RapportScore.ai"
---

# Santa Method

マルチエージェント敵対的検証フレームワーク。リストを作り、二度チェックする。悪い子なら、いい子になるまで直す。

中核となる洞察：単一エージェントが自身の出力をレビューすると、その出力を生み出した同じバイアス、知識ギャップ、系統的エラーを共有してしまう。共有コンテキストを持たない 2 つの独立したレビュアーがこの失敗モードを破る。

## 起動するタイミング

このスキルを呼び出すのは：
- 出力が公開、デプロイ、またはエンドユーザーに消費される場合
- コンプライアンス、規制、ブランド制約を強制する必要がある場合
- 人間レビューなしでコードが本番に出る場合
- コンテンツの正確性が重要な場合（技術ドキュメント、教育資料、顧客向けコピー）
- スポットチェックが系統的パターンを見逃す規模でのバッチ生成
- ハルシネーションリスクが高い場合（主張、統計、API リファレンス、法的言語）

内部下書き、探索的調査、決定的検証のあるタスク（それには build/test/lint パイプラインを使う）には使用しない。

## アーキテクチャ

```
┌─────────────┐
│  GENERATOR   │  Phase 1: Make a List
│  (Agent A)   │  Produce the deliverable
└──────┬───────┘
       │ output
       ▼
┌──────────────────────────────┐
│     DUAL INDEPENDENT REVIEW   │  Phase 2: Check It Twice
│                                │
│  ┌───────────┐ ┌───────────┐  │  Two agents, same rubric,
│  │ Reviewer B │ │ Reviewer C │  │  no shared context
│  └─────┬─────┘ └─────┬─────┘  │
│        │              │        │
└────────┼──────────────┼────────┘
         │              │
         ▼              ▼
┌──────────────────────────────┐
│        VERDICT GATE           │  Phase 3: Naughty or Nice
│                                │
│  B passes AND C passes → NICE  │  Both must pass.
│  Otherwise → NAUGHTY           │  No exceptions.
└──────┬──────────────┬─────────┘
       │              │
    NICE           NAUGHTY
       │              │
       ▼              ▼
   [ SHIP ]    ┌─────────────┐
               │  FIX CYCLE   │  Phase 4: Fix Until Nice
               │              │
               │ iteration++  │  Collect all flags.
               │ if i > MAX:  │  Fix all issues.
               │   escalate   │  Re-run both reviewers.
               │ else:        │  Loop until convergence.
               │   goto Ph.2  │
               └──────────────┘
```

## フェーズ詳細

### フェーズ 1：リストを作る（生成）

主タスクを実行する。通常の生成ワークフローに変更なし。Santa Method は生成後の検証層であり、生成戦略ではない。

```python
# The generator runs as normal
output = generate(task_spec)
```

### フェーズ 2：二度チェックする（独立した二重レビュー）

2 つのレビューエージェントを並列に起動する。重要な不変条件：

1. **コンテキスト分離** — どちらのレビュアーも他方の評価を見ない
2. **同一ルブリック** — 両方が同じ評価基準を受け取る
3. **同じ入力** — 両方が元の仕様と生成された出力を受け取る
4. **構造化出力** — 各々が散文ではなく型付き判定を返す

```python
REVIEWER_PROMPT = """
You are an independent quality reviewer. You have NOT seen any other review of this output.

## Task Specification
{task_spec}

## Output Under Review
{output}

## Evaluation Rubric
{rubric}

## Instructions
Evaluate the output against EACH rubric criterion. For each:
- PASS: criterion fully met, no issues
- FAIL: specific issue found (cite the exact problem)

Return your assessment as structured JSON:
{
  "verdict": "PASS" | "FAIL",
  "checks": [
    {"criterion": "...", "result": "PASS|FAIL", "detail": "..."}
  ],
  "critical_issues": ["..."],   // blockers that must be fixed
  "suggestions": ["..."]         // non-blocking improvements
}

Be rigorous. Your job is to find problems, not to approve.
"""
```

```python
# Spawn reviewers in parallel (Claude Code subagents)
review_b = Agent(prompt=REVIEWER_PROMPT.format(...), description="Santa Reviewer B")
review_c = Agent(prompt=REVIEWER_PROMPT.format(...), description="Santa Reviewer C")

# Both run concurrently — neither sees the other
```

### ルブリック設計

ルブリックは最も重要な入力。曖昧なルブリックは曖昧なレビューを生む。各基準には客観的なパス／フェイル条件が必要。

| 基準 | パス条件 | 失敗シグナル |
|-----------|---------------|----------------|
| 事実の正確性 | すべての主張がソース資料または共通知識に対して検証可能 | 捏造された統計、間違ったバージョン番号、存在しない API |
| ハルシネーションなし | 捏造されたエンティティ、引用、URL、参照がない | 存在しないページへのリンク、ソースのない引用 |
| 完全性 | 仕様のすべての要件が対処されている | 欠落セクション、スキップされたエッジケース、不完全なカバレッジ |
| コンプライアンス | すべてのプロジェクト固有の制約に合格 | 禁止用語の使用、トーン違反、規制非準拠 |
| 内部一貫性 | 出力内に矛盾がない | セクション A は X と言い、セクション B は not-X と言う |
| 技術的正確性 | コードがコンパイル／実行され、アルゴリズムが健全 | 構文エラー、ロジックバグ、誤った複雑度主張 |

#### ドメイン固有ルブリック拡張

**コンテンツ／マーケティング：**
- ブランドボイス遵守
- SEO 要件達成（キーワード密度、メタタグ、構造）
- 競合商標の誤用なし
- CTA 存在と正しいリンク

**コード：**
- 型安全性（`any` リークなし、適切な null 処理）
- エラー処理カバレッジ
- セキュリティ（コード内のシークレットなし、入力バリデーション、インジェクション防止）
- 新パスのテストカバレッジ

**コンプライアンスセンシティブ（規制、法務、金融）：**
- 結果保証や根拠のない主張なし
- 必要な免責事項あり
- 承認用語のみ
- 管轄に適した言語

### フェーズ 3：悪い子か良い子か（判定ゲート）

```python
def santa_verdict(review_b, review_c):
    """Both reviewers must pass. No partial credit."""
    if review_b.verdict == "PASS" and review_c.verdict == "PASS":
        return "NICE"  # Ship it

    # Merge flags from both reviewers, deduplicate
    all_issues = dedupe(review_b.critical_issues + review_c.critical_issues)
    all_suggestions = dedupe(review_b.suggestions + review_c.suggestions)

    return "NAUGHTY", all_issues, all_suggestions
```

両方合格が必要な理由：レビュアー一人だけが問題を捉えたら、その問題は本物。もう一人のレビュアーの盲点こそ Santa Method が排除する失敗モード。

### フェーズ 4：いい子になるまで直す（収束ループ）

```python
MAX_ITERATIONS = 3

for iteration in range(MAX_ITERATIONS):
    verdict, issues, suggestions = santa_verdict(review_b, review_c)

    if verdict == "NICE":
        log_santa_result(output, iteration, "passed")
        return ship(output)

    # Fix all critical issues (suggestions are optional)
    output = fix_agent.execute(
        output=output,
        issues=issues,
        instruction="Fix ONLY the flagged issues. Do not refactor or add unrequested changes."
    )

    # Re-run BOTH reviewers on fixed output (fresh agents, no memory of previous round)
    review_b = Agent(prompt=REVIEWER_PROMPT.format(output=output, ...))
    review_c = Agent(prompt=REVIEWER_PROMPT.format(output=output, ...))

# Exhausted iterations — escalate
log_santa_result(output, MAX_ITERATIONS, "escalated")
escalate_to_human(output, issues)
```

重要：各レビューラウンドは**新しいエージェント**を使う。レビュアーは前のラウンドからメモリを持ち越してはならない。先行コンテキストはアンカリングバイアスを作る。

## 実装パターン

### パターン A：Claude Code サブエージェント（推奨）

サブエージェントは真のコンテキスト分離を提供する。各レビュアーは共有状態のない別プロセス。

```bash
# In a Claude Code session, use the Agent tool to spawn reviewers
# Both agents run in parallel for speed
```

```python
# Pseudocode for Agent tool invocation
reviewer_b = Agent(
    description="Santa Review B",
    prompt=f"Review this output for quality...\n\nRUBRIC:\n{rubric}\n\nOUTPUT:\n{output}"
)
reviewer_c = Agent(
    description="Santa Review C",
    prompt=f"Review this output for quality...\n\nRUBRIC:\n{rubric}\n\nOUTPUT:\n{output}"
)
```

### パターン B：順次インライン（フォールバック）

サブエージェントが利用不可な場合、明示的なコンテキストリセットで分離をシミュレートする：

1. 出力を生成
2. 新コンテキスト：「あなたはレビュアー 1。このルブリックのみで評価。問題を見つける」
3. 所見を逐語的に記録
4. コンテキストを完全にクリア
5. 新コンテキスト：「あなたはレビュアー 2。このルブリックのみで評価。問題を見つける」
6. 両方のレビューを比較、修正、繰り返し

サブエージェントパターンは厳密に優れている — インラインシミュレーションはレビュアー間のコンテキストブリードのリスクがある。

### パターン C：バッチサンプリング

大規模バッチ（100+ アイテム）では、全アイテムへのフル Santa はコスト過大。層化サンプリングを使う：

1. ランダムサンプル（バッチの 10-15%、最小 5 アイテム）に Santa を実行
2. 失敗をタイプで分類（ハルシネーション、コンプライアンス、完全性など）
3. 系統的パターンが現れたら、ターゲットを絞った修正をバッチ全体に適用
4. 修正されたバッチを再サンプル、再検証
5. クリーンサンプルが合格するまで継続

```python
import random

def santa_batch(items, rubric, sample_rate=0.15):
    sample = random.sample(items, max(5, int(len(items) * sample_rate)))

    for item in sample:
        result = santa_full(item, rubric)
        if result.verdict == "NAUGHTY":
            pattern = classify_failure(result.issues)
            items = batch_fix(items, pattern)  # Fix all items matching pattern
            return santa_batch(items, rubric)   # Re-sample

    return items  # Clean sample → ship batch
```

## 失敗モードと緩和策

| 失敗モード | 症状 | 緩和策 |
|-------------|---------|------------|
| 無限ループ | 修正後もレビュアーが新しい問題を見つけ続ける | 最大反復キャップ（3）。エスカレート。 |
| ラバースタンプ | 両レビュアーがすべてを通す | 敵対的プロンプト：「あなたの仕事は問題を見つけることで、承認することではない」 |
| 主観的ドリフト | レビュアーがエラーではなくスタイル選好をフラグ | 客観的パス／フェイル基準のみのタイトなルブリック |
| 修正リグレッション | 問題 A の修正が問題 B を導入 | 各ラウンドの新しいレビュアーがリグレッションを捕捉 |
| レビュアー合意バイアス | 両レビュアーが同じものを見逃す | 独立性で緩和、排除ではない。重要な出力には 3 番目のレビュアーまたは人間スポットチェックを追加。 |
| コスト爆発 | 大きな出力での反復が多すぎる | バッチサンプリングパターン。検証サイクルあたりの予算上限。 |

## 他スキルとの統合

| スキル | 関係 |
|-------|-------------|
| Verification Loop | 決定的チェック（ビルド、リント、テスト）に使う。Santa は意味チェック（正確性、ハルシネーション）に。verification-loop を先に、Santa を次に実行。 |
| Eval Harness | Santa Method の結果は eval メトリックに入力される。時間経過で生成器品質を測るため Santa ラン全体で pass@k を追跡。 |
| Continuous Learning v2 | Santa 所見は本能になる。同じ基準での繰り返し失敗 → パターン回避を学習行動として獲得。 |
| Strategic Compact | コンパクト前に Santa を実行。検証中にレビューコンテキストを失わない。 |

## メトリック

Santa Method の有効性を測るためこれらを追跡する：

- **初回パス率**：ラウンド 1 で Santa を通過する出力の %（目標：>70%）
- **収束までの平均反復**：NICE までの平均ラウンド（目標：<1.5）
- **問題分類**：失敗タイプの分布（ハルシネーション vs 完全性 vs コンプライアンス）
- **レビュアー合意**：両レビュアーがフラグした問題 vs 一方のみの %（低合意 = ルブリックを締めるべき）
- **エスケープ率**：Santa が捕捉すべきだった出荷後に見つかった問題（目標：0）

## コスト分析

Santa Method は検証サイクルあたり生成単独のトークンコストの約 2-3 倍。ほとんどの高ステークス出力にとって、これはお得：

```
Cost of Santa = (generation tokens) + 2×(review tokens per round) × (avg rounds)
Cost of NOT Santa = (reputation damage) + (correction effort) + (trust erosion)
```

バッチ操作では、サンプリングパターンがコストをフル検証の約 15-20% に削減しながら、系統的問題の >90% を捕捉する。

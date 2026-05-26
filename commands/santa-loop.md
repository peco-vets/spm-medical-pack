---
description: 敵対的デュアルレビュー収束ループ — 2つの独立したモデルレビュワーがコードを出荷する前に両方とも承認する必要がある / Adversarial dual-review convergence loop — two independent model reviewers must both approve before code ships.
---

# Santa Loop

santa-method スキルを使った敵対的デュアルレビュー収束ループ。2つの独立したレビュワー — 異なるモデル、共有コンテキストなし — がコードが出荷される前に両方とも NICE を返す必要がある。

## 目的

現在のタスク出力に対して2つの独立したレビュワー（Claude Opus + 外部モデル）を実行する。コードがプッシュされる前に両方が NICE を返す必要がある。どちらかが NAUGHTY を返したら、フラグされたすべての問題を修正し、コミットし、新鮮なレビュワーで再実行する — 最大3ラウンドまで。

## Usage

```
/santa-loop [file-or-glob | description]
```

## ワークフロー

### Step 1: 何をレビューするかを特定する

`$ARGUMENTS` からスコープを決定するか、未コミット変更にフォールバックする：

```bash
git diff --name-only HEAD
```

変更されたすべてのファイルを読んで完全なレビューコンテキストを構築する。`$ARGUMENTS` がパス、ファイル、または説明を指定する場合、それをスコープとして使う。

### Step 2: ルーブリックを構築する

レビューするファイルタイプに適したルーブリックを構築する。すべての基準には客観的な PASS/FAIL 条件が必要である。少なくとも以下を含める：

| Criterion | Pass Condition |
|-----------|---------------|
| Correctness | ロジックが健全、バグなし、エッジケース対応 |
| Security | シークレット、インジェクション、XSS、または OWASP Top 10 問題なし |
| Error handling | エラーが明示的に処理され、サイレントな飲み込みなし |
| Completeness | すべての要件に対応、ケース不足なし |
| Internal consistency | ファイルまたはセクション間の矛盾なし |
| No regressions | 変更が既存の動作を壊さない |

ファイルタイプに基づいてドメイン固有の基準を追加する（例：TS の型安全性、Rust のメモリ安全性、SQL のマイグレーション安全性）。

### Step 3: デュアル独立レビュー

Agent ツールを使って2つのレビュワーを**並列**に起動する（並行実行のため単一のメッセージで両方）。判定ゲート（Step 4）に進む前に両方が完了する必要がある。

各レビュワーはすべてのルーブリック基準を PASS または FAIL として評価し、構造化された JSON を返す：

```json
{
  "verdict": "PASS" | "FAIL",
  "checks": [
    {"criterion": "...", "result": "PASS|FAIL", "detail": "..."}
  ],
  "critical_issues": ["..."],
  "suggestions": ["..."]
}
```

判定ゲート（Step 4）はこれらを NICE/NAUGHTY にマップする：両方が PASS → NICE、どちらかが FAIL → NAUGHTY。

#### Reviewer A: Claude Agent（常に実行）

完全なルーブリック + レビュー対象のすべてのファイルで Agent（subagent_type: `code-reviewer`、model: `opus`）を起動する。プロンプトには以下を含める：
- 完全なルーブリック
- レビュー対象のすべてのファイルの内容
- 「あなたは独立した品質レビュワーである。他のレビューを見ていない。あなたの仕事は問題を見つけることであり、承認することではない。」
- 上記の構造化された JSON 判定を返す

#### Reviewer B: 外部モデル（外部 CLI がインストールされていない場合のみ Claude フォールバック）

まず、どの CLI が利用可能かを検出する：
```bash
command -v codex >/dev/null 2>&1 && echo "codex" || true
command -v gemini >/dev/null 2>&1 && echo "gemini" || true
```

レビュワープロンプト（Reviewer A と同じルーブリック + 指示）を構築し、ユニークな temp ファイルに書き出す：
```bash
PROMPT_FILE=$(mktemp /tmp/santa-reviewer-b-XXXXXX.txt)
cat > "$PROMPT_FILE" << 'EOF'
... full rubric + file contents + reviewer instructions ...
EOF
```

最初に利用可能な CLI を使う：

**Codex CLI**（インストールされている場合）
```bash
codex exec --sandbox read-only -m gpt-5.4 -C "$(pwd)" - < "$PROMPT_FILE"
rm -f "$PROMPT_FILE"
```

**Gemini CLI**（インストールされており codex でない場合）
```bash
gemini -p "$(cat "$PROMPT_FILE")" -m gemini-2.5-pro
rm -f "$PROMPT_FILE"
```

**Claude Agent フォールバック**（`codex` も `gemini` もインストールされていない場合のみ）
2つ目の Claude Agent（subagent_type: `code-reviewer`、model: `opus`）を起動する。両レビュワーが同じモデルファミリーを共有することを警告にログする — 真のモデル多様性は達成されないが、コンテキスト分離は依然として強制される。

すべての場合で、レビュワーは Reviewer A と同じ構造化された JSON 判定を返す必要がある。

### Step 4: 判定ゲート

- **両方 PASS** → **NICE** — Step 6（push）へ進む
- **どちらか FAIL** → **NAUGHTY** — 両レビュワーからのすべてのクリティカルな問題をマージし、重複排除し、Step 5 へ進む

### Step 5: 修正サイクル（NAUGHTY パス）

1. 両レビュワーからのすべてのクリティカルな問題を表示する
2. フラグされたすべての問題を修正する — フラグされたものだけを変更し、ドライブバイのリファクタはしない
3. すべての修正を単一のコミットでコミットする：
   ```
   fix: address santa-loop review findings (round N)
   ```
4. **新鮮なレビュワー**（前ラウンドの記憶なし）で Step 3 を再実行する
5. 両方が PASS を返すまで繰り返す

**最大3反復**。3ラウンド後も NAUGHTY なら、停止して残りの問題を提示する：

```
SANTA LOOP ESCALATION (exceeded 3 iterations)

Remaining issues after 3 rounds:
- [list all unresolved critical issues from both reviewers]

Manual review required before proceeding.
```

プッシュしてはならない。

### Step 6: Push（NICE パス）

両レビュワーが PASS を返したとき：

```bash
git push -u origin HEAD
```

### Step 7: 最終レポート

出力レポートを表示する（下記の Output セクションを参照）。

## 出力

```
SANTA VERDICT: [NICE / NAUGHTY (escalated)]

Reviewer A (Claude Opus):   [PASS/FAIL]
Reviewer B ([model used]):  [PASS/FAIL]

Agreement:
  Both flagged:      [issues caught by both]
  Reviewer A only:   [issues only A caught]
  Reviewer B only:   [issues only B caught]

Iterations: [N]/3
Result:     [PUSHED / ESCALATED TO USER]
```

## 注意事項

- Reviewer A（Claude Opus）は常に実行される — ツーリングに関係なく少なくとも1つの強いレビュワーを保証する。
- モデル多様性が Reviewer B の目標である。GPT-5.4 または Gemini 2.5 Pro が真の独立性を与える — 異なる訓練データ、異なるバイアス、異なる盲点。Claude のみのフォールバックはコンテキスト分離経由で依然として価値を提供するが、モデル多様性を失う。
- 最も強い利用可能なモデルが使われる：Reviewer A には Opus、Reviewer B には GPT-5.4 または Gemini 2.5 Pro。
- 外部レビュワーはレビュー中のリポミューテーションを防ぐために `--sandbox read-only`（Codex）で実行される。
- 各ラウンドで新鮮なレビュワーは、前回の発見からのアンカリングバイアスを防ぐ。
- ルーブリックが最も重要な入力である。レビュワーがゴム判を押すか主観的なスタイルの問題をフラグする場合、それを厳しくする。
- NAUGHTY ラウンドでコミットが行われるため、ループが中断されても修正が保持される。
- プッシュは NICE 後のみに行われる — ループ中には決してない。

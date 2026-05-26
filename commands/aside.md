---
description: 現在のタスクの文脈を失わずに、サイドの質問に素早く答える / Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.
---

# Aside Command

タスクの途中で質問し、即座に焦点を絞った回答を受け取り、その後、中断した地点から作業を続行する。現在のタスク・ファイル・コンテキストは一切変更されない。

## 利用シーン

- Claude が作業中に何かが気になり、勢いを失いたくない場合
- Claude が現在編集中のコードについて簡単な説明が欲しい場合
- タスクを脱線させずに、決定について第二の意見や明確化が欲しい場合
- Claude が進める前に、エラー・概念・パターンを理解する必要がある場合
- 新しいセッションを開始せずに、現在のタスクとは無関係のことを質問したい場合

## Usage

```
/aside <your question>
/aside what does this function actually return?
/aside is this pattern thread-safe?
/aside why are we using X instead of Y here?
/aside what's the difference between foo() and bar()?
/aside should we be worried about the N+1 query we just added?
```

## プロセス

### Step 1: 現在のタスク状態を凍結する

質問に答える前に、頭の中で以下を記録する：
- アクティブなタスクは何か？（どのファイル・機能・問題に取り組んでいたか）
- `/aside` が呼ばれた瞬間、どのステップが進行中だったか？
- 次に何が起こる予定だったか？

aside の間は、ファイルを触ったり、編集したり、作成したり、削除したりしてはならない。

### Step 2: 質問に直接答える

完全かつ有用でありながら、最も簡潔な形で質問に答える。

- 推論ではなく、答えから先に述べる
- 短く保つ — 完全な説明が必要なら、タスクの後に深掘りすることを提案する
- 質問が現在のファイルや作業中のコードに関するものであれば、正確に参照する（必要ならファイルパスと行番号）
- 回答にファイルの読み込みが必要なら読み込む — ただし読むだけで、書き込みは絶対にしない

回答は以下の形式でフォーマットする：

```
ASIDE: [restate the question briefly]

[Your answer here]

— Back to task: [one-line description of what was being done]
```

### Step 3: メインタスクを再開する

回答を提示したら、即座に、アクティブなタスクが一時停止された正確な地点から続行する。aside の回答がブロッカーや現在のアプローチを再考すべき理由を明らかにしない限り、再開の許可を求めてはならない（エッジケース参照）。

---

## エッジケース

**質問が提供されない（`/aside` の後に何もない場合）：**
以下のように応答する：
```
ASIDE: no question provided

What would you like to know? (ask your question and I'll answer without losing the current task context)

— Back to task: [one-line description of what was being done]
```

**質問が現在のタスクの潜在的な問題を明らかにする場合：**
再開する前に明確にフラグを立てる：
```
ASIDE: [answer]

WARNING: Note: This answer suggests [issue] with the current approach. Want to address this before continuing, or proceed as planned?
```
再開する前に、ユーザーの決定を待つ。

**質問が実際にはタスクのリダイレクトである場合（サイドの質問ではない）：**
質問が構築するものを変更することを示唆する場合（例：`/aside actually, let's use Redis instead`）、明確化する：
```
ASIDE: That sounds like a direction change, not just a side question.
Do you want to:
  (a) Answer this as information only and keep the current plan
  (b) Pause the current task and change approach
```
ユーザーの回答を待つ — 仮定をしてはならない。

**質問が現在開いているファイルまたはコードに関する場合：**
ライブコンテキストから答える。ファイルがセッションの早い段階で読み込まれていたら、直接参照する。そうでない場合、今読み込む（読み取り専用）し、file:line 参照で答える。

**アクティブなタスクがない（`/aside` が呼ばれたときに何も進行していない）場合：**
それでも標準のラッパーを使用し、応答の形を一貫させる：
```
ASIDE: [restate the question briefly]

[Your answer here]

— Back to task: no active task to resume
```

**質問が長い回答を必要とする場合：**
本質的な答えを簡潔に伝え、その後提案する：
```
That's the short version. Want a deeper explanation after we finish [current task]?
```

**連続して複数の `/aside` 質問がある場合：**
それぞれを順番に答える。最後の回答後、メインタスクを再開する。aside のチェーンを通じてタスク状態を失わないこと。

**aside の回答がコード変更が必要であることを示唆する場合：**
必要な変更をメモするが、aside の間には実行しない：
```
ASIDE: [answer]

 Worth fixing: [what should be changed]. I'll flag this after the current task unless you want to address it now.
```

**質問が曖昧または漠然としすぎている場合：**
1つの明確化質問をする — 答えるのに必要な情報を得る最短の質問。複数の質問をしてはならない。

---

## 出力例

```
User: /aside what does fetchWithRetry() actually do?

ASIDE: what does fetchWithRetry() do?

fetchWithRetry() (src/api/retry.ts:12) attempts the request up to 3 times with
exponential backoff (250ms → 500ms → 1s). It only retries on 5xx responses and
network errors — 4xx errors are treated as final and not retried.

— Back to task: refactoring the auth middleware in src/middleware/auth.ts
```

```
User: /aside is the approach we're taking thread-safe?

ASIDE: is the current approach thread-safe?

No — the shared cache object in src/cache/store.ts:34 is mutated without locking.
Under concurrent requests this is a race condition. It's low risk in a single-process
Node.js server but would be a real problem with worker threads or clustering.

WARNING: Note: This could affect the feature we're building. Want to address this now or continue and fix it in a follow-up?
```

---

## 注意事項

- aside の間にファイルを変更してはならない — 読み取り専用アクセスのみ
- aside は会話の一時停止であり、新しいタスクではない — 元のタスクは常に再開されなければならない
- 回答を焦点を絞ったものに保つ：ゴールはユーザーを素早くアンブロックすることであり、講義を提供することではない
- aside がより大きな議論を引き起こす場合、aside がブロッカーを明らかにしない限り、まず現在のタスクを終わらせる
- aside は、タスクの結果に明示的に関連していない限り、セッションファイルに保存されない

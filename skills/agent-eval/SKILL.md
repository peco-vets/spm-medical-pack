---
name: agent-eval
description: コーディングエージェント (Claude Code・Aider・Codex 等) のカスタムタスクでのヘッドツーヘッド比較。合格率・コスト・時間・一貫性の各メトリクスで比較する (agent eval, coding agent comparison, Claude Code, Aider, Codex, pass rate, benchmark)。
origin: ECC
tools: Read, Write, Edit, Bash, Grep, Glob
---

# Agent Eval スキル

再現可能なタスク上でコーディングエージェントをヘッドツーヘッドで比較する軽量 CLI ツールである。「どのコーディングエージェントが最良か?」という比較はすべて感覚に頼って行われている — このツールはそれを体系化する。

## 起動するタイミング

- 自分のコードベース上でコーディングエージェント (Claude Code・Aider・Codex 等) を比較する時
- 新しいツールやモデルを採用する前にエージェントパフォーマンスを測定する時
- エージェントがモデルやツールを更新した時に回帰チェックを実行する時
- チームのためにデータに基づくエージェント選定の意思決定を行う時

## インストール

> **Note:** ソースを確認した上で、リポジトリから agent-eval をインストールすること。

## 中核となる概念

### YAML タスク定義

タスクを宣言的に定義する。各タスクは何を行うか、どのファイルに触れるか、成功をどう判定するかを指定する:

```yaml
name: add-retry-logic
description: Add exponential backoff retry to the HTTP client
repo: ./my-project
files:
  - src/http_client.py
prompt: |
  Add retry logic with exponential backoff to all HTTP requests.
  Max 3 retries. Initial delay 1s, max delay 30s.
judge:
  - type: pytest
    command: pytest tests/test_http_client.py -v
  - type: grep
    pattern: "exponential_backoff|retry"
    files: src/http_client.py
commit: "abc1234"  # pin to specific commit for reproducibility
```

### Git Worktree による隔離

各エージェント実行は独自の git worktree を取得する — Docker は不要である。これにより、エージェント同士が干渉したりベースリポジトリを破壊することなく、再現性のある隔離が提供される。

### 収集するメトリクス

| メトリクス | 測定対象 |
|--------|-----------------|
| 合格率 (Pass rate) | エージェントは判定をパスするコードを生成したか? |
| コスト | タスク当たりの API 支出 (利用可能な場合) |
| 時間 | 完了までの実時間秒数 |
| 一貫性 | 繰り返し実行での合格率 (例: 3/3 = 100%) |

## ワークフロー

### 1. タスクを定義する

`tasks/` ディレクトリを作成し、タスクごとに YAML ファイルを配置する:

```bash
mkdir tasks
# Write task definitions (see template above)
```

### 2. エージェントを実行する

タスクに対してエージェントを実行する:

```bash
agent-eval run --task tasks/add-retry-logic.yaml --agent claude-code --agent aider --runs 3
```

各実行は以下を行う:
1. 指定したコミットから新しい git worktree を作成
2. エージェントにプロンプトを渡す
3. 判定基準を実行
4. 合否・コスト・時間を記録

### 3. 結果を比較する

比較レポートを生成する:

```bash
agent-eval report --format table
```

```
Task: add-retry-logic (3 runs each)
┌──────────────┬───────────┬────────┬────────┬─────────────┐
│ Agent        │ Pass Rate │ Cost   │ Time   │ Consistency │
├──────────────┼───────────┼────────┼────────┼─────────────┤
│ claude-code  │ 3/3       │ $0.12  │ 45s    │ 100%        │
│ aider        │ 2/3       │ $0.08  │ 38s    │  67%        │
└──────────────┴───────────┴────────┴────────┴─────────────┘
```

## 判定タイプ

### コードベース (決定論的)

```yaml
judge:
  - type: pytest
    command: pytest tests/ -v
  - type: command
    command: npm run build
```

### パターンベース

```yaml
judge:
  - type: grep
    pattern: "class.*Retry"
    files: src/**/*.py
```

### モデルベース (LLM-as-judge)

```yaml
judge:
  - type: llm
    prompt: |
      Does this implementation correctly handle exponential backoff?
      Check for: max retries, increasing delays, jitter.
```

## ベストプラクティス

- **3〜5 タスクから始める** — おもちゃのような例ではなく実際のワークロードを代表するもの
- **エージェント毎に最低 3 試行実行する** — エージェントは非決定論的なので分散を捕捉する
- **タスク YAML でコミットを固定する** — 結果が日や週をまたいで再現可能になる
- **タスク毎に最低 1 つの決定論的判定を含める** (テスト・ビルド) — LLM 判定はノイズを増やす
- **合格率と並んでコストを追跡する** — 10 倍のコストで 95% のエージェントは正しい選択でないかもしれない
- **タスク定義をバージョン管理する** — これらはテストフィクスチャでありコードとして扱う

## リンク

- リポジトリ: [github.com/joaquinhuigomez/agent-eval](https://github.com/joaquinhuigomez/agent-eval)

---
name: evolve
description: 本能（instincts）を分析し、進化した構造を提案または生成する / Analyze instincts and suggest or generate evolved structures
command: true
---

# Evolve Command

## 実装

プラグインのルートパスを使って instinct CLI を実行する：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" evolve [--generate]
```

または `CLAUDE_PLUGIN_ROOT` が設定されていない（手動インストール）場合：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py evolve [--generate]
```

本能を分析し、関連するものをより高レベルの構造へクラスタリングする：
- **Commands**：本能がユーザー起動のアクションを記述する場合
- **Skills**：本能が自動トリガーされる振る舞いを記述する場合
- **Agents**：本能が複雑な多段プロセスを記述する場合

## Usage

```
/evolve                    # Analyze all instincts and suggest evolutions
/evolve --generate         # Also generate files under evolved/{skills,commands,agents}
```

## 進化ルール

### → Command（ユーザー起動）
本能がユーザーが明示的に要求するアクションを記述する場合：
- 「ユーザーが…を要求したとき」に関する複数の本能
- 「新しい X を作成するとき」のようなトリガーを持つ本能
- 反復可能なシーケンスに従う本能

例：
- `new-table-step1`: "when adding a database table, create migration"
- `new-table-step2`: "when adding a database table, update schema"
- `new-table-step3`: "when adding a database table, regenerate types"

→ Creates: **new-table** command

### → Skill（自動トリガー）
本能が自動的に起こるべき振る舞いを記述する場合：
- パターンマッチングトリガー
- エラーハンドリング応答
- コードスタイル徹底

例：
- `prefer-functional`: "when writing functions, prefer functional style"
- `use-immutable`: "when modifying state, use immutable patterns"
- `avoid-classes`: "when designing modules, avoid class-based design"

→ Creates: `functional-patterns` skill

### → Agent（深さ/分離が必要）
本能が分離によってメリットを得る複雑な多段プロセスを記述する場合：
- デバッグワークフロー
- リファクタリングシーケンス
- リサーチタスク

例：
- `debug-step1`: "when debugging, first check logs"
- `debug-step2`: "when debugging, isolate the failing component"
- `debug-step3`: "when debugging, create minimal reproduction"
- `debug-step4`: "when debugging, verify fix with test"

→ Creates: **debugger** agent

## やること

1. 現在のプロジェクトコンテキストを検出する
2. プロジェクト + グローバル本能を読む（ID 衝突時はプロジェクト優先）
3. トリガー/ドメインパターンで本能をグループ化する
4. 以下を特定する：
   - Skill 候補（2つ以上の本能を持つトリガークラスタ）
   - Command 候補（高信頼度のワークフロー本能）
   - Agent 候補（より大きな高信頼度のクラスタ）
5. 該当する場合、プロモーション候補（project -> global）を表示する
6. `--generate` が渡された場合、以下にファイルを書き込む：
   - Project scope: `~/.claude/homunculus/projects/<project-id>/evolved/`
   - Global fallback: `~/.claude/homunculus/evolved/`

## 出力フォーマット

```
============================================================
  EVOLVE ANALYSIS - 12 instincts
  Project: my-app (a1b2c3d4e5f6)
  Project-scoped: 8 | Global: 4
============================================================

High confidence instincts (>=80%): 5

## SKILL CANDIDATES
1. Cluster: "adding tests"
   Instincts: 3
   Avg confidence: 82%
   Domains: testing
   Scopes: project

## COMMAND CANDIDATES (2)
  /adding-tests
    From: test-first-workflow [project]
    Confidence: 84%

## AGENT CANDIDATES (1)
  adding-tests-agent
    Covers 3 instincts
    Avg confidence: 82%
```

## フラグ

- `--generate`: 分析出力に加えて、進化したファイルを生成する

## 生成ファイル形式

### Command
```markdown
---
name: new-table
description: Create a new database table with migration, schema update, and type generation
command: /new-table
evolved_from:
  - new-table-migration
  - update-schema
  - regenerate-types
---

# New Table Command

[Generated content based on clustered instincts]

## Steps
1. ...
2. ...
```

### Skill
```markdown
---
name: functional-patterns
description: Enforce functional programming patterns
evolved_from:
  - prefer-functional
  - use-immutable
  - avoid-classes
---

# Functional Patterns Skill

[Generated content based on clustered instincts]
```

### Agent
```markdown
---
name: debugger
description: Systematic debugging agent
model: sonnet
evolved_from:
  - debug-check-logs
  - debug-isolate
  - debug-reproduce
---

# Debugger Agent

[Generated content based on clustered instincts]
```

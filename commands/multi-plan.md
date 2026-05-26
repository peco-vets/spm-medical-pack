---
description: プロダクションコードを変更せずに、マルチモデル実装計画を作成する / Create a multi-model implementation plan without modifying production code.
---

# Plan - Multi-Model Collaborative Planning

マルチモデル協調計画 - コンテキスト取得 + デュアルモデル分析 → ステップバイステップの実装計画を生成する。

$ARGUMENTS

---

## コアプロトコル

- **Language Protocol**：ツール/モデルとのやり取りには **English** を使い、ユーザーとはユーザーの言語でコミュニケーションする
- **Mandatory Parallel**：Codex/Gemini 呼び出しは `run_in_background: true` を使用しなければならない（メインスレッドのブロックを避けるため、単一モデル呼び出しを含む）
- **Code Sovereignty**：外部モデルは**ファイルシステム書き込みアクセス権ゼロ**、すべての修正は Claude による
- **Stop-Loss Mechanism**：現フェーズ出力が検証されるまで次フェーズへ進まない
- **Planning Only**：このコマンドはコンテキスト読み込みと `.claude/plan/*` 計画ファイルへの書き込みを許可するが、**プロダクションコードを決して修正しない**

---

## マルチモデル呼び出し仕様

**Call Syntax**（並列：`run_in_background: true` を使用）：

```
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend <codex|gemini> {{GEMINI_MODEL_FLAG}}- \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement>
Context: <retrieved project context>
</TASK>
OUTPUT: Step-by-step implementation plan with pseudo-code. DO NOT modify any files.
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})
```

**Model Parameter Notes**:
- `{{GEMINI_MODEL_FLAG}}`：`--backend gemini` を使う場合は `--gemini-model gemini-3-pro-preview` に置換（末尾スペース注意）；codex の場合は空文字列

**Role Prompts**:

| Phase | Codex | Gemini |
|-------|-------|--------|
| Analysis | `~/.claude/.ccg/prompts/codex/analyzer.md` | `~/.claude/.ccg/prompts/gemini/analyzer.md` |
| Planning | `~/.claude/.ccg/prompts/codex/architect.md` | `~/.claude/.ccg/prompts/gemini/architect.md` |

**Session Reuse**：各呼び出しは `SESSION_ID: xxx` を返す（通常 wrapper が出力する）。後続の `/ccg:execute` 利用のために**必ず保存する**。

**バックグラウンドタスクを待つ**（最大タイムアウト 600000ms = 10分）：

```
TaskOutput({ task_id: "<task_id>", block: true, timeout: 600000 })
```

**IMPORTANT**:
- `timeout: 600000` を指定すること。さもなければデフォルト30秒で早期タイムアウトする
- 10分後もまだ未完了なら、`TaskOutput` でポーリングを続行し、**プロセスを決して kill しない**
- タイムアウトで待機がスキップされた場合、**続行を待つか kill するかをユーザーに尋ねるために `AskUserQuestion` を必ず呼ぶ**

---

## 実行ワークフロー

**Planning Task**：$ARGUMENTS

### Phase 1: 完全コンテキスト取得

`[Mode: Research]`

#### 1.1 Prompt Enhancement（最初に必ず実行）

**ace-tool MCP が利用可能な場合**、`mcp__ace-tool__enhance_prompt` ツールを呼ぶ：

```
mcp__ace-tool__enhance_prompt({
  prompt: "$ARGUMENTS",
  conversation_history: "<last 5-10 conversation turns>",
  project_root_path: "$PWD"
})
```

強化されたプロンプトを待ち、**後続のすべてのフェーズで元の $ARGUMENTS を強化結果に置換する**。

**ace-tool MCP が利用不可な場合**：このステップをスキップし、後続のすべてのフェーズで元の `$ARGUMENTS` をそのまま使う。

#### 1.2 Context Retrieval

**ace-tool MCP が利用可能な場合**、`mcp__ace-tool__search_context` ツールを呼ぶ：

```
mcp__ace-tool__search_context({
  query: "<semantic query based on enhanced requirement>",
  project_root_path: "$PWD"
})
```

- 自然言語を使ってセマンティッククエリを構築する（Where/What/How）
- **仮定に基づいて決して答えない**

**ace-tool MCP が利用不可な場合**、フォールバックとして Claude Code 組み込みツールを使う：
1. **Glob**：パターンで関連ファイルを見つける（例：`Glob("**/*.ts")`、`Glob("src/**/*.py")`）
2. **Grep**：主要なシンボル、関数名、クラス定義を検索する（例：`Grep("className|functionName")`）
3. **Read**：発見されたファイルを読み込み、完全なコンテキストを収集する
4. **Task (Explore agent)**：より深い探索には、コードベース全体を検索するために `subagent_type: "Explore"` で `Task` を使う

#### 1.3 完全性チェック

- 関連するクラス、関数、変数の**完全な定義とシグネチャ**を取得しなければならない
- コンテキストが不十分なら、**再帰的取得**をトリガーする
- 出力を優先する：エントリファイル + 行番号 + 主要なシンボル名；曖昧さを解消するために必要な場合のみ最小限のコードスニペットを追加

#### 1.4 要件アライメント

- 要件にまだ曖昧さがある場合、ユーザーへのガイディング質問を**必ず**出力する
- 要件境界が明確になるまで（漏れなし、冗長なし）

### Phase 2: マルチモデル協調分析

`[Mode: Analysis]`

#### 2.1 入力を配布する

**Codex と Gemini を並列呼び出し**（`run_in_background: true`）：

両モデルに**元の要件**（プリセット意見なし）を配布する：

1. **Codex Backend Analysis**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/analyzer.md`
   - Focus: 技術的実現可能性、アーキテクチャ影響、パフォーマンス考慮、潜在的リスク
   - OUTPUT: 多視点ソリューション + 長所/短所分析

2. **Gemini Frontend Analysis**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/gemini/analyzer.md`
   - Focus: UI/UX 影響、ユーザー体験、ビジュアルデザイン
   - OUTPUT: 多視点ソリューション + 長所/短所分析

`TaskOutput` で両モデルの完全な結果を待つ。**SESSION_ID を保存する**（`CODEX_SESSION` と `GEMINI_SESSION`）。

#### 2.2 クロスバリデーション

視点を統合し、最適化のために反復する：

1. **コンセンサスを特定する**（強いシグナル）
2. **発散を特定する**（重み付けが必要）
3. **補完的な強み**：バックエンドロジックは Codex に従い、フロントエンドデザインは Gemini に従う
4. **論理的推論**：ソリューションの論理的ギャップを除去する

#### 2.3 （任意だが推奨）デュアルモデル計画ドラフト

Claude が統合した計画での漏れリスクを減らすため、両モデルに「計画ドラフト」を並列で出力させることができる（依然としてファイル修正は**許可されない**）：

1. **Codex Plan Draft**（バックエンド権威）：
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/architect.md`
   - OUTPUT: ステップバイステップの計画 + 擬似コード（焦点：データフロー/エッジケース/エラーハンドリング/テスト戦略）

2. **Gemini Plan Draft**（フロントエンド権威）：
   - ROLE_FILE: `~/.claude/.ccg/prompts/gemini/architect.md`
   - OUTPUT: ステップバイステップの計画 + 擬似コード（焦点：情報アーキテクチャ/インタラクション/アクセシビリティ/ビジュアル一貫性）

`TaskOutput` で両モデルの完全な結果を待ち、それらの提案の主要な違いを記録する。

#### 2.4 実装計画を生成する（Claude 最終版）

両方の分析を統合し、**ステップバイステップの実装計画**を生成する：

```markdown
## Implementation Plan: <Task Name>

### Task Type
- [ ] Frontend (→ Gemini)
- [ ] Backend (→ Codex)
- [ ] Fullstack (→ Parallel)

### Technical Solution
<Optimal solution synthesized from Codex + Gemini analysis>

### Implementation Steps
1. <Step 1> - Expected deliverable
2. <Step 2> - Expected deliverable
...

### Key Files
| File | Operation | Description |
|------|-----------|-------------|
| path/to/file.ts:L10-L50 | Modify | Description |

### Risks and Mitigation
| Risk | Mitigation |
|------|------------|

### SESSION_ID (for /ccg:execute use)
- CODEX_SESSION: <session_id>
- GEMINI_SESSION: <session_id>
```

### Phase 2 終了：計画デリバリ（実行ではない）

**`/ccg:plan` の責任はここで終了。以下のアクションを必ず実行しなければならない**：

1. 完全な実装計画をユーザーに提示する（擬似コードを含む）
2. 計画を `.claude/plan/<feature-name>.md` に保存する（要件から機能名を抽出、例：`user-auth`、`payment-module`）
3. **太字テキスト**でプロンプトを出力する（実際に保存されたファイルパスを必ず使用）：

---
**Plan generated and saved to `.claude/plan/actual-feature-name.md`**

**Please review the plan above. You can:**
- **Modify plan**: Tell me what needs adjustment, I'll update the plan
- **Execute plan**: Copy the following command to a new session

```
/ccg:execute .claude/plan/actual-feature-name.md
```
---

**NOTE**：上記の `actual-feature-name.md` は、実際に保存されたファイル名に必ず置換しなければならない！

4. **現在の応答を直ちに終了する**（ここで停止。これ以上ツール呼び出しなし。）

**絶対禁止**：
- ユーザーに "Y/N" を尋ねた後に自動実行する（実行は `/ccg:execute` の責任）
- プロダクションコードへのいかなる書き込み操作
- `/ccg:execute` または任意の実装アクションを自動的に呼ぶ
- ユーザーが明示的に修正を要求していないのに、モデル呼び出しを継続的にトリガーする

---

## 計画保存

計画完了後、計画を以下に保存する：

- **First planning**: `.claude/plan/<feature-name>.md`
- **Iteration versions**: `.claude/plan/<feature-name>-v2.md`, `.claude/plan/<feature-name>-v3.md`...

計画ファイル書き込みは、ユーザーに計画を提示する前に完了する必要がある。

---

## 計画修正フロー

ユーザーが計画修正を要求した場合：

1. ユーザーフィードバックに基づいて計画内容を調整する
2. `.claude/plan/<feature-name>.md` ファイルを更新する
3. 修正された計画を再提示する
4. ユーザーに再度レビューまたは実行を促す

---

## 次のステップ

ユーザーが承認した後、**手動**で実行する：

```bash
/ccg:execute .claude/plan/<feature-name>.md
```

---

## 主要ルール

1. **計画のみ、実装なし** – このコマンドはコード変更を実行しない
2. **Y/N プロンプトなし** – 計画を提示するだけ、ユーザーが次のステップを決める
3. **Trust Rules** – バックエンドは Codex に従い、フロントエンドは Gemini に従う
4. 外部モデルは**ファイルシステム書き込みアクセス権ゼロ**
5. **SESSION_ID Handoff** – 計画は末尾に `CODEX_SESSION` / `GEMINI_SESSION` を含めなければならない（`/ccg:execute resume <SESSION_ID>` 利用のため）

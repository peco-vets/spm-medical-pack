---
description: Claude を唯一のファイルシステムライターとして保持しつつ、マルチモデル実装計画を実行する / Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.
---

# Execute - Multi-Model Collaborative Execution

マルチモデル協調実行 - 計画からプロトタイプを取得 → Claude がリファクタして実装 → マルチモデル監査とデリバリ。

$ARGUMENTS

---

## コアプロトコル

- **Language Protocol**：ツール/モデルとのやり取りには **English** を使い、ユーザーとはユーザーの言語でコミュニケーションする
- **Code Sovereignty**：外部モデルは**ファイルシステム書き込みアクセス権ゼロ**、すべての修正は Claude による
- **Dirty Prototype Refactoring**：Codex/Gemini の Unified Diff を「ダーティプロトタイプ」として扱い、本番グレードコードへリファクタする必要がある
- **Stop-Loss Mechanism**：現フェーズ出力が検証されるまで次フェーズへ進まない
- **Prerequisite**：ユーザーが `/ccg:plan` 出力に対して明示的に "Y" と返答した後のみ実行（不明の場合は先に確認する）

---

## マルチモデル呼び出し仕様

**Call Syntax**（並列：`run_in_background: true` を使用）：

```
# Resume session call (recommended) - Implementation Prototype
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend <codex|gemini> {{GEMINI_MODEL_FLAG}}resume <SESSION_ID> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <task description>
Context: <plan content + target files>
</TASK>
OUTPUT: Unified Diff Patch ONLY. Strictly prohibit any actual modifications.
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})

# New session call - Implementation Prototype
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend <codex|gemini> {{GEMINI_MODEL_FLAG}}- \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <task description>
Context: <plan content + target files>
</TASK>
OUTPUT: Unified Diff Patch ONLY. Strictly prohibit any actual modifications.
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})
```

**Audit Call Syntax**（Code Review / Audit）：

```
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend <codex|gemini> {{GEMINI_MODEL_FLAG}}resume <SESSION_ID> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Scope: Audit the final code changes.
Inputs:
- The applied patch (git diff / final unified diff)
- The touched files (relevant excerpts if needed)
Constraints:
- Do NOT modify any files.
- Do NOT output tool commands that assume filesystem access.
</TASK>
OUTPUT:
1) A prioritized list of issues (severity, file, rationale)
2) Concrete fixes; if code changes are needed, include a Unified Diff Patch in a fenced code block.
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
| Implementation | `~/.claude/.ccg/prompts/codex/architect.md` | `~/.claude/.ccg/prompts/gemini/frontend.md` |
| Review | `~/.claude/.ccg/prompts/codex/reviewer.md` | `~/.claude/.ccg/prompts/gemini/reviewer.md` |

**Session Reuse**：`/ccg:plan` が SESSION_ID を提供した場合、コンテキストを再利用するために `resume <SESSION_ID>` を使う。

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

**実行タスク**：$ARGUMENTS

### Phase 0: 計画を読む

`[Mode: Prepare]`

1. **入力タイプの特定**：
   - 計画ファイルパス（例：`.claude/plan/xxx.md`）
   - 直接のタスク説明

2. **計画内容を読む**：
   - 計画ファイルパスが提供されたら、読み込んでパースする
   - 抽出：タスクタイプ、実装ステップ、主要ファイル、SESSION_ID

3. **実行前確認**：
   - 入力が「直接のタスク説明」または計画に `SESSION_ID` / 主要ファイルがない場合：まずユーザーと確認する
   - ユーザーが計画に "Y" と返答したか確認できない場合：進む前に再確認する必要がある

4. **タスクタイプルーティング**：

   | タスクタイプ | 検出 | ルート |
   |-----------|-----------|-------|
   | **Frontend** | ページ、コンポーネント、UI、スタイル、レイアウト | Gemini |
   | **Backend** | API、インターフェース、データベース、ロジック、アルゴリズム | Codex |
   | **Fullstack** | フロントエンドとバックエンドの両方を含む | Codex ∥ Gemini parallel |

---

### Phase 1: クイックコンテキスト取得

`[Mode: Retrieval]`

**ace-tool MCP が利用可能な場合**、クイックコンテキスト取得に使う：

計画の "Key Files" リストに基づき、`mcp__ace-tool__search_context` を呼ぶ：

```
mcp__ace-tool__search_context({
  query: "<semantic query based on plan content, including key files, modules, function names>",
  project_root_path: "$PWD"
})
```

**取得戦略**：
- 計画の "Key Files" テーブルからターゲットパスを抽出する
- エントリファイル、依存モジュール、関連型定義をカバーするセマンティッククエリを構築する
- 結果が不十分なら、1-2回の再帰的取得を追加する

**ace-tool MCP が利用不可な場合**、フォールバックとして Claude Code 組み込みツールを使う：
1. **Glob**：計画の "Key Files" テーブルからターゲットファイルを見つける（例：`Glob("src/components/**/*.tsx")`）
2. **Grep**：コードベースを通じて主要なシンボル、関数名、型定義を検索する
3. **Read**：発見されたファイルを読み込み、完全なコンテキストを収集する
4. **Task (Explore agent)**：より広範な探索には、`subagent_type: "Explore"` で `Task` を使う

**取得後**：
- 取得したコードスニペットを整理する
- 実装のための完全なコンテキストを確認する
- Phase 3 へ進む

---

### Phase 3: プロトタイプ取得

`[Mode: Prototype]`

**タスクタイプに基づくルーティング**：

#### Route A: Frontend/UI/Styles → Gemini

**Limit**：Context < 32k tokens

1. Gemini を呼ぶ（`~/.claude/.ccg/prompts/gemini/frontend.md` を使用）
2. Input: 計画内容 + 取得コンテキスト + ターゲットファイル
3. OUTPUT: `Unified Diff Patch ONLY. Strictly prohibit any actual modifications.`
4. **Gemini はフロントエンドデザイン権威であり、その CSS/React/Vue プロトタイプが最終的なビジュアルベースラインである**
5. **WARNING**：Gemini のバックエンドロジック提案を無視する
6. 計画に `GEMINI_SESSION` を含む場合：`resume <GEMINI_SESSION>` を優先する

#### Route B: Backend/Logic/Algorithms → Codex

1. Codex を呼ぶ（`~/.claude/.ccg/prompts/codex/architect.md` を使用）
2. Input: 計画内容 + 取得コンテキスト + ターゲットファイル
3. OUTPUT: `Unified Diff Patch ONLY. Strictly prohibit any actual modifications.`
4. **Codex はバックエンドロジック権威であり、その論理的推論とデバッグ能力を活用する**
5. 計画に `CODEX_SESSION` を含む場合：`resume <CODEX_SESSION>` を優先する

#### Route C: Fullstack → 並列呼び出し

1. **並列呼び出し**（`run_in_background: true`）：
   - Gemini：フロントエンド部分を処理
   - Codex：バックエンド部分を処理
2. `TaskOutput` で両モデルの完全な結果を待つ
3. それぞれが計画の対応する `SESSION_ID` を `resume` に使う（不足なら新しいセッションを作成）

**上記の `Multi-Model Call Specification` の `IMPORTANT` 指示に従う**

---

### Phase 4: コード実装

`[Mode: Implement]`

**Claude が Code Sovereign として以下のステップを実行する**：

1. **Diff を読む**：Codex/Gemini が返した Unified Diff Patch をパースする

2. **Mental Sandbox**：
   - ターゲットファイルへの Diff 適用をシミュレートする
   - 論理的一貫性を確認する
   - 潜在的な衝突や副作用を特定する

3. **リファクタとクリーン**：
   - 「ダーティプロトタイプ」を**高い可読性、保守可能性、エンタープライズグレードコード**にリファクタする
   - 冗長なコードを除去する
   - プロジェクトの既存コード標準への準拠を確保する
   - **必要でなければコメント/ドキュメントを生成しない**、コードは自己説明的であるべき

4. **最小スコープ**：
   - 変更を要件範囲のみに限定する
   - 副作用の**必須レビュー**
   - 的を絞った修正を行う

5. **変更の適用**：
   - 実際の修正を実行するには Edit/Write ツールを使う
   - **必要なコードのみを修正する**、ユーザーの他の既存機能に決して影響しない

6. **自己検証**（強く推奨）：
   - プロジェクトの既存 lint / typecheck / tests を実行（最小関連スコープを優先）
   - 失敗した場合：まず回帰を修正し、その後 Phase 5 へ進む

---

### Phase 5: 監査とデリバリ

`[Mode: Audit]`

#### 5.1 自動監査

**変更が反映された後、即座に Codex と Gemini を並列で Code Review に呼ばなければならない**：

1. **Codex Review**（`run_in_background: true`）：
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/reviewer.md`
   - Input: 変更 Diff + ターゲットファイル
   - Focus: セキュリティ、パフォーマンス、エラーハンドリング、ロジック正確性

2. **Gemini Review**（`run_in_background: true`）：
   - ROLE_FILE: `~/.claude/.ccg/prompts/gemini/reviewer.md`
   - Input: 変更 Diff + ターゲットファイル
   - Focus: アクセシビリティ、デザイン一貫性、ユーザー体験

`TaskOutput` で両モデルの完全なレビュー結果を待つ。コンテキスト一貫性のため、Phase 3 セッション（`resume <SESSION_ID>`）の再利用を優先する。

#### 5.2 統合と修正

1. Codex + Gemini レビューフィードバックを統合する
2. 信頼ルールで重み付けする：バックエンドは Codex に従い、フロントエンドは Gemini に従う
3. 必要な修正を実行する
4. 必要に応じて Phase 5.1 を繰り返す（リスクが許容できるまで）

#### 5.3 デリバリ確認

監査が通過した後、ユーザーに報告する：

```markdown
## Execution Complete

### Change Summary
| File | Operation | Description |
|------|-----------|-------------|
| path/to/file.ts | Modified | Description |

### Audit Results
- Codex: <Passed/Found N issues>
- Gemini: <Passed/Found N issues>

### Recommendations
1. [ ] <Suggested test steps>
2. [ ] <Suggested verification steps>
```

---

## 主要ルール

1. **Code Sovereignty** – すべてのファイル修正は Claude による、外部モデルは書き込みアクセス権ゼロ
2. **Dirty Prototype Refactoring** – Codex/Gemini 出力はドラフトとして扱い、リファクタが必須
3. **Trust Rules** – バックエンドは Codex に従い、フロントエンドは Gemini に従う
4. **Minimal Changes** – 必要なコードのみを修正、副作用なし
5. **Mandatory Audit** – 変更後にマルチモデル Code Review が必須

---

## Usage

```bash
# Execute plan file
/ccg:execute .claude/plan/feature-name.md

# Execute task directly (for plans already discussed in context)
/ccg:execute implement user authentication based on previous plan
```

---

## /ccg:plan との関係

1. `/ccg:plan` が計画 + SESSION_ID を生成する
2. ユーザーが "Y" で確認する
3. `/ccg:execute` が計画を読み、SESSION_ID を再利用し、実装を実行する

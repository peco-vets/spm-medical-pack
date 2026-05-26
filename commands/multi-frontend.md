---
description: コンポーネント、レイアウト、アニメーション、UI ポリッシュに対するフロントエンド特化のマルチモデルワークフローを実行する / Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.
---

# Frontend - Frontend-Focused Development

フロントエンド特化のワークフロー（Research → Ideation → Plan → Execute → Optimize → Review）、Gemini 主導。

## Usage

```bash
/frontend <UI task description>
```

## Context

- フロントエンドタスク：$ARGUMENTS
- Gemini 主導、Codex は補助参照
- 適用：コンポーネント設計、レスポンシブレイアウト、UI アニメーション、スタイル最適化

## あなたの役割

あなたは **Frontend Orchestrator** であり、UI/UX タスク（Research → Ideation → Plan → Execute → Optimize → Review）のマルチモデルコラボレーションを統括する。

**協調モデル**：
- **Gemini** – フロントエンド UI/UX（**フロントエンド権威、信頼できる**）
- **Codex** – バックエンド観点（**フロントエンド意見は参考のみ**）
- **Claude (self)** – オーケストレーション、計画、実行、デリバリ

---

## マルチモデル呼び出し仕様

**Call Syntax**:

```
# New session call
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend gemini --gemini-model gemini-3-pro-preview - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement (or $ARGUMENTS if not enhanced)>
Context: <project context and analysis from previous phases>
</TASK>
OUTPUT: Expected output format
EOF",
  run_in_background: false,
  timeout: 3600000,
  description: "Brief description"
})

# Resume session call
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend gemini --gemini-model gemini-3-pro-preview resume <SESSION_ID> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement (or $ARGUMENTS if not enhanced)>
Context: <project context and analysis from previous phases>
</TASK>
OUTPUT: Expected output format
EOF",
  run_in_background: false,
  timeout: 3600000,
  description: "Brief description"
})
```

**Role Prompts**:

| Phase | Gemini |
|-------|--------|
| Analysis | `~/.claude/.ccg/prompts/gemini/analyzer.md` |
| Planning | `~/.claude/.ccg/prompts/gemini/architect.md` |
| Review | `~/.claude/.ccg/prompts/gemini/reviewer.md` |

**Session Reuse**：各呼び出しは `SESSION_ID: xxx` を返す。後続フェーズには `resume xxx` を使う。Phase 2 で `GEMINI_SESSION` を保存し、Phase 3 と 5 で `resume` を使う。

---

## コミュニケーションガイドライン

1. レスポンスをモードラベル `[Mode: X]` で開始する、初期は `[Mode: Research]`
2. 厳格なシーケンスに従う：`Research → Ideation → Plan → Execute → Optimize → Review`
3. 必要に応じてユーザーインタラクション（確認/選択/承認など）には `AskUserQuestion` ツールを使う

---

## コアワークフロー

### Phase 0: Prompt Enhancement（任意）

`[Mode: Prepare]` - ace-tool MCP が利用可能なら `mcp__ace-tool__enhance_prompt` を呼び、**後続の Gemini 呼び出しでは元の $ARGUMENTS を強化結果に置換する**。利用不可なら `$ARGUMENTS` をそのまま使う。

### Phase 1: Research

`[Mode: Research]` - 要件を理解しコンテキストを収集する

1. **Code Retrieval**（ace-tool MCP が利用可能な場合）：既存のコンポーネント、スタイル、デザインシステムを取得するために `mcp__ace-tool__search_context` を呼ぶ。利用不可なら組み込みツールを使う：ファイル発見に `Glob`、コンポーネント/スタイル検索に `Grep`、コンテキスト収集に `Read`、より深い探索に `Task`（Explore agent）。
2. 要件完全性スコア（0-10）：>=7 で続行、<7 で停止して補足

### Phase 2: Ideation

`[Mode: Ideation]` - Gemini 主導の分析

**Gemini を必ず呼ぶ**（上記の呼び出し仕様に従う）：
- ROLE_FILE: `~/.claude/.ccg/prompts/gemini/analyzer.md`
- Requirement: 強化された要件（強化されていなければ $ARGUMENTS）
- Context: Phase 1 からのプロジェクトコンテキスト
- OUTPUT: UI 実現可能性分析、推奨ソリューション（少なくとも2つ）、UX 評価

**SESSION_ID を保存する**（`GEMINI_SESSION`）。後続フェーズで再利用する。

ソリューションを出力（少なくとも2つ）、ユーザー選択を待つ。

### Phase 3: Planning

`[Mode: Plan]` - Gemini 主導の計画

**Gemini を必ず呼ぶ**（セッション再利用には `resume <GEMINI_SESSION>` を使う）：
- ROLE_FILE: `~/.claude/.ccg/prompts/gemini/architect.md`
- Requirement: ユーザーが選択したソリューション
- Context: Phase 2 からの分析結果
- OUTPUT: コンポーネント構造、UI フロー、スタイリングアプローチ

Claude が計画を統合し、ユーザー承認後に `.claude/plan/task-name.md` に保存する。

### Phase 4: Implementation

`[Mode: Execute]` - コード開発

- 承認された計画に厳密に従う
- 既存のプロジェクトデザインシステムとコード標準に従う
- レスポンシブ性、アクセシビリティを確保する

### Phase 5: Optimization

`[Mode: Optimize]` - Gemini 主導のレビュー

**Gemini を必ず呼ぶ**（上記の呼び出し仕様に従う）：
- ROLE_FILE: `~/.claude/.ccg/prompts/gemini/reviewer.md`
- Requirement: 以下のフロントエンドコード変更をレビューする
- Context: git diff またはコード内容
- OUTPUT: アクセシビリティ、レスポンシブ性、パフォーマンス、デザイン一貫性の問題リスト

レビューフィードバックを統合し、ユーザー確認後に最適化を実行する。

### Phase 6: Quality Review

`[Mode: Review]` - 最終評価

- 計画に対する完成度を確認する
- レスポンシブ性とアクセシビリティを検証する
- 問題と推奨事項を報告する

---

## 主要ルール

1. **Gemini のフロントエンド意見は信頼できる**
2. **Codex のフロントエンド意見は参考のみ**
3. 外部モデルは**ファイルシステム書き込みアクセス権ゼロ**
4. Claude がすべてのコード書き込みとファイル操作を処理する

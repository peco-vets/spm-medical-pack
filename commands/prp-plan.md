---
description: コードベース分析とパターン抽出による包括的な機能実装計画を作成する / Create comprehensive feature implementation plan with codebase analysis and pattern extraction
argument-hint: <feature description | path/to/prd.md>
---

> Wirasm 氏による PRPs-agentic-eng から派生したものである。PRP ワークフローシリーズの一部である。

# PRP Plan

機能を1パスで実装するために必要なすべてのコードベースパターン、規約、コンテキストを捉えた詳細で自己完結型の実装計画を作成する。

**Core Philosophy**：素晴らしい計画は、さらなる質問なしに実装するために必要なすべてを含む。すべてのパターン、すべての規約、すべての gotcha — 一度捉えて、全体で参照する。

**Golden Rule**：実装中にコードベースを検索する必要が生じるなら、その知識を**今**計画に捉える。

---

## Phase 0 — DETECT

`$ARGUMENTS` から入力タイプを決定する：

| Input Pattern | Detection | Action |
|---|---|---|
| `.prd.md` で終わるパス | PRD へのファイルパス | PRD をパースし、次の保留中フェーズを見つける |
| "Implementation Phases" を含む `.md` へのパス | PRD 様ドキュメント | フェーズをパースし、次の保留中を見つける |
| 任意の他のファイルへのパス | 参照ファイル | コンテキスト用にファイルを読み、自由形式として扱う |
| 自由形式テキスト | 機能説明 | Phase 1 へ直接進む |
| 空 / ブランク | 入力なし | 何のフィーチャーを計画するかをユーザーに尋ねる |

### PRD パース（入力が PRD の場合）

1. `cat "$PRD_PATH"` で PRD ファイルを読む
2. **Implementation Phases** セクションをパースする
3. ステータスでフェーズを見つける：
   - `pending` フェーズを探す
   - 依存関係チェーンを確認する（フェーズは先行フェーズが `complete` であることに依存する場合がある）
   - **次の対象となる保留中フェーズ**を選択する
4. 選択されたフェーズから抽出する：
   - フェーズ名と説明
   - 受け入れ基準
   - 先行フェーズへの依存
   - スコープノートや制約
5. フェーズの説明を計画する機能として使う

保留中フェーズが残っていない場合、すべてのフェーズが完了したと報告する。

---

## Phase 1 — PARSE

機能要件を抽出して明確化する。

### 機能の理解

入力（PRD フェーズまたは自由形式の説明）から、以下を特定する：

- **What** が構築されるか（具体的なデリバラブル）
- **Why** それが重要か（ユーザー価値）
- **Who** がそれを使うか（ターゲットユーザー/システム）
- **Where** それが収まるか（コードベースのどの部分）

### ユーザーストーリー

以下の形式：
```
As a [type of user],
I want [capability],
So that [benefit].
```

### 複雑度評価

| Level | Indicators | Typical Scope |
|---|---|---|
| **Small** | 単一ファイル、孤立した変更、新依存関係なし | 1-3 files, <100 lines |
| **Medium** | 複数ファイル、既存パターンに従う、軽微な新概念 | 3-10 files, 100-500 lines |
| **Large** | 横断的関心事、新パターン、外部統合 | 10+ files, 500+ lines |
| **XL** | アーキテクチャ変更、新サブシステム、マイグレーション必要 | 20+ files, 分割を検討 |

### 曖昧性ゲート

以下のいずれかが不明確な場合、進む前に**停止してユーザーに尋ねる**：

- コアデリバラブルが曖昧
- 成功基準が未定義
- 複数の有効な解釈がある
- 技術アプローチに大きな未知数がある

推測してはならない。尋ねる。仮定に基づいて構築された計画は実装中に失敗する。

---

## Phase 2 — EXPLORE

深いコードベースインテリジェンスを集める。各カテゴリについて直接コードベースを検索する。

### コードベース検索（8カテゴリ）

各カテゴリについて、grep、find、ファイル読み込みで検索する：

1. **Similar Implementations** — 計画されたものに似た既存機能を見つける。類似パターン、エンドポイント、コンポーネント、モジュールを探す。
2. **Naming Conventions** — コードベースの関連エリアでファイル、関数、変数、クラス、エクスポートがどのように命名されているかを特定する。
3. **Error Handling** — エラーがどのように捕捉、伝播、ログ、ユーザーに返却されるかを類似コードパスで見つける。
4. **Logging Patterns** — 何が、どのレベルで、どんなフォーマットでログされるかを特定する。
5. **Type Definitions** — 関連する型、インターフェース、スキーマ、それらの整理方法を見つける。
6. **Test Patterns** — 類似機能がどのようにテストされるかを見つける。テストファイルの場所、命名、setup/teardown パターン、アサーションスタイルを記録する。
7. **Configuration** — 関連する config ファイル、環境変数、フィーチャーフラグを見つける。
8. **Dependencies** — 類似機能で使われるパッケージ、imports、内部モジュールを特定する。

### コードベース分析（5トレース）

関連するファイルを読んで以下をトレースする：

1. **Entry Points** — リクエスト/アクションがどのようにシステムに入り、修正するエリアに到達するか？
2. **Data Flow** — 関連するコードパスを通してデータがどう移動するか？
3. **State Changes** — 何の state がどこで修正されるか？
4. **Contracts** — どのインターフェース、API、プロトコルが尊重されるべきか？
5. **Patterns** — どんなアーキテクチャパターンが使われるか（repository、service、controller など）？

### 統一発見テーブル

発見事項を単一の参照にコンパイルする：

| Category | File:Lines | Pattern | Key Snippet |
|---|---|---|---|
| Naming | `src/services/userService.ts:1-5` | camelCase services, PascalCase types | `export class UserService` |
| Error | `src/middleware/errorHandler.ts:10-25` | Custom AppError class | `throw new AppError(...)` |
| ... | ... | ... | ... |

---

## Phase 3 — RESEARCH

機能が外部ライブラリ、API、または不慣れな技術を含む場合：

1. 公式ドキュメントを Web 検索する
2. 使用例とベストプラクティスを見つける
3. バージョン固有の gotcha を特定する

各発見を以下の形式：

```
KEY_INSIGHT: [what you learned]
APPLIES_TO: [which part of the plan this affects]
GOTCHA: [any warnings or version-specific issues]
```

機能がよく理解されている内部パターンのみを使う場合、このフェーズをスキップし、注記する：「No external research needed — feature uses established internal patterns.」

---

## Phase 4 — DESIGN

### UX 変換（該当する場合）

before/after のユーザー体験を文書化する。before と after の状態の ASCII 図、Interaction Changes テーブル（Touchpoint、Before、After、Notes）を含める。

機能が純粋にバックエンド/内部で UX 変更がない場合、注記する：「Internal change — no user-facing UX transformation.」

---

## Phase 5 — ARCHITECT

### 戦略設計

実装アプローチを定義する：

- **Approach**：ハイレベル戦略（例：「既存のリポジトリパターンに従って新しいサービスレイヤを追加する」）
- **Alternatives Considered**：どんな他のアプローチが評価され、なぜ却下されたか
- **Scope**：何を構築するかの具体的な境界
- **NOT Building**：スコープから外れるものの明示的なリスト（実装中のスコープクリープを防ぐ）

---

## Phase 6 — GENERATE

下記テンプレートを使って完全な計画ドキュメントを書く。`.claude/PRPs/plans/{kebab-case-feature-name}.plan.md` に保存する。

ディレクトリが存在しなければ作成：
```bash
mkdir -p .claude/PRPs/plans
```

### 計画テンプレート

計画は以下のセクションを含む：Summary、User Story、Problem → Solution、Metadata（Complexity、Source PRD、PRD Phase、Estimated Files）、UX Design（Before、After、Interaction Changes）、Mandatory Reading（優先度付きファイルテーブル）、External Documentation、Patterns to Mirror（NAMING_CONVENTION、ERROR_HANDLING、LOGGING_PATTERN、REPOSITORY_PATTERN、SERVICE_PATTERN、TEST_STRUCTURE）、Files to Change、NOT Building、Step-by-Step Tasks（各タスクに ACTION、IMPLEMENT、MIRROR、IMPORTS、GOTCHA、VALIDATE）、Testing Strategy（Unit Tests テーブル、Edge Cases Checklist）、Validation Commands（Static Analysis、Unit Tests、Full Test Suite、Database Validation、Browser Validation、Manual Validation）、Acceptance Criteria、Completion Checklist、Risks、Notes。

---

## 出力

### 計画を保存する

生成された計画を以下に書き出す：
```
.claude/PRPs/plans/{kebab-case-feature-name}.plan.md
```

### PRD を更新する（入力が PRD だった場合）

この計画が PRD フェーズから生成された場合：
1. フェーズステータスを `pending` から `in-progress` に更新する
2. フェーズ内に参照として計画ファイルパスを追加する

### ユーザーに報告する

```
## Plan Created

- **File**: .claude/PRPs/plans/{kebab-case-feature-name}.plan.md
- **Source PRD**: [path or "N/A"]
- **Phase**: [phase name or "standalone"]
- **Complexity**: [level]
- **Scope**: [N files, M tasks]
- **Key Patterns**: [top 3 discovered patterns]
- **External Research**: [topics researched or "none needed"]
- **Risks**: [top risk or "none identified"]
- **Confidence Score**: [1-10] — likelihood of single-pass implementation

> Next step: Run `/prp-implement .claude/PRPs/plans/{name}.plan.md` to execute this plan.
```

---

## 検証

最終化する前に、これらのチェックリストに対して計画を検証する：

### コンテキスト完全性
- [ ] すべての関連ファイルが発見され文書化されている
- [ ] 例と共に命名規約が捉えられている
- [ ] エラーハンドリングパターンが文書化されている
- [ ] テストパターンが特定されている
- [ ] 依存関係がリストされている

### 実装準備度
- [ ] すべてのタスクに ACTION、IMPLEMENT、MIRROR、VALIDATE がある
- [ ] 追加のコードベース検索を必要とするタスクがない
- [ ] import パスが指定されている
- [ ] 該当する場合 GOTCHA が文書化されている

### パターン忠実性
- [ ] コードスニペットが実際のコードベース例である（捏造ではない）
- [ ] SOURCE 参照が実際のファイルと行番号を指す
- [ ] パターンが命名、エラー、ロギング、データアクセス、テストをカバーする
- [ ] 新しいコードが既存コードと区別できない

### 検証カバレッジ
- [ ] 静的解析コマンドが指定されている
- [ ] テストコマンドが指定されている
- [ ] ビルド検証が含まれる

### UX 明確性
- [ ] before/after 状態が文書化されている（または N/A とマーク）
- [ ] インタラクション変更がリストされている
- [ ] UX のエッジケースが特定されている

### 事前知識なしテスト
このコードベースに不慣れな開発者が、コードベースを検索したり質問したりせず、この計画**のみ**を使って機能を実装できるべきである。できない場合、不足するコンテキストを追加する。

---

## 次のステップ

- この計画を実行するには `/prp-implement <plan-path>` を実行
- アーティファクトなしの素早い会話型計画には `/plan` を実行
- スコープが不明確なら、先に PRD を作成するために `/prp-prd` を実行

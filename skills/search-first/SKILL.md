---
name: search-first
description: コーディング前のリサーチワークフロー（research-before-coding）。カスタムコードを書く前に既存のツール、ライブラリ、パターンを検索する。researcher エージェントを呼び出す。
origin: ECC
---

# /search-first — コードを書く前に調査する

「実装する前に既存ソリューションを検索する」ワークフローを体系化する。

## トリガー

このスキルを使うのは：
- 既存ソリューションがありそうな新機能を開始するとき
- 依存関係または統合を追加するとき
- ユーザーが「X 機能を追加して」と言い、コードを書こうとしているとき
- 新しいユーティリティ、ヘルパー、抽象化を作成する前

## ワークフロー

```
┌─────────────────────────────────────────────┐
│  0. ツール利用可能性プリフライト             │
│     検索チャネルに依存する前にチェックし、    │
│     スキップしたチャネルを正直に報告する     │
├─────────────────────────────────────────────┤
│  1. ニーズ分析                              │
│     必要な機能を定義する                     │
│     言語／フレームワーク制約を特定する        │
├─────────────────────────────────────────────┤
│  2. 並列検索（researcher エージェント）      │
│     ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│     │  npm /   │ │  MCP /   │ │  GitHub / │  │
│     │  PyPI    │ │  Skills  │ │  Web      │  │
│     └──────────┘ └──────────┘ └──────────┘  │
├─────────────────────────────────────────────┤
│  3. 評価                                    │
│     候補をスコア（機能、保守性、コミュニ     │
│     ティ、ドキュメント、ライセンス、依存）   │
├─────────────────────────────────────────────┤
│  4. 決定                                    │
│     ┌─────────┐  ┌──────────┐  ┌─────────┐  │
│     │  Adopt  │  │  Extend  │  │  Build   │  │
│     │ as-is   │  │  /Wrap   │  │  Custom  │  │
│     └─────────┘  └──────────┘  └─────────┘  │
├─────────────────────────────────────────────┤
│  5. 実装                                    │
│     パッケージインストール／MCP 設定／      │
│     最小限のカスタムコード作成              │
└─────────────────────────────────────────────┘
```

## 意思決定マトリックス

| シグナル | 処置 |
|--------|--------|
| 完全マッチ、よく保守されている、MIT/Apache | **Adopt** — インストールして直接使用 |
| 部分マッチ、良い基盤 | **Extend** — インストール + 薄いラッパーを書く |
| 複数の弱いマッチ | **Compose** — 2-3 個の小さいパッケージを組み合わせる |
| 適切なものが見つからない | **Build** — カスタムで書くが、リサーチに基づく |

## 使い方

### ステップ 0：ツール利用可能性プリフライト

これはエージェントガイダンスであり、実行可能なセットアップスクリプトではない。目の前のタスクとプロジェクトに関連するチャネルのみをチェックする。

| チャネル | チェック | 欠落時 |
|---------|-------|------------|
| リポジトリ検索 | `rg --files` と `rg` クエリ | 可視ファイルのみが検査されたと明示 |
| パッケージレジストリ | `npm --version`、`python -m pip --version`、プロジェクトパッケージマネージャ | Web／ドキュメント検索を使い、レジストリカバレッジを主張しない |
| GitHub CLI | `gh auth status` | 公開 Web またはローカル git 履歴のみを使う |
| MCP／ドキュメントツール | 利用可能ツールリストまたはローカル MCP 設定 | 公式ドキュメント／Web 検索にフォールバック |
| Skills ディレクトリ | 該当する場合 `ls ~/.claude/skills ~/.codex/skills` | ローカルスキルカタログが利用不可と述べる |

### Quick Mode（インライン）

ユーティリティを書いたり機能を追加する前に、心の中で以下を実行する：

0. これはリポにすでに存在するか？ → 関連モジュール／テストを先に `rg` する
1. これは一般的な問題か？ → npm/PyPI を検索
2. これに MCP はあるか？ → `~/.claude/settings.json` をチェックし検索
3. これにスキルはあるか？ → `~/.claude/skills/` をチェック
4. GitHub 実装／テンプレートはあるか？ → 新規コードを書く前に保守されている OSS の GitHub コード検索を実行

### Full Mode（エージェント）

非自明な機能には、researcher エージェントを起動する：

```
Agent(subagent_type="general-purpose", prompt="
  Research existing tools for: [DESCRIPTION]
  Language/framework: [LANG]
  Constraints: [ANY]

  Search: npm/PyPI, MCP servers, Claude Code skills, GitHub
  Return: Structured comparison with recommendation
")
```

古い Claude Code ドキュメントではこれを `Task(...)` と呼ぶことがある。アクティブなハーネスが公開する現在のエージェント／サブエージェントツール名を使う。

## カテゴリ別検索ショートカット

### 開発ツーリング
- リンティング → `eslint`、`ruff`、`textlint`、`markdownlint`
- フォーマット → `prettier`、`black`、`gofmt`
- テスト → `jest`、`pytest`、`go test`
- pre-commit → `husky`、`lint-staged`、`pre-commit`

### AI/LLM 統合
- Claude SDK → 最新ドキュメントには Context7
- プロンプト管理 → MCP サーバをチェック
- ドキュメント処理 → `unstructured`、`pdfplumber`、`mammoth`

### データと API
- HTTP クライアント → `httpx`（Python）、`ky`/`undici`（Node）
- バリデーション → `zod`（TS）、`pydantic`（Python）
- データベース → 先に MCP サーバをチェック

### コンテンツと刊行
- Markdown 処理 → `remark`、`unified`、`markdown-it`
- 画像最適化 → `sharp`、`imagemin`

## 統合ポイント

### planner エージェントと
planner はフェーズ 1（アーキテクチャレビュー）の前に researcher を呼び出すべき：
- researcher が利用可能なツールを特定
- planner がそれらを実装計画に組み込む
- 計画で「車輪の再発明」を回避する

### architect エージェントと
architect は以下のため researcher に相談すべき：
- 技術スタック決定
- 統合パターン発見
- 既存のリファレンスアーキテクチャ

### iterative-retrieval スキルと
進歩的発見のため組み合わせる：
- サイクル 1：広範な検索（npm、PyPI、MCP）
- サイクル 2：トップ候補を詳細に評価
- サイクル 3：プロジェクト制約との互換性をテスト

## 例

### 例 1：「デッドリンクチェックを追加」
```
Need: Markdown ファイルで壊れたリンクをチェック
Search: npm "markdown dead link checker"
Found: textlint-rule-no-dead-link (score: 9/10)
Action: ADOPT — npm install textlint-rule-no-dead-link
Result: ゼロカスタムコード、実戦テスト済みソリューション
```

### 例 2：「HTTP クライアントラッパーを追加」
```
Need: リトライとタイムアウト処理付きの堅牢な HTTP クライアント
Search: npm "http client retry", PyPI "httpx retry"
Found: got (Node) + リトライプラグイン、httpx (Python) ビルトインリトライ
Action: ADOPT — got/httpx をリトライ設定で直接使用
Result: ゼロカスタムコード、本番実証済みライブラリ
```

### 例 3：「設定ファイルリンタを追加」
```
Need: プロジェクト設定ファイルをスキーマに対して検証
Search: npm "config linter schema", "json schema validator cli"
Found: ajv-cli (score: 8/10)
Action: ADOPT + EXTEND — ajv-cli インストール、プロジェクト固有スキーマを書く
Result: 1 パッケージ + 1 スキーマファイル、カスタムバリデーションロジックなし
```

## アンチパターン

- **コードへのジャンプ**：既存があるかチェックせずにユーティリティを書く
- **MCP を無視**：MCP サーバがすでに機能を提供しているかチェックしない
- **サイレントスキップ**：検索チャネルが利用不可だったときに「何も見つからない」と報告
- **過剰カスタマイズ**：ライブラリを重くラップしすぎて利点を失う
- **依存関係肥大化**：1 つの小さな機能のために巨大なパッケージをインストール

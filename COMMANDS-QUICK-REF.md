# コマンドクイックリファレンス

> 59 のスラッシュコマンドがグローバルにインストールされている。Claude Code セッションで `/` を入力すると呼び出せる。

---

## コアワークフロー

| コマンド | 内容 |
|---------|------|
| `/plan` | 要件を整理し、リスクを評価し、ステップ・バイ・ステップの実装計画を作成する — **コード変更前に確認を待つ** |
| `/tdd` | TDD を強制する: インターフェース足場 → 失敗するテストを書く → 実装 → 80% 以上のカバレッジを検証 |
| `/code-review` | 変更ファイルの完全なコード品質、セキュリティ、保守性レビュー |
| `/build-fix` | ビルドエラーを検出し修正する — 適切な build-resolver エージェントへ自動的に委任する |
| `/verify` | 完全な検証ループを実行: build → lint → test → type-check |
| `/quality-gate` | プロジェクト基準に照らした品質ゲートチェック |

---

## テスト

| コマンド | 内容 |
|---------|------|
| `/tdd` | 汎用 TDD ワークフロー (任意の言語) |
| `/e2e` | Playwright E2E テストの生成・実行、スクリーンショット・動画・トレースの取得 |
| `/test-coverage` | テストカバレッジレポート、ギャップ特定 |
| `/go-test` | Go 向け TDD ワークフロー (テーブル駆動、`go test -cover` で 80% 以上) |
| `/kotlin-test` | Kotlin 向け TDD (Kotest + Kover) |
| `/rust-test` | Rust 向け TDD (cargo test、インテグレーションテスト) |
| `/cpp-test` | C++ 向け TDD (GoogleTest + gcov/lcov) |

---

## コードレビュー

| コマンド | 内容 |
|---------|------|
| `/code-review` | 汎用コードレビュー |
| `/python-review` | Python — PEP 8、型ヒント、セキュリティ、イディオマティックパターン |
| `/go-review` | Go — イディオマティックパターン、並行安全性、エラーハンドリング |
| `/kotlin-review` | Kotlin — null 安全性、コルーチン安全性、クリーンアーキテクチャ |
| `/rust-review` | Rust — 所有権、ライフタイム、unsafe 使用 |
| `/cpp-review` | C++ — メモリ安全性、モダンイディオム、並行性 |

---

## ビルド修復

| コマンド | 内容 |
|---------|------|
| `/build-fix` | 言語を自動検出してビルドエラーを修正 |
| `/go-build` | Go ビルドエラーと `go vet` 警告を修正 |
| `/kotlin-build` | Kotlin/Gradle コンパイラエラーを修正 |
| `/rust-build` | Rust ビルドおよびボローチェッカー問題を修正 |
| `/cpp-build` | C++ CMake とリンカ問題を修正 |
| `/gradle-build` | Android/KMP 向け Gradle エラー修正 |

---

## 計画・アーキテクチャ

| コマンド | 内容 |
|---------|------|
| `/plan` | リスク評価を伴う実装計画 |
| `/multi-plan` | マルチモデル協調計画 |
| `/multi-workflow` | マルチモデル協調開発 |
| `/multi-backend` | バックエンドにフォーカスしたマルチモデル開発 |
| `/multi-frontend` | フロントエンドにフォーカスしたマルチモデル開発 |
| `/multi-execute` | マルチモデル協調実行 |
| `/orchestrate` | tmux/worktree マルチエージェントオーケストレーションのガイド |
| `/devfleet` | DevFleet 経由で並列 Claude Code エージェントをオーケストレーション |

---

## セッション管理

| コマンド | 内容 |
|---------|------|
| `/save-session` | 現在のセッション状態を `~/.claude/session-data/` に保存 |
| `/resume-session` | 正規セッションストアから最新の保存済みセッションをロードし、中断した場所から再開 |
| `/sessions` | `~/.claude/session-data/` のエイリアス付きでセッション履歴をブラウズ、検索、管理 (`~/.claude/sessions/` のレガシー読み込みあり) |
| `/checkpoint` | 現在のセッションにチェックポイントをマークする |
| `/aside` | 現在のタスクコンテキストを失わずに簡単なサイド質問に回答する |
| `/context-budget` | コンテキストウィンドウの使用状況を分析 — トークンオーバーヘッドを発見し最適化 |

---

## 学習・改善

| コマンド | 内容 |
|---------|------|
| `/learn` | 現在のセッションから再利用可能なパターンを抽出 |
| `/learn-eval` | パターン抽出 + 保存前に品質を自己評価 |
| `/evolve` | 学習した instincts を分析し、進化したスキル構造を提案 |
| `/promote` | プロジェクトスコープの instincts をグローバルスコープに昇格 |
| `/instinct-status` | 学習済み instincts (project + global) を信頼度スコアとともに表示 |
| `/instinct-export` | instincts をファイルにエクスポート |
| `/instinct-import` | ファイルまたは URL から instincts をインポート |
| `/skill-create` | ローカル git 履歴を分析 → 再利用可能なスキルを生成 |
| `/skill-health` | アナリティクス付きスキルポートフォリオヘルスダッシュボード |
| `/rules-distill` | スキルをスキャンし、横断的原則を抽出し、ルールに蒸留する |

---

## リファクタリング・クリーンアップ

| コマンド | 内容 |
|---------|------|
| `/refactor-clean` | デッドコード除去、重複統合、構造クリーンアップ |
| `/prompt-optimize` | ドラフトプロンプトを分析し、最適化された ECC エンリッチドバージョンを出力 |

---

## ドキュメント・調査

| コマンド | 内容 |
|---------|------|
| `/docs` | Context7 経由で最新ライブラリ・API ドキュメントを参照 |
| `/update-docs` | プロジェクトドキュメントを更新 |
| `/update-codemaps` | コードベースのコードマップを再生成 |

---

## ループ・自動化

| コマンド | 内容 |
|---------|------|
| `/loop-start` | 一定間隔で繰り返すエージェントループを開始 |
| `/loop-status` | 実行中のループのステータスを確認 |
| `/claw` | NanoClaw v2 を開始 — モデルルーティング、スキルホットロード、ブランチング、メトリクスを備えた永続的 REPL |

---

## プロジェクト・インフラ

| コマンド | 内容 |
|---------|------|
| `/projects` | 既知プロジェクトとその instinct 統計を一覧表示 |
| `/harness-audit` | エージェントハーネス設定を信頼性とコストの観点で監査 |
| `/eval` | 評価ハーネスを実行 |
| `/model-route` | タスクを適切なモデル (Haiku/Sonnet/Opus) にルーティング |
| `/pm2` | PM2 プロセスマネージャの初期化 |
| `/setup-pm` | パッケージマネージャ (npm/pnpm/yarn/bun) を構成 |

---

## クイック判断ガイド

```
Starting a new feature?         → /plan first, then /tdd
Code just written?              → /code-review
Build broken?                   → /build-fix
Need live docs?                 → /docs <library>
Session about to end?           → /save-session or /learn-eval
Resuming next day?              → /resume-session
Context getting heavy?          → /context-budget then /checkpoint
Want to extract what you learned? → /learn-eval then /evolve
Running repeated tasks?         → /loop-start
```

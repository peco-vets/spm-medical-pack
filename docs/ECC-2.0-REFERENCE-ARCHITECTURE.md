# ECC 2.0 リファレンスアーキテクチャ

現在の実行ミラー:
[`ECC-2.0-GA-ROADMAP.md`](ECC-2.0-GA-ROADMAP.md)。

本ドキュメントは、2026 年 5 月のリファレンススウィープを具体的な ECC バックログ形状に変える。これは 2 つ目のストラテジメモではない: 以下に挙げる各リファレンスプレッシャーは、アダプタ、チェック、可観測性シグナル、セキュリティポリシー、PR レビューサーフェス、またはリリースレディネスゲートとして着地すべきである。

## リファレンスベースライン

スナップショット日: 2026-05-12。

| リファレンス | ECC 2.0 への主要プレッシャー | 具体的な ECC デルタ |
| --- | --- | --- |
| [`stablyai/orca`](https://github.com/stablyai/orca) | ターミナル、ソースコントロール、GitHub 統合、SSH、通知、デザイン/ブラウザモード、アカウント切替、worktree ごとのコンテキストを備えた worktree ネイティブマルチエージェント IDE | worktree ライフサイクル、レビュー状態、通知状態、アカウント/プロバイダアイデンティティをファーストクラスアダプタシグナルとして扱う |
| [`superset-sh/superset`](https://github.com/superset-sh/superset) | 並列実行、worktree 分離、diff レビュー、ワークスペースプリセット、広範な CLI エージェント互換を備えたデスクトップ AI エージェントワークスペース | ワークスペースプリセット分類体系を追加し、ECC2 セッション/worktree 状態を外部エディタが消費できる程度にエクスポート可能にする |
| [`standardagents/dmux`](https://github.com/standardagents/dmux) | tmux/worktree オーケストレーション、ライフサイクルフック、マルチセレクトエージェント制御、スマートマージ、ファイルブラウザ、通知、クリーンアップ | ハーネスマトリクスにライフサイクルフックカバレッジを追加し、マージ/コンフリクトキューイベントを定義する |
| [`aidenybai/ghast`](https://github.com/aidenybai/ghast) | cwd グループ化ワークスペース、ペイン、タブ、ドラッグ&ドロップ、検索、通知を備えたネイティブ macOS ターミナルマルチプレクサ | ターミナルネイティブな使い勝手を保ちつつ、cwd/セッショングルーピングと検索可能な引き継ぎ/セッション記録を追加する |
| [`jarrodwatts/claude-hud`](https://github.com/jarrodwatts/claude-hud) | コンテキスト、ツール、エージェント、todo、トランスクリプトバックアクティビティ用の常時可視 Claude Code ステータスライン | コンテキスト、コスト、ツール呼び出し、アクティブエージェント、todo、キュー状態、チェック、リスク用の ECC HUD/ステータスペイロードを形式化する |
| [`stanford-iris-lab/meta-harness`](https://github.com/stanford-iris-lab/meta-harness) | タスク固有ハーネス設計に対する自動検索: 何を保存・検索・表示するか | ECC 改善ループをシナリオ仕様、proposer トレース、検証者結果、promote されたプレイブックに分割する |
| [`greyhaven-ai/autocontext`](https://github.com/greyhaven-ai/autocontext) | トレース、レポート、アーティファクト、データセット、プレイブック、role 分離 evaluator を使う再帰的ハーネス改善 | インストール済みハーネスアセットを変更する前に、再利用可能なトレースとプレイブックを保存する |
| [`NousResearch/hermes-agent`](https://github.com/NousResearch/hermes-agent) | メモリ、スキル、スケジューラ、ゲートウェイ、サブエージェント、ターミナルバックエンド、マイグレーションツールを備えた自己改善オペレータシェル | 基底コマンドを隠蔽せずに、ローカル、SSH、コンテナ、ホストターミナルバックエンド全体で ECC をポータブルに保つ |
| [`anthropics/claude-code`](https://github.com/anthropics/claude-code)、[`sst/opencode`](https://github.com/sst/opencode)、Zed、Codex、Cursor、Gemini | 異なるエージェントハーネスは異なるフック、プラグインサーフェス、セッションストア、設定ファイル、レビューループを公開する | いずれか 1 つのハーネスを canonical な UX として扱うのではなく、公開アダプタコンプライアンスマトリクスを維持する |
| ローカル Claude Code ソースレビュー | セッション、ツール、権限、フック、リモート、アナリティクス、タスク、コンテキスト提案サーフェスは公開 CLI UX が示唆するより構造化されている | セッションメッセージ、権限要求、ツール進捗、コンテキスト圧力、サマリ状態を中心にステータスとリスクイベントをモデル化する |

## アーキテクチャ形状

ECC 2.0 はコマンド、エージェント、スキルのカタログのみではなく、ハーネスオペレーティングシステムであるべきである。

```text
┌──────────────────────────────────────────────────────────────┐
│ Operator Surface                                             │
│ CLI, plugin, TUI, HUD/statusline, release gates, PR checks   │
├──────────────────────────────────────────────────────────────┤
│ Harness Adapter Layer                                        │
│ Claude Code, Codex, OpenCode, Cursor, Gemini, Zed, dmux,     │
│ Orca, Superset, Ghast, terminal-only                         │
├──────────────────────────────────────────────────────────────┤
│ Worktree, Session, And Queue Runtime                         │
│ worktrees, panes, sessions, todos, checks, merge/conflict    │
│ queues, notification state, ownership, handoff exports       │
├──────────────────────────────────────────────────────────────┤
│ Observability And Evaluation Loop                            │
│ JSONL traces, status snapshots, risk ledger, harness audit,  │
│ scenario specs, verifiers, promoted playbooks, RAG sets      │
├──────────────────────────────────────────────────────────────┤
│ Security And Commercial Platform                             │
│ AgentShield policies/SARIF, ECC Tools checks, billing,       │
│ Linear/GitHub sync, enterprise reports                       │
└──────────────────────────────────────────────────────────────┘
```

## リファレンス → バックログマップ

### Worktree とセッションオーケストレーション

Orca、Superset、dmux、Ghast から採用する:

- Worktree ライフサイクルイベント: create、resume、pause、stop、diff、review、PR、merge-ready、conflict、stale、close、salvage。
- リポジトリ、ブランチ、cwd、タスク、オーナー、ハーネスによるセッショングルーピング。
- リリースレーン、PR トリアージレーン、ドキュメントレーン、セキュリティレーン、テストライターレーン用のワークスペースプリセット。
- ブロック CI、汚れた worktree、マージコンフリクト、陳腐レビュー、完了した自律実行の通知。
- メンテナから所有権を奪うことなく diff と PR にアノテートできるレビューループ。

リポジトリ作業:

- `everything-claude-code`: アダプタコンプライアンスマトリクスと公開スコアカードオンランプを拡張する。
- `ecc2`: ホストテレメトリを追加する前に、安定したローカルペイロード経由でセッション/worktree 状態を公開する。
- `ECC-Tools`: PR チェック、issue ルーティング、Linear 同期のために同じライフサイクルイベントを消費する。

検証:

- `npm run harness:audit -- --format json`
- `npm run observability:ready`
- マトリクスがドキュメントからデータに移動した後のターゲットアダプタマトリクステスト

### HUD、ステータス、可観測性

Claude HUD と Claude Code ソースレビューから採用する:

- コンテキスト圧力: 使用量、compaction リスク、大規模結果警告、サマリ状態。
- ツールアクティビティ: アクティブツール、最近のツール、所要時間、リスキー操作、権限要求。
- エージェントアクティビティ: アクティブサブエージェント、委任タスク、branch/worktree、待機状態。
- キューアクティビティ: オープン PR/issue、CI 状態、stale/conflict バッチ、レビュー状態、closed-stale サルベージバックログ。
- コスト/リスク: トークンコスト見積もり、破壊的操作リスク、フック/MCP リスク、セキュリティスキャン状態。

リポジトリ作業:

- `docs/architecture/observability-readiness.md` をオペレータ向けレディネスゲートとして維持する。
- ECC2 と ECC Tools の両方が消費できるバージョン管理された HUD/ステータス JSON コントラクトを定義する。
- ビジュアル UI を構築する前に、`loop-status`、`session-inspect`、ハーネス監査、リスク台帳からのサンプルエクスポートをフィクスチャディレクトリに追加する。

検証:

- `npm run observability:ready`
- すべてのステータスペイロードのフィクスチャ検証
- セッション履歴を読むコマンドのクロスプラットフォームスモークテスト

### 自己改善ハーネスループ

Meta-Harness、Autocontext、Hermes Agent から採用する:

- ループを観察、提案、検証、promotion、ロールバックに分離する。
- 提案された各改善を最終変更ファイルとしてだけでなく、トレース + アーティファクトとして保存する。
- 検証者がブラスト半径を広げずにシナリオを改善することを証明した後のみプレイブックを promote する。
- 検証済み ECC パターン、チーム履歴、CI 失敗、レビュー結果、ハーネス設定品質、セキュリティ決定のために RAG/リファレンスセットを使う。

リポジトリ作業:

- `everything-claude-code`: シナリオ仕様、検証者コントラクト、プレイブック promotion ルールを文書化する。
- `ECC-Tools`: ワークスペースをフラッディングせずに analyzer 所見を PR コメント、check run、Linear タスクにマップする。
- `agentshield`: プロンプトインジェクションと設定リスク所見を回帰スイートに供給する。

現在のプロトタイプ:

- `docs/architecture/evaluator-rag-prototype.md` が read-only evaluator/RAG アーティファクトコントラクトを定義する。
- `examples/evaluator-rag-prototype/` が stale-PR サルベージの最初のシナリオ仕様、トレース、レポート、候補プレイブック、検証者結果を記録する。

検証:

- トレース、レポート、候補プレイブック、検証者結果を発出する read-only プロトタイプ
- 悪い提案が拒否されることを証明する回帰フィクスチャ

### AgentShield エンタープライズセキュリティプラットフォーム

AgentShield は有用なスキャナからエンタープライズセキュリティプラットフォームへ移行すべきである。

バックログ形状:

- 組織ベースライン、ルール重大度、オーナー、例外、有効期限、エビデンス、監査トレイル用のポリシースキーマ。
- GitHub code scanning 用の SARIF 出力。
- OSS、チーム、エンタープライズ、規制、高リスクフック/MCP、CI 強制用のポリシーパック。
- MCP パッケージ、npm/pip provenance、CVE、typosquat、依存評判用のサプライチェーンインテリジェンス。
- プロンプトインジェクションコーパスと回帰ベンチマーク。
- JSON とエグゼクティブ HTML/PDF レポート出力。

検証:

- スキーマユニットテスト
- SARIF フィクスチャテスト
- ポリシーパックゴールデンテスト
- 公開 issue 履歴からの false-positive 回帰テスト

### ECC Tools 商用・レビュープラットフォーム

ECC Tools は billing、deep analysis、PR チェック、Linear 進捗追跡のための GitHub ネイティブレイヤになるべきである。

バックログ形状:

- 任意の支払い告知前のネイティブ GitHub Marketplace billing 監査: プラン、シート、組織/アカウントマッピング、サブスクリプション状態、オーバージ挙動、ダウングレード/キャンセル挙動、失敗モード。
- GitGuardian、Dependabot、CodeRabbit、Greptile の有用な部分に匹敵するスコープの deep analyzer: セキュリティエビデンス、依存リスク、CI/CD 推奨、PR レビュー挙動、設定品質、トークン/コストリスク、ハーネスドリフト。
- 検証済み ECC パターン、過去 PR 結果、依存アドバイザリ、CI 失敗、レビュー決定、チーム固有規約上の RAG/リファレンスセット。
- 所見をプロジェクトステータス、マイルストーンエビデンス、オーナー対応 issue にマップする Linear 同期(issue 制限を消費しない)。

検証:

- check-run フィクスチャテスト
- billing webhook リプレイテスト
- analyzer ゴールデン PR フィクスチャ
- Linear 同期ドライランフィクスチャ

### Closed-Stale サルベージレーン

陳腐 PR をクローズすることは公開キューを利用可能に保つが、コントリビューターがリベースの時間が無くなったために有用な作業が失われてはならない。

実行ルール:

1. 陳腐、コンフリクト、廃止 PR を明確なお礼コメントとともにクローズする。
2. ソース PR、作者、クローズ理由、有用なファイル/コンセプト、リスク、推奨メンテナアクション付きでサルベージ台帳に記録する。
3. クリーンアップバッチ後、各クローズ PR diff を手動で検査する。
4. パッチがまだクリーンに適用でき現在のアーキテクチャを保持する場合にのみ cherry-pick する。それ以外は新しいメンテナブランチで有用なアイデアを再実装する。
5. コミット本文または PR 本文に帰属を保つ。
6. 有用な作業が着地したら、メンテナ PR またはマージされたコミットをリンクしてソース PR にコメントを返す。
7. 台帳アイテムを landed、superseded、Linear 追跡、無アクションとしてマークする。

必須安全策:

- 生成された churn、バルクローカライズ、依存メジャーバージョン変更を盲目的に cherry-pick しない。
- 1 つのサルベージメガブランチより小さなメンテナ PR を優先する。
- 通常のコード、ドキュメント、カタログ変更と同じ検証ゲートを実行する。
- 最終実装が書き直された場合でもコントリビューター帰属を保つ。

## 近期実装順序

1. ハーネスアダプタマトリクスと公開スコアカードオンランプを拡張する。
2. rc.1 公開前に新鮮な最終コミットエビデンスでリリース/名前/プラグイン公開チェックリストを最新に保つ。
3. HUD/ステータス JSON コントラクトとフィクスチャディレクトリを定義する。
4. AgentShield ポリシースキーマと SARIF フィクスチャを開始する。
5. ECC Tools billing と check-run サーフェスを監査する。
6. レガシーフォルダと closed-stale PR をサルベージ台帳にインベントリする。
7. 帰属付きの小さなメンテナ PR で有用な陳腐作業を port する。

## 非ゴール

- ローカルイベントモデルが有用かつテスト可能になる前のホストテレメトリ。
- 検証者エビデンス無しでのユーザーハーネス設定の自動変更。
- いずれか 1 つのエージェントハーネスを canonical なインターフェースとして扱うこと。
- コマンド、パッケージ、マーケットプレース、billing エビデンスが新鮮になる前のリリースまたは支払い告知。

# Changelog

## 2.0.0-rc.1 - 2026-04-28

### ハイライト

- Hermes オペレータ向けに ECC 2.0 のリリース候補サーフェスを公開する。
- ECC を Claude Code、Codex、Cursor、OpenCode、Gemini にまたがる再利用可能なクロスハーネス基盤として位置づける。
- プライベートなオペレータ状態を公開する代わりに、サニタイズした Hermes インポートスキルサーフェスを追加する。

### リリースサーフェス

- package、plugin、marketplace、OpenCode、agent、README のメタデータを `2.0.0-rc.1` に更新した。
- `docs/releases/2.0.0-rc.1/` を追加し、リリースノート、ソーシャル投稿草稿、ローンチチェックリスト、引き継ぎノート、デモプロンプトを収録した。
- `docs/architecture/cross-harness.md` と、ECC/Hermes 境界の回帰カバレッジを追加した。
- `ecc2/` のバージョニングは当面独立を保つ。リリースエンジニアリングが別途決定しない限り、これはアルファコントロールプレーンの足場という位置づけである。

### 注意事項

- これはリリース候補であり、完全な ECC 2.0 コントロールプレーンロードマップの GA を主張するものではない。
- プレリリースの npm 公開は、リリースエンジニアリングが明示的に他を選択しない限り `next` dist-tag を使用すること。

## 1.10.0 - 2026-04-05

### ハイライト

- 数週間にわたる OSS の成長とバックログマージを経て、公開リリースサーフェスをライブリポジトリと同期した。
- オペレータワークフローレーンを拡張し、ボイス、グラフランキング、課金、ワークスペース、アウトバウンドのスキルを追加した。
- メディア生成レーンを拡張し、Manim と Remotion を中心としたローンチツールを追加した。
- ECC 2.0 アルファコントロールプレーンバイナリが `ecc2/` からローカルでビルドできるようになり、最初の実用可能な CLI/TUI サーフェスを公開する。

### リリースサーフェス

- plugin、marketplace、Codex、OpenCode、agent のメタデータを `1.10.0` に更新した。
- 公開カウントをライブ OSS サーフェスに同期した: 38 エージェント、156 スキル、72 コマンド。
- トップレベルのインストール向けドキュメントとマーケットプレース説明を、現在のリポジトリ状態に合わせて更新した。

### 新規ワークフローレーン

- `brand-voice` — 正規のソース由来ライティングスタイルシステム。
- `social-graph-ranker` — 重み付き温かい紹介グラフランキングプリミティブ。
- `connections-optimizer` — グラフランキング上に構築されたネットワーク剪定・追加ワークフロー。
- `customer-billing-ops`, `google-workspace-ops`, `project-flow-ops`, `workspace-surface-audit`。
- `manim-video`, `remotion-video-creation`, `nestjs-patterns`。

### ECC 2.0 アルファ

- `cargo build --manifest-path ecc2/Cargo.toml` がリポジトリベースラインで成功する。
- `ecc-tui` は現在 `dashboard`, `start`, `sessions`, `status`, `stop`, `resume`, `daemon` を公開する。
- アルファは実在し、ローカル実験に使用可能であるが、より広範なコントロールプレーンロードマップは未完成であり、GA とみなすべきではない。

### 注意事項

- Claude プラグインはプラットフォームレベルのルール配布制約により制限を受け続けている。selective install/OSS パスが依然として最も信頼できるフルインストール手段である。
- 本リリースはリポジトリサーフェスの是正とエコシステム同期であり、完全な ECC 2.0 ロードマップ完成の主張ではない。

## 1.9.0 - 2026-03-20

### ハイライト

- マニフェスト駆動パイプラインと SQLite ステートストアによる selective install アーキテクチャ。
- 6 つの新エージェントと言語別ルールにより、10 以上のエコシステムをカバー。
- メモリスロットリング、サンドボックス修正、5 層ループガードによる observer の信頼性強化。
- スキル進化とセッションアダプタを備えた、自己改善スキルの基盤。

### 新エージェント

- `typescript-reviewer` — TypeScript/JavaScript コードレビュー専門 (#647)
- `pytorch-build-resolver` — PyTorch ランタイム、CUDA、学習エラー解決 (#549)
- `java-build-resolver` — Maven/Gradle ビルドエラー解決 (#538)
- `java-reviewer` — Java と Spring Boot のコードレビュー (#528)
- `kotlin-reviewer` — Kotlin/Android/KMP コードレビュー (#309)
- `kotlin-build-resolver` — Kotlin/Gradle ビルドエラー (#309)
- `rust-reviewer` — Rust コードレビュー (#523)
- `rust-build-resolver` — Rust ビルドエラー解決 (#523)
- `docs-lookup` — ドキュメントと API リファレンス調査 (#529)

### 新スキル

- `pytorch-patterns` — PyTorch ディープラーニングワークフロー (#550)
- `documentation-lookup` — API リファレンスとライブラリドキュメント調査 (#529)
- `bun-runtime` — Bun ランタイムパターン (#529)
- `nextjs-turbopack` — Next.js Turbopack ワークフロー (#529)
- `mcp-server-patterns` — MCP サーバー設計パターン (#531)
- `data-scraper-agent` — AI 駆動の公開データ収集 (#503)
- `team-builder` — チーム構成スキル (#501)
- `ai-regression-testing` — AI 回帰テストワークフロー (#433)
- `claude-devfleet` — マルチエージェントオーケストレーション (#505)
- `blueprint` — マルチセッション構築計画
- `everything-claude-code` — 自己参照型 ECC スキル (#335)
- `prompt-optimizer` — プロンプト最適化スキル (#418)
- 8 つの Evos オペレーショナルドメインスキル (#290)
- 3 つの Laravel スキル (#420)
- VideoDB スキル (#301)

### 新コマンド

- `/docs` — ドキュメント参照 (#530)
- `/aside` — サイド会話 (#407)
- `/prompt-optimize` — プロンプト最適化 (#418)
- `/resume-session`, `/save-session` — セッション管理
- チェックリストベースの総合判定による `learn-eval` の改善

### 新ルール

- Java 言語ルール (#645)
- PHP ルールパック (#389)
- Perl 言語ルールおよびスキル (パターン、セキュリティ、テスト)
- Kotlin/Android/KMP ルール (#309)
- C++ 言語サポート (#539)
- Rust 言語サポート (#523)

### インフラストラクチャ

- マニフェスト解決による selective install アーキテクチャ (`install-plan.js`, `install-apply.js`) (#509, #512)
- インストール済みコンポーネント追跡用のクエリ CLI 付き SQLite ステートストア (#510)
- 構造化セッション記録のためのセッションアダプタ (#511)
- 自己改善スキルのためのスキル進化基盤 (#514)
- 決定論的スコアリングによるオーケストレーションハーネス (#524)
- CI でのカタログカウント強制 (#525)
- 109 スキル全てのインストールマニフェスト検証 (#537)
- PowerShell インストーララッパー (#532)
- `--target antigravity` フラグによる Antigravity IDE サポート (#332)
- Codex CLI カスタマイズスクリプト (#336)

### バグ修正

- 6 ファイルにわたる 19 件の CI テスト失敗を解決 (#519)
- インストールパイプライン、オーケストレータ、リペアでの 8 件のテスト失敗を修正 (#564)
- スロットリング、再入防止ガード、テールサンプリングによる observer メモリ爆発の修正 (#536)
- Haiku 起動時の observer サンドボックスアクセス修正 (#661)
- ワークツリー project ID 不一致の修正 (#665)
- observer の遅延起動ロジック (#508)
- observer の 5 層ループ防止ガード (#399)
- フックの可搬性および Windows .cmd サポート
- Biome フック最適化 — npx オーバーヘッドを排除 (#359)
- InsAIts セキュリティフックをオプトイン化 (#370)
- Windows spawnSync エクスポート修正 (#431)
- instinct CLI の UTF-8 エンコーディング修正 (#353)
- フックでのシークレットスクラビング (#348)

### 翻訳

- 韓国語 (ko-KR) 翻訳 — README、エージェント、コマンド、スキル、ルール (#392)
- 中国語 (zh-CN) ドキュメント同期 (#428)

### Credits

- @ymdvsymd — observer サンドボックスおよびワークツリー修正
- @pythonstrup — biome フック最適化
- @Nomadu27 — InsAIts セキュリティフック
- @hahmee — 韓国語翻訳
- @zdocapp — 中国語翻訳同期
- @cookiee339 — Kotlin エコシステム
- @pangerlkr — CI ワークフロー修正
- @0xrohitgarg — VideoDB スキル
- @nocodemf — Evos オペレーショナルスキル
- @swarnika-cmd — コミュニティコントリビューション

## 1.8.0 - 2026-03-04

### ハイライト

- 信頼性、評価規律、自律ループ運用にフォーカスしたハーネスファーストリリース。
- フックランタイムがプロファイルベースの制御とターゲットフック無効化をサポートするようになった。
- NanoClaw v2 にモデルルーティング、スキルホットロード、ブランチング、検索、コンパクション、エクスポート、メトリクスを追加した。

### コア

- 新コマンドを追加: `/harness-audit`, `/loop-start`, `/loop-status`, `/quality-gate`, `/model-route`。
- 新スキルを追加:
  - `agent-harness-construction`
  - `agentic-engineering`
  - `ralphinho-rfc-pipeline`
  - `ai-first-engineering`
  - `enterprise-agent-ops`
  - `nanoclaw-repl`
  - `continuous-agent-loop`
- 新エージェントを追加:
  - `harness-optimizer`
  - `loop-operator`

### フックの信頼性

- 堅牢なフォールバックサーチによる SessionStart のルート解決を修正。
- セッションサマリの永続化を、トランスクリプトペイロードが利用可能な `Stop` に移動。
- quality-gate および cost-tracker フックを追加。
- 脆弱なインラインフックワンライナーを、専用スクリプトファイルに置き換え。
- `ECC_HOOK_PROFILE` と `ECC_DISABLED_HOOKS` のコントロールを追加。

### クロスプラットフォーム

- ドキュメント警告ロジックでの Windows セーフなパス処理を改善。
- 非対話実行でのハングを避けるため、observer ループ挙動を堅牢化。

### 注意事項

- `autonomous-loops` は 1 リリースの間、互換エイリアスとして維持される。正規名は `continuous-agent-loop` である。

### Credits

- inspired by [zarazhangrui](https://github.com/zarazhangrui)
- homunculus-inspired by [humanplane](https://github.com/humanplane)

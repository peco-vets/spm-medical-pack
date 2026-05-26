# Working Context

Last updated: 2026-04-08

## 目的

エージェント、スキル、コマンド、フック、ルール、インストールサーフェス、ECC 2.0 プラットフォーム構築のための公開 ECC プラグインリポジトリ。

## 現在の正(Current Truth)

- デフォルトブランチ: `main`
- 公開リリースサーフェスは `v1.10.0` に揃っている
- 公開カタログの正は `47` agents、`79` commands、`181` skills
- 公開プラグインスラッグは現在 `ecc` である。レガシー `everything-claude-code` インストールパスは互換のためサポートし続ける
- リリース議論: `#1272`
- ECC 2.0 はツリー内に存在しビルドできるが、依然として GA ではなくアルファである
- 主な進行中の運用作業:
  - デフォルトブランチを green に保つ
  - 公開 PR バックログがゼロになった今、`main` からの issue 駆動修正を続ける
  - ECC 2.0 コントロールプレーンとオペレータサーフェスの構築を続ける

## 現在の制約

- タイトルまたはコミットサマリのみでのマージは不可。
- 出荷される ECC サーフェスに任意の外部ランタイムインストールを入れない。
- 重複するスキル、フック、エージェントは、重複が実質的でランタイム分離が不要な場合に統合する。

## アクティブなキュー

- PR バックログ: 減ったがアクティブである。安全な ECC ネイティブ変更のみを direct-port し、重複、陳腐ジェネレータ、未監査の外部ランタイムレーンはクローズする
- アップストリームブランチのバックログは依然として選択的なマイニングとクリーンアップが必要:
  - `origin/feat/hermes-generated-ops-skills` には依然 3 つのユニークコミットが残るが、ECC ネイティブの再利用可能スキルのみを救出すること
  - 複数の `origin/ecc-tools/*` 自動化ブランチは陳腐化している。ユニークな価値が無いことを確認してから剪定する
- Product:
  - selective install のクリーンアップ
  - control plane のプリミティブ
  - operator surface
  - 自己改善スキル
  - `agent.yaml` エクスポートと出荷済み `commands/`・`skills/` ディレクトリのパリティ維持(現代的インストールサーフェスがコマンド登録を静かに失わないように)
- スキル品質:
  - コンテンツ系スキルをソース由来のボイスモデリングを使うよう書き直す
  - 一般的な LLM 修辞、定型 CTA パターン、強制的なプラットフォームステレオタイプを削除する
  - 重複・低シグナルなスキル内容の 1 件ずつ監査を継続する
  - リポジトリガイダンスとコントリビューションフローを skills-first へ移し、`commands/` は明示的な互換 shim としてのみ残す
  - 生の API や切り離されたプリミティブのみを公開するのではなく、接続されたサーフェスを包むオペレータスキルを追加する
  - canonical なボイスシステム、ネットワーク最適化レーン、再利用可能な Manim 解説レーンを着地させる
- セキュリティ:
  - 依存関係の姿勢をクリーンに保つ
  - 自己完結型のフック・MCP 挙動を維持する

## オープン PR の分類

- 2026-04-01 にバックログハイジーン・マージポリシーでクローズ:
  - `#1069` `feat: add everything-claude-code ECC bundle`
  - `#1068` `feat: add everything-claude-code-conventions ECC bundle`
  - `#1080` `feat: add everything-claude-code ECC bundle`
  - `#1079` `feat: add everything-claude-code-conventions ECC bundle`
  - `#1064` `chore(deps-dev): bump @eslint/js from 9.39.2 to 10.0.1`
  - `#1063` `chore(deps-dev): bump eslint from 9.39.2 to 10.1.0`
- 2026-04-01 に、内容が外部エコシステム由来であり、手動の ECC ネイティブ再移植経由でのみ着地させるべきものとしてクローズ:
  - `#852` openclaw-user-profiler
  - `#851` openclaw-soul-forge
  - `#640` harper skills
- 次に完全 diff 監査するネイティブサポート候補:
  - `#1055` Dart / Flutter サポート
  - `#1043` C# reviewer と .NET スキル
- 監査後に着地した direct-port 候補:
  - `#1078` 管理 Claude フック再インストール時の hook-id dedupe
  - `#844` ui-demo スキル
  - `#1110` インストール時 Claude フックのルート解決
  - `#1106` ポータブル Codex Context7 キー抽出
  - `#1107` Codex ベースラインマージとサンプルエージェントロール同期
  - `#1119` 陳腐 CI/lint クリーンアップで安全な低リスク修正を含むもの
- 完全監査後に ECC 内で port または rebuild するもの:
  - `#894` Jira インテグレーション
  - `#814` + `#808` を Opencode およびクロスハーネスサーフェス用の単一統合通知レーンとして再構築

## インターフェース

- 公開の正: GitHub Issue と PR
- 内部実行の正: ECC プログラム配下のリンク済み Linear ワークアイテム
- 現在リンクされている Linear アイテム:
  - `ECC-206` エコシステム CI ベースライン
  - `ECC-207` PR バックログ監査とマージポリシー強化
  - `ECC-208` コンテキストハイジーン
  - `ECC-210` skills-first ワークフロー移行とコマンド互換廃止

## 更新ルール

このファイルは現在のスプリント、ブロッカー、次のアクションについてのみ詳細を保つ。完了した作業は、実行を能動的に形作らなくなった時点でアーカイブまたはリポジトリドキュメントに要約する。

## 最新の実行ノート

- 2026-04-05: `#1213` の重複クリーンアップを継続し、`coding-standards` を削除せずにベースラインのクロスプロジェクト規約レイヤに絞り込んだ。スキルは詳細な React/UI ガイダンスを `frontend-patterns` に、バックエンド/API 構造を `backend-patterns`/`api-design` に明示的に指し示すようになり、再利用可能な命名・可読性・イミュータビリティ・コード品質の期待のみを保持する。
- 2026-04-05: `#1287` で公開された `v1.10.0` アーティファクトが依然として陳腐だったため、OpenCode リリースパスのパッケージング回帰ガードを追加。`tests/scripts/build-opencode.test.js` が `npm pack --dry-run` の tarball に `.opencode/dist/index.js` とコンパイル済みプラグイン/ツールエントリポイントが含まれることを確認するようになり、将来のリリースが OpenCode ペイロードを静かに省略できないようにした。
- 2026-04-05: `#829` 用の `skills/agent-introspection-debugging` を ECC ネイティブな自己デバッグフレームワークとして着地。意図的に偽のランタイム自動化ではなくガイダンスファーストにしている: 失敗状態を捕捉し、パターンを分類し、最小限の封じ込められた回復アクションを適用し、構造化された内省レポートを出力して、適切なときに `verification-loop` / `continuous-learning-v2` へ引き継ぐ。
- 2026-04-05: 最新の direct port 後の `main` の npm CI break を修正。`package-lock.json` が `globals` devDependency で `package.json` に対しドリフト (`^17.1.0` vs `^17.4.0`) しており、すべての npm ベース GitHub Actions ジョブが `npm ci` で失敗していた。ロックファイルのみリフレッシュし、`npm ci --ignore-scripts` で検証し、混在ロックワークスペースはそれ以外はそのままにした。
- 2026-04-05: `#1221` の有用な発見可能性部分を direct-port しつつ、2 つ目のヘルスケアコンプライアンスシステムを重複させないようにした。`skills/hipaa-compliance/SKILL.md` を canonical な `healthcare-phi-compliance` / `healthcare-reviewer` レーンへの細い HIPAA 固有エントリポイントとして追加し、両方のヘルスケアプライバシースキルを selective install のために `security` インストールモジュールに配線した。
- 2026-04-05: 監査済みのブロックチェーン/web3 セキュリティレーンを `#1222` から 4 つの自己完結スキルとして `main` に direct-port: `defi-amm-security`、`evm-token-decimals`、`llm-trading-agent-security`、`nodejs-keccak256`。マージされていないフォーク PR としてではなく、`security` インストールモジュールの一部となった。
- 2026-04-05: `#1203` の有用な救出パスを `main` 上で完了。`skills/security-bounty-hunter`、`skills/api-connector-builder`、`skills/dashboard-builder` は、元のコミュニティドラフトの薄い版ではなく、ECC ネイティブな書き直しとしてツリー内にある。元の PR はマージではなく superseded として扱うべき。
- 2026-04-02: `ECC-Tools/main` が `9566637` (`fix: prefer commit lookup over git ref resolution`) を出荷した。PR-analysis の火災は、`git.getRef` の前に明示的なコミット解決を優先することでアプリリポジトリで修正され、pull ref と plain branch ref の回帰カバレッジも追加された。本リポジトリでミラーされた公開トラッキング issue `#1184` はアップストリームで解決済みとしてクローズされた。
- 2026-04-02: `#1043` のクリーンなネイティブサポートコアを `main` に direct-port: `agents/csharp-reviewer.md`、`skills/dotnet-patterns/SKILL.md`、`skills/csharp-testing/SKILL.md`。既存の C# ルール/ドキュメント言及と、実際に出荷される C# レビュー/テストガイダンスとのギャップを埋めた。
- 2026-04-02: `#1055` のクリーンなネイティブサポートコアを `main` に direct-port: `agents/dart-build-resolver.md`、`commands/flutter-build.md`、`commands/flutter-review.md`、`commands/flutter-test.md`、`rules/dart/*`、`skills/dart-flutter-patterns/SKILL.md`。古い PR の別個の `flutter-dart` モジュールレイアウトを再生せず、現行の `framework-language` モジュールにスキルパスを配線した。
- 2026-04-02: diff 監査後に `#1081` をクローズ。PR は canonical な `x-api` スキルに外部 X/Twitter バックエンド (`Xquik` / `x-twitter-scraper`) のベンダーマーケティングドキュメントを追加しただけで、ECC ネイティブな能力をコントリビュートしていなかった。
- 2026-04-02: `#894` の有用な Jira レーンを direct-port しつつ、現在のサプライチェーンポリシーに合致するようサニタイズ。`commands/jira.md`、`skills/jira-integration/SKILL.md`、`mcp-configs/mcp-servers.json` の pinned `jira` MCP テンプレートはツリー内にあるが、スキルはユーザーに `curl | bash` で `uv` をインストールするよう指示しないようになった。`jira-integration` は selective install のため `operator-workflows` に分類されている。
- 2026-04-02: 完全 diff 監査後に `#1125` をクローズ。バンドル/スキルルーターレーンは多くの存在しない、または非 canonical なサーフェスをハードコードし、小さな ECC ネイティブインデックスレイヤの代わりに 2 つ目のルーティング抽象を作っていた。
- 2026-04-02: 完全 diff 監査後に `#1124` をクローズ。追加されたエージェントロスターは丁寧に書かれていたが、ツリー内の canonical エージェントを強化する代わりに、既存の ECC エージェントサーフェスを 2 つ目の競合カタログ (`dispatch`、`explore`、`verifier`、`executor` など) で重複させていた。
- 2026-04-02: Argus クラスタ `#1098`、`#1099`、`#1100`、`#1101`、`#1102` を完全 diff 監査後にすべてクローズ。5 つの PR すべてに共通する失敗モードは同じ: 出荷される ECC サーフェスのファーストクラスランタイム依存として外部マルチ CLI ディスパッチを扱っていた。有用なプロトコルアイデアは、外部 CLI ファンアウトの前提を持たない ECC ネイティブなオーケストレーション、レビュー、リフレクションレーンに後日再移植すべき。
- 2026-04-02: 以前オープンだったネイティブサポート/インテグレーションキュー (`#1081`、`#1055`、`#1043`、`#894`) は direct-port またはクローズポリシーにより完全に解決された。アクティブな公開 PR キューは現在ゼロ。次のフォーカスはバックログ PR の受け入れではなく、issue 駆動の mainline 修正と CI ヘルス。
- 2026-04-01: `main` CI はロックファイルとフック検証修正後、ローカルで `1723/1723` テストパスに復旧した。
- 2026-04-01: 自動生成された ECC バンドル PR `#1068` と `#1069` はマージではなくクローズした。有用なアイデアは明示的な diff 監査後に手動で移植すること。
- 2026-04-01: メジャーバージョン ESLint bump PR `#1063` と `#1064` をクローズ。計画された ESLint 10 移行レーン内でのみ再訪する。
- 2026-04-01: Notification PR `#808` と `#814` は重複として識別され、並列ブランチとして着地させるのではなく、1 つの統一機能として再構築すべきと判断した。
- 2026-04-01: 外部ソーススキル PR `#640`、`#851`、`#852` は新しい取り込みポリシーの下でクローズした。ブランド/ソースインポート PR を直接マージするのではなく、後日、監査済みソースからアイデアをコピーする。
- 2026-04-01: `ecc2/Cargo.lock` の残っていた低 GitHub アドバイザリは `ratatui` を `crossterm_0_28` 付きの `0.30` に移すことで対処した。これにより transitive な `lru` が `0.12.5` から `0.16.3` に更新された。`cargo build --manifest-path ecc2/Cargo.toml` は依然パスする。
- 2026-04-01: `#834` の安全コアを PR 全体をマージするのではなく `main` に直接 port した。これにはより厳密な install-plan 検証、サポートされていないモジュールツリーをスキップする antigravity ターゲットフィルタリング、英語と zh-CN ドキュメントの追跡カタログ同期、専用 `catalog:sync` 書き込みモードが含まれる。
- 2026-04-01: リポジトリカタログの正は、追跡される英語と zh-CN ドキュメント全体で `36` agents、`68` commands、`142` skills に同期された。
- 2026-04-01: ドキュメント、スクリプト、テストでのレガシー絵文字と非必須シンボル使用を正規化し、unicode-safety レーンを green に保ちつつチェック自体を弱めないようにした。
- 2026-04-01: `#834` の残っていた自己完結部分 `docs/zh-CN/skills/browser-qa/SKILL.md` をリポジトリに direct-port した。コミット後、`#834` は superseded-by-direct-port としてクローズすべき。
- 2026-04-01: コンテンツスキルクリーンアップを `content-engine`、`crosspost`、`article-writing`、`investor-outreach` から開始した。新しい方向性は、ソースファーストなボイスキャプチャ、明示的なアンチトロープ禁止、強制的なプラットフォームペルソナシフト無し。
- 2026-04-01: `node scripts/ci/check-unicode-safety.js --write` が残りの絵文字を含む Markdown ファイル(複数の `remotion-video-creation` ルールドキュメントと古いローカルプランノートを含む)をサニタイズした。
- 2026-04-01: コア英語リポジトリサーフェスは skills-first 姿勢にシフトした。README、AGENTS、プラグインメタデータ、コントリビューター指示は `skills/` を canonical として扱い、`commands/` は移行中のレガシースラッシュエントリ互換として扱う。
- 2026-04-01: 後続のバンドルクリーンアップで `#1080` と `#1079` をクローズした。これらは canonical な ECC ソース変更を出荷するのではなく、command-first 足場を重複させる生成された `.claude/` バンドル PR だった。
- 2026-04-01: `#1078` の有用なコアを `main` に直接 port しつつ、レガシーな ID 無しフックインストールが 2 回目ではなく初回再インストールでクリーンに dedupe されるよう実装を引き締めた。`hooks/hooks.json` に安定したフック ID を追加し、`mergeHookEntries()` にセマンティックフォールバックエイリアスを追加し、pre-id 設定からのアップグレードをカバーする回帰テストを追加した。
- 2026-04-01: 明白なコマンド/スキル重複を薄いレガシー shim に畳み込み、`skills/` が NanoClaw、context-budget、DevFleet、docs lookup、E2E、evals、orchestration、prompt optimization、rules distillation、TDD、verification のメンテナンス本体を持つようにした。
- 2026-04-01: `#844` の自己完結コアを `main` に `skills/ui-demo/SKILL.md` として直接 port し、PR 全体をマージするのではなく `media-generation` インストールモジュール下に登録した。
- 2026-04-01: 最初の接続済みワークフローオペレータレーンを生プラグインや API としてサーフェスを残さず、ECC ネイティブスキルとして追加した: `workspace-surface-audit`、`customer-billing-ops`、`project-flow-ops`、`google-workspace-ops`。これらは新しい `operator-workflows` インストールモジュール下で追跡される。
- 2026-04-01: 未解決のフックパス PR レーンからの実際の修正をアクティブインストーラに直接 port した。Claude インストールは `settings.json` とコピーされた `hooks/hooks.json` の両方で `${CLAUDE_PLUGIN_ROOT}` を具体的なインストールルートに置換するようになり、プラグイン管理 env 注入の外側で PreToolUse/PostToolUse フックが動作し続けるようになった。
- 2026-04-01: `scripts/sync-ecc-to-codex.sh` の GNU 専用 `grep -P` パーサを Context7 キー抽出のためのポータブル Node パーサに置き換えた。BSD/macOS 同期が非ポータブルパースに戻らないよう、ソースレベルの回帰カバレッジを追加した。
- 2026-04-01: direct port 後のターゲット回帰スイートは green: `tests/scripts/install-apply.test.js`、`tests/scripts/sync-ecc-to-codex.test.js`、`tests/scripts/codex-hooks.test.js`。
- 2026-04-01: `#1107` の有用なコアを add-only な Codex ベースラインマージとして `main` に直接 port した。`scripts/sync-ecc-to-codex.sh` は `.codex/config.toml` から不足する非 MCP デフォルトを埋め、サンプルエージェントロールファイルを `~/.codex/agents` に同期し、ユーザー設定を置き換える代わりに保持するようになった。sparse 設定と暗黙の親テーブルの回帰カバレッジを追加した。
- 2026-04-01: 陳腐な CI PR をオープンに保つ代わりに、`#1119` の安全な低リスククリーンアップを `main` に直接 port した。これには `.mjs` eslint 処理、より厳密な null チェック、bash-log テストの Windows ホームディレクトリカバレッジ、より長い Trae シェルテストタイムアウトが含まれる。
- 2026-04-01: `brand-voice` を canonical なソース由来ライティングスタイルシステムとして追加し、コンテンツレーンがスキル間で部分的なスタイルヒューリスティクスを重複させる代わりに、共有ボイスの正として扱うよう配線した。
- 2026-04-01: `connections-optimizer` を X と LinkedIn のためのレビューファーストな social-graph 再編成ワークフローとして追加した。明示的な剪定モード、ブラウザフォールバック期待、Apple Mail ドラフトガイダンス付き。
- 2026-04-01: `manim-video` を再利用可能な技術解説レーンとして追加し、ローンチやシステムアニメーションが 1 回限りのスクラッチスクリプトに依存しないよう、スターターのネットワークグラフシーンを seed した。
- 2026-04-02: 重み付きブリッジ減衰モデルが完全なリードワークフロー外でも再利用可能なため、`social-graph-ranker` をスタンドアロンプリミティブとして再抽出した。`lead-intelligence` は全アルゴリズム説明をインラインで持つ代わりに canonical なグラフランキングのためにそれを指し示すようになり、`connections-optimizer` は剪定、追加、アウトバウンドレビューパックのためのより広いオペレータレイヤとして残る。
- 2026-04-02: 同じ統合ルールをライティングレーンに適用した。`brand-voice` が canonical なボイスシステムのまま残り、`content-engine`、`crosspost`、`article-writing`、`investor-outreach` は 2 つ目の Affaan/ECC ボイスモデルを重複させたり、完全な禁止リストを複数箇所で繰り返す代わりに、ワークフロー固有のガイダンスのみを保持するようになった。
- 2026-04-02: 既存ポリシーの下で新たに自動生成されたバンドル PR `#1182` と `#1183` をクローズした。ジェネレータ出力からの有用なアイデアは、`.claude`/バンドル PR を全体マージするのではなく、canonical なリポジトリサーフェスに手動で port すること。
- 2026-04-02: `#1164` の安全な 1 ファイル macOS observer 修正を `continuous-learning-v2` 遅延起動ロックのための POSIX `mkdir` フォールバックとして `main` に直接 port し、direct port により superseded として PR をクローズした。
- 2026-04-02: `#1153` の安全なコアを `main` に直接 port した: orchestration/docs サーフェスの markdownlint クリーンアップに加え、`install-apply`/`repair` テストの Windows `USERPROFILE` とパス正規化修正。リポジトリ依存をインストール後のローカル検証: `node tests/scripts/install-apply.test.js`、`node tests/scripts/repair.test.js`、ターゲット `yarn markdownlint` すべてパス。
- 2026-04-02: 安全な web/frontend ルールレーンを `#1122` から `rules/web/` に direct-port したが、`rules/web/hooks.md` をプロジェクトローカルツールを優先し、リモート 1 回限りのパッケージ実行例を避けるよう適応させた。
- 2026-04-02: `#1127` の design-quality リマインダを現在の ECC フックアーキテクチャに適応させた。ローカル `scripts/hooks/design-quality-check.js`、Claude `hooks/hooks.json` 配線、Cursor `after-file-edit.js` 配線、`tests/hooks/design-quality-check.test.js` の専用フックカバレッジを伴う。
- 2026-04-02: `#1141` を `main` 上で `16e9b17` で修正した。observer ライフサイクルは純粋にデタッチされたものではなくセッション認識型になった: `SessionStart` がプロジェクトスコープリースを書き、`SessionEnd` がそのリースを削除し最後のリースが消えたときに observer を停止し、`observe.sh` がプロジェクトアクティビティを記録し、`observer-loop.sh` はリースが残っていないときアイドルで exit するようになった。`bash -n`、`node tests/hooks/observer-memory.test.js`、`node tests/integration/hooks.test.js`、`node scripts/ci/validate-hooks.js hooks/hooks.json`、`node scripts/ci/check-unicode-safety.js` のターゲット検証がパスした。
- 2026-04-02: `#1070` の背後にある残っていた Windows 限定フック回帰を、`scripts/lib/utils.js#getHomeDir()` が `os.homedir()` にフォールバックする前に明示的な `HOME`/`USERPROFILE` オーバーライドを尊重するようにすることで修正した。これにより、Windows でのフックインテグレーション実行用のテスト分離 observer 状態パスが復元される。`tests/lib/utils.test.js` に回帰カバレッジを追加した。`node tests/lib/utils.test.js`、`node tests/integration/hooks.test.js`、`node tests/hooks/observer-memory.test.js`、`node scripts/ci/check-unicode-safety.js` のターゲット検証がパスした。
- 2026-04-02: NestJS サポートを `#1022` のために `skills/nestjs-patterns/SKILL.md` として `main` に direct-port し、`framework-language` インストールモジュールに配線した。その後リポジトリカタログを同期 (`38` agents、`72` commands、`156` skills) し、NestJS が未充足フレームワークギャップとしてリストされなくなるようドキュメントを更新した。
- 2026-04-05: `846ffb7` (`chore: ship v1.10.0 release surface refresh`) を出荷した。これにより README/プラグインメタデータ/パッケージバージョンが更新され、明示的プラグインエージェントインベントリが同期され、陳腐な star/fork/contributor カウントが更新され、`docs/releases/1.10.0/*` が作成され、`v1.10.0` がタグ付けされリリースされ、`#1272` でアナウンス議論が投稿された。
- 2026-04-05: ブランチ全体を replay せずに `6eba30f` で再利用可能な Hermes ブランチオペレータスキルを救出した。`skills/github-ops`、`skills/knowledge-ops`、`skills/hookify-rules` を追加し、それらをインストールモジュールに配線し、リポジトリを `159` skills に再同期した。`knowledge-ops` は現在のワークスペースモデル(クローン済みリポジトリ内のライブコード、GitHub/Linear のアクティブな正、KB/アーカイブレイヤのより広い非コードコンテキスト)に明示的に適応された。
- 2026-04-05: `db6d52e` で残りの OpenCode npm-publish ギャップを修正した。ルートパッケージは `prepack` 中に `.opencode/dist` をビルドし、コンパイル済み OpenCode プラグインアセットを公開された tarball に含め、専用回帰テスト (`tests/scripts/build-opencode.test.js`) を持つようになり、そのサーフェスについて生 TypeScript ソースのみを出荷しなくなった。
- 2026-04-05: `skills/council` を追加し、`#1193` の安全な `code-tour` レーンを direct-port し、リポジトリを `162` skills に再同期した。`code-tour` は自己完結のままで、実際のファイル/行アンカーを持つ `.tours/*.tour` アーティファクトのみを生成する。スキル内に外部ランタイムや拡張インストールは仮定されない。
- 2026-04-05: 最新の自動生成 ECC バンドル PR ウェーブ (`#1275`-`#1281`) を、リポジトリレベル issue コメント `/analyze` リクエストが繰り返しバンドル PR を開くのをブロックしつつ、PR スレッド再試行分析が不変ヘッド SHA に対して走るのを許可する `ECC-Tools/main` 修正 `f615905` を展開した後にクローズした。
- 2026-04-05: `agents/seo-specialist.md` と `skills/seo/SKILL.md` を `main` に direct-port し、`skills/seo` を `business-content` に配線して SEO ギャップを埋めた。これにより `team-builder` の SEO スペシャリストへの陳腐な参照が解決され、陳腐な PR を全体マージせずに公開カタログを `39` agents、`163` skills にした。
- 2026-04-05: `#1214` の有用な common-rule デルタを `rules/common/coding-style.md` と `rules/common/testing.md` (KISS/DRY/YAGNI リマインダ、命名規約、code-smell ガイダンス、AAA スタイルテストガイダンス) に直接救出し、元の mixed deletion PR をクローズした。その PR の広範なスキル削除は意図的に replay しなかった。
- 2026-04-05: `.github/workflows/monthly-metrics.yml` の stale-row バグを `bf5961e` で修正した。ワークフローは月が既に存在する場合に early-return する代わりに、issue `#1087` の現在の月行をリフレッシュするようになり、ディスパッチされた実行が 4 月のスナップショットを現在の star/fork/release カウントに更新した。
- 2026-04-05: ブランチを replay する代わりに、発散した Hermes ブランチからの有用なコスト制御ワークフローを小さな ECC ネイティブオペレータスキルとして救出した。`skills/ecc-tools-cost-audit/SKILL.md` は現在 `operator-workflows` に配線され、兄弟 `ECC-Tools` リポジトリでの webhook → queue → worker トレース、burn 抑制、クオータ回避、プレミアムモデル漏洩、リトライファンアウトにフォーカスしている。
- 2026-04-05: `skills/council/SKILL.md` を `753da37` で ECC ネイティブ四声決定ワークフローとして追加した。PR `#1254` からの有用なプロトコルは保持されたが、シャドウ `~/.claude/notes` 書き込みパスは決定デルタが重要な時に `knowledge-ops`、`/save-session`、または直接 GitHub/Linear 更新を優先して明示的に削除された。
- 2026-04-05: PR `#1243` からの安全な `globals` bump を council レーンの一部として `main` に direct-port し、PR を superseded としてクローズした。
- 2026-04-05: 完全監査後に PR `#1232` をクローズした。提案された `skill-scout` ワークフローは現在の `search-first`、`/skill-create`、`skill-stocktake` と重複している。専用 marketplace-discovery レイヤが後日戻る場合、並列発見パスとして着地させるのではなく、現在のインストール/カタログモデルの上に再構築すべき。
- 2026-04-05: PR `#1209` の安全なローカライズ README スイッチャ修正をドキュメント PR 全体をマージせずに `main` に直接 port した。ナビゲーションがローカライズ README スイッチャ全体で `Português (Brasil)` と `Türkçe` を一貫して含むようになり、より新しいローカライズボディコピーはそのまま残った。
- 2026-04-05: `main` から陳腐な InsAIts 出荷サーフェスを削除した。ECC は外部 Python MCP エントリ、オプトインフック配線、ラッパー/モニタースクリプト、`insa-its` の現在のドキュメント言及をもはや出荷していない。changelog 履歴は残るが、ライブプロダクトサーフェスは現在完全に再び ECC ネイティブになっている。
- 2026-04-05: ブランチ全体を replay せずに再利用可能な Hermes 生成オペレータワークフローレーンを救出した。古い nested `skills/hermes-generated/*` ツリーの代わりに、6 つの ECC ネイティブトップレベルスキルを追加した: `automation-audit-ops`、`email-ops`、`finance-billing-ops`、`messages-ops`、`research-ops`、`terminal-ops`。`research-ops` は既存の research スタックをラップし、他の 5 つは外部ランタイム仮定を導入せず `operator-workflows` を拡張する。
- 2026-04-05: `skills/product-capability` プラス `docs/examples/product-capability-template.md` を issue `#1185` のための canonical な PRD-to-SRS レーンとして追加した。これは曖昧なプロダクト意図と実装の間の ECC ネイティブな capability-contract ステップであり、並列計画サブシステムを生み出すのではなく `business-content` に存在する。
- 2026-04-05: `product-lens` を新しい capability-contract レーンと重複しないよう引き締めた。`product-lens` は明示的にプロダクト診断/ブリーフ検証を所有し、`product-capability` は実装準備のできた capability プランと SRS スタイル制約を所有する。
- 2026-04-05: `#1213` クリーンアップを継続し、削除された `project-guidelines-example` スキルへの陳腐な参照をエクスポート済みインベントリ/ドキュメントから削除し、`continuous-learning-v2` への明示的引き継ぎで `continuous-learning` v1 をサポートされたレガシーパスとしてマークした。
- 2026-04-05: `docs/ko-KR` と `docs/zh-CN` から最後の orphaned ローカライズ `project-guidelines-example` ドキュメントを削除した。テンプレートは現在 `docs/examples/project-guidelines-template.md` のみに存在し、現在のリポジトリサーフェスと一致し、削除されたスキルのための翻訳ドキュメントを出荷することを避ける。
- 2026-04-05: `docs/HERMES-OPENCLAW-MIGRATION.md` を issue `#1051` の現在の公開マイグレーションガイドとして追加した。Hermes/OpenClaw を最終ランタイムではなく蒸留するソースシステムとして再フレーミングし、スケジューラ、ディスパッチ、メモリ、スキル、サービスレイヤを既存の ECC ネイティブサーフェスと ECC 2.0 バックログにマップする。
- 2026-04-05: issue `#916` から `skills/agent-sort` とレガシー `/agent-sort` shim を ECC ネイティブな selective-install ワークフローとして着地させた。具体的なリポジトリ証拠を使ってエージェント、スキル、コマンド、ルール、フック、エクストラを DAILY と LIBRARY バケットに分類し、並列インストーラを発明せず `configure-ecc` にインストール変更を引き継ぐ。カタログの正は現在 `39` agents、`73` commands、`179` skills。
- 2026-04-05: ブランチをマージする代わりに、安全な README 専用 `#1285` スライスを `main` に direct-port した。ECC 上に構築された公開作業をダウンストリームチームがリンクできるよう、小さな `Community Projects` セクションを追加し、インストール、セキュリティ、ランタイムサーフェスを変更しなかった。`#1286` は外部サードパーティ GitHub Action (`hashgraph-online/codex-plugin-scanner`) を追加し、現在のサプライチェーンポリシーを満たさないためレビューで拒否した。
- 2026-04-05: `origin/feat/hermes-generated-ops-skills` を完全 diff で再監査した。ブランチは依然マージ可能ではない: 現在の ECC ネイティブサーフェスを削除し、パッケージング/インストールメタデータを退行させ、より新しい `main` 内容を削除している。ブランチマージではなく選択的救出ポリシーを継続した。
- 2026-04-05: Hermes ブランチから `skills/frontend-design` を自己完結 ECC ネイティブスキルとして選択的に救出し、`.agents` にミラーし、`framework-language` に配線し、検証後にカタログを `180` skills に再同期した。ブランチ自体は、残りのすべてのユニークファイルが意図的に port されるか拒否されるまでリファレンス専用のまま残る。
- 2026-04-05: Hermes ブランチから `hookify` コマンドバンドルとサポート `conversation-analyzer` エージェントを選択的に救出した。`hookify-rules` は canonical なスキルとして既に存在していた。このパスは外部ランタイムやブランチ全体の退行を引き入れずに、ユーザー向けコマンドサーフェス (`/hookify`、`/hookify-help`、`/hookify-list`、`/hookify-configure`) を復元する。カタログの正は現在 `40` agents、`77` commands、`180` skills。
- 2026-04-05: Hermes ブランチから自己完結レビュー/開発バンドルを選択的に救出した: `review-pr`、`feature-dev`、サポートアナライザ/アーキテクチャエージェント (`code-architect`、`code-explorer`、`code-simplifier`、`comment-analyzer`、`pr-test-analyzer`、`silent-failure-hunter`、`type-design-analyzer`)。ブランチのより広い退行をマージせず、PR レビューと機能計画の周辺に ECC ネイティブコマンドサーフェスを追加する。カタログの正は現在 `47` agents、`79` commands、`180` skills。
- 2026-04-05: `docs/HERMES-SETUP.md` をマイグレーションレーン用にサニタイズされたオペレータトポロジードキュメントとして Hermes ブランチから port した。これは `#1051` のためのドキュメント専用サポートであり、ランタイム変更ではなく、Hermes ブランチ自体がマージ可能であることのサインでもない。
- 2026-04-05: `origin/feat/hermes-generated-ops-skills` 上の有用な救出パスを完了した。残りのユニークファイルは明示的に拒否された:
  - 重複した git ヘルパーコマンド (`commit`、`commit-push-pr`、`clean-gone`) は現在のチェックポイント / 公開フローと重複
  - `scripts/hooks/security-reminder*` は現在のランタイムポリシーで正当化されない新しい Python ベースのフックパスを追加する
  - `skills/oura-health` と `skills/pmx-guidelines` はユーザーまたはプロジェクト固有で、canonical な ECC サーフェスではない
  - `docs/releases/2.0.0-preview/*` は時期尚早の collateral であり、後日現在のプロダクトの正から再構築すべき
  - nested `skills/hermes-generated/*` は `main` に既に port された top-level ECC ネイティブオペレータスキルにより superseded されている
- 2026-04-08: `#1327` で報告されたコマンドエクスポート回帰を、`agent.yaml` の canonical な `commands:` セクションを復元し、YAML エクスポートサーフェスと実際の `commands/` ディレクトリの正確なパリティを強制する `tests/ci/agent-yaml-surface.test.js` を追加することで修正した。リポジトリ完全テスト sweep: `1764/1764` パスで検証された。

# ECC 2.0 GA ロードマップ

本ロードマップはアクティブな Linear プロジェクトの永続的なリポジトリミラーである:

<https://linear.app/itomarkets/project/ecc-platform-roadmap-52b328ee03e1>

Linear issue の作成は Ito Markets ワークスペースで再び利用可能である。ライブ実行の正は以下に分かれている:

- Linear プロジェクトドキュメント、issue レーン、依存関係、マイルストーン
- 本リポジトリドキュメント
- マージされた PR のエビデンス
- `~/.cluster-swarm/handoffs/` 配下の引き継ぎ

5 月 19 日のリリース/成長実行マップは
[`docs/releases/2.0.0/ecc-2-hypergrowth-release-command-center.md`](releases/2.0.0/ecc-2-hypergrowth-release-command-center.md)
にある。これは最終 ECC 2.0 リポジトリアイデンティティ、ビデオスイート、パートナー/スポンサーファネル、コンサルティング/トークファネル、ソーシャルローンチ計画のオペレータサーフェスである。

## 2026-05-20 デルタ

- 追跡対象プラットフォーム監査は 5 月 20 日時点で依然 green: `affaan-m/ECC`、`affaan-m/agentshield`、`affaan-m/JARVIS`、`ECC-Tools/ECC-Tools`、`ECC-Tools/ECC-website` 全体でオープン PR 0 件、オープン Issue 0 件、ディスカッションメンテナタッチギャップ 0、回答可能 Q&A ギャップ 0、コンフリクト PR 0、ブロッキング dirty ファイル 0。
- 新規 #2015 setup-location Q&A に回答し、受理済みとしてマークした。回答ではインストールガイダンスを保守的に保つ: `C:\` にインストールしない、通常のワークスペースを使う、`ecc@ecc` Claude プラグインを 1 回だけインストールする、手動ルール使用時は必要なルールフォルダのみコピーする、プラグインとフル手動インストールの積み重ねを避ける。
- ECC-Tools PR #80-#88 が次のホストプラットフォームバッチを着地: runtime receipts が失敗理由を必須化、AgentShield fleet approval ID がホストセキュリティレビューを生き延びてコメント/check-run にレンダーされる、Linear follow-up sync が決定論的な external ID を再利用、ホスト AgentShield remediation items が Linear に同期、ホストジョブ可観測性イベントが queued/completed/blocked/failed/budget-blocked 状態に対して発出、ホストジョブステータスコメントとホスト depth-plan check-run が最近の可観測性/予算イベントを読み戻す。PR #88 はオペレータダッシュボードと本番スモークテスト用に認証済み可観測性 API 読み戻しを追加する。
- AgentShield PR #94 が次のクロスハーネスアダプタスライスを着地: Zed と VS Code はファーストクラスアダプタ検出、`.zed/settings.json` と `.zed/tasks.json` は発見可能スキャン入力、`.zed/setup.mjs` は `.vscode/setup.mjs` と同じ AI-tool persistence IOC ルールにトリップする。
- AgentShield PR #95 が `brace-expansion` 5.x ロックファイルエントリを `5.0.6` に移動して残る default-branch Dependabot アラートをクリア。post-merge Dependabot open-alert API が `[]` を返し、ローカル `npm audit --audit-level=moderate` は脆弱性 0 を返す。
- ECC PR #2019 が Marketplace Pro selected-target release-gate sync を本リポジトリに `30f60710d4e0424fc70d9bbdc105009db141d9d8` としてマージ。post-merge main CI run `26135974576` が lint、coverage、security、validation、フル OS/パッケージマネージャマトリクスで green 完了。
- ECC PR #2020 が selected-target announcement-gate mirror を `c2471fe5c535310f8a8008c9ed7ea9f6757b33f2` としてマージ。post-merge main CI run `26136949698` が同様に完了。
- ECC-Tools PR #90 が `billing:announcement-gate -- --select-ready-target` 用の selected-target official announcement gate を追加。安全な本番 preflight は生 GitHub ログインを必要としなくなり、ライブ実行前にローカル/内部 `INTERNAL_API_SECRET` 入力のみでブロックするようになった。
- ECC-Tools PR #91 が両方の billing gate スクリプトに `--env-file` サポートを追加。無視されるローカルオペレータ認証情報ファイルがシークレット内容を出力せずに `INTERNAL_API_SECRET`、Cloudflare 認証、Wrangler 認証モード、ターゲットフォールバックを供給できる。Verify、Security Audit、Workers Builds が `72119a1` としてマージ前にパスし、main CI run `26137280847` がマージ後に成功完了した。
- ECC-Tools PR #92 が、既存の `INTERNAL_API_SECRET` をローテートせずに特権内部 API ルートが受理する非破壊的な `INTERNAL_OPERATOR_API_SECRET` ベアラを追加。Verify、Security Audit、Workers Builds が `18d80197be779619283e0b37e2952bac53819a07` としてマージ前にパスし、マージされた Worker は `api.ecc.tools` にデプロイされた。
- 5 月 20 日のライブネイティブ支払いゲートが通過するようになった: vault バック Wrangler 読み戻しが指紋 `e953a74209fe` でレディな Marketplace Pro ターゲットを選択、両キーファミリ存在、Webhook エビデンスレディ、KV ブロッカー 0、official `npm run billing:announcement-gate -- --select-ready-target` が新オペレータベアラパス経由で `announcementGateReady: true`、必須アクション 0、ブロッカー 0、監査サマリ 6 pass / 1 warn / 0 fail を返した。
- ECC-Tools PR #93 がそのライブ billing エビデンスをアプリローンチチェックリストと配布ロードマップに `d3d62df83fa075660fa4530c3e0edc311a4355fe` として記録。公開ネイティブ支払いコピーは billing エビデンスでブロックされなくなったが、公開タイミングは依然として最終リリース、プラグイン、ライブ URL、オーナー承認ゲートの背後にある。
- Linear ITO-54 と ECC Platform Roadmap には現在、5 月 20 日 ECC-Tools ホスト可観測性更新コメント `74dcc101-3be5-4173-be13-62b80d54f569` と `348ea8f5-2a2d-46d9-a0fe-ed99653e7fe5` がある(以前の PR #84/#85 コメントが remediation sync とホスト可観測性イベントを記録した)。PR #88 は Linear コメント `291e2a4b-06e3-4672-a057-cdb141478161` と `b2d35de0-ca49-44cb-982a-ddec229e7691` に記録、AgentShield #94 は ITO-49 コメント `faed69dd-35f5-469d-acb5-ddde6a70d6a1` とプロジェクトコメント `70187c1e-d481-4181-b418-09bd65d54b5e` に記録、AgentShield #95 は ITO-49 コメント `371fc3e4-611f-4d20-a23f-67db1260b418`、ITO-57 コメント `bd06e252-15c1-4256-b667-caa3f64f5968`、プロジェクトコメント `22c2c388-2fd1-4dea-a939-6141f40c9a21` に記録。
- Linear ITO-61 と ECC Platform Roadmap には現在、5 月 20 日 Marketplace Pro release-gate コメント `467d148a-712a-4777-aad9-95593e9f1739` と `7642ee9c-3107-400c-a229-53e2895a8914` があり、ECC-Tools #89、ECC #2019、green な post-merge CI 実行、残りの内部ベアラトークンゲートを記録している。リポジトリミラーには ECC-Tools #90 と #91 も selected-target announcement gate と billing gate env-file オペレータパスフォローアップとして記録されている。

## 2026-05-19 デルタ

- 公開リポジトリアイデンティティは現在 `affaan-m/ECC`。リリース、パッケージ、プラグイン、ワークフロー、ローンチコピーサーフェスは現在の公開リンクにその URL を使うべき。
- 5 月 19 日の後半キュードレインが ECC `main` 上に決定論的 `release:approval-gate` を追加、ECC-Tools billing-announcement redaction hardening をマージ、JARVIS Dependabot/deploy 修復テールをクリアした。追跡対象プラットフォーム監査は 5 つの追跡リポジトリ全体でオープン PR 0、オープン Issue 0、ディスカッションギャップ 0 で現在 green だが、リリース/公開アクションは依然オーナーおよびライブ URL ゲートを必要とする。
- ECC 2.0 リリースストーリーはプロダクト形状を直接リードすべき: ハーネスネイティブオペレータシステム、再利用可能スキル/ルール/フック/MCP 規約、`ecc2/` アルファコントロールプレーン、オプショナルオペレータシェルとしての Hermes、ビジネスサーフェスとしての ECC Tools Pro/Sponsors/コンサルティング。
- コピーはこれをリポジトリ改名や config-pack マイグレーションとして提示すべきでない。リリースプルーフはインストールフロー、クロスハーネスデモ、セキュリティエビデンス、ホストプロダクトエビデンス、ビデオスイートを通じてシステムを見せるべき。

## 現状エビデンス

2026-05-20 時点:

- GitHub キューは `affaan-m/ECC`、`affaan-m/agentshield`、`affaan-m/JARVIS`、`ECC-Tools/ECC-Tools`、`ECC-Tools/ECC-website` 全体でクリーン: 最新の `platform-audit` スウィープがオープン PR 0、オープン Issue 0、ディスカッションメンテナタッチギャップ 0、受理済み回答が欠けている回答可能 Q&A 0、ブロッキング dirty ファイル 0 を見出した。現在の `scripts/work-items.js list --json` 出力も `totalCount: 0` を報告するため、SQLite ブリッジにオープンまたはブロックされたローカルワークアイテムは無い。
- オーナー全域のキュークリーンアップも要求された予算内である: `docs/releases/2.0.0-rc.1/owner-queue-cleanup-2026-05-18.md` がライブ `gh search` スウィープを記録し、陳腐な dependency-bot PR 24 件と陳腐なレガシー payments/0EM ロードマップ Issue 72 件をクローズし、その後、残る陳腐・生成・コンフリクト・テスト/ノイズ PR 9 件と残るレガシー・アウトリーチ・プレースホルダ Issue 5 件をクローズした。より広範な `affaan-m` オーナー名前空間は現在、ライブ `gh search` でオープン PR 0 とオープン Issue 0。クローズ中に触れたアーカイブ済みリポジトリはアーカイブ状態に戻された。
- GitHub ディスカッションは追跡対象リポジトリで最新: `affaan-m/ECC` は 5 月 19 日に #2003 AURA インテグレーション提案が外部アダプタ提案としてルーティングされ(コアウォレット/エスクロー結合ではなく)、5 月 20 日に #2015 setup-location Q&A が回答され受理された後、メンテナタッチ無しが 0 で総ディスカッション 60 件。AgentShield、JARVIS、ECC Tools、ECC Tools ウェブサイトはディスカッションが無効か総ディスカッション 0 件。`docs/architecture/discussion-response-playbook.md` が ITO-59 レスポンスカテゴリ、公開テンプレート、セキュリティエスカレーションパス、将来のディスカッションバッチ用 readback ルールを提供する。
- 現在の Linear ロードマップは 16 の issue レーン (`ITO-44` から `ITO-59`) と 5 つのマイルストーン (Security and Access Baseline、ECC 2.0 Preview and Publication、AgentShield Enterprise Iteration、ECC Tools Next-Level Platform、Legacy Audit and Salvage) を含む。
- Linear ライブ同期は 5 月 19 日 PR #2002 マージとディスカッションバッチで最新: ECC platform プロジェクトは post-PR #2002 同期ドキュメント `ecc-may-19-post-pr-2002-sync-64cef8f668e0`、プロジェクトコメント `a6411e3a-8c8e-4a58-adba-687e77d4c543`、ITO-44、ITO-47、ITO-48、ITO-49、ITO-51、ITO-54、ITO-56 上の issue コメントを持つ。ITO-47、ITO-48、ITO-49、ITO-51、ITO-54、ITO-56 は実装/エビデンスが現在のためと残る gate/readback 作業のため In Progress に移動された。ITO-57 は 5 月 18 日緊急サプライチェーンリフレッシュコメント (`3fe5b2b7-c4fe-401c-a317-b40d72119cb3`) を保持する。Linear プロジェクトステータス更新は本ワークスペースで無効になっているため、プロジェクトドキュメントとコメントがサポート対象の外部ステータスサーフェスである。

(以下、長大なエビデンスログが続く。原文の内容は技術的なリリース履歴の詳細であるため、章立てと主要なポリシー記述を中心に和訳し、PR/コミット詳細は元文を保持する方針とする。)

> 注: 本ドキュメントの "Current Evidence" 以降の項目は、Pull Request 番号、SHA、CI 実行 ID、タイムスタンプを多数含むリリース履歴ログである。技術用語と固有値を変更しないため、各エントリは原文の構造を維持しつつ概要文のみ和訳する。詳細な PR 番号と SHA は元のままである。

## 運用ルール

- 公開 PR と Issue を 20 件未満に保つ。リリースレーンの推奨ターゲットはゼロ。
- すべての GA レディネスバッチ後にハーネス監査 80/80 と可観測性レディネス 21/21 を維持する。
- GitHub release、npm/パッケージ状態、billing 状態、プラグイン提出サーフェスが新鮮なエビデンスで検証されるまで、リリースまたはソーシャル告知を公開しない。
- クローズした陳腐 PR を破棄したものとして扱わない。各クリーンアップバッチとサルベージパスをペアにする: クローズした diff を検査し、メンテナ所有ブランチで有用な互換作業を port し、ソース PR をクレジットする。
- プロジェクトレベル更新には Linear プロジェクトドキュメント/コメントを使う(本ワークスペースでプロジェクトステータス更新は無効化されている)。レーンが永続的実行オーナーを必要とするときは Issue を作成または更新する。

## プロンプト → アーティファクト実行チェックリスト

このテーブルは長いオペレータプロンプトを具体的なアーティファクトに結びつけ続ける。エビデンス列が存在し新鮮に検証されない限り、ステータスは完了とみなさない。

| プロンプト要件 | 必要なアーティファクトまたはゲート | 現在のエビデンス | ステータス |
| --- | --- | --- | --- |
| 公開 PR を 20 件未満に保つ | リポジトリファミリー PR 再チェック | 後半 2026-05-19 プラットフォーム監査で `ECC`、AgentShield、JARVIS、`ECC-Tools/ECC-Tools`、`ECC-Tools/ECC-website` 全体でオープン PR 0 件 (ECC PR #2013、ECC-Tools PR #79、JARVIS PR #15、JARVIS PR #16 をマージ後) | 完了 |
| 公開 Issue を 20 件未満に保つ | リポジトリファミリー Issue 再チェック | ライブプラットフォーム監査リフレッシュ後の 2026-05-19 に `ECC`、AgentShield、JARVIS、`ECC-Tools/ECC-Tools`、`ECC-Tools/ECC-website` 全体でオープン Issue 0 件 | 完了 |
| リポジトリディスカッション管理 | リポジトリファミリーディスカッション再チェック + レスポンスプレイブック | プラットフォーム監査がディスカッションメンテナタッチギャップ 0 と受理済み回答が欠けている回答可能 Q&A 0 を報告。trunk は #2003 がメンテナレスポンスでルーティングされた後 59 件の総ディスカッション。`docs/architecture/discussion-response-playbook.md` がサポート、メンテナ協調、陳腐/結了、リリース、情報、セキュリティ機微レスポンスパスを区別 | 完了 |
| PR ディスカッション管理 | PR レビュー/コメントクロージャ + マージ/クローズ状態 | ECC #1990-#2013 がハーネス監査、canonical アイデンティティ、リリースビデオスイート、成長アウトリーチ、エビデンスリフレッシュ、ビジュアル QA、suite-count、オーナー承認パケット、オーナー承認ダッシュボードゲート、Linear レディネスエビデンス、サプライチェーンエビデンスゲート、per-project Claude Code アダプタ、継続学習プロジェクトレジストリハイジーン、GateGuard quoted git introspection、決定論的リリース承認ゲートバッチを通じてマージ。ECC-Tools #79 と JARVIS #15/#16 もマージ。追跡対象オープン PR は無い | 完了 |
| 有用な陳腐作業のサルベージ | `docs/stale-pr-salvage-ledger.md` + `docs/legacy-artifact-inventory.md` | 台帳がサルベージ済み、superseded、スキップ、手動レビューテールを記録。#1815-#1818 がコスト追跡、skill scout、フロントエンドデザインガイダンス、code-reviewer false-positive ガードレール、5 月 12 日ギャップパスを追加。#1687、#1609、#1563、#1564、#1565 ローカライズテールは Linear ITO-55 に添付(言語オーナーレビュー用)であり自動インポートはリリースブロッキングではない | 完了。リリース前にレガシースキャンを繰り返す |
| ECC 2.0 プレビューパックレディ | リリースドキュメント、クイックスタート、公開レディネス、リリースノート | `docs/releases/2.0.0-rc.1/` とレディネスドキュメントがツリー内。5 月 19/20 日エビデンスがキューゼロ状態、canonical ECC アイデンティティ、リリースビデオスイート、成長アウトリーチパック、オーナー承認パケット、ローカル 2568 テストスイート、PR #2001 マージと GitHub Actions 実行 `26102500291`、PR #2002 オーナー承認ダッシュボードゲートリフレッシュと GitHub Actions 実行 `26103853507`、PR #2004 Linear レディネスエビデンス同期と GitHub Actions 実行 `26105012698`、PR #2008 サプライチェーンエビデンスゲート CI 実行 `26108473648`、post-PR #2006 main CI 実行 `26109953093`、PR #2009 プロジェクトレジストリハイジーン GitHub Actions 実行 `26111313938`、post-PR #2009 main CI 実行 `26111946778`、post-PR #2011 GateGuard main CI 実行 `26113695068`、post-PR #2013 リリース承認 main CI 実行 `26128749863`、post-PR #2019 main CI 実行 `26135974576`、post-PR #2020 main CI 実行 `26136949698`、ECC-Tools #91 main CI 実行 `26137280847`、5 月 20 日オペレータダッシュボード、`owner-approval-packet-2026-05-19.md`、`release-approval-gate.js`、プレビューパックスモークダイジェスト `eebb8a66c33e` を記録 | 最終リリース承認待ち |
| Hermes 専門スキル安全包含 | Hermes セットアップ/インポートドキュメントとサニタイズスキルサーフェス | Hermes セットアップとインポートプレイブックが公開。シークレットはローカルに留まる | 最終リリースレビュー待ち |
| 命名と改名レディネス | package/plugin/docs/social サーフェスにわたる命名マトリクス | `docs/releases/2.0.0-rc.1/naming-and-publication-matrix.md` が現在のパッケージ、リポジトリ、Claude プラグイン、Codex プラグイン、OpenCode、npm 可用性エビデンスを記録 | rc.1 で完了。rc 後の改名は将来の作業として残る |
| Claude と Codex プラグイン公開 | 必要なアーティファクトとステータスを伴う連絡/提出パス | 公開レディネス、命名マトリクス、5 月 12 日ドライランエビデンスがプラグイン検証、クリーンチェックアウト Claude タグ/インストールスモーク、Codex マーケットプレース CLI 形状をドキュメント化 | リアルタグ/プッシュとマーケットプレース提出には明示的承認が必要 |
| 記事、ツイート、告知 | X スレッド、LinkedIn コピー、GitHub release コピー、push チェックリスト、パートナー/スポンサー/トークパック | ドラフトローンチコラテラルと承認ゲート付きアウトリーチコピーが rc.1 リリースドキュメント配下にある | 投稿または送信前に URL バックリフレッシュと人間承認が必要 |
| AgentShield エンタープライズ反復 | ポリシーゲート、SARIF、パック、provenance、コーパス、HTML レポート、例外ライフサイクル監査、ベースラインドリフト Action/CLI サーフェス、evidence-pack redaction、ハーネスアダプタレジストリ、エディタネイティブ Zed/VS Code アダプタカバレッジ、Dependabot アラートクロージャ、エンタープライズ研究ロードマップ、サプライチェーン強化リリースパス、CI セーフベースライン指紋、コーパス精度推奨、remediation ワークフローフェーズ、env プロキシハイジャックコーパスカバレッジ、Mini Shai-Hulud full-campaign パッケージ IOC、CI-provenance evidence pack、plugin-cache ランタイム信頼度トリアージ、evidence-pack consumer readback、fleet レベル evidence-pack ルーティング、fleet review item、fleet review チケットペイロード、checksum バック policy export、checksum 検証 policy promotion、policy promotion review item、パッケージマネージャ強化ドリフト検出、npm 経過日数ガイダンス修正、ワークフロー action ランタイム pin リフレッシュ、パッケージマネージャ強化 Action 出力、policy-promotion Action 出力、ECC-Tools ホスト消費 promotion Action 出力、ECC-Tools オペレータ可視 promotion 出力値、ECC-Tools ホスト promotion judge 監査トレース | PR #53、#55-#64、#67-#69、#78-#92、#94、#95 がテストエビデンスとともに着地。ECC-Tools #76 がホストセキュリティレビューで fleet-summary 出力を消費、#77 がホスト finding 出力でソースエビデンスパスを表面化、#78 が fleet ルートをハーネスオーナーレビューにリンク。AgentShield #91 がブランチ保護レビューとダウンストリーム promotion 用 `agentshield policy export` バンドルを追加。AgentShield #92 が `agentshield policy promote` でダイジェスト検証、改ざん拒否、明示的パック選択、アクティブポリシー書き込み前のドライラン JSON レビューを追加。AgentShield #94 が Zed/VS Code アダプタ検出、`.zed/settings.json` と `.zed/tasks.json` スキャン発見、`.zed/setup.mjs` AI-tool persistence IOC カバレッジを追加。AgentShield #95 が `brace-expansion` Dependabot アラートをパッチ済みロックファイルでクリアし、マージ後 Dependabot オープンアラート 0。AgentShield commit `87aec47` がダイジェストエビデンス、オーナーレビュー、保護ロールアウト PR 引き継ぎ、ランタイムスモークテストの `reviewItems` を追加(ローカルとリモート CI green)。AgentShield commit `28d08c7` がプレーンテキストレジストリ認証情報、ライフサイクルスクリプト有効化、弱い pnpm/Yarn release-age cooldown 用のパッケージマネージャ強化ドリフト検出を追加(ローカルとリモート CI green)。AgentShield commit `659f569` がすべてのワークフロー action ランタイム pin を SHA-pin された checkout v6.0.2 と setup-node v6.4.0 にリフレッシュ(リモート CI green、action ランタイム deprecation アノテーション残無し)。AgentShield commit `ee585cd` がサポート外 npm 経過日数キーをフラグし pnpm/Yarn に強制可能 cooldown findings を保持することで npm release-age ガイダンスを修正(ローカルとリモート CI green)。AgentShield commit `1124535` がパッケージマネージャ強化ステータス/カウント出力とレジストリ認証情報、ライフサイクルスクリプト、release-age ゲート用 redacted job-summary セクションを公開(ローカルとリモート CI green)。AgentShield commit `1593925` がオーナー承認、保護ロールアウト、ランタイムスモーク用 policy-promotion ステータス/カウント/ダイジェスト出力と job-summary review items を公開し、同 Action ジョブが promoted ポリシーでスキャンするときランタイムスモーク verified とマーク。AgentShield commit `840952a` が Linear/オペレータ対応 fleet review チケットペイロードを追加し現在の Mini Shai-Hulud IOC ブレッドクラムを拡張(ローカルとリモート CI green)。ECC-Tools commit `8658951` がそれらの policy-promotion Action 出力をホストセキュリティレビュー findings と Hosted Promotion Readiness スコアリングにルーティング。ECC-Tools commit `16c537f` がホストセキュリティジョブコメント/check-run で policy-promotion ステータス、パック、review item カウント、action-required カウント、ダイジェストをレンダー。ECC-Tools commit `05d4e82` が生プロバイダ出力なしで hosted promotion judge リクエスト指紋と allowed-citation カウントをレンダー。明示的エンタープライズ需要が現れるまでネイティブ PDF エクスポートは自己完結 HTML + print-to-PDF を優先して延期。`docs/architecture/agentshield-enterprise-research-roadmap.md` が現在、ベースラインドリフト、evidence-pack バンドル、redaction、adapter-registry、サプライチェーン強化、hashed ベースライン指紋、コーパス精度推奨、remediation ワークフロー、env プロキシハイジャックコーパス、Mini Shai-Hulud full-campaign パッケージテーブル、`ci-context.json` provenance、`plugin-cache` 信頼度、`evidence-pack inspect` readback、`evidence-pack fleet` ルーティング、fleet `reviewItems`、fleet review チケットペイロード、policy export、policy promotion、policy promotion `reviewItems`、パッケージマネージャ強化 Action 出力、policy-promotion Action 出力、promotion Action 出力のホスト消費、オペレータ可視 promotion 出力値、hosted promotion judge 監査トレース、エディタネイティブアダプタカバレッジ、Dependabot クロージャを着地済み | 次のワークフロー自動化は Marketplace/支払いゲート後にライブオペレータ承認/readback を深化させるべき |
| ECC Tools 次世代アプリ | Billing 監査、PR チェック、deep analyzer、sync バックログ、evaluator/RAG コーパス、hosted promotion judge 監査トレース、ネイティブ支払い readback、ready Marketplace Pro ターゲット選択、selected-target announcement gate、billing gate env-file オペレータパス、hosted observability、AgentShield fleet-summary hosted ルーティング、ホスト finding エビデンスパス、ハーネスルートポリシーリンク、policy-promotion Action 出力 hosted テレメトリ、オペレータ可視 promotion 出力値 | PR #26-#43 と #53-#93 がテストエビデンスとともに着地。ECC-Tools #89 が `512bca6` としてマージ(Verify、Security Audit、Workers Builds パス後)。2026-05-20 production Wrangler OAuth readback が ready-like Marketplace Pro レコードを発見、両キーファミリでターゲット選択、ログイン非出力で 0 ブロッカー報告。ECC-Tools #90 が `16a5bb3` としてマージし、本番 preflight が生ログイン無しで `/api/billing/readiness?selectReadyTarget=1` を要求するように。ECC-Tools #91 が `72119a1` としてマージし無視されるローカル billing 認証情報の `--env-file` サポートと sentinel no-secret/no-login 出力テスト。ECC-Tools #92 が `18d8019` としてマージし非破壊 `INTERNAL_OPERATOR_API_SECRET` パスを `api.ecc.tools` にデプロイ、2026-05-20 ライブ selected-target ゲートは必須アクション 0、ブロッカー 0 で `announcementGateReady: true` を返した。ECC-Tools #93 が `d3d62df` としてマージしアプリローンチチェックリストとロードマップにライブ billing エビデンスを記録 | ローンチ直前に KV readback と selected-target announcement gate を繰り返す。ネイティブ支払いコピーは最終リリース、プラグイン、ライブ URL、オーナー承認ゲートの背後に保つ |
| GitGuardian/Dependabot/CodeRabbit 様チェック | 非ブロッキング分類体系、決定論的フォローアップチェック、ローカルサプライチェーンゲート | ECC-Tools リスク分類体系チェックとフォローアップシグナル着地(Skill Quality、Deep Analyzer Evidence、Analyzer Corpus Evidence、RAG/Evaluator Evidence、PR Review/Salvage Evidence、AgentShield evidence-pack エビデンスを含む)。#1846 が npm レジストリ署名ゲート追加。#1848 がサプライチェーンインシデントレスポンスプレイブックと `pull_request_target` キャッシュ汚染バリデータガード追加。#1851 が特権 checkout 認証情報永続化ガード追加。AgentShield #78、JARVIS #13、ECC-Tools #53 が trunk 外で同じ強化適用 | 現在のサプライチェーンゲート完了。より深いホストレビュー機能は将来の作業 |
| ハーネス非依存学習システム | 監査、アダプタマトリクス、可観測性、トレース、promotion ループ | 監査/アダプタ/可観測性ゲートと `docs/architecture/evaluator-rag-prototype.md`、`examples/evaluator-rag-prototype/`、ECC-Tools PR #40 が read-only stale-salvage、billing-readiness、CI-failure-diagnosis、harness-config-quality、AgentShield policy-exception、skill-quality エビデンス、deep-analyzer エビデンス、RAG/evaluator 比較シナリオをトレース、レポート、プレイブック、検証者、予測チェックアーティファクトで定義。ECC-Tools PR #68-#72 がそのコーパスを決定論的 PR check-run ゲートに変換(キャッシュ済みホスト出力スコアリング、ランク付き検索候補、モデルプロンプトシード、fail-closed ホストモデル judge リクエストコントラクト、厳格なホストエビデンスゲート背後のオプトインライブモデル実行付き) | 決定論的ホスト PR チェック、キャッシュ出力スコアリング、検索計画、judge コントラクト、ゲート付きモデル実行統合済み |
| Linear ロードマップ詳細化 | Linear プロジェクトドキュメント/コメント + リポジトリミラー | リポジトリミラーが存在し issue 作成が再び動作。5 月 19 日同期が post-PR #2002 ドキュメント `ecc-may-19-post-pr-2002-sync-64cef8f668e0`、プロジェクトコメント `a6411e3a-8c8e-4a58-adba-687e77d4c543`、ITO-44/47/48/49/51/54/56 issue コメント、ITO-47、ITO-48、ITO-49、ITO-51、ITO-54、ITO-56 の In Progress 状態を追加。後半パスバッチが PR #2013、ECC-Tools #79、JARVIS #15/#16 用ドキュメント `ecc-may-19-late-queue-zero-and-release-gate-sync-1c26f65e6b3f`、プロジェクトコメント `d42bf0e2-7a8e-4934-9f3f-e281498ee805`、ITO-44/50/54/56/61 コメントを追加(ワークスペースでプロジェクトステータス更新が無効化されているため) | 各重要マージバッチ後に繰り返しドキュメント/コメント更新が必要 |
| フロー分離と進捗追跡 | オーナーアーティファクトと更新ケイデンスを持つフローレーン | 本ロードマップが以下にレーンを定義し、`docs/architecture/progress-sync-contract.md` が GitHub/Linear/handoff/roadmap 同期をレディネスゲートの一部に | アクティブ |
| リアルタイム Linear 同期 | レーン更新用プロジェクトドキュメント/コメント + issue コメント | ECC-Tools #39 が deferred follow-up バックログアイテム用オプトイン Linear API 同期実装、ECC-Tools #54 が draft PR シェルがオープンされないときコピーレディ PR ドラフトをそのバックログに追加。`docs/architecture/progress-sync-contract.md` がローカルファイルバックリアルタイム境界を定義。5 月 18 日と 5 月 19 日のライブコネクタコメントが、プロジェクトステータス更新が無効化されて戻った後の ECC platform プロジェクトとレーン issue に投稿された | ホスト issue 同期にはワークスペース config/プロダクトロールアウトが必要 |
| 自己利用のための可観測性 | ローカルレディネスゲート、トレース、ステータススナップショット、HUD/ステータスコントラクト、リスク台帳、進捗同期コントラクト | `npm run observability:ready` が 21/21 を報告 | ローカルゲートで完了 |
| 適切なリリースと通知 | リリースタグ、npm 公開状態、プラグイン状態、ソーシャル投稿 | 5 月 12 日ドライランと 5 月 13 日レディネスエビデンスとともに公開レディネスゲート存在 | 未完了。承認/ライブ URL が必要 |

## 実行レーンと追跡コントラクト

Linear issue 容量がクリアされるまで、本ドキュメントが永続的実行台帳であり、Linear はプロジェクトステータス更新のみを受領する。同期コントラクトは `docs/architecture/progress-sync-contract.md` にある。容量が利用可能になったとき、以下の各レーンはリポジトリエビデンスとマージコミットにリンクバックされた小さな Linear issue のセットになるべきである。

| レーン | 信頼の源 | 次の追跡アーティファクト | 更新ケイデンス |
| --- | --- | --- | --- |
| キューハイジーンとサルベージ | GitHub PR/issue 状態、サルベージ台帳 | 将来の陳腐クロージャに台帳エントリを追加 | 各クリーンアップバッチ毎 |
| リリースと公開 | rc.1 リリースドキュメント、公開レディネスドキュメント | 命名マトリクスとプラグイン提出/連絡チェックリスト | 任意のタグ前 |
| ハーネス OS コア | 監査、アダプタマトリクス、可観測性ドキュメント、`ecc2/` | HUD/セッションコントロール受入仕様 | GA まで毎週 |
| 評価と RAG | リファレンスセット検証、ハーネス監査、トレース、ECC-Tools コーパス | Read-only evaluator/RAG プロトタイプと stale-salvage、billing-readiness、CI-failure-diagnosis、harness-config-quality、AgentShield policy-exception、skill-quality エビデンス、deep-analyzer エビデンス、RAG/evaluator 比較フィクスチャ。ECC-Tools #68 がコーパスをホスト promotion レディネス check-run として公開、#69 がキャッシュホストジョブ出力を同コーパスに対してスコアリング、#70 がランク付き検索候補とモデルプロンプトシードを発出、#71 が fail-closed ホストモデル judge リクエストコントラクトを追加、#72 が明示的に有効化されホスト検索引用にバックされたときのみその judge を実行。ECC-Tools `16c537f` がホストセキュリティコメント/チェックで policy-promotion Action 出力値を表面化。ECC-Tools `05d4e82` がリクエスト指紋と allowed-citation カウントを持つホストモデル judge 監査トレースを追加 | Webhook provenance を伴う Marketplace Pro billing-state 検証 |
| AgentShield エンタープライズ | AgentShield PR エビデンスとロードマップノート | #88 で evidence-pack inspect/readback 出荷後 #89 で Fleet ルーティング着地。#90 が fleet `reviewItems` 発出。#91 が checksum バックポリシーバンドルエクスポート。#92 がそれらバンドルから checksum 検証済みポリシーをアクティブポリシーファイルに promote。#94 が Zed と VS Code アダプタ検出、Zed プロジェクトスキャン発見、`.zed/setup.mjs` persistence IOC カバレッジを追加。#95 が `brace-expansion` Dependabot アラートを 0 オープンアラートでクローズ。AgentShield `87aec47` がポリシー promotion `reviewItems` 追加。`28d08c7` がパッケージマネージャ強化ドリフト検出追加。`659f569` がワークフロー action ランタイム pin リフレッシュ。`ee585cd` がサポート外 npm release-age ガイダンスを修正し pnpm/Yarn に強制可能 cooldown findings を保持。`1124535` が CI/ホストルーティング用パッケージマネージャ強化 Action 出力を公開。`1593925` が policy-promotion Action 出力とランタイムスモーク job-summary エビデンスを公開。`840952a` が fleet review チケットペイロードと現在の Mini Shai-Hulud IOC ブレッドクラムを追加。ECC-Tools #76 が fleet サマリ消費、#77 がホスト findings でソースエビデンスパスを表面化、#78 が fleet ルートをハーネスオーナーにリンク、ECC-Tools `8658951` が policy-promotion Action 出力を消費、ECC-Tools `16c537f` がオペレータ可視出力値をレンダー | Marketplace/支払いゲート後にライブオペレータ承認/readback を深化 |
| ECC Tools アプリ | ECC-Tools PR エビデンス、billing 監査、リスク分類体系、evaluator/RAG コーパス | ECC-Tools #53 がサプライチェーンワークフロー強化ブランチ公開、#54 が Linear/プロジェクトバックログでコピーレディ PR ドラフトを追跡、#55 が分析深度レディネス分類、#56 がホスト実行計画公開、#57 が初の CI 診断ジョブ実行、#58 がホストセキュリティエビデンスレビュー実行、#59 がホストハーネス互換性監査実行、#60 がホストリファレンスセット評価実行、#61 がホスト AI ルーティング/コストレビュー実行、#62 がホストチームバックログルーティング実行、#63 がホスト depth-plan check-run 公開、#64 が PR コメントからホストジョブディスパッチ、#65 がホスト結果履歴/check-run 永続化、#66 が PR コメントからホストジョブステータス公開、#67 が depth-plan 推奨をキャッシュ認識に、#68 が evaluator/RAG コーパスからホスト promotion レディネス公開、#69 がキャッシュホストジョブ出力を同コーパスに対してスコアリング、#70 がランク付き検索候補とモデルプロンプトシード発出、#71 がライブモデル呼び出し無しでゲート付き `hosted-promotion-judge.v1` コントラクト発出、#72 がホストエビデンスと厳格 JSON/引用ゲート背後にオプトインライブモデル judge 実行追加、#73 が billing readiness に fail-closed ネイティブ支払い `announcementGate` 追加、#74 がオペレータ検証用 `npm run billing:announcement-gate` 追加、#75 がライブ Marketplace readback 用に billing announcement gate を強化、#76 が AgentShield fleet サマリエビデンスをホストセキュリティ findings にルーティング、#77 がホスト finding 出力にソースエビデンスパス追加、#78 が AgentShield fleet ターゲットパスをホストハーネスオーナー findings にリンク、`8658951` が AgentShield policy-promotion Action 出力をホストセキュリティレビューと promotion レディネスにルーティング、`16c537f` がホストセキュリティコメント/チェックで policy-promotion ステータス/パック/カウント/ダイジェスト値をレンダー、`05d4e82` が allowed-citation 監査トレースとともにホスト promotion judge リクエスト指紋をレンダー、`91a441b` が必須 readback 入力用 billing announcement preflight 出力追加、`eb69412` が初期本番 readback 状態記録、`95d0bec` が集計 `billing:kv-readback` エビデンス追加、`2859678` が billing readiness で Marketplace webhook provenance 要求、`42653f9` がライブ集計本番カウントとともに Wrangler OAuth readback 追加、`632e059` が正確な Marketplace テストアカウント用サニタイズターゲットアカウント billing readback 追加、ECC-Tools #89 が selected-ready-target KV readback 追加、ECC-Tools #90 が生ログイン入力なしで selected-target 公式 announcement ゲート追加、ECC-Tools #91 がシークレットやログインを出力せずに無視されるローカル billing 認証情報用 `--env-file` サポート追加 | ローカル/内部 `INTERNAL_API_SECRET` ベアラトークンパス (エクスポート env または無視 `--env-file` 経由) を取得またはローテートし、ライブ selected-target billing announcement ゲートを実行する |
| Linear 進捗 | Linear プロジェクトステータス更新、`docs/architecture/progress-sync-contract.md`、生成された `operator:dashboard` 出力、本ミラー | キュー/エビデンス/欠落ゲート付きステータス更新 | 各重要マージバッチ毎 |

プロジェクトステータス更新は常に以下を含むべき:

1. 現在の公開 PR と Issue カウント。
2. 前回更新以降のマージ済みエビデンス。
3. 理由付きの延期またはブロックされたアイテム。
4. 次の 1 つまたは 2 つの実装スライス。
5. エビデンスバックされていない任意のリリースまたは公開ゲート。

## リファレンスプレッシャー

GA ロードマップは以下のリファレンスサーフェスから情報を得ている:

- `stablyai/orca` と `superset-sh/superset` (worktree ネイティブ並列エージェント UX、レビューループ、ワークスペースプリセット用)
- `standardagents/dmux` と `aidenybai/ghast` (ターミナル/worktree マルチプレキシング、セッショングルーピング、ライフサイクルフック用)
- `jarrodwatts/claude-hud` (常時可視ステータス、ツール、エージェント、todo、コンテキストテレメトリ用)
- `stanford-iris-lab/meta-harness` と `greyhaven-ai/autocontext` (評価駆動ハーネス改善、トレース、プレイブック、promotion ループ用)
- `NousResearch/hermes-agent` (オペレータシェル、ゲートウェイ、メモリ、スキル、マルチプラットフォームコマンドパターン用)
- `anthropics/claude-code`、アクティブな `sst/opencode`/`anomalyco/opencode`、Zed、Codex、Cursor、Gemini、ターミナル専用ワークフロー (アダプタ期待用)

本リファレンス作業の出力は具体的な ECC デルタであるべきで、2 つ目のストラテジメモではない。

## マイルストーン

### 1. GA リリース、命名、プラグイン公開レディネス

ターゲット: 2026-05-24

受入条件:

- 命名マトリクスがプロダクト名、npm パッケージ、Claude プラグイン、Codex プラグイン、OpenCode パッケージ、マーケットプレースメタデータ、ドキュメント、マイグレーションコピーをカバー。
- GitHub release、npm dist-tag、プラグイン公開、announcement ゲートが新鮮なコマンドエビデンスにマップされる。
- リリースノート、マイグレーションガイド、既知の問題、クイックスタート、X スレッド、LinkedIn 投稿、GitHub release コピーが用意済みだが、リリース URL が存在する前にはポストされない。
- Claude と Codex のプラグイン公開/連絡パスがオーナー、必要なアーティファクト、提出ステータス付きで文書化される。

### 2. ハーネスアダプタコンプライアンスマトリクスとスコアカードオンランプ

ターゲット: 2026-05-31

受入条件:

- アダプタマトリクスが Claude Code、Codex、OpenCode、Cursor、Gemini、Zed 近接サーフェス、dmux、Orca、Superset、Ghast、ターミナル専用利用をカバー。
- 各アダプタはサポート対象アセット、非サポートサーフェス、インストールパス、検証コマンド、リスクノートを持つ。
- ハーネス監査が 80/80 を維持し、チームがスコアカードを使う方法を説明する公開オンランプを得る。
- リファレンス所見が具体的なアダプタ、可観測性、またはオペレータサーフェスデルタに変換される。

### 3. ローカル可観測性、HUD/ステータス、セッションコントロールプレーン

ターゲット: 2026-06-07

受入条件:

- 可観測性レディネスが 21/21 を維持し、JSONL トレース、ステータススナップショット、リスク台帳、エクスポート可能な引き継ぎコントラクトでバックされる。
- HUD/ステータスモデルがコンテキスト、ツール呼び出し、アクティブエージェント、todo、チェック、コスト、リスク、キュー状態をカバー。
- worktree/セッションコントロールが create、resume、status、stop、diff、PR、マージキュー、コンフリクトキューをカバー。
- Linear/GitHub/handoff 同期モデルがリアルタイム進捗追跡のために十分に明示的である。

### 4. 自己改善ハーネス評価ループ

ターゲット: 2026-06-10

受入条件:

- シナリオ仕様、検証者コントラクト、トレース、プレイブック、回帰ゲートが文書化され、少なくとも 1 つの read-only プロトタイプが存在する。
- ループが観測、提案、検証、promotion を分離する。
- チームおよび個人セットアップが設定を盲目的に変更せずにスコアリング・改善できる。
- RAG/リファレンスセット設計が検証済み ECC パターン、チーム履歴、CI 失敗、diff、レビュー結果、ハーネス設定品質をカバー。

### 5. AgentShield エンタープライズセキュリティプラットフォーム

ターゲット: 2026-06-14

受入条件:

- 組織ベースライン、例外、オーナー、有効期限、重大度、監査トレイル、近日期限可視性、期限切れ例外強制のための形式的なポリシースキーマと評価出力が存在。
- SARIF/code-scanning 出力が実装・テスト済み。
- GitHub Action ポリシーゲートがブランチ保護と CI エビデンスのために組織ポリシーステータスと違反カウントを公開。
- ポリシーパックが OSS、チーム、エンタープライズ、規制、高リスクフック/MCP、CI 強制用に定義される。
- サプライチェーンインテリジェンスが MCP パッケージ provenance をカバーし、npm/pip 評判、CVE、typosquat、依存リスクのための拡張パスを持つ。
- プロンプトインジェクションコーパスと回帰ベンチマークがカテゴリレベルカバレッジと回帰ゲート出力を持つ継続的ルール強化に対してレディ。
- エンタープライズレポートに JSON とリスクポスチャ、優先所見、カテゴリ露出、ターミナル/CI サマリでのポリシー例外ライフサイクルエビデンスを持つ自己完結 HTML エグゼクティブ出力が含まれる。
- 自己完結 HTML レポートとブラウザ print-to-PDF パスではなく生成 PDF ファイルを必要とするエンタープライズ/コンプライアンスワークフローがない限り、ネイティブ PDF エクスポートは GA ブロッカーではない。

### 6. ECC Tools Billing、Deep Analysis、PR チェック、Linear 同期

ターゲット: 2026-06-21

受入条件:

- ネイティブ GitHub Marketplace billing announcement が検証済み実装とドキュメントでバックされる。
- 内部 billing レディネス監査がプラン制限、シート、エンタイトルメントマッピング、Marketplace プラン形状、サブスクリプション状態、オーバージフック、失敗モードをカバー。
- Deep analyzer が diff パターン、CI/CD ワークフロー、依存/セキュリティサーフェス、PR レビュー挙動、失敗履歴、ハーネス設定、スキル品質、専用 analyzer コーパスエビデンス、co-located analyzer リファレンスセット、PR review/stale-salvage エビデンス、RAG/evaluator 比較、リファレンスセット検証をカバー。
- PR チェックスイート分類体系が Security Evidence、Harness Drift、Install Manifest Integrity、CI/CD Recommendation、Cost/Token Risk、Reference Set Validation、Deep Analyzer Evidence、RAG/Evaluator Evidence、PR Review/Salvage Evidence、Skill Quality、Agent Config Review を含む。
- evaluator/RAG billing レディネスフィクスチャ `examples/evaluator-rag-prototype/billing-marketplace-readiness/` が、ローンチコピーがこれらクレームをライブとして扱える前に Marketplace、App、サブスクリプション、シート、エンタイトルメント、プラン言語に対する read-only クレーム検証パスを記録。
- Cost/token-risk 予測フォローアップが、予算エビデンスが欠けているとき AI ルーティング、モデル呼び出し、使用、クオータ、予算変更をフラグ。
- リファレンスセット検証フォローアップが、eval、ゴールデントレース、ベンチマーク、または維持リファレンスセットエビデンスが欠けている analyzer、スキル、エージェント、コマンド、ハーネスガイダンス変更をフラグ。
- Deep-analyzer フォローアップが、analyzer コーパス、スナップショット、フィクスチャ、ベンチマークエビデンスが欠けているリポジトリ、コミット、アーキテクチャ、パターン、解析パイプライン変更をフラグ。
- Analyzer コーパスエビデンスが、現在のアーキテクチャとコミット analyzer 出力のための維持フィクスチャとテスト、加えて co-located `src/analyzers/{fixtures,goldens,reference-sets,benchmarks,evals}/` エビデンスパスを含む。
- RAG/evaluator フォローアップが、リファレンスセット比較、ゴールデントレース、ベンチマーク、フィクスチャ、eval-run エビデンスが欠けている retrieval、埋め込み、ランキング、evaluator 変更をフラグ。
- Evaluator/RAG コーパスコントラクトが、stale-PR salvage、billing readiness、CI failure diagnosis、harness config quality、AgentShield ポリシー例外、skill-quality エビデンス、deep-analyzer エビデンス、RAG/evaluator 比較のローカルプロトタイプシナリオを ECC-Tools フィクスチャとテストにミラー。
- PR review/stale-salvage フォローアップが、stale-salvage フィクスチャ、reviewer-thread ケース、reopen-flow リファレンスエビデンスが欠けているレビュー、トリアージ、stale-closure、pull-request 自動化変更をフラグ。
- PR analysis コメントが要求された変更、未解決または古いレビュースレッド、欠落承認のレビューフォローアップシグナルを要約。
- CI failure-mode 予測フォローアップが、失敗フィクスチャ、キャプチャログ、トラブルシューティングノート、ドライランエビデンス、回帰カバレッジが欠けているワークフローとテストランナー変更をフラグ。
- ハーネス設定品質予測フォローアップが、監査、アダプタマトリクス、クロスハーネスドキュメント、互換性回帰エビデンスが欠けている MCP、プラグイン、エージェント、フック、コマンド、ハーネス設定変更をフラグ。
- Linear 同期が deferred バックログ所見を GitHub をフラッディングせずに Linear issue にマップ、設定されているとき exact-title Linear issue を作成または再利用し、認証情報またはチーム設定が無いときスキップ同期を報告。
- Linear/プロジェクトバックログ同期が、`/ecc-tools followups sync-linear` を `open-pr-drafts` 無しで使うときコピーレディ PR ドラフトを含み、stale-PR salvage 作業が余分な PR シェルを開かずに追跡され続ける。
- フォローアップ生成が自動 GitHub オブジェクト生成をキャップし、オーバーフロー所見をコピーレディプロジェクト同期バックログに保持。

### 7. レガシー監査と陳腐作業サルベージクロージャ

ターゲット: 2026-06-15

受入条件:

- レガシーディレクトリと孤立 handoff がインベントリされる。
- 各有用アーティファクトが landed、Linear/プロジェクト追跡、サルベージブランチ、またはアーカイブ/無アクションとしてマークされる。
- ワークスペースレベルレガシーリポジトリはサニタイズされたメンテナブランチ経由でのみマイニングされる。生コンテキスト、シークレット、個人パス、ローカル設定、プライベートドラフトは全体としてインポートされない。
- 陳腐 PR サルベージポリシーが強制力を保つ: 陳腐/コンフリクト PR を最初にクローズ、サルベージ台帳アイテムを記録、その後メンテナブランチで帰属付きで有用な互換コンテンツを port。
- #1687 ローカライズ残余は盲目的 cherry-pick ではなく翻訳者/手動レビューでのみ扱われる。

## 次のエンジニアリングスライス

1. `docs/architecture/agentshield-enterprise-research-roadmap.md` から AgentShield エンタープライズコントロールプレーンシーケンスを継続する。PR #63 が GitHub Action ベースライン出力と job-summary エビデンスを出荷。PR #64 が `agentshield baseline write` 経由でファーストクラスベースラインスナップショット作成を出荷。PR #67 が evidence-pack バンドル出荷。PR #68 が evidence-pack redaction を強化。PR #69 がマルチハーネスアダプタレジストリ出荷。PR #78 が現在のサプライチェーンインシデントクラス用にリリースワークフローを強化。PR #79 がベースライン/監視/remediation 指紋をハッシュエビデンスに移動し、新ベースラインに生エビデンス書き込みを停止。PR #80 が失敗回帰ゲートに優先順位付きコーパス精度推奨を追加。PR #81 が順序付き remediation ワークフローフェーズを追加。PR #82 が env プロキシハイジャックと帯域外排出のコーパスカバレッジを拡張。PR #83-#85 が Mini Shai-Hulud IOC カバレッジとリリースパスサプライチェーン検証を強化。PR #86 が evidence pack にホワイトリスト化された `ci-context.json` ワークフロー、コミット、実行、ランタイム provenance を追加。PR #87 がインストール済み Claude プラグインキャッシュをアクティブトップレベルランタイム設定 (キャッシュフック実装含む) と別に分類。PR #88 がダウンストリームコンシューマ用 `agentshield evidence-pack inspect` JSON/テキスト readback を追加。PR #89 が複数の検査済みバンドルにわたって `agentshield evidence-pack fleet` サマリ/ルーティングを追加。ECC-Tools PR #42/#43 が現在 evidence pack をルーティングして認識。ECC-Tools PR #76 がホストセキュリティレビューで fleet サマリを消費。ECC-Tools PR #77 がホスト PR コメントと check-run でソースエビデンスパスを表面化。ECC-Tools PR #78 が AgentShield fleet ターゲットパスをホストハーネスオーナー findings にリンク。AgentShield PR #90 がソースエビデンスパスとオーナー対応推奨を持つ fleet `reviewItems` を発出。AgentShield PR #91 がブランチ保護レビューとダウンストリームポリシー promotion 用 checksum バックポリシーバンドルをエクスポート。AgentShield PR #92 が dry-run JSON レビュー付きで checksum 検証済みポリシーバンドルをアクティブポリシーファイルに promote。AgentShield commit `87aec47` がダイジェストエビデンス、オーナーレビュー、保護ロールアウト PR 引き継ぎ、ランタイムスモークテスト用ポリシー promotion `reviewItems` を追加。AgentShield commit `28d08c7` がパッケージマネージャ強化ドリフト検出追加。AgentShield commit `659f569` が現在の SHA-pin v6 actions で action ランタイム deprecation 警告をクリア。AgentShield commit `ee585cd` が npm release-age ガイダンスを修正し、サポート外 npm 経過日数キーが findings となり強制可能 cooldown findings が pnpm/Yarn に留まるようにする。AgentShield commit `1124535` がレジストリ認証情報、ライフサイクルスクリプトドリフト、release-age ゲートドリフト用パッケージマネージャ強化 Action 出力を公開。AgentShield commit `1593925` がオーナー承認、保護ロールアウト、ダイジェストエビデンス、ランタイムスモークレビューアイテム用 policy-promotion Action 出力を公開。ECC-Tools commit `8658951` がそれらの出力をホストセキュリティレビューと Hosted Promotion Readiness スコアリングで消費。ECC-Tools commit `16c537f` がホストセキュリティコメント/check-run で promotion ステータス、パック、review item カウント、残アクションカウント、ダイジェストをレンダー。AgentShield commit `840952a` が Linear/オペレータ対応 fleet review チケットペイロードを追加し現在の Mini Shai-Hulud IOC ブレッドクラムを拡張(ローカルとリモート CI green)。AgentShield commit `4e36aab` が拡張 Mini Shai-Hulud リフレッシュ後に CI パッケージインストールを強化(CI、Test GitHub Action、Self-Scan、Dependabot Update ワークフロー green)。ECC-Tools commit `05d4e82` が生プロバイダ出力露出無しで決定論的リクエスト指紋と allowed-citation カウントを持つホスト promotion judge 監査トレース追加。ECC-Tools commit `91a441b` が特権 API 呼び出し前の Marketplace readback 入力チェック用 billing announcement preflight コマンド追加。ECC-Tools commit `2859678` がネイティブ支払い announcement レディネスがパスする前に billing-state で Marketplace webhook provenance 要求。ECC-Tools commit `42653f9` が Wrangler OAuth KV readback 追加し現在のブロッカーが Cloudflare 読み込みアクセスではなく webhook provenance を伴う ready-like Marketplace Pro billing-state レコードの不在であることを確認。ECC-Tools commit `632e059` がサニタイズターゲットアカウント readback 追加。PR #89/#90/#91 が最終オペレータパスを selected-target readback、selected-target announcement gating、アカウントログインまたは生 KV キー名を出力しない無視 env-file 認証情報ロードに移動。ECC-Tools PR #79 が billing announcement gate アカウント出力を redact。PR #80 がランタイム receipt で失敗理由要求。PR #81/#82 が AgentShield fleet approval ID を保持・レンダー。PR #83 が Linear follow-up 同期を external ID でべき等にする。PR #84 がホスト AgentShield remediation アイテムを Linear に同期。PR #85 が budget-blocked 結果含むホストジョブ可観測性イベント発出。PR #86/#87 がそれらイベントをホストステータスコメントとホスト depth-plan check-run に読み戻す。PR #88 がオペレータダッシュボード用認証済みホスト可観測性 API readback を公開。
2. `npm run billing:announcement-gate -- --preflight --select-ready-target` を実行する。ローカルベアラトークンが無視されたオペレータファイルに格納されているとき `--env-file /path/to/ecc-tools.env` を追加する。その後 `--preflight` 無しで同コマンドを実行し、任意のネイティブ GitHub 支払い announcement の前に `announcementGate.ready === true` を必須とする。
3. ワークスペース issue 容量がクリアされるか Linear ワークスペースがアップグレードされた後にマージ済み Linear バックログ同期パスを有効化/設定し、PR-draft サルベージアイテムが期待されるプロジェクトに着地することを検証する。
4. より深いホスト検索、ベクトルストレージ、自動 check-run promotion を追加する前に、ECC-Tools evaluator/RAG コーパスを promotion ゲートとして使う。

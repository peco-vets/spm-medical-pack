# PR レビューとキュートリアージ — 2026 年 3 月 13 日

## スナップショット

本ドキュメントは `2026-03-13T08:33:31Z` 時点の `everything-claude-code` プルリクエストキューに対するライブ GitHub トリアージスナップショットを記録する。

使用ソース:

- `gh pr view`
- `gh pr checks`
- `gh pr diff --name-only`
- マージされた `#399` head に対するターゲットローカル検証

このパスで使う陳腐閾値:

- `2026-02-11 より前の最終更新` (2026-03-13 から `>30` 日)

## PR `#399` 回顧レビュー

PR:

- `#399` — `fix(observe): 5-layer automated session guard to prevent self-loop observations`
- state: `MERGED`
- merged at: `2026-03-13T06:40:03Z`
- merge commit: `c52a28ace9e7e84c00309fc7b629955dfc46ecf9`

変更ファイル:

- `skills/continuous-learning-v2/hooks/observe.sh`
- `skills/continuous-learning-v2/agents/observer-loop.sh`

merged head `546628182200c16cc222b97673ddd79e942eacce` に対して実施した検証:

- 両変更シェルスクリプトに `bash -n`
- `node tests/hooks/hooks.test.js` (`204` passed, `0` failed)
- 以下のためのターゲットフック起動:
  - 対話型 CLI セッション
  - `CLAUDE_CODE_ENTRYPOINT=mcp`
  - `ECC_HOOK_PROFILE=minimal`
  - `ECC_SKIP_OBSERVE=1`
  - `agent_id` ペイロード
  - トリム済み `ECC_OBSERVE_SKIP_PATHS`

挙動結果:

- コア自己ループ修正は動作する
- 自動化セッションガードブランチは観測書き込みを意図通り抑制する
- 最終的な `non-cli => exit` エントリポイントロジックは正しい fail-closed 形状

残る所見:

1. Medium: スキップされる自動化セッションが新ガードが exit する前に homunculus プロジェクト状態を作成する。
   `observe.sh` は自動化セッションガードブロックに到達する前に `cwd` を解決しプロジェクト検出をソースするため、`detect-project.sh` は後に early exit するセッションに対しても依然として `projects/<id>/...` ディレクトリを作成し `projects.json` を更新する。
2. Low: 新ガードマトリクスは直接の回帰カバレッジ無しで出荷された。
   フックテストスイートは隣接挙動を依然として検証するが、新しい `CLAUDE_CODE_ENTRYPOINT`、`ECC_HOOK_PROFILE`、`ECC_SKIP_OBSERVE`、`agent_id`、またはトリム skip-path ブランチを直接アサートしない。

判定:

- `#399` は主目的に対して技術的に正しく、緊急のループ停止修正としてマージは安全だった。
- 自動化セッションガードをプロジェクト登録副作用の前に移動し、明示的なガードパステストを追加するフォローアップ Issue またはパッチが依然として正当化される。

## オープン PR インベントリ

現在 `4` 件のオープン PR がある。

### キューテーブル

| PR | Title | Draft | Mergeable | Merge State | Updated | Stale | 現在の判定 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `#292` | `chore(config): governance and config foundation (PR #272 split 1/6)` | `false` | `MERGEABLE` | `UNSTABLE` | `2026-03-13T07:26:55Z` | `No` | `現在最も良いマージ候補` |
| `#298` | `feat(agents,skills,rules): add Rust, Java, mobile, DevOps, and performance content` | `false` | `CONFLICTING` | `DIRTY` | `2026-03-11T04:29:07Z` | `No` | `レビュー完了前に変更が必要` |
| `#336` | `Customisation for Codex CLI - Features from Claude Code and OpenCode` | `true` | `MERGEABLE` | `UNSTABLE` | `2026-03-13T07:26:12Z` | `No` | `手動レビューとドラフト解除が必要` |
| `#420` | `feat: add laravel skills` | `true` | `MERGEABLE` | `UNSTABLE` | `2026-03-12T22:57:36Z` | `No` | `低リスクドラフト、ドラフト解除後にレビュー` |

`>30 日以上更新が無い` ルールで現在オープン PR に陳腐なものは無い。

## PR 別評価

### `#292` — Governance / Config Foundation

ライブ状態:

- open
- non-draft
- `MERGEABLE`
- merge state `UNSTABLE`
- 可視チェック:
  - `CodeRabbit` パス
  - `GitGuardian Security Checks` パス

スコープ:

- `.env.example`
- `.github/ISSUE_TEMPLATE/copilot-task.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.gitignore`
- `.markdownlint.json`
- `.tool-versions`
- `VERSION`

評価:

- 現キューで最もクリーンなマージ候補である。
- ブランチは既に現行 `main` 上にリフレッシュされている。
- 現在可視のボットフィードバックは明らかにマージブロッキングではなく、minor/nit レベルである。
- 主な注意点は外部ボットチェックのみが現在可視であること。現在の PR チェック出力に GitHub Actions マトリクス実行は現れない。

現在の推奨:

- `最終オーナーパス後にマージ可能。`
- 保守的パスを望むなら、マージ前に残る `.env.example`、PR テンプレート、`.tool-versions` の nit にすばやく人間レビューを 1 回行う。

### `#298` — 大規模マルチドメインコンテンツ拡張

ライブ状態:

- open
- non-draft
- `CONFLICTING`
- merge state `DIRTY`
- 可視チェック:
  - `CodeRabbit` パス
  - `GitGuardian Security Checks` パス
  - `cubic · AI code reviewer` パス

スコープ:

- `35` ファイル
- Java、Rust、モバイル、DevOps、パフォーマンス、データ、MLOps にわたる大規模ドキュメントとスキル/ルール拡張

評価:

- この PR はマージ準備ができていない。
- 現行 `main` とコンフリクトするため、ブランチレベルでまだマージ可能でもない。
- cubic が現レビューで `35` ファイルにわたって `34` 問題を識別した。これら所見は実質的・技術的であり、単なるスタイルクリーンアップではない。複数の新スキルにわたる壊れたまたは誤解を招く例をカバーする。
- コンフリクトが無くても、スコープは迅速なマージ判断ではなく意図的なコンテンツ修正パスを必要とするほど大きい。

現在の推奨:

- `変更が必要。`
- 最初にリベースまたはリスタックし、その後実質的な例品質問題を解決する。
- モメンタムが重要なら、1 つの非常に大きな PR を運ぶのではなくドメインで分割する。

### `#336` — Codex CLI カスタマイズ

ライブ状態:

- open
- draft
- `MERGEABLE`
- merge state `UNSTABLE`
- 可視チェック:
  - `CodeRabbit` パス
  - `GitGuardian Security Checks` パス

スコープ:

- `scripts/codex-git-hooks/pre-commit`
- `scripts/codex-git-hooks/pre-push`
- `scripts/codex/check-codex-global-state.sh`
- `scripts/codex/install-global-git-hooks.sh`
- `scripts/sync-ecc-to-codex.sh`

評価:

- この PR はもうコンフリクトしていないが、依然 draft のみで、意味のあるファーストパーティレビューパスが無い。
- ユーザーグローバル Codex セットアップ挙動と git フックインストールを変更するため、運用ブラスト半径はドキュメント専用 PR より高い。
- 可視チェックは外部ボットのみ。現在のチェックセットにフル GitHub Actions 実行は表示されていない。
- ブランチがコントリビューターフォーク `main` から来ているため、ステータスを変更する前に何が正確に提案されているかの追加の正気チェックにも値する。

現在の推奨:

- `マージレディネス前に変更が必要`。必要な変更は既証明のコード欠陥ではなくプロセス・レビュー指向である:
  - 手動レビュー完了
  - グローバル状態スクリプトでの検証実行または確認
  - そのレビューが完了してからのみドラフトから外す

### `#420` — Laravel Skills

ライブ状態:

- open
- draft
- `MERGEABLE`
- merge state `UNSTABLE`
- 可視チェック:
  - `CodeRabbit` パス
  - `GitGuardian Security Checks` パス

スコープ:

- `README.md`
- `examples/laravel-api-CLAUDE.md`
- `rules/php/patterns.md`
- `rules/php/security.md`
- `rules/php/testing.md`
- `skills/configure-ecc/SKILL.md`
- `skills/laravel-patterns/SKILL.md`
- `skills/laravel-security/SKILL.md`
- `skills/laravel-tdd/SKILL.md`
- `skills/laravel-verification/SKILL.md`

評価:

- コンテンツヘビーで `#336` より運用上低リスク。
- 依然 draft で実質的な人間レビューパスはまだ無い。
- 可視チェックは外部ボットのみ。
- ライブ PR 状態にマージブロッカーを示唆するものは無いが、依然 draft で十分にレビューされていないという理由だけでマージ準備ができていない。

現在の推奨:

- `最高優先度の非ドラフト作業後にレビュー。`
- 作者がドラフトを抜ける準備ができたら、おそらく良いレビュー候補。

## マージ可能性バケット

### 今マージ可能または最終オーナーパス後にマージ可能

- `#292`

### マージ前に変更が必要

- `#298`
- `#336`

### Draft / マージ判断前にレビューが必要

- `#420`

### 陳腐 `>30 日`

- 無し

## 推奨順序

1. `#292`
   現キューで最もクリーンなライブマージ候補。
2. `#420`
   ランタイムリスクは低いが、draft 解除と実際のレビューパスを待つ。
3. `#336`
   グローバル Codex 同期とフック挙動を変更するため慎重にレビューする。
4. `#298`
   リベースして実質的なコンテンツ問題を修正してから、これにさらにレビュー時間を費やす。

## ボトムライン

- `#399`: 安全なバグ修正マージ。1 つのフォローアップクリーンアップが依然正当化される
- `#292`: 現オープンキューで最高優先のマージ候補
- `#298`: マージ不可。コンフリクトに加え実質的コンテンツ欠陥
- `#336`: もはやコンフリクトしないが、依然 draft で軽く検証されたままなので準備ができていない
- `#420`: draft、低リスクコンテンツレーン、非ドラフトキュー後にレビュー

## ライブリフレッシュ

`2026-03-13T22:11:40Z` にリフレッシュ。

### Main Branch

- `origin/main` は現在 green であり、Windows テストマトリクスを含む。
- メインライン CI 修復は現在のボトルネックではない。

### 更新キュー読み取り

#### `#292` — Governance / Config Foundation

- open
- non-draft
- `MERGEABLE`
- 可視チェック:
  - `CodeRabbit` パス
  - `GitGuardian Security Checks` パス
- 残る最高シグナル作業は CI 修復ではなく、マージ前の `.env.example` と PR テンプレートアラインメントの小さな正確性パス

現在の推奨:

- `次の実行可能 PR。`
- 残るドキュメント/設定正確性問題をパッチするか、現在のトレードオフを受け入れるなら最終オーナーパスを 1 回行ってマージする。

#### `#420` — Laravel Skills

- open
- draft
- `MERGEABLE`
- 可視チェック:
  - PR が draft のため `CodeRabbit` スキップ
  - `GitGuardian Security Checks` パス
- まだ実質的な人間レビューは可視ではない

現在の推奨:

- `非ドラフトキュー後にレビュー。`
- 実装リスクは低いが、依然 draft で十分にレビューされていないままマージ準備ができていない。

#### `#336` — Codex CLI カスタマイズ

- open
- draft
- `MERGEABLE`
- 可視チェック:
  - `CodeRabbit` パス
  - `GitGuardian Security Checks` パス
- グローバル Codex 同期と git フックインストール挙動に触れるため、依然意図的な手動レビューが必要

現在の推奨:

- `手動レビューレーン、即時マージレーンではない。`

#### `#298` — 大規模コンテンツ拡張

- open
- non-draft
- `CONFLICTING`
- 依然キューで最も難しい残り PR

現在の推奨:

- `現オープン PR の中で最低優先度。`
- 最初にリベースし、その後実質的なコンテンツ/例修正を扱う。

### 現在の順序

1. `#292`
2. `#420`
3. `#336`
4. `#298`

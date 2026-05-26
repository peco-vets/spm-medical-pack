---
name: continuous-learning-v2
description: フックを介してセッションを観察し、信頼度スコアリング付きのアトミックなインスティンクトを作成し、スキル/コマンド/エージェントへと進化させるインスティンクトベース学習システム。v2.1 はクロスプロジェクト汚染を防ぐためにプロジェクトスコープドのインスティンクトを追加 (continuous learning, instinct, hooks, project-scoped, confidence scoring, observation)。
origin: ECC
version: 2.1.0
---

# Continuous Learning v2.1 - インスティンクトベースアーキテクチャ

Claude Code セッションを、信頼度スコアリング付きの小さな学習挙動である「インスティンクト」を介して再利用可能な知識に変える高度な学習システム。

**v2.1** は **プロジェクトスコープドインスティンクト** を追加 — React パターンは React プロジェクトに、Python 規約は Python プロジェクトに留まり、汎用パターン (「入力を常に検証する」等) はグローバルに共有される。

## 起動するタイミング

- Claude Code セッションからの自動学習のセットアップ
- フックを介したインスティンクトベースの挙動抽出の設定
- 学習挙動の信頼度しきい値のチューニング
- インスティンクトライブラリのレビュー・エクスポート・インポート
- インスティンクトをフルスキル・コマンド・エージェントへ進化
- プロジェクトスコープド vs グローバルインスティンクトの管理
- インスティンクトをプロジェクトからグローバルスコープへプロモート

## v2.1 の新機能

| 機能 | v2.0 | v2.1 |
|---------|------|------|
| ストレージ | グローバル (`~/.claude/homunculus/`) | プロジェクトスコープド (`${XDG_DATA_HOME:-~/.local/share}/ecc-homunculus/projects/<hash>/`) |
| スコープ | すべてのインスティンクトがどこでも適用 | プロジェクトスコープド + グローバル |
| 検出 | なし | git remote URL / repo path |
| プロモーション | N/A | 2 以上のプロジェクトで見られたらプロジェクト → グローバル |
| コマンド | 4 (status/evolve/export/import) | 6 (+promote/projects) |
| クロスプロジェクト | 汚染リスク | デフォルトで隔離 |

## v2 の新機能 (v1 と比較)

| 機能 | v1 | v2 |
|---------|----|----|
| 観察 | Stop フック (セッション終了) | PreToolUse/PostToolUse (100% 信頼性) |
| 分析 | メインコンテキスト | バックグラウンドエージェント (Haiku) |
| 粒度 | フルスキル | アトミックな「インスティンクト」 |
| 信頼度 | なし | 0.3-0.9 重み付け |
| 進化 | スキルへ直接 | インスティンクト -> クラスタ -> スキル/コマンド/エージェント |
| 共有 | なし | インスティンクトのエクスポート/インポート |

## インスティンクトモデル

インスティンクトは小さな学習挙動である:

```yaml
---
id: prefer-functional-style
trigger: "when writing new functions"
confidence: 0.7
domain: "code-style"
source: "session-observation"
scope: project
project_id: "a1b2c3d4e5f6"
project_name: "my-react-app"
---

# Prefer Functional Style

## Action
Use functional patterns over classes when appropriate.

## Evidence
- Observed 5 instances of functional pattern preference
- User corrected class-based approach to functional on 2025-01-15
```

**プロパティ:**
- **Atomic** -- 1 トリガー、1 アクション
- **Confidence-weighted** -- 0.3 = 暫定、0.9 = ほぼ確実
- **Domain-tagged** -- code-style・testing・git・debugging・workflow 等
- **Evidence-backed** -- それを作成した観察を追跡
- **Scope-aware** -- `project` (デフォルト) または `global`

## 仕組み

```
Session Activity (in a git repo)
      |
      | Hooks capture prompts + tool use (100% reliable)
      | + detect project context (git remote / repo path)
      v
+---------------------------------------------+
|  projects/<project-hash>/observations.jsonl  |
|   (prompts, tool calls, outcomes, project)   |
+---------------------------------------------+
      |
      | Observer agent reads (background, Haiku)
      v
+---------------------------------------------+
|          PATTERN DETECTION                   |
|   * User corrections -> instinct             |
|   * Error resolutions -> instinct            |
|   * Repeated workflows -> instinct           |
|   * Scope decision: project or global?       |
+---------------------------------------------+
      |
      | Creates/updates
      v
+---------------------------------------------+
|  projects/<project-hash>/instincts/personal/ |
|   * prefer-functional.yaml (0.7) [project]   |
|   * use-react-hooks.yaml (0.9) [project]     |
+---------------------------------------------+
|  instincts/personal/  (GLOBAL)               |
|   * always-validate-input.yaml (0.85) [global]|
|   * grep-before-edit.yaml (0.6) [global]     |
+---------------------------------------------+
      |
      | /evolve clusters + /promote
      v
+---------------------------------------------+
|  projects/<hash>/evolved/ (project-scoped)   |
|  evolved/ (global)                           |
|   * commands/new-feature.md                  |
|   * skills/testing-workflow.md               |
|   * agents/refactor-specialist.md            |
+---------------------------------------------+
```

## プロジェクト検出

システムは現在のプロジェクトを自動検出する:

1. **`CLAUDE_PROJECT_DIR` 環境変数** (最高優先度)
2. **`git remote get-url origin`** -- ポータブルなプロジェクト ID を作成するためにハッシュ化 (異なるマシンの同じリポは同じ ID を得る)
3. **`git rev-parse --show-toplevel`** -- リポパスを使うフォールバック (マシン固有)
4. **グローバルフォールバック** -- プロジェクトが検出されなければ、インスティンクトはグローバルスコープに行く

各プロジェクトは 12 文字のハッシュ ID を取得する (例: `a1b2c3d4e5f6`)。レジストリファイル `${XDG_DATA_HOME:-~/.local/share}/ecc-homunculus/projects.json` が ID を人間可読名にマップする。

### データディレクトリ

continuous-learning-v2 は Claude Code のセンシティブパスガードがバックグラウンドインスティンクト書き込みをブロックしないように `~/.claude` の外に観察データを保存する:

1. 絶対パスに設定されているときの `CLV2_HOMUNCULUS_DIR`
2. `$XDG_DATA_HOME/ecc-homunculus`
3. `$HOME/.local/share/ecc-homunculus`

`~/.claude/homunculus` にデータを持つ既存ユーザーは一度移行できる:

```bash
bash skills/continuous-learning-v2/scripts/migrate-homunculus.sh
```

## クイックスタート

### 1. 観察フックを有効化

**プラグインとしてインストールされている場合** (推奨):

追加の `settings.json` フックブロックは不要。Claude Code v2.1+ はプラグイン `hooks/hooks.json` を自動ロードし、`observe.sh` は既にそこに登録されている。

以前に `observe.sh` を `~/.claude/settings.json` にコピーしていた場合、その重複した `PreToolUse` / `PostToolUse` ブロックを削除する。プラグインフックを重複させると二重実行と `${CLAUDE_PLUGIN_ROOT}` 解決エラーが発生する。この変数はプラグイン管理 `hooks/hooks.json` エントリ内でのみ利用可能だからである。

**手動で `~/.claude/skills` にインストールされている場合**、これを `~/.claude/settings.json` に追加する:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh"
      }]
    }],
    "PostToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh"
      }]
    }]
  }
}
```

### 2. ディレクトリ構造を初期化

システムは初回使用時に自動的にディレクトリを作成するが、手動で作成することもできる:

```bash
# Global directories
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/ecc-homunculus"/{instincts/{personal,inherited},evolved/{agents,skills,commands},projects}

# Project directories are auto-created when the hook first runs in a git repo
```

### 3. インスティンクトコマンドを使う

```bash
/instinct-status     # Show learned instincts (project + global)
/evolve              # Cluster related instincts into skills/commands
/instinct-export     # Export instincts to file
/instinct-import     # Import instincts from others
/promote             # Promote project instincts to global scope
/projects            # List all known projects and their instinct counts
```

## コマンド

| コマンド | 説明 |
|---------|-------------|
| `/instinct-status` | 信頼度付きですべてのインスティンクト (プロジェクトスコープド + グローバル) を表示 |
| `/evolve` | 関連インスティンクトをスキル/コマンドにクラスタ、プロモーションを提案 |
| `/instinct-export` | インスティンクトをエクスポート (スコープ/ドメインでフィルタ可) |
| `/instinct-import <file>` | スコープ制御付きでインスティンクトをインポート |
| `/promote [id]` | プロジェクトインスティンクトをグローバルスコープにプロモート |
| `/projects` | 既知のすべてのプロジェクトとそのインスティンクト数をリスト |

## 設定

バックグラウンドオブザーバを制御するために `config.json` を編集する:

```json
{
  "version": "2.1",
  "observer": {
    "enabled": false,
    "run_interval_minutes": 5,
    "min_observations_to_analyze": 20
  }
}
```

| キー | デフォルト | 説明 |
|-----|---------|-------------|
| `observer.enabled` | `false` | バックグラウンドオブザーバエージェントを有効化 |
| `observer.run_interval_minutes` | `5` | オブザーバが観察を分析する頻度 |
| `observer.min_observations_to_analyze` | `20` | 分析実行前の最小観察数 |

他の挙動 (観察キャプチャ、インスティンクトしきい値、プロジェクトスコーピング、プロモーション基準) は `instinct-cli.py` と `observe.sh` のコードデフォルトで設定される。

## ファイル構造

```
${XDG_DATA_HOME:-~/.local/share}/ecc-homunculus/
+-- identity.json           # Your profile, technical level
+-- projects.json           # Registry: project hash -> name/path/remote
+-- observations.jsonl      # Global observations (fallback)
+-- instincts/
|   +-- personal/           # Global auto-learned instincts
|   +-- inherited/          # Global imported instincts
+-- evolved/
|   +-- agents/             # Global generated agents
|   +-- skills/             # Global generated skills
|   +-- commands/           # Global generated commands
+-- projects/
    +-- a1b2c3d4e5f6/       # Project hash (from git remote URL)
    |   +-- project.json    # Per-project metadata mirror (id/name/root/remote)
    |   +-- observations.jsonl
    |   +-- observations.archive/
    |   +-- instincts/
    |   |   +-- personal/   # Project-specific auto-learned
    |   |   +-- inherited/  # Project-specific imported
    |   +-- evolved/
    |       +-- skills/
    |       +-- commands/
    |       +-- agents/
    +-- f6e5d4c3b2a1/       # Another project
        +-- ...
```

## スコープ決定ガイド

| パターンタイプ | スコープ | 例 |
|-------------|-------|---------|
| 言語/フレームワーク規約 | **project** | 「React hooks を使う」「Django REST パターンに従う」 |
| ファイル構造の好み | **project** | 「テストは `__tests__`/」「コンポーネントは src/components/」 |
| コードスタイル | **project** | 「関数型スタイルを使う」「dataclass を優先」 |
| エラー処理戦略 | **project** | 「エラーには Result 型を使う」 |
| セキュリティ慣行 | **global** | 「ユーザー入力を検証」「SQL をサニタイズ」 |
| 一般的なベストプラクティス | **global** | 「テストを最初に書く」「常にエラーを処理」 |
| ツールワークフローの好み | **global** | 「Edit 前に Grep」「Write 前に Read」 |
| Git 慣行 | **global** | 「Conventional commits」「小さく集中したコミット」 |

## インスティンクトプロモーション (プロジェクト -> グローバル)

同じインスティンクトが複数プロジェクトで高い信頼度で現れる場合、グローバルスコープへのプロモーション候補である。

**自動プロモーション基準:**
- 2 以上のプロジェクトで同じインスティンクト ID
- 平均信頼度 >= 0.8

**プロモートする方法:**

```bash
# Promote a specific instinct
python3 instinct-cli.py promote prefer-explicit-errors

# Auto-promote all qualifying instincts
python3 instinct-cli.py promote

# Preview without changes
python3 instinct-cli.py promote --dry-run
```

`/evolve` コマンドもプロモーション候補を提案する。

## 信頼度スコアリング

信頼度は時間とともに進化する:

| スコア | 意味 | 挙動 |
|-------|---------|----------|
| 0.3 | 暫定 | 提案するが強制しない |
| 0.5 | 中程度 | 関連する場合適用 |
| 0.7 | 強い | アプリケーションのため自動承認 |
| 0.9 | ほぼ確実 | コア挙動 |

**信頼度上昇** の場合:
- パターンが繰り返し観察される
- ユーザーが提案された挙動を修正しない
- 他ソースからの類似インスティンクトが同意する

**信頼度低下** の場合:
- ユーザーが明示的に挙動を修正
- 拡張期間パターンが観察されない
- 矛盾する証拠が現れる

## なぜ観察にスキルではなくフック?

> 「v1 は観察にスキルを頼った。スキルは確率的 -- Claude の判断に基づき 50-80% の時間発火する」

フックは決定論的に **100% の時間** 発火する。これは以下を意味する:
- すべてのツール呼び出しが観察される
- パターンが見逃されない
- 学習が網羅的

## 後方互換性

v2.1 は v2.0 と v1 と完全互換である:
- 既存のグローバルインスティンクトは `scripts/migrate-homunculus.sh` で `~/.claude/homunculus/instincts/` から移行できる
- v1 の既存 `~/.claude/skills/learned/` スキルはまだ機能する
- Stop フックはまだ動作する (今は v2 にも供給する)
- 段階的移行: 両方を並列実行

## プライバシー

- 観察はマシン上に **ローカル** に留まる
- プロジェクトスコープドインスティンクトはプロジェクトごとに隔離される
- 生の観察ではなく **インスティンクト** (パターン) のみがエクスポートできる
- 実際のコードや会話コンテンツは共有されない
- 何がエクスポートされプロモートされるかをコントロールする

## 関連

- [ECC-Tools GitHub App](https://github.com/apps/ecc-tools) - リポジトリ履歴からインスティンクトを生成
- Homunculus - v2 インスティンクトベースアーキテクチャにインスパイアしたコミュニティプロジェクト (アトミック観察、信頼度スコアリング、インスティンクト進化パイプライン)
- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - Continuous learning セクション

---

*インスティンクトベース学習: Claude にあなたのパターンを、プロジェクトごとに教える。*

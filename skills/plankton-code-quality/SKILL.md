---
name: plankton-code-quality
description: "Plankton を使った書き込み時のコード品質強制 — フックを介したすべてのファイル編集での自動フォーマット、リンティング、Claude 駆動の修正 (Write-time code quality enforcement using Plankton — auto-formatting, linting, Claude-powered fixes on every file edit via hooks)。"
origin: community
---

# Plankton コード品質スキル

Plankton (クレジット: @alxfazio) の統合リファレンス。Claude Code 向けの書き込み時コード品質強制システムである。Plankton は PostToolUse フック経由ですべてのファイル編集でフォーマッタとリンタを実行し、その後 Claude サブプロセスをスポーンしてエージェントがキャッチしなかった違反を修正する。

## 使用するタイミング

- すべてのファイル編集で自動フォーマットとリンティングが欲しい場合 (コミット時だけでなく)
- 修正の代わりに通過するためにエージェントがリンタ設定を変更することへの防御が必要
- 修正のための階層化されたモデルルーティングが欲しい場合 (シンプルなスタイルには Haiku、ロジックには Sonnet、型には Opus)
- 複数言語 (Python、TypeScript、Shell、YAML、JSON、TOML、Markdown、Dockerfile) で作業する

## 動作の仕組み

### 3 フェーズアーキテクチャ

Claude Code がファイルを編集または書き込むたびに、Plankton の `multi_linter.sh` PostToolUse フックが実行される:

```
Phase 1: Auto-Format (Silent)
├─ Runs formatters (ruff format, biome, shfmt, taplo, markdownlint)
├─ Fixes 40-50% of issues silently
└─ No output to main agent

Phase 2: Collect Violations (JSON)
├─ Runs linters and collects unfixable violations
├─ Returns structured JSON: {line, column, code, message, linter}
└─ Still no output to main agent

Phase 3: Delegate + Verify
├─ Spawns claude -p subprocess with violations JSON
├─ Routes to model tier based on violation complexity:
│   ├─ Haiku: formatting, imports, style (E/W/F codes) — 120s timeout
│   ├─ Sonnet: complexity, refactoring (C901, PLR codes) — 300s timeout
│   └─ Opus: type system, deep reasoning (unresolved-attribute) — 600s timeout
├─ Re-runs Phase 1+2 to verify fixes
└─ Exit 0 if clean, Exit 2 if violations remain (reported to main agent)
```

### メインエージェントが見るもの

| シナリオ | エージェントは見る | フック終了 |
|----------|-----------|-----------|
| 違反なし | 何も | 0 |
| サブプロセスがすべて修正 | 何も | 0 |
| サブプロセス後も違反が残る | `[hook] N violation(s) remain` | 2 |
| アドバイザリ (重複、古いツーリング) | `[hook:advisory] ...` | 0 |

メインエージェントはサブプロセスが修正できなかった問題のみ見る。ほとんどの品質問題は透過的に解決される。

### 設定保護 (ルールゲーミングへの防御)

LLM はコードを修正する代わりにルールを無効にするために `.ruff.toml` や `biome.json` を変更する。Plankton はこれを 3 層でブロックする:

1. **PreToolUse フック** — `protect_linter_configs.sh` はすべてのリンタ設定への編集を発生前にブロック
2. **Stop フック** — `stop_config_guardian.sh` はセッション終了時の `git diff` 経由で設定変更を検出
3. **保護されたファイルリスト** — `.ruff.toml`、`biome.json`、`.shellcheckrc`、`.yamllint`、`.hadolint.yaml` など

### パッケージマネージャ強制

Bash の PreToolUse フックはレガシーパッケージマネージャをブロックする:
- `pip`、`pip3`、`poetry`、`pipenv` → ブロック (`uv` を使う)
- `npm`、`yarn`、`pnpm` → ブロック (`bun` を使う)
- 許可される例外: `npm audit`、`npm view`、`npm publish`

## セットアップ

### クイックスタート

> **注:** Plankton はそのリポジトリからの手動インストールが必要。インストール前にコードをレビューすること。

```bash
# Install core dependencies
brew install jaq ruff uv

# Install Python linters
uv sync --all-extras

# Start Claude Code — hooks activate automatically
claude
```

インストールコマンドなし、プラグイン設定なし。`.claude/settings.json` のフックは Plankton ディレクトリで Claude Code を実行するときに自動的にピックアップされる。

### プロジェクトごとの統合

自分のプロジェクトで Plankton フックを使うには:

1. `.claude/hooks/` ディレクトリをプロジェクトにコピー
2. `.claude/settings.json` フック設定をコピー
3. リンタ設定ファイル (`.ruff.toml`、`biome.json` など) をコピー
4. 言語用のリンタをインストール

### 言語固有依存関係

| 言語 | 必須 | オプション |
|----------|----------|----------|
| Python | `ruff`、`uv` | `ty` (型)、`vulture` (デッドコード)、`bandit` (セキュリティ) |
| TypeScript/JS | `biome` | `oxlint`、`semgrep`、`knip` (デッドエクスポート) |
| Shell | `shellcheck`、`shfmt` | — |
| YAML | `yamllint` | — |
| Markdown | `markdownlint-cli2` | — |
| Dockerfile | `hadolint` (>= 2.12.0) | — |
| TOML | `taplo` | — |
| JSON | `jaq` | — |

## ECC とのペアリング

### 補完的、重複しない

| 懸念 | ECC | Plankton |
|---------|-----|----------|
| コード品質強制 | PostToolUse フック (Prettier、tsc) | PostToolUse フック (20+ リンタ + サブプロセス修正) |
| セキュリティスキャン | AgentShield、security-reviewer エージェント | Bandit (Python)、Semgrep (TypeScript) |
| 設定保護 | — | PreToolUse ブロック + Stop フック検出 |
| パッケージマネージャ | 検出 + セットアップ | 強制 (レガシー PM をブロック) |
| CI 統合 | — | Git 用プリコミットフック |
| モデルルーティング | 手動 (`/model opus`) | 自動 (違反複雑さ → 階層) |

### 推奨される組み合わせ

1. プラグインとして ECC をインストール (エージェント、スキル、コマンド、ルール)
2. 書き込み時品質強制のために Plankton フックを追加
3. セキュリティ監査に AgentShield を使う
4. PR 前の最終ゲートとして ECC の verification-loop を使う

### フック競合の回避

ECC と Plankton フックの両方を実行する場合:
- ECC の Prettier フックと Plankton の biome フォーマッタは JS/TS ファイルで競合する可能性がある
- 解決: Plankton を使うとき ECC の Prettier PostToolUse フックを無効にする (Plankton の biome の方が包括的)
- 両方とも異なるファイルタイプで共存できる (ECC は Plankton がカバーしないものを処理)

## 設定リファレンス

Plankton の `.claude/hooks/config.json` はすべての挙動を制御する:

```json
{
  "languages": {
    "python": true,
    "shell": true,
    "yaml": true,
    "json": true,
    "toml": true,
    "dockerfile": true,
    "markdown": true,
    "typescript": {
      "enabled": true,
      "js_runtime": "auto",
      "biome_nursery": "warn",
      "semgrep": true
    }
  },
  "phases": {
    "auto_format": true,
    "subprocess_delegation": true
  },
  "subprocess": {
    "tiers": {
      "haiku":  { "timeout": 120, "max_turns": 10 },
      "sonnet": { "timeout": 300, "max_turns": 10 },
      "opus":   { "timeout": 600, "max_turns": 15 }
    },
    "volume_threshold": 5
  }
}
```

**主要設定:**
- フックを高速化するために使わない言語を無効にする
- `volume_threshold` — このカウントを超える違反は自動的に高いモデル階層にエスカレートする
- `subprocess_delegation: false` — フェーズ 3 を完全にスキップ (違反を報告するのみ)

## 環境オーバーライド

| 変数 | 目的 |
|----------|---------|
| `HOOK_SKIP_SUBPROCESS=1` | フェーズ 3 をスキップ、違反を直接報告 |
| `HOOK_SUBPROCESS_TIMEOUT=N` | 階層タイムアウトをオーバーライド |
| `HOOK_DEBUG_MODEL=1` | モデル選択決定をログ |
| `HOOK_SKIP_PM=1` | パッケージマネージャ強制をバイパス |

## 参照

- Plankton (クレジット: @alxfazio)
- Plankton REFERENCE.md — 完全なアーキテクチャドキュメント (クレジット: @alxfazio)
- Plankton SETUP.md — 詳細なインストールガイド (クレジット: @alxfazio)

## ECC v1.8 追加事項

### コピー可能フックプロファイル

厳格な品質挙動を設定:

```bash
export ECC_HOOK_PROFILE=strict
export ECC_QUALITY_GATE_FIX=true
export ECC_QUALITY_GATE_STRICT=true
```

### 言語ゲートテーブル

- TypeScript/JavaScript: Biome 優先、Prettier フォールバック
- Python: Ruff フォーマット/チェック
- Go: gofmt

### 設定改ざんガード

品質強制中、同じイテレーションで設定ファイルの変更をフラグ付け:

- `biome.json`、`.eslintrc*`、`prettier.config*`、`tsconfig.json`、`pyproject.toml`

違反を抑制するために設定が変更される場合、マージ前に明示的レビューを要求する。

### CI 統合パターン

CI とローカルフックで同じコマンドを使う:

1. フォーマッタチェックを実行
2. lint/type チェックを実行
3. strict モードでフェイルファスト
4. 修復サマリーを公開

### ヘルスメトリクス

追跡:
- ゲートでフラグ付けされた編集
- 平均修復時間
- カテゴリ別の繰り返し違反
- ゲート失敗によるマージブロック

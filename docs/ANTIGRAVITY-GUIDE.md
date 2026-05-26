# Antigravity セットアップ・利用ガイド

Google の [Antigravity](https://antigravity.dev) は、設定に `.agent/` ディレクトリ規約を用いる AI コーディング IDE である。ECC はその selective install システムを通じて Antigravity をファーストクラスでサポートする。

## クイックスタート

```bash
# Install ECC with Antigravity target
./install.sh --target antigravity typescript

# Or with multiple language modules
./install.sh --target antigravity typescript python go
```

これにより、ECC コンポーネントがプロジェクトの `.agent/` ディレクトリにインストールされ、Antigravity が取得できる状態になる。

## インストールマッピングの仕組み

ECC はコンポーネント構造を Antigravity の期待レイアウトに合わせて remap する:

| ECC ソース | Antigravity 配置先 | 内容 |
|------------|--------------------|------|
| `rules/` | `.agent/rules/` | 言語ルールとコーディング標準 (フラット化) |
| `commands/` | `.agent/workflows/` | スラッシュコマンドは Antigravity ワークフローになる |
| `agents/` | `.agent/skills/` | エージェント定義は Antigravity スキルになる |

> **`.agents/` vs `.agent/` vs `agents/` についての注意**: インストーラは明示的に 3 つのソースパスのみを扱う: `rules` → `.agent/rules/`、`commands` → `.agent/workflows/`、`agents` (ドットプレフィクス無し) → `.agent/skills/`。ECC リポジトリ内のドットプレフィクスの `.agents/` ディレクトリは Codex/Antigravity スキル定義および `openai.yaml` 設定のための **静的レイアウト** であり、インストーラによって直接マップされない。`.agents/` パスはデフォルト足場オペレーションにフォールスルーする。`.agents/skills/` の内容を Antigravity ランタイムで利用可能にしたい場合は、手動で `.agent/skills/` にコピーする必要がある。

### Claude Code との主な相違点

- **ルールはフラット化される**: Claude Code はサブディレクトリ (`rules/common/`, `rules/typescript/`) 配下にルールをネストする。Antigravity はフラットな `rules/` ディレクトリを期待する。インストーラはこれを自動で処理する。
- **コマンドはワークフローになる**: ECC の `/command` ファイルは `.agent/workflows/` に着地する。これはスラッシュコマンドに相当する Antigravity の概念である。
- **エージェントはスキルになる**: ECC のエージェント定義は `.agent/skills/` にマップされる。Antigravity はスキル設定をここで探す。

## インストール後のディレクトリ構造

```
your-project/
├── .agent/
│   ├── rules/
│   │   ├── coding-standards.md
│   │   ├── testing.md
│   │   ├── security.md
│   │   └── typescript.md          # language-specific rules
│   ├── workflows/
│   │   ├── plan.md
│   │   ├── code-review.md
│   │   ├── tdd.md
│   │   └── ...
│   ├── skills/
│   │   ├── planner.md
│   │   ├── code-reviewer.md
│   │   ├── tdd-guide.md
│   │   └── ...
│   └── ecc-install-state.json     # tracks what ECC installed
```

## `openai.yaml` エージェント設定

`.agents/skills/` 配下の各スキルディレクトリには、`.agents/skills/<skill-name>/agents/openai.yaml` パスに `agents/openai.yaml` ファイルがあり、Antigravity 向けにスキルを設定する:

```yaml
interface:
  display_name: "API Design"
  short_description: "REST API design patterns and best practices"
  brand_color: "#F97316"
  default_prompt: "Design REST API: resources, status codes, pagination"
policy:
  allow_implicit_invocation: true
```

| フィールド | 目的 |
|------------|------|
| `display_name` | Antigravity の UI に表示される人間可読名 |
| `short_description` | スキルが何をするかの簡単な説明 |
| `brand_color` | スキルのビジュアルバッジ用 hex 色 |
| `default_prompt` | スキルを手動で呼び出した際の推奨プロンプト |
| `allow_implicit_invocation` | `true` のとき、Antigravity がコンテキストに基づきスキルを自動アクティブ化できる |

## インストール管理

### インストール済み内容の確認

```bash
node scripts/list-installed.js --target antigravity
```

### 壊れたインストールの修復

```bash
# First, diagnose what's wrong
node scripts/doctor.js --target antigravity

# Then, restore missing or drifted files
node scripts/repair.js --target antigravity
```

### アンインストール

```bash
node scripts/uninstall.js --target antigravity
```

### インストール状態

インストーラは `.agent/ecc-install-state.json` を書き、ECC が所有するファイルを追跡する。これにより安全なアンインストールと修復が可能になる — ECC は自身が作成していないファイルには触れない。

## Antigravity 用カスタムスキルの追加

新スキルをコントリビュートし、Antigravity で利用可能にしたい場合:

1. 通常通り `skills/your-skill-name/SKILL.md` 配下にスキルを作成する
2. `agents/your-skill-name.md` にエージェント定義を追加する — これはインストーラがランタイムで `.agent/skills/` にマップするパスであり、スキルが Antigravity ハーネスで利用可能になる
3. `.agents/skills/your-skill-name/agents/openai.yaml` に Antigravity エージェント設定を追加する — これは Codex が implicit invocation メタデータのために消費する静的リポジトリレイアウトである
4. `SKILL.md` の内容を `.agents/skills/your-skill-name/SKILL.md` にミラーする — この静的コピーは Codex により使用され、Antigravity 向けの参照としても機能する
5. PR で Antigravity サポートを追加した旨を言及する

> **重要な区別**: インストーラは `agents/` (ドット無し) → `.agent/skills/` を配置する — これによりスキルがランタイムで利用可能になる。`.agents/` (ドットプレフィクス) ディレクトリは Codex `openai.yaml` 設定のための別個の静的レイアウトであり、インストーラによる自動配置の対象ではない。

完全なコントリビューションガイドは [CONTRIBUTING.md](../CONTRIBUTING.md) を参照。

## 他ターゲットとの比較

| 機能 | Claude Code | Cursor | Codex | Antigravity |
|------|-------------|--------|-------|-------------|
| Install target | `claude-home` | `cursor-project` | `codex-home` | `antigravity` |
| Config root | `~/.claude/` | `.cursor/` | `~/.codex/` | `.agent/` |
| スコープ | User-level | Project-level | User-level | Project-level |
| Rules 形式 | Nested dirs | Flat | Flat | Flat |
| Commands | `commands/` | N/A | N/A | `workflows/` |
| Agents/Skills | `agents/` | N/A | N/A | `skills/` |
| Install state | `ecc-install-state.json` | `ecc-install-state.json` | `ecc-install-state.json` | `ecc-install-state.json` |

## トラブルシューティング

### Antigravity でスキルがロードされない

- `.agent/` ディレクトリがプロジェクトルート (ホームディレクトリではなく) に存在することを確認する
- `ecc-install-state.json` が作成されたか確認する — 不在ならインストーラを再実行する
- ファイルが `.md` 拡張子と有効な frontmatter を持つことを確認する

### ルールが適用されない

- ルールはサブディレクトリにネストせず `.agent/rules/` に置く必要がある
- `node scripts/doctor.js --target antigravity` を実行してインストールを検証する

### ワークフローが利用できない

- Antigravity はワークフローを `commands/` ではなく `.agent/workflows/` で探す
- ECC コマンドを手動コピーした場合は、ディレクトリ名を変更する

## 関連リソース

- [Selective Install Architecture](./SELECTIVE-INSTALL-ARCHITECTURE.md) — インストールシステムが内部でどう動作するか
- [Selective Install Design](./SELECTIVE-INSTALL-DESIGN.md) — 設計判断とターゲットアダプタコントラクト
- [CONTRIBUTING.md](../CONTRIBUTING.md) — スキル、エージェント、コマンドのコントリビューション方法

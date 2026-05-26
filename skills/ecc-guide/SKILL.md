---
name: ecc-guide
description: ECC のエージェント・スキル・コマンド・フック・ルール・インストールプロファイル・プロジェクトオンボーディングを、回答前にライブリポジトリ表面を読み取って案内する（ECC guide, agents, skills, commands, hooks, install profiles, project onboarding）。
origin: community
---

# ECC ガイド

ユーザーが Everything Claude Code の理解・ナビゲーション・インストール・選択を必要とする際に用いる。

## 利用タイミング

ユーザーが以下を行う場合に用いる。

- ECC に何が含まれるかを尋ねる
- スキル・コマンド・エージェント・フック・ルール・インストールプロファイルを探したい
- 初めてのリポジトリでガイド付きパスが必要
- "How do I do X with ECC?" と尋ねる
- どの ECC コンポーネントがプロジェクトに合うかを尋ねる
- コマンド・スキル・エージェント・フック・ルールの関係について軽い説明が必要
- インストールパス・重複インストール・reset/uninstall・選択的インストールに困惑している

## 中核原則

記憶ではなく現在のファイルから回答する。ECC は変化が速いため、ハードコードしたカタログ件数・機能リスト・インストール手順は古びる。

ECC リポジトリが利用可能なら、具体回答前に該当ファイルを参照する。

```bash
node scripts/ci/catalog.js --json
find skills -maxdepth 2 -name SKILL.md | sort
find commands -maxdepth 1 -name '*.md' | sort
find agents -maxdepth 1 -name '*.md' | sort
node scripts/install-plan.js --list-profiles
node scripts/install-plan.js --list-components --json
```

ユーザーの問いに必要な最小の読み取り集合のみを用いる。

## リポジトリマップ

- `README.md`: インストールパス、uninstall/reset 手順、公開ポジショニング、FAQ
- `AGENTS.md`: コントリビュータガイダンス・プロジェクト構成
- `agent.yaml`: エクスポートされた gitagent 表面とコマンドリスト
- `commands/`: メンテナンスされたスラッシュコマンド互換シム
- `skills/*/SKILL.md`: 再利用可能なワークフローとドメインプレイブック
- `agents/*.md`: 委譲対象サブエージェントのロールプロンプト
- `rules/`: 言語とハーネスのルール
- `hooks/README.md`, `hooks/hooks.json`, `scripts/hooks/`: フックの挙動と安全ゲート
- `manifests/install-*.json`: 選択的インストールのモジュール・コンポーネント・プロファイル・対象サポート
- `docs/`: ハーネスガイド・アーキテクチャノート・翻訳ドキュメント・リリースドキュメント

## 回答スタイル

まず答えを示し、次のアクションを与える。多くのユーザーはフルカタログダンプを必要としない。

良い初回回答の構成:

1. 何を使うか
2. なぜ適合するか
3. 確認すべきファイルまたはコマンド
4. 次の1コマンドまたは質問

避けるべきこと:

- デフォルトで全スキル・全コマンドを列挙する
- README の大きなセクションを繰り返す
- スキル先行パスがあるのに引退コマンドシムを勧める
- ファイルシステム未確認のままコンポーネント存在を断定する
- 管理対象インストーラが対象をサポートしているのに手動 copy コマンドで代用する

## 一般的なタスク

### 新規ユーザーのオンボーディング

短いメニューを提示する。

- ECC のインストール・リセット
- プロジェクト向けのスキル選定
- コマンド vs スキルの理解
- フックと安全挙動の確認
- ハーネス監査の実行
- 特定ワークフローの検索

`README.md` でインストール/リセット、`/project-init` でプロジェクト固有オンボーディングを示す。

### 機能発見

"何を使えば X ができるか?" について:

1. `skills/`, `commands/`, `agents/` を検索する
2. 主要ワークフロー表面としてスキルを優先する
3. メンテ済み互換シムである場合、またはユーザーが明示的にスラッシュコマンド挙動を望む場合のみコマンドを使う
4. 委譲が有効な場合はエージェントに触れる

便利な検索:

```bash
rg -n "<query>" skills commands agents docs
find skills -maxdepth 2 -name SKILL.md | sort
```

### インストール案内

管理対象インストールパスを使う。

```bash
node scripts/install-plan.js --list-profiles
node scripts/install-plan.js --profile minimal --target claude --json
node scripts/install-apply.js --profile minimal --target claude --dry-run
```

特定スキルのインストール:

```bash
node scripts/install-plan.js --skills <skill-id> --target claude --json
node scripts/install-apply.js --skills <skill-id> --target claude --dry-run
```

意図的に表面重複を望む場合を除き、プラグインインストールと完全な手動/プロファイルインストールを重ねないよう警告すること。

### プロジェクトオンボーディング

ターゲットリポジトリ向けに ECC を構成したい場合は `/project-init` を使う。期待される順序:

1. プロジェクトファイルからスタックを検出する
2. ドライランインストールプランを解決する
3. 既存 `CLAUDE.md` と設定ファイルを確認する
4. 変更適用前に確認をとる
5. 生成ガイダンスは最小限かつリポジトリ固有に保つ

### トラブルシューティング

まず対象ハーネスとインストールパスを確認し、以下を点検する。

- プラグインインストールメタデータ
- `.claude/`, `.cursor/`, `.codex/`, `.gemini/`, `.opencode/`, `.codebuddy/`, `.joycode/`, `.qwen/`
- `hooks/hooks.json`
- インストール状態ファイル
- 関連コマンド/スキルファイル

リポジトリ健全性には以下を提案する。

```bash
npm run harness:audit -- --format text
npm run observability:ready
npm test
```

## 出力テンプレート

### 簡潔な推奨

```text
Use <skill-or-command>. It fits because <reason>.

Canonical file: <path>
Verify with: <command>
Next: <one concrete action>
```

### 検索結果

```text
Best matches:
- <path>: <why it matters>
- <path>: <why it matters>

Recommendation: <which one to use first and why>
```

### インストールプラン要約

```text
Detected: <stack evidence>
Target: <harness>
Plan: <profile/modules/skills>
Dry run: <command>
Would change: <paths>
Needs approval before apply: <yes/no>
```

## 関連表面

- `/project-init`: 対象リポジトリへのスタック対応オンボーディングプラン
- `/harness-audit`: 決定論的なレディネススコアカード
- `/skill-health`: スキル品質レビュー
- `/skill-create`: ローカル git 履歴から新スキルを生成
- `/security-scan`: Claude/OpenCode 設定セキュリティの点検

---
description: プロジェクトのスタックを検出し、リポジトリの install マニフェストとスタックマッピングを使って dry-run の ECC オンボーディング計画を生成する / Detect a project's stack and produce a dry-run ECC onboarding plan using the repository's install manifests and stack mappings.
---

# /project-init

現在のプロジェクトのために安全でレビュー可能な ECC オンボーディング計画を作成する。このコマンドは dry-run モードで開始し、明示的なユーザー承認後にのみファイルを書き出す。

## Usage

```text
/project-init
/project-init --dry-run
/project-init --target claude
/project-init --target cursor
/project-init --skills continuous-learning-v2,security-review
/project-init --config ecc-install.json
```

## 安全ルール

1. デフォルトで dry-run。ユーザーが具体的な計画を承認するまで、`CLAUDE.md`、設定ファイル、ルール、スキル、または install state を変更しない。
2. 既存のプロジェクトガイダンスを保持する。`CLAUDE.md`、`.claude/settings.local.json`、`.cursor/`、`.codex/`、`.gemini/`、`.opencode/`、`.codebuddy/`、`.joycode/`、または `.qwen/` が既に存在する場合、それを調査し、上書きの代わりに merge/append 計画を提案する。
3. ECC のインストーラーとマニフェストツールを使う。インストールのショートカットとしてファイルを手作業でコピーしたり、任意のリモートをクローンしたりしない。
4. パーミッションを狭く保つ。生成された設定は、検出されたビルド/テスト/lint ツールに一致するべきで、広範なシェルアクセスを避ける。
5. 何かを適用する前に、何が変わるかを正確に報告する。

## 検出入力

現在のプロジェクトルートを読み、以下からスタックシグナルを検出する：

- パッケージマネージャファイル：`package.json`、`package-lock.json`、`pnpm-lock.yaml`、`yarn.lock`、`bun.lockb`
- 言語マニフェスト：`pyproject.toml`、`requirements.txt`、`go.mod`、`Cargo.toml`、`pom.xml`、`build.gradle`、`build.gradle.kts`
- フレームワークファイル：`next.config.*`、`vite.config.*`、`tailwind.config.*`、`Dockerfile`、`docker-compose.yml`
- ECC config：`ecc-install.json`
- 任意のスタックマップ：ECC リポジトリの `config/project-stack-mappings.json`

ECC チェックアウトが利用可能な場合、スタックからルール/スキルへの参照として `config/project-stack-mappings.json` を使う。ファイルが利用不可な場合、インストール済み ECC マニフェストと明示的なユーザー選択にフォールバックする。

## 計画フロー

1. ターゲットハーネスを特定する。ユーザーが `cursor`、`codex`、`gemini`、`opencode`、`codebuddy`、`joycode`、または `qwen` を求めない限り、`claude` をデフォルトとする。
2. プロジェクトファイルからスタックを検出し、各マッチの証拠を表示する。
3. 最も小さく有用な ECC 計画を解決する：
   - プロジェクトに `ecc-install.json` がある場合：`node scripts/install-plan.js --config ecc-install.json --json`
   - ユーザーがプロファイルを指定した場合：`node scripts/install-plan.js --profile <profile> --target <target> --json`
   - ユーザーがスキルを指定した場合：`node scripts/install-plan.js --skills <skill-ids> --target <target> --json`
   - 言語スタックのみが検出された場合：それらの言語名でレガシー言語インストール dry-run を使う
4. 書き込み前に dry-run apply コマンドを実行する：

```bash
node scripts/install-apply.js --target <target> --dry-run --json <language-or-profile-args>
```

5. 検出されたスタック、選択されたモジュール/コンポーネント/スキル、ターゲットパス、スキップされた未サポートモジュール、変更されるファイルを要約する。
6. 非 dry-run コマンドを適用する前に承認を求める。

## 出力契約

以下を返す：

1. 検出されたスタックの証拠
2. 提案されたターゲットハーネス
3. 使用された正確な dry-run コマンド
4. 承認後に実行する正確な apply コマンド
5. 作成または変更されるファイル/ディレクトリ
6. 既存ファイル、広いパーミッション、不足するスクリプト、未サポートターゲットに関する警告

## CLAUDE.md ガイダンス

ユーザーが `CLAUDE.md` のスターターを求める場合、インストーラー計画とは別に生成し、最小限に保つ：

- ビルドコマンド（検出された場合）
- テストコマンド（検出された場合）
- lint/typecheck コマンド（検出された場合）
- dev server コマンド（検出された場合）
- 既存のパッケージスクリプトやマニフェストからのリポ固有のノート

diff を表示してユーザーの承認を受けるまで、既存の `CLAUDE.md` を決して置換しない。

## 関連

- スタックから surface へのヒント用に `config/project-stack-mappings.json`
- 決定論的な計画解決用に `scripts/install-plan.js`
- dry-run と適用操作用に `scripts/install-apply.js`
- インストール前のインタラクティブな機能発見用に `/ecc-guide`

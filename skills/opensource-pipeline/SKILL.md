---
name: opensource-pipeline
description: "オープンソースパイプライン: プライベートプロジェクトをフォーク、サニタイズ、安全な公開リリース用にパッケージ化する。3 エージェント (forker、sanitizer、packager) を連鎖。トリガー: '/opensource'、'open source this'、'make this public'、'prepare for open source' (Open-source pipeline: fork, sanitize, package private projects for safe public release)。"
origin: ECC
---

# Open-Source パイプラインスキル

3 段階パイプラインを通じて任意のプロジェクトを安全にオープンソース化する: **Fork** (シークレットを削除) → **Sanitize** (クリーンを検証) → **Package** (CLAUDE.md + setup.sh + README)。

## 起動するタイミング

- ユーザーが "open source this project" や "make this public" と発言
- ユーザーが公開リリース用にプライベートリポを準備したい
- ユーザーが GitHub にプッシュ前にシークレットを削除する必要がある
- ユーザーが `/opensource fork`、`/opensource verify`、または `/opensource package` を呼び出す

## コマンド

| コマンド | アクション |
|---------|--------|
| `/opensource fork PROJECT` | フルパイプライン: fork + sanitize + package |
| `/opensource verify PROJECT` | 既存リポでサニタイザを実行 |
| `/opensource package PROJECT` | CLAUDE.md + setup.sh + README を生成 |
| `/opensource list` | すべてのステージングプロジェクトを表示 |
| `/opensource status PROJECT` | ステージングプロジェクトのレポートを表示 |

## プロトコル

### /opensource fork PROJECT

**フルパイプライン — メインワークフロー**

#### ステップ 1: パラメータ収集

プロジェクトパスを解決する。PROJECT に `/` が含まれる場合、パス (絶対または相対) として扱う。そうでなければ確認: 現在の作業ディレクトリ、`$HOME/PROJECT`、その後ユーザーに尋ねる。

```
SOURCE_PATH="<resolved absolute path>"
STAGING_PATH="$HOME/opensource-staging/${PROJECT_NAME}"
```

ユーザーに尋ねる:
1. "Which project?" (見つからない場合)
2. "License? (MIT / Apache-2.0 / GPL-3.0 / BSD-3-Clause)"
3. "GitHub org or username?" (デフォルト: `gh api user -q .login` で検出)
4. "GitHub repo name?" (デフォルト: プロジェクト名)
5. "Description for README?" (提案のためにプロジェクトを分析)

#### ステップ 2: ステージングディレクトリの作成

```bash
mkdir -p $HOME/opensource-staging/
```

#### ステップ 3: Forker エージェントを実行

`opensource-forker` エージェントをスポーンする:

```
Agent(
  description="Fork {PROJECT} for open-source",
  subagent_type="opensource-forker",
  prompt="""
Fork project for open-source release.

Source: {SOURCE_PATH}
Target: {STAGING_PATH}
License: {chosen_license}

Follow the full forking protocol:
1. Copy files (exclude .git, node_modules, __pycache__, .venv)
2. Strip all secrets and credentials
3. Replace internal references with placeholders
4. Generate .env.example
5. Clean git history
6. Generate FORK_REPORT.md in {STAGING_PATH}/FORK_REPORT.md
"""
)
```

完了を待ち、`{STAGING_PATH}/FORK_REPORT.md` を読む。

#### ステップ 4: Sanitizer エージェントを実行

`opensource-sanitizer` エージェントをスポーンする:

```
Agent(
  description="Verify {PROJECT} sanitization",
  subagent_type="opensource-sanitizer",
  prompt="""
Verify sanitization of open-source fork.

Project: {STAGING_PATH}
Source (for reference): {SOURCE_PATH}

Run ALL scan categories:
1. Secrets scan (CRITICAL)
2. PII scan (CRITICAL)
3. Internal references scan (CRITICAL)
4. Dangerous files check (CRITICAL)
5. Configuration completeness (WARNING)
6. Git history audit

Generate SANITIZATION_REPORT.md inside {STAGING_PATH}/ with PASS/FAIL verdict.
"""
)
```

完了を待ち、`{STAGING_PATH}/SANITIZATION_REPORT.md` を読む。

**FAIL の場合:** 結果をユーザーに表示。"Fix these and re-scan, or abort?" と尋ねる
- 修正する場合: 修正を適用し、サニタイザを再実行 (最大 3 回のリトライ — 3 回 FAIL 後、すべての結果を提示しユーザーに手動修正を依頼)
- 中止する場合: ステージングディレクトリをクリーンアップ

**PASS または PASS WITH WARNINGS の場合:** ステップ 5 に進む

#### ステップ 5: Packager エージェントを実行

`opensource-packager` エージェントをスポーンする:

```
Agent(
  description="Package {PROJECT} for open-source",
  subagent_type="opensource-packager",
  prompt="""
Generate open-source packaging for project.

Project: {STAGING_PATH}
License: {chosen_license}
Project name: {PROJECT_NAME}
Description: {description}
GitHub repo: {github_repo}

Generate:
1. CLAUDE.md (commands, architecture, key files)
2. setup.sh (one-command bootstrap, make executable)
3. README.md (or enhance existing)
4. LICENSE
5. CONTRIBUTING.md
6. .github/ISSUE_TEMPLATE/ (bug_report.md, feature_request.md)
"""
)
```

#### ステップ 6: 最終レビュー

ユーザーに提示:
```
Open-Source Fork Ready: {PROJECT_NAME}

Location: {STAGING_PATH}
License: {license}
Files generated:
  - CLAUDE.md
  - setup.sh (executable)
  - README.md
  - LICENSE
  - CONTRIBUTING.md
  - .env.example ({N} variables)

Sanitization: {sanitization_verdict}

Next steps:
  1. Review: cd {STAGING_PATH}
  2. Create repo: gh repo create {github_org}/{github_repo} --public
  3. Push: git remote add origin ... && git push -u origin main

Proceed with GitHub creation? (yes/no/review first)
```

#### ステップ 7: GitHub 公開 (ユーザー承認時)

```bash
cd "{STAGING_PATH}"
gh repo create "{github_org}/{github_repo}" --public --source=. --push --description "{description}"
```

---

### /opensource verify PROJECT

サニタイザを独立して実行。パスを解決: PROJECT に `/` が含まれる場合、パスとして扱う。そうでなければ `$HOME/opensource-staging/PROJECT`、その後 `$HOME/PROJECT`、その後現在のディレクトリを確認。

```
Agent(
  subagent_type="opensource-sanitizer",
  prompt="Verify sanitization of: {resolved_path}. Run all 6 scan categories and generate SANITIZATION_REPORT.md."
)
```

---

### /opensource package PROJECT

パッケージャを独立して実行。"License?" と "Description?" を尋ね、その後:

```
Agent(
  subagent_type="opensource-packager",
  prompt="Package: {resolved_path} ..."
)
```

---

### /opensource list

```bash
ls -d $HOME/opensource-staging/*/
```

各プロジェクトをパイプライン進捗 (FORK_REPORT.md、SANITIZATION_REPORT.md、CLAUDE.md の存在) とともに表示。

---

### /opensource status PROJECT

```bash
cat $HOME/opensource-staging/${PROJECT}/SANITIZATION_REPORT.md
cat $HOME/opensource-staging/${PROJECT}/FORK_REPORT.md
```

## ステージングレイアウト

```
$HOME/opensource-staging/
  my-project/
    FORK_REPORT.md           # From forker agent
    SANITIZATION_REPORT.md   # From sanitizer agent
    CLAUDE.md                # From packager agent
    setup.sh                 # From packager agent
    README.md                # From packager agent
    .env.example             # From forker agent
    ...                      # Sanitized project files
```

## アンチパターン

- **決して** ユーザー承認なしに GitHub にプッシュしない
- **決して** サニタイザをスキップしない — これは安全ゲートである
- **決して** すべてのクリティカル結果を修正せずにサニタイザ FAIL 後に進まない
- **決して** ステージングディレクトリに `.env`、`*.pem`、または `credentials.json` を残さない

## ベストプラクティス

- 新規リリースには常にフルパイプライン (fork → sanitize → package) を実行する
- ステージングディレクトリは明示的にクリーンアップされるまで永続 — レビューに使う
- 公開前の手動修正後にサニタイザを再実行する
- シークレットを削除するのではなくパラメータ化する — プロジェクト機能を保持する

## 関連スキル

サニタイザが使うシークレット検出パターンには `security-review` を参照。

---
name: configure-ecc
description: Everything Claude Code のためのインタラクティブインストーラー — ユーザーレベルまたはプロジェクトレベルディレクトリへのスキルとルールの選択とインストール、パスの検証、オプションでインストール済みファイルの最適化を行う (configure ECC, interactive installer, skills, rules, user-level, project-level)。
origin: ECC
---

# Configure Everything Claude Code (ECC)

Everything Claude Code プロジェクトのインタラクティブでステップバイステップなインストールウィザード。`AskUserQuestion` を使ってユーザーをスキルとルールの選択的インストールに導き、正確性を検証し、最適化を提供する。

## 起動するタイミング

- ユーザーが「configure ecc」「install ecc」「setup everything claude code」または類似のことを言う
- ユーザーがこのプロジェクトのスキルやルールを選択的にインストールしたい
- ユーザーが既存の ECC インストールを検証または修正したい
- ユーザーがインストール済みスキルやルールをプロジェクト用に最適化したい

## 前提条件

このスキルは起動前に Claude Code からアクセス可能でなければならない。ブートストラップの 2 つの方法:
1. **プラグイン経由**: `/plugin install ecc@ecc` — プラグインはこのスキルを自動ロードする
2. **手動**: このスキルだけを `~/.claude/skills/configure-ecc/SKILL.md` にコピーし、「configure ecc」と言って起動する

---

## Step 0: ECC リポジトリをクローン

任意のインストール前に、最新の ECC ソースを `/tmp` にクローンする:

```bash
rm -rf /tmp/everything-claude-code
git clone https://github.com/affaan-m/everything-claude-code.git /tmp/everything-claude-code
```

すべての後続のコピー操作のソースとして `ECC_ROOT=/tmp/everything-claude-code` を設定する。

クローンが失敗した (ネットワーク問題等) 場合、`AskUserQuestion` を使ってユーザーに既存の ECC クローンへのローカルパスを提供するよう依頼する。

---

## Step 1: インストールレベルを選ぶ

`AskUserQuestion` を使ってインストール場所をユーザーに尋ねる:

```
Question: "Where should ECC components be installed?"
Options:
  - "User-level (~/.claude/)" — "Applies to all your Claude Code projects"
  - "Project-level (.claude/)" — "Applies only to the current project"
  - "Both" — "Common/shared items user-level, project-specific items project-level"
```

選択を `INSTALL_LEVEL` として保存する。ターゲットディレクトリを設定する:
- User-level: `TARGET=~/.claude`
- Project-level: `TARGET=.claude` (現在のプロジェクトルートからの相対)
- Both: `TARGET_USER=~/.claude`、`TARGET_PROJECT=.claude`

ターゲットディレクトリが存在しなければ作成する:
```bash
mkdir -p $TARGET/skills $TARGET/rules
```

---

## Step 2: スキルを選択 & インストール

### 2a: スコープを選ぶ (Core vs Niche)

**Core (新規ユーザー推奨)** をデフォルトとする — `.agents/skills/*` 加えて research ファーストワークフローのための `skills/search-first/` をコピー。このバンドルはエンジニアリング、eval、検証、セキュリティ、戦略的圧縮、フロントエンドデザイン、Anthropic クロスファンクショナルスキル (article-writing、content-engine、market-research、frontend-slides) をカバーする。

`AskUserQuestion` を使う (単一選択):
```
Question: "Install core skills only, or include niche/framework packs?"
Options:
  - "Core only (recommended)" — "tdd, e2e, evals, verification, research-first, security, frontend patterns, compacting, cross-functional Anthropic skills"
  - "Core + selected niche" — "Add framework/domain-specific skills after core"
  - "Niche only" — "Skip core, install specific framework/domain skills"
Default: Core only
```

ユーザーが niche または core + niche を選んだ場合、下記のカテゴリ選択に続けユーザーが選ぶ niche スキルのみ含める。

### 2b: スキルカテゴリを選ぶ

以下に 7 つの選択可能カテゴリグループがある。続く詳細確認リストは 8 カテゴリにわたる 45 スキル、加えてスタンドアロンテンプレート 1 件をカバーする。`multiSelect: true` で `AskUserQuestion` を使う:

```
Question: "Which skill categories do you want to install?"
Options:
  - "Framework & Language" — "Django, Laravel, Spring Boot, Quarkus, Go, Python, Java, Frontend, Backend patterns"
  - "Database" — "PostgreSQL, ClickHouse, JPA/Hibernate patterns"
  - "Workflow & Quality" — "TDD, verification, learning, security review, compaction"
  - "Research & APIs" — "Deep research, Exa search, Claude API patterns"
  - "Social & Content Distribution" — "X/Twitter API, crossposting alongside content-engine"
  - "Media Generation" — "fal.ai image/video/audio alongside VideoDB"
  - "Orchestration" — "dmux multi-agent workflows"
  - "All skills" — "Install every available skill"
```

### 2c: 個別スキルを確認

選択された各カテゴリについて、下記の完全なスキルリストを表示し、ユーザーに特定のものを確認または選択解除するよう依頼する。リストが 4 項目を超える場合、リストをテキストとして表示し、「Install all listed」オプションと特定の名前を貼り付けるための「Other」を含めた `AskUserQuestion` を使う。

**Category: Framework & Language (25 skills)**

(原文の詳細リストは英語のまま保持 — スキル ID と説明のため変更不要)

| Skill | Description |
|-------|-------------|
| `backend-patterns` | Backend architecture, API design, server-side best practices for Node.js/Express/Next.js |
| `coding-standards` | Universal coding standards for TypeScript, JavaScript, React, Node.js |
| `django-patterns` | Django architecture, REST API with DRF, ORM, caching, signals, middleware |
| `django-security` | Django security: auth, CSRF, SQL injection, XSS prevention |
| `django-tdd` | Django testing with pytest-django, factory_boy, mocking, coverage |
| `django-verification` | Django verification loop: migrations, linting, tests, security scans |
| `laravel-patterns` | Laravel architecture patterns: routing, controllers, Eloquent, queues, caching |
| `laravel-security` | Laravel security: auth, policies, CSRF, mass assignment, rate limiting |
| `laravel-tdd` | Laravel testing with PHPUnit and Pest, factories, fakes, coverage |
| `laravel-verification` | Laravel verification: linting, static analysis, tests, security scans |
| `frontend-patterns` | React, Next.js, state management, performance, UI patterns |
| `frontend-slides` | Zero-dependency HTML presentations, style previews, and PPTX-to-web conversion |
| `golang-patterns` | Idiomatic Go patterns, conventions for robust Go applications |
| `golang-testing` | Go testing: table-driven tests, subtests, benchmarks, fuzzing |
| `java-coding-standards` | Java coding standards for Spring Boot and Quarkus: naming, immutability, Optional, streams, CDI |
| `python-patterns` | Pythonic idioms, PEP 8, type hints, best practices |
| `python-testing` | Python testing with pytest, TDD, fixtures, mocking, parametrization |
| `quarkus-patterns` | Quarkus architecture, Camel messaging, CDI services, Panache data access |
| `quarkus-security` | Quarkus security: JWT/OIDC, RBAC, input validation, secrets management |
| `quarkus-tdd` | Quarkus TDD with JUnit 5, Mockito, REST Assured, Camel testing |
| `quarkus-verification` | Quarkus verification: build, static analysis, tests, native compilation |
| `springboot-patterns` | Spring Boot architecture, REST API, layered services, caching, async |
| `springboot-security` | Spring Security: authn/authz, validation, CSRF, secrets, rate limiting |
| `springboot-tdd` | Spring Boot TDD with JUnit 5, Mockito, MockMvc, Testcontainers |
| `springboot-verification` | Spring Boot verification: build, static analysis, tests, security scans |

**Category: Database (3 skills)**

| Skill | Description |
|-------|-------------|
| `clickhouse-io` | ClickHouse patterns, query optimization, analytics, data engineering |
| `jpa-patterns` | JPA/Hibernate entity design, relationships, query optimization, transactions |
| `postgres-patterns` | PostgreSQL query optimization, schema design, indexing, security |

**Category: Workflow & Quality (8 skills)**

| Skill | Description |
|-------|-------------|
| `continuous-learning` | Legacy v1 Stop-hook session pattern extraction; prefer `continuous-learning-v2` for new installs |
| `continuous-learning-v2` | Instinct-based learning with confidence scoring, evolves into skills, agents, and optional legacy command shims |
| `eval-harness` | Formal evaluation framework for eval-driven development (EDD) |
| `iterative-retrieval` | Progressive context refinement for subagent context problem |
| `security-review` | Security checklist: auth, input, secrets, API, payment features |
| `strategic-compact` | Suggests manual context compaction at logical intervals |
| `tdd-workflow` | Enforces TDD with 80%+ coverage: unit, integration, E2E |
| `verification-loop` | Verification and quality loop patterns |

**Category: Business & Content (5 skills)**

| Skill | Description |
|-------|-------------|
| `article-writing` | Long-form writing in a supplied voice using notes, examples, or source docs |
| `content-engine` | Multi-platform social content, scripts, and repurposing workflows |
| `market-research` | Source-attributed market, competitor, fund, and technology research |
| `investor-materials` | Pitch decks, one-pagers, investor memos, and financial models |
| `investor-outreach` | Personalized investor cold emails, warm intros, and follow-ups |

**Category: Research & APIs (2 skills)**

| Skill | Description |
|-------|-------------|
| `deep-research` | Multi-source deep research using firecrawl and exa MCPs with cited reports |
| `exa-search` | Neural search via Exa MCP for web, code, company, and people research |

`claude-api` は Anthropic の正規スキルである。ECC バンドルコピーの代わりに公式 Claude API ワークフローが欲しいときは [`anthropics/skills`](https://github.com/anthropics/skills) からインストールする。

**Category: Social & Content Distribution (2 skills)**

| Skill | Description |
|-------|-------------|
| `x-api` | X/Twitter API integration for posting, threads, search, and analytics |
| `crosspost` | Multi-platform content distribution with platform-native adaptation |

**Category: Media Generation (2 skills)**

| Skill | Description |
|-------|-------------|
| `fal-ai-media` | Unified AI media generation (image, video, audio) via fal.ai MCP |
| `video-editing` | AI-assisted video editing for cutting, structuring, and augmenting real footage |

**Category: Orchestration (1 skill)**

| Skill | Description |
|-------|-------------|
| `dmux-workflows` | Multi-agent orchestration using dmux for parallel agent sessions |

**Standalone**

| Skill | Description |
|-------|-------------|
| `docs/examples/project-guidelines-template.md` | Template for creating project-specific skills |

### 2d: インストール実行

選択された各スキルについて、正しいソースルートからスキルディレクトリ全体をコピーする:

```bash
# Core skills live under .agents/skills/
cp -R "$ECC_ROOT/.agents/skills/<skill-name>" "$TARGET/skills/"

# Niche skills live under skills/
cp -R "$ECC_ROOT/skills/<skill-name>" "$TARGET/skills/"
```

glob されたソースディレクトリを反復処理する際、決して末尾スラッシュ付きソースを直接 `cp` に渡さない。明示的にディレクトリパスを宛先名として使う:

```bash
cp -R "${src%/}" "$TARGET/skills/$(basename "${src%/}")"
```

注: `continuous-learning` と `continuous-learning-v2` は追加ファイル (config.json・hooks・scripts) を持つ — SKILL.md だけでなくディレクトリ全体がコピーされることを確認する。

---

## Step 3: ルールを選択 & インストール

`multiSelect: true` で `AskUserQuestion` を使う:

```
Question: "Which rule sets do you want to install?"
Options:
  - "Common rules (Recommended)" — "Language-agnostic principles: coding style, git workflow, testing, security, etc. (8 files)"
  - "TypeScript/JavaScript" — "TS/JS patterns, hooks, testing with Playwright (5 files)"
  - "Python" — "Python patterns, pytest, black/ruff formatting (5 files)"
  - "Go" — "Go patterns, table-driven tests, gofmt/staticcheck (5 files)"
```

インストールを実行する:
```bash
# Common rules
cp -r $ECC_ROOT/rules/common $TARGET/rules/common

# Language-specific rules (preserve per-language directories)
cp -r $ECC_ROOT/rules/typescript $TARGET/rules/typescript   # if selected
cp -r $ECC_ROOT/rules/python $TARGET/rules/python            # if selected
cp -r $ECC_ROOT/rules/golang $TARGET/rules/golang            # if selected
```

**重要**: ユーザーが言語固有ルールを選択するが共通ルールを選択しない場合、警告する:
> 「言語固有ルールは共通ルールを拡張する。共通ルールなしのインストールはカバレッジ不完全になりうる。共通ルールもインストールするか?」

---

## Step 4: インストール後検証

インストール後、これらの自動チェックを実行する:

### 4a: ファイル存在の検証

インストールされたすべてのファイルをリストし、ターゲット場所に存在することを確認する:
```bash
ls -la $TARGET/skills/
ls -la $TARGET/rules/
```

### 4b: パス参照のチェック

インストールされたすべての `.md` ファイルをスキャンしてパス参照を見つける:
```bash
grep -rn "~/.claude/" $TARGET/skills/ $TARGET/rules/
grep -rn "../common/" $TARGET/rules/
grep -rn "skills/" $TARGET/skills/
```

**プロジェクトレベルインストールでは**、`~/.claude/` パスへの参照をフラグする:
- スキルが `~/.claude/settings.json` を参照する場合 — これは通常問題ない (設定は常にユーザーレベル)
- スキルが `~/.claude/skills/` や `~/.claude/rules/` を参照する場合 — プロジェクトレベルのみインストールでは壊れている可能性
- スキルが別のスキルを名前で参照する場合 — 参照されるスキルもインストールされたか確認

### 4c: スキル間の相互参照をチェック

一部のスキルは他を参照する。これらの依存関係を検証する:
- `django-tdd` は `django-patterns` を参照することがある
- `laravel-tdd` は `laravel-patterns` を参照することがある
- `quarkus-tdd` は `quarkus-patterns` を参照することがある
- `springboot-tdd` は `springboot-patterns` を参照することがある
- `continuous-learning-v2` は `~/.claude/homunculus/` ディレクトリを参照する
- `python-testing` は `python-patterns` を参照することがある
- `golang-testing` は `golang-patterns` を参照することがある
- `crosspost` は `content-engine` と `x-api` を参照する
- `deep-research` は `exa-search` を参照する (補完的 MCP ツール)
- `fal-ai-media` は `videodb` を参照する (補完的メディアスキル)
- `x-api` は `content-engine` と `crosspost` を参照する
- 言語固有ルールは `common/` 相当物を参照する

### 4d: 問題を報告

見つかった各問題について、報告する:
1. **File**: 問題のある参照を含むファイル
2. **Line**: 行番号
3. **Issue**: 何が間違っているか (例:「`~/.claude/skills/python-patterns` を参照するが python-patterns がインストールされていない」)
4. **Suggested fix**: 何をすべきか (例:「python-patterns スキルをインストール」「パスを `.claude/skills/` に更新」)

---

## Step 5: インストール済みファイルを最適化 (オプション)

`AskUserQuestion` を使う:

```
Question: "Would you like to optimize the installed files for your project?"
Options:
  - "Optimize skills" — "Remove irrelevant sections, adjust paths, tailor to your tech stack"
  - "Optimize rules" — "Adjust coverage targets, add project-specific patterns, customize tool configs"
  - "Optimize both" — "Full optimization of all installed files"
  - "Skip" — "Keep everything as-is"
```

### スキル最適化の場合:
1. インストール済み各 SKILL.md を読む
2. プロジェクトの技術スタックをユーザーに尋ねる (既知でなければ)
3. 各スキルについて、無関係なセクションの削除を提案
4. インストールターゲットで SKILL.md ファイルをその場で編集 (ソースリポジトリではない)
5. Step 4 で見つかったパス問題を修正

### ルール最適化の場合:
1. インストール済み各ルール .md ファイルを読む
2. ユーザーの好みを尋ねる:
   - テストカバレッジ目標 (デフォルト 80%)
   - 好みのフォーマットツール
   - Git ワークフロー規約
   - セキュリティ要件
3. インストールターゲットでルールファイルをその場で編集

**重要**: インストールターゲット (`$TARGET/`) 内のファイルのみ修正、ソース ECC リポジトリ (`$ECC_ROOT/`) のファイルを決して修正しないこと。

---

## Step 6: インストールサマリ

`/tmp` からクローン済みリポジトリをクリーンアップする:

```bash
rm -rf /tmp/everything-claude-code
```

次にサマリレポートを表示する:

```
## ECC Installation Complete

### Installation Target
- Level: [user-level / project-level / both]
- Path: [target path]

### Skills Installed ([count])
- skill-1, skill-2, skill-3, ...

### Rules Installed ([count])
- common (8 files)
- typescript (5 files)
- ...

### Verification Results
- [count] issues found, [count] fixed
- [list any remaining issues]

### Optimizations Applied
- [list changes made, or "None"]
```

---

## トラブルシューティング

### 「スキルが Claude Code に拾われない」
- スキルディレクトリに `SKILL.md` ファイルが含まれているか確認する (緩い .md ファイルだけではない)
- ユーザーレベル: `~/.claude/skills/<skill-name>/SKILL.md` が存在することをチェック
- プロジェクトレベル: `.claude/skills/<skill-name>/SKILL.md` が存在することをチェック

### 「ルールが機能しない」
- ルールはサブディレクトリではなくフラットファイル: `$TARGET/rules/coding-style.md` (正しい) vs `$TARGET/rules/common/coding-style.md` (フラットインストールでは誤り)
- ルールインストール後に Claude Code を再起動

### 「プロジェクトレベルインストール後のパス参照エラー」
- 一部のスキルは `~/.claude/` パスを前提とする。これらを見つけ修正するために Step 4 検証を実行する。
- `continuous-learning-v2` では、`~/.claude/homunculus/` ディレクトリは常にユーザーレベルである — これは期待されており、エラーではない。

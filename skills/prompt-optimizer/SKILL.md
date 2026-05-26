---
name: prompt-optimizer
description: >-
  生のプロンプトを分析し、意図とギャップを識別し、ECC コンポーネント
  (skills/commands/agents/hooks) とマッチングし、貼り付け可能な最適化済み
  プロンプトを出力する。アドバイザリの役割のみ — タスク自体は実行しない
  （prompt optimizer / optimize prompt / improve prompt / rewrite prompt /
  プロンプト最適化 / プロンプト改善 / プロンプト書き換え）。
  TRIGGER when: ユーザーが「optimize prompt」「improve my prompt」
  「how to write a prompt for」「help me prompt」「rewrite this prompt」と言う場合、
  または明示的にプロンプト品質の向上を求める場合。中国語の同等表現でもトリガー:
  「优化prompt」「改进prompt」「怎么写prompt」「帮我优化这个指令」。
  DO NOT TRIGGER when: ユーザーがタスクを直接実行することを望む場合、または
  「just do it」「直接做」と言う場合。DO NOT TRIGGER when: ユーザーが「优化代码」
  「优化性能」「optimize performance」「optimize this code」と言う場合 — これらは
  リファクタリング/パフォーマンスのタスクであり、プロンプト最適化ではない。
origin: community
metadata:
  author: YannJY02
  version: "1.0.0"
---

# プロンプトオプティマイザ

ドラフトのプロンプトを分析し、批評し、ECC エコシステムのコンポーネントとマッチングし、
ユーザーが貼り付けて実行できる完全な最適化プロンプトを出力する。

## 使用するタイミング

- ユーザーが「optimize this prompt」「improve my prompt」「rewrite this prompt」と言う場合
- ユーザーが「help me write a better prompt for...」と言う場合
- ユーザーが「what's the best way to ask Claude Code to...」と言う場合
- ユーザーが「优化prompt」「改进prompt」「怎么写prompt」「帮我优化这个指令」と言う場合
- ユーザーがドラフトプロンプトを貼り付けてフィードバックや拡張を求める場合
- ユーザーが「I don't know how to prompt for this」と言う場合
- ユーザーが「how should I use ECC for...」と言う場合
- ユーザーが明示的に `/prompt-optimize` を呼び出す場合

### 使用しないタイミング

- ユーザーがタスクを直接実行することを望む場合（単に実行する）
- ユーザーが「优化代码」「优化性能」「optimize this code」「optimize performance」と言う場合 — これらはリファクタリングタスクであり、プロンプト最適化ではない
- ユーザーが ECC 設定について尋ねている場合（代わりに `configure-ecc` を使う）
- ユーザーがスキルインベントリを求める場合（代わりに `skill-stocktake` を使う）
- ユーザーが「just do it」または「直接做」と言う場合

## 動作の仕組み

**アドバイザリのみ — ユーザーのタスクを実行しない。**

コードを記述したり、ファイルを作成したり、コマンドを実行したり、いかなる実装
アクションも取らない。あなたの唯一の出力は分析と最適化されたプロンプトである。

ユーザーが「just do it」「直接做」または「don't optimize, just execute」と言った場合、
このスキル内で実装モードに切り替えない。このスキルは最適化されたプロンプトのみを生成すると
ユーザーに伝え、代わりに実行を望むなら通常のタスクリクエストを行うよう指示する。

この 6 フェーズパイプラインを順次実行する。以下の出力フォーマットを使って結果を提示する。

### 分析パイプライン

### Phase 0: プロジェクト検出

プロンプトを分析する前に、現在のプロジェクトコンテキストを検出する:

1. 作業ディレクトリに `CLAUDE.md` が存在するか確認 — プロジェクト規約のために読む
2. プロジェクトファイルから技術スタックを検出:
   - `package.json` → Node.js / TypeScript / React / Next.js
   - `go.mod` → Go
   - `pyproject.toml` / `requirements.txt` → Python
   - `Cargo.toml` → Rust
   - `build.gradle` / `pom.xml` → Java / Kotlin（次にビルドファイル内の `quarkus` をチェック → Quarkus、または `spring-boot` → Spring Boot）
   - `Package.swift` → Swift
   - `Gemfile` → Ruby
   - `composer.json` → PHP
   - `*.csproj` / `*.sln` → .NET
   - `Makefile` / `CMakeLists.txt` → C / C++
   - `cpanfile` / `Makefile.PL` → Perl
3. Phase 3 と Phase 4 で使用するために検出された技術スタックをメモする

プロジェクトファイルが見つからない場合（例: プロンプトが抽象的または新規プロジェクト向け）、
検出をスキップし、Phase 4 で「技術スタック不明」とフラグを立てる。

### Phase 1: 意図検出

ユーザーのタスクを 1 つ以上のカテゴリに分類する:

| カテゴリ | シグナルワード | 例 |
|----------|-------------|---------|
| New Feature | build, create, add, implement, 创建, 实现, 添加 | "Build a login page" |
| Bug Fix | fix, broken, not working, error, 修复, 报错 | "Fix the auth flow" |
| Refactor | refactor, clean up, restructure, 重构, 整理 | "Refactor the API layer" |
| Research | how to, what is, explore, investigate, 怎么, 如何 | "How to add SSO" |
| Testing | test, coverage, verify, 测试, 覆盖率 | "Add tests for the cart" |
| Review | review, audit, check, 审查, 检查 | "Review my PR" |
| Documentation | document, update docs, 文档 | "Update the API docs" |
| Infrastructure | deploy, CI, docker, database, 部署, 数据库 | "Set up CI/CD pipeline" |
| Design | design, architecture, plan, 设计, 架构 | "Design the data model" |

### Phase 2: スコープ評価

Phase 0 がプロジェクトを検出した場合、コードベースサイズをシグナルとして使う。それ以外の場合、
プロンプト記述のみから推定し、その推定を不確実とマークする。

| スコープ | ヒューリスティック | オーケストレーション |
|-------|-----------|---------------|
| TRIVIAL | 単一ファイル、50 行未満 | 直接実行 |
| LOW | 単一コンポーネントまたはモジュール | 単一コマンドまたはスキル |
| MEDIUM | 複数コンポーネント、同じドメイン | コマンドチェーン + /verify |
| HIGH | ドメイン横断、5 ファイル以上 | まず /plan、次に段階的実行 |
| EPIC | マルチセッション、マルチ PR、アーキテクチャシフト | マルチセッション計画には blueprint スキルを使用 |

### Phase 3: ECC コンポーネントマッチング

意図 + スコープ + 技術スタック（Phase 0 から）を特定の ECC コンポーネントにマップする。

#### 意図タイプ別

| 意図 | Commands | Skills | Agents |
|--------|----------|--------|--------|
| New Feature | /plan, /tdd, /code-review, /verify | tdd-workflow, verification-loop | planner, tdd-guide, code-reviewer |
| Bug Fix | /tdd, /build-fix, /verify | tdd-workflow | tdd-guide, build-error-resolver |
| Refactor | /refactor-clean, /code-review, /verify | verification-loop | refactor-cleaner, code-reviewer |
| Research | /plan | search-first, iterative-retrieval | — |
| Testing | /tdd, /e2e, /test-coverage | tdd-workflow, e2e-testing | tdd-guide, e2e-runner |
| Review | /code-review | security-review | code-reviewer, security-reviewer |
| Documentation | /update-docs, /update-codemaps | — | doc-updater |
| Infrastructure | /plan, /verify | docker-patterns, deployment-patterns, database-migrations | architect |
| Design (MEDIUM-HIGH) | /plan | — | planner, architect |
| Design (EPIC) | — | blueprint (スキルとして呼び出し) | planner, architect |

#### 技術スタック別

| 技術スタック | 追加するスキル | Agent |
|------------|--------------|-------|
| Python / Django | django-patterns, django-tdd, django-security, django-verification, python-patterns, python-testing | python-reviewer |
| Go | golang-patterns, golang-testing | go-reviewer, go-build-resolver |
| Spring Boot / Java | springboot-patterns, springboot-tdd, springboot-security, springboot-verification, java-coding-standards, jpa-patterns | java-reviewer |
| Quarkus / Java | quarkus-patterns, quarkus-tdd, quarkus-security, quarkus-verification, java-coding-standards, jpa-patterns | java-reviewer |
| Kotlin / Android | kotlin-coroutines-flows, compose-multiplatform-patterns, android-clean-architecture | kotlin-reviewer |
| TypeScript / React | frontend-patterns, backend-patterns, coding-standards | code-reviewer |
| Swift / iOS | swiftui-patterns, swift-concurrency-6-2, swift-actor-persistence, swift-protocol-di-testing | code-reviewer |
| PostgreSQL | postgres-patterns, database-migrations | database-reviewer |
| Perl | perl-patterns, perl-testing, perl-security | code-reviewer |
| C++ | cpp-coding-standards, cpp-testing | code-reviewer |
| Other / Unlisted | coding-standards (universal) | code-reviewer |

### Phase 4: 欠落コンテキスト検出

プロンプトをスキャンして欠落している重要情報を確認する。各項目をチェックし、
Phase 0 が自動検出したか、ユーザーが供給する必要があるかをマークする:

- [ ] **技術スタック** — Phase 0 で検出済みか、ユーザーが指定する必要があるか?
- [ ] **対象スコープ** — ファイル、ディレクトリ、またはモジュールが言及されているか?
- [ ] **受け入れ基準** — タスクが完了したことをどう知るか?
- [ ] **エラー処理** — エッジケースと失敗モードに対処しているか?
- [ ] **セキュリティ要件** — 認証、入力検証、シークレット?
- [ ] **テスト期待値** — Unit、Integration、E2E?
- [ ] **パフォーマンス制約** — 負荷、レイテンシ、リソース制限?
- [ ] **UI/UX 要件** — デザイン仕様、レスポンシブ、a11y?（フロントエンドの場合）
- [ ] **データベース変更** — スキーマ、マイグレーション、インデックス?（データレイヤーの場合）
- [ ] **既存パターン** — 従うべき参照ファイルや規約?
- [ ] **スコープ境界** — してはいけないこと?

**3 つ以上の重要項目が欠落している場合**、最適化されたプロンプトを生成する前に、
ユーザーに最大 3 つの明確化質問をする。その後、回答を最適化されたプロンプトに組み込む。

### Phase 5: ワークフロー & モデル推奨

このプロンプトが開発ライフサイクルのどこに位置するかを判断する:

```
Research → Plan → Implement (TDD) → Review → Verify → Commit
```

MEDIUM+ タスクの場合、常に /plan で開始する。EPIC タスクの場合、blueprint スキルを使う。

**モデル推奨**（出力に含める）:

| スコープ | 推奨モデル | 根拠 |
|-------|------------------|-----------|
| TRIVIAL-LOW | Sonnet 4.6 | 単純なタスクに高速かつコスト効率的 |
| MEDIUM | Sonnet 4.6 | 標準作業に最適なコーディングモデル |
| HIGH | Sonnet 4.6 (main) + Opus 4.6 (planning) | アーキテクチャに Opus、実装に Sonnet |
| EPIC | Opus 4.6 (blueprint) + Sonnet 4.6 (execution) | マルチセッション計画のための深い推論 |

**マルチプロンプト分割**（HIGH/EPIC スコープ向け）:

単一セッションを超えるタスクの場合、順次プロンプトに分割する:
- Prompt 1: Research + Plan（search-first スキル使用、次に /plan）
- Prompt 2-N: 各プロンプトで 1 フェーズを実装（各 /verify で終わる）
- Final Prompt: 全フェーズ横断の Integration test + /code-review
- セッション間のコンテキストを保持するために /save-session と /resume-session を使う

---

## 出力フォーマット

この正確な構造で分析を提示する。ユーザーの入力と同じ言語で応答する。

### Section 1: プロンプト診断

**強み:** 元のプロンプトがうまくやっていることをリストする。

**問題:**

| 問題 | 影響 | 提案される修正 |
|-------|--------|---------------|
| (problem) | (consequence) | (how to fix) |

**明確化が必要:** ユーザーが回答すべき質問の番号付きリスト。
Phase 0 が自動検出した場合は、尋ねる代わりに述べる。

### Section 2: 推奨される ECC コンポーネント

| タイプ | コンポーネント | 目的 |
|------|-----------|---------|
| Command | /plan | コーディング前にアーキテクチャを計画 |
| Skill | tdd-workflow | TDD 方法論ガイダンス |
| Agent | code-reviewer | 実装後レビュー |
| Model | Sonnet 4.6 | このスコープに推奨 |

### Section 3: 最適化プロンプト — フルバージョン

完全な最適化プロンプトを単一のフェンス付きコードブロック内に提示する。
プロンプトは自己完結的でコピー＆ペースト準備完了でなければならない。以下を含める:
- コンテキスト付きの明確なタスク記述
- 技術スタック（検出済みまたは指定済み）
- 適切なワークフロー段階での /command 呼び出し
- 受け入れ基準
- 検証ステップ
- スコープ境界（してはいけないこと）

blueprint を参照する項目については、`/blueprint` ではなく
「Use the blueprint skill to...」と書く（blueprint はコマンドではなくスキルだから）。

### Section 4: 最適化プロンプト — クイックバージョン

経験豊富な ECC ユーザー向けのコンパクトバージョン。意図タイプによって異なる:

| 意図 | クイックパターン |
|--------|--------------|
| New Feature | `/plan [feature]. /tdd to implement. /code-review. /verify.` |
| Bug Fix | `/tdd — write failing test for [bug]. Fix to green. /verify.` |
| Refactor | `/refactor-clean [scope]. /code-review. /verify.` |
| Research | `Use search-first skill for [topic]. /plan based on findings.` |
| Testing | `/tdd [module]. /e2e for critical flows. /test-coverage.` |
| Review | `/code-review. Then use security-reviewer agent.` |
| Docs | `/update-docs. /update-codemaps.` |
| EPIC | `Use blueprint skill for "[objective]". Execute phases with /verify gates.` |

### Section 5: 拡張根拠

| 拡張 | 理由 |
|-------------|--------|
| (what was added) | (why it matters) |

### フッター

> 必要なものではないか? 何を調整するか教えるか、プロンプト最適化ではなく実行を望むなら
> 通常のタスクリクエストをすること。

---

## 例

### トリガー例

- "Optimize this prompt for ECC"
- "Rewrite this prompt so Claude Code uses the right commands"
- "帮我优化这个指令"
- "How should I prompt ECC for this task?"

### 例 1: 曖昧な中国語プロンプト（プロジェクト検出済み）

**ユーザー入力:**
```
帮我写一个用户登录页面
```

**Phase 0 が検出:** Next.js 15、TypeScript、Tailwind CSS を含む `package.json`

**最適化プロンプト（フル）:**
```
使用项目现有技术栈（Next.js 15 + TypeScript + Tailwind CSS）实现用户登录页面。

技术要求：
- 沿用项目现有的组件结构和路由约定
- 表单验证使用项目中已有的验证方案（检查是否已用 Zod/Yup/其他）
- 认证方式：沿用项目现有认证方案（如无，默认 JWT）
- 包含：邮箱/密码登录表单、表单验证、错误提示、加载状态、响应式布局

工作流：
1. /plan 先规划组件结构和认证流程，参考现有页面的模式
2. /tdd 测试先行：编写登录表单的单元测试和认证流程的集成测试
3. 实现登录页面和认证逻辑
4. /code-review 审查实现
5. /verify 验证所有测试通过且页面正常渲染

安全要求：
- 密码不明文传输
- 防止暴力破解（rate limiting）
- XSS 防护
- CSRF token

验收标准：
- 所有测试通过，覆盖率 80%+
- 页面在移动端和桌面端正常渲染
- 登录成功跳转到 dashboard，失败显示错误信息

不要做：
- 不要实现注册页面
- 不要实现忘记密码功能
- 不要修改现有的路由结构
```

### 例 2: 中程度の英語プロンプト

**ユーザー入力:**
```
Add a REST API endpoint for user profile updates with validation
```

**Phase 0 が検出:** Go 1.22、Chi router を含む `go.mod`

**最適化プロンプト（フル）:**
```
Add a REST API endpoint for user profile updates (PATCH /api/users/:id).

Tech stack: Go 1.22 + Chi router (detected from project)

Requirements:
- PATCH /api/users/:id — partial update of user profile
- Input validation for fields: name, email, avatar_url, bio
- Auth: require valid token, users can only update own profile
- Return 200 with updated user on success
- Return 400 with validation errors on invalid input
- Return 401/403 for auth failures
- Follow existing API patterns in the codebase

Workflow:
1. /plan the endpoint structure, middleware chain, and validation logic
2. /tdd — write table-driven tests for success, validation failure, auth failure, not-found
3. Implement following existing handler patterns
4. /go-review
5. /verify — run full test suite, confirm no regressions

Do not:
- Modify existing endpoints
- Change the database schema (use existing user table)
- Add new dependencies without checking existing ones first (use search-first skill)
```

### 例 3: EPIC プロジェクト

**ユーザー入力:**
```
Migrate our monolith to microservices
```

**最適化プロンプト（フル）:**
```
Use the blueprint skill to plan: "Migrate monolith to microservices architecture"

Before executing, answer these questions in the blueprint:
1. Which domain boundaries exist in the current monolith?
2. Which service should be extracted first (lowest coupling)?
3. Communication pattern: REST APIs, gRPC, or event-driven (Kafka/RabbitMQ)?
4. Database strategy: shared DB initially or database-per-service from start?
5. Deployment target: Kubernetes, Docker Compose, or serverless?

The blueprint should produce phases like:
- Phase 1: Identify service boundaries and create domain map
- Phase 2: Set up infrastructure (API gateway, service mesh, CI/CD per service)
- Phase 3: Extract first service (strangler fig pattern)
- Phase 4: Verify with integration tests, then extract next service
- Phase N: Decommission monolith

Each phase = 1 PR, with /verify gates between phases.
Use /save-session between phases. Use /resume-session to continue.
Use git worktrees for parallel service extraction when dependencies allow.

Recommended: Opus 4.6 for blueprint planning, Sonnet 4.6 for phase execution.
```

---

## 関連コンポーネント

| コンポーネント | 参照するタイミング |
|-----------|------------------|
| `configure-ecc` | ユーザーがまだ ECC をセットアップしていない場合 |
| `skill-stocktake` | どのコンポーネントがインストールされているかを監査する（ハードコードされたカタログの代わりに使用） |
| `search-first` | 最適化プロンプトのリサーチフェーズ |
| `blueprint` | EPIC スコープの最適化プロンプト（コマンドではなくスキルとして呼び出す） |
| `strategic-compact` | 長いセッションコンテキスト管理 |
| `cost-aware-llm-pipeline` | トークン最適化推奨 |

# スキル開発ガイド

Everything Claude Code (ECC) 用の効果的なスキル作成の包括的ガイド。

## 目次

- [スキルとは何か?](#スキルとは何か)
- [スキルアーキテクチャ](#スキルアーキテクチャ)
- [最初のスキル作成](#最初のスキル作成)
- [スキルカテゴリ](#スキルカテゴリ)
- [効果的なスキルコンテンツの書き方](#効果的なスキルコンテンツの書き方)
- [ベストプラクティス](#ベストプラクティス)
- [共通パターン](#共通パターン)
- [スキルのテスト](#スキルのテスト)
- [スキルの提出](#スキルの提出)
- [例ギャラリー](#例ギャラリー)

---

## スキルとは何か?

スキルは Claude Code がコンテキストに基づいてロードする **知識モジュール** である。以下を提供する:

- **ドメイン専門知識**: フレームワークパターン、言語イディオム、ベストプラクティス
- **ワークフロー定義**: 一般的タスクのステップバイステッププロセス
- **リファレンス資料**: コードスニペット、チェックリスト、決定木
- **コンテキスト注入**: 特定条件が満たされたときにアクティブ化

**エージェント** (専門サブアシスタント) や **コマンド** (ユーザートリガアクション) と異なり、スキルは Claude Code が関連時に参照する受動的知識である。

### スキルがアクティブ化するとき

スキルは以下のときにアクティブ化する:
- ユーザーのタスクがスキルのドメインに合致する
- Claude Code が関連コンテキストを検出する
- コマンドがスキルを参照する
- エージェントがドメイン知識を必要とする

### Skill vs Agent vs Command

| コンポーネント | 目的 | アクティベーション |
|--------------|------|--------------------|
| **Skill** | 知識リポジトリ | コンテキストベース (自動) |
| **Agent** | タスクエクゼキュータ | 明示的委任 |
| **Command** | ユーザーアクション | ユーザー起動 (`/command`) |
| **Hook** | 自動化 | イベントトリガ |
| **Rule** | 常時ガイドライン | 常時アクティブ |

---

## スキルアーキテクチャ

### ファイル構造

```
skills/
└── your-skill-name/
    ├── SKILL.md           # Required: Main skill definition
    ├── examples/          # Optional: Code examples
    │   ├── basic.ts
    │   └── advanced.ts
    └── references/        # Optional: External references
        └── links.md
```

### SKILL.md 形式

```markdown
---
name: skill-name
description: Brief description shown in skill list and used for auto-activation
origin: ECC
---

# Skill Title

Brief overview of what this skill covers.

## When to Activate

Describe scenarios where Claude should use this skill.

## Core Concepts

Main patterns and guidelines.

## Code Examples

\`\`\`typescript
// Practical, tested examples
\`\`\`

## Anti-Patterns

Show what NOT to do with concrete examples.

## Best Practices

- Actionable guidelines
- Do's and don'ts

## Related Skills

Link to complementary skills.
```

### YAML Frontmatter フィールド

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | はい | 小文字・ハイフン区切り識別子 (例: `react-patterns`) |
| `description` | はい | スキルリストと自動アクティベーション用の 1 行説明 |
| `origin` | いいえ | ソース識別子 (例: `ECC`、`community`、プロジェクト名) |
| `tags` | いいえ | 分類用タグの配列 |
| `version` | いいえ | 更新追跡用スキルバージョン |

---

## 最初のスキル作成

### Step 1: フォーカスを選ぶ

良いスキルは **フォーカスされ実行可能** である:

| PASS: 良いフォーカス | FAIL: 広すぎる |
|---------------------|---------------|
| `react-hook-patterns` | `react` |
| `postgresql-indexing` | `databases` |
| `pytest-fixtures` | `python-testing` |
| `nextjs-app-router` | `nextjs` |

### Step 2: ディレクトリを作成

```bash
mkdir -p skills/your-skill-name
```

### Step 3: SKILL.md を書く

最小限テンプレート:

```markdown
---
name: your-skill-name
description: Brief description of when to use this skill
---

# Your Skill Title

Brief overview (1-2 sentences).

## When to Activate

- Scenario 1
- Scenario 2
- Scenario 3

## Core Concepts

### Concept 1

Explanation with examples.

### Concept 2

Another pattern with code.

## Code Examples

\`\`\`typescript
// Practical example
\`\`\`

## Best Practices

- Do this
- Avoid that

## Related Skills

- `related-skill-1`
- `related-skill-2`
```

### Step 4: コンテンツを追加

Claude が **即座に使える** コンテンツを書く:

- PASS: コピペ可能なコード例
- PASS: 明確な決定木
- PASS: 検証用チェックリスト
- FAIL: 例の無い曖昧な説明
- FAIL: 実行可能ガイダンスの無い長い散文

---

## スキルカテゴリ

### Language Standards

イディオマティックなコード、命名規約、言語固有パターンにフォーカスする。

**例:** `python-patterns`、`golang-patterns`、`typescript-standards`

```markdown
---
name: python-patterns
description: Python idioms, best practices, and patterns for clean, idiomatic code.
---

# Python Patterns

## When to Activate

- Writing Python code
- Refactoring Python modules
- Python code review

## Core Concepts

### Context Managers

\`\`\`python
# Always use context managers for resources
with open('file.txt') as f:
    content = f.read()
\`\`\`
```

### Framework Patterns

フレームワーク固有規約、共通パターン、アンチパターンにフォーカスする。

**例:** `django-patterns`、`nextjs-patterns`、`springboot-patterns`

```markdown
---
name: django-patterns
description: Django best practices for models, views, URLs, and templates.
---

# Django Patterns

## When to Activate

- Building Django applications
- Creating models and views
- Django URL configuration
```

### Workflow Skills

一般的開発タスクのステップバイステッププロセスを定義する。

**例:** `tdd-workflow`、`code-review-workflow`、`deployment-checklist`

```markdown
---
name: code-review-workflow
description: Systematic code review process for quality and security.
---

# Code Review Workflow

## Steps

1. **Understand Context** - Read PR description and linked issues
2. **Check Tests** - Verify test coverage and quality
3. **Review Logic** - Analyze implementation for correctness
4. **Check Security** - Look for vulnerabilities
5. **Verify Style** - Ensure code follows conventions
```

### Domain Knowledge

特定ドメイン (セキュリティ、パフォーマンスなど) の専門知識。

**例:** `security-review`、`performance-optimization`、`api-design`

```markdown
---
name: api-design
description: REST and GraphQL API design patterns, versioning, and best practices.
---

# API Design Patterns

## RESTful Conventions

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | /resources | List all |
| GET | /resources/:id | Get one |
| POST | /resources | Create |
```

### Tool Integration

特定ツール、ライブラリ、サービス使用のガイダンス。

**例:** `supabase-patterns`、`docker-patterns`、`mcp-server-patterns`

---

## 効果的なスキルコンテンツの書き方

### 1. "When to Activate" から始める

このセクションは自動アクティベーションに **クリティカル** である。具体的にする:

```markdown
## When to Activate

- Creating new React components
- Refactoring existing components
- Debugging React state issues
- Reviewing React code for best practices
```

### 2. 「言うのではなく見せる」を使う

悪い例:
```markdown
## Error Handling

Always handle errors properly in async functions.
```

良い例:
```markdown
## Error Handling

\`\`\`typescript
async function fetchData(url: string) {
  try {
    const response = await fetch(url)

    if (!response.ok) {
      throw new Error(\`HTTP \${response.status}: \${response.statusText}\`)
    }

    return await response.json()
  } catch (error) {
    console.error('Fetch failed:', error)
    throw new Error('Failed to fetch data')
  }
}
\`\`\`

### Key Points

- Check \`response.ok\` before parsing
- Log errors for debugging
- Re-throw with user-friendly message
```

### 3. アンチパターンを含める

何を *しない* かを示す:

```markdown
## Anti-Patterns

### FAIL: Direct State Mutation

\`\`\`typescript
// NEVER do this
user.name = 'New Name'
items.push(newItem)
\`\`\`

### PASS: Immutable Updates

\`\`\`typescript
// ALWAYS do this
const updatedUser = { ...user, name: 'New Name' }
const updatedItems = [...items, newItem]
\`\`\`
```

### 4. チェックリストを提供

チェックリストは実行可能で従いやすい:

```markdown
## Pre-Deployment Checklist

- [ ] All tests passing
- [ ] No console.log in production code
- [ ] Environment variables documented
- [ ] Secrets not hardcoded
- [ ] Error handling complete
- [ ] Input validation in place
```

### 5. 決定木を使う

複雑な決定用:

```markdown
## Choosing the Right Approach

\`\`\`
Need to fetch data?
├── Single request → use fetch directly
├── Multiple independent → Promise.all()
├── Multiple dependent → await sequentially
└── With caching → use SWR or React Query
\`\`\`
```

---

## ベストプラクティス

### DO

| 慣行 | 例 |
|------|-----|
| **具体的に** | "Use \`useCallback\` for event handlers passed to child components" |
| **例を示す** | コピペ可能なコードを含める |
| **WHY を説明** | "Immutability prevents unexpected side effects in React state" |
| **関連スキルをリンク** | "See also: \`react-performance\`" |
| **フォーカスを保つ** | 1 スキル = 1 ドメイン/コンセプト |
| **セクションを使う** | スキャンしやすい明確なヘッダ |

### DON'T

| 慣行 | なぜ悪いか |
|------|-----------|
| **曖昧に** | "Write good code" - 実行不可能 |
| **長い散文** | パースが難しい、コードの方が良い |
| **広すぎる** | "Python, Django, and Flask patterns" - 広すぎる |
| **例をスキップ** | 実践無しの理論は有用性が下がる |
| **アンチパターンを無視** | 何を *しない* かの学習は価値がある |

### コンテンツガイドライン

1. **長さ**: 標準 200-500 行、最大 800 行
2. **コードブロック**: 言語識別子を含める
3. **ヘッダ**: `##` と `###` 階層を使う
4. **リスト**: 順序無し `-`、順序付き `1.`
5. **テーブル**: 比較とリファレンス用

---

## 共通パターン

### Pattern 1: Standards スキル

```markdown
---
name: language-standards
description: Coding standards and best practices for [language].
---

# [Language] Coding Standards

## When to Activate

- Writing [language] code
- Code review
- Setting up linting

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Variables | camelCase | userName |
| Constants | SCREAMING_SNAKE | MAX_RETRY |
| Functions | camelCase | fetchUser |
| Classes | PascalCase | UserService |

## Code Examples

[Include practical examples]

## Linting Setup

[Include configuration]

## Related Skills

- `language-testing`
- `language-security`
```

### Pattern 2: Workflow スキル

```markdown
---
name: task-workflow
description: Step-by-step workflow for [task].
---

# [Task] Workflow

## When to Activate

- [Trigger 1]
- [Trigger 2]

## Prerequisites

- [Requirement 1]
- [Requirement 2]

## Steps

### Step 1: [Name]

[Description]

\`\`\`bash
[Commands]
\`\`\`

### Step 2: [Name]

[Description]

## Verification

- [ ] [Check 1]
- [ ] [Check 2]

## Troubleshooting

| Problem | Solution |
|---------|----------|
| [Issue] | [Fix] |
```

### Pattern 3: Reference スキル

```markdown
---
name: api-reference
description: Quick reference for [API/Library].
---

# [API/Library] Reference

## When to Activate

- Using [API/Library]
- Looking up [API/Library] syntax

## Common Operations

### Operation 1

\`\`\`typescript
// Basic usage
\`\`\`

### Operation 2

\`\`\`typescript
// Advanced usage
\`\`\`

## Configuration

[Include config examples]

## Error Handling

[Include error patterns]
```

---

## スキルのテスト

### ローカルテスト

1. **Claude Code スキルディレクトリにコピー**:
   ```bash
   cp -r skills/your-skill-name ~/.claude/skills/
   ```

2. **Claude Code でテスト**:
   ```
   You: "I need to [task that should trigger your skill]"

   Claude should reference your skill's patterns.
   ```

3. **アクティベーションを検証**:
   - Claude にスキルのコンセプトを説明してもらう
   - 例とパターンを使うかチェックする
   - ガイドラインに従うことを確認する

### 検証チェックリスト

- [ ] **YAML frontmatter が有効** - 構文エラー無し
- [ ] **name が規約に従う** - lowercase-with-hyphens
- [ ] **description が明確** - 利用タイミングを伝える
- [ ] **例が動作する** - コードがコンパイル・実行する
- [ ] **リンクが有効** - 関連スキルが存在する
- [ ] **機密データ無し** - API キー、トークン、パス無し

### コード例テスト

すべてのコード例をテストする:

```bash
# From the repo root
npx tsc --noEmit skills/your-skill-name/examples/*.ts

# Or from inside the skill directory
npx tsc --noEmit examples/*.ts

# From the repo root
python -m py_compile skills/your-skill-name/examples/*.py

# Or from inside the skill directory
python -m py_compile examples/*.py

# From the repo root
go build ./skills/your-skill-name/examples/...

# Or from inside the skill directory
go build ./examples/...
```

---

## スキルの提出

### 1. Fork and Clone

```bash
gh repo fork affaan-m/everything-claude-code --clone
cd everything-claude-code
```

### 2. ブランチ作成

```bash
git checkout -b feat/skill-your-skill-name
```

### 3. スキル追加

```bash
mkdir -p skills/your-skill-name
# Create SKILL.md
```

### 4. 検証

```bash
# Check YAML frontmatter
head -10 skills/your-skill-name/SKILL.md

# Verify structure
ls -la skills/your-skill-name/

# Run tests if available
npm test
```

### 5. Commit and Push

```bash
git add skills/your-skill-name/
git commit -m "feat(skills): add your-skill-name skill"
git push -u origin feat/skill-your-skill-name
```

### 6. プルリクエスト作成

この PR テンプレートを使う:

```markdown
## Summary

Brief description of the skill and why it's valuable.

## Skill Type

- [ ] Language standards
- [ ] Framework patterns
- [ ] Workflow
- [ ] Domain knowledge
- [ ] Tool integration

## Testing

How I tested this skill locally.

## Checklist

- [ ] YAML frontmatter valid
- [ ] Code examples tested
- [ ] Follows skill guidelines
- [ ] No sensitive data
- [ ] Clear activation triggers
```

---

## 例ギャラリー

### 例 1: Language Standards

**File:** `skills/rust-patterns/SKILL.md`

```markdown
---
name: rust-patterns
description: Rust idioms, ownership patterns, and best practices for safe, idiomatic code.
origin: ECC
---

# Rust Patterns

## When to Activate

- Writing Rust code
- Handling ownership and borrowing
- Error handling with Result/Option
- Implementing traits

## Ownership Patterns

### Borrowing Rules

\`\`\`rust
// PASS: CORRECT: Borrow when you don't need ownership
fn process_data(data: &str) -> usize {
    data.len()
}

// PASS: CORRECT: Take ownership when you need to modify or consume
fn consume_data(data: Vec<u8>) -> String {
    String::from_utf8(data).unwrap()
}
\`\`\`

## Error Handling

### Result Pattern

\`\`\`rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Parse error: {0}")]
    Parse(#[from] std::num::ParseIntError),
}

pub type AppResult<T> = Result<T, AppError>;
\`\`\`

## Related Skills

- `rust-testing`
- `rust-security`
```

### 例 2: Framework Patterns

**File:** `skills/fastapi-patterns/SKILL.md`

```markdown
---
name: fastapi-patterns
description: FastAPI patterns for routing, dependency injection, validation, and async operations.
origin: ECC
---

# FastAPI Patterns

## When to Activate

- Building FastAPI applications
- Creating API endpoints
- Implementing dependency injection
- Handling async database operations

## Project Structure

\`\`\`
app/
├── main.py              # FastAPI app entry point
├── routers/             # Route handlers
│   ├── users.py
│   └── items.py
├── models/              # Pydantic models
│   ├── user.py
│   └── item.py
├── services/            # Business logic
│   └── user_service.py
└── dependencies.py      # Shared dependencies
\`\`\`

## Dependency Injection

\`\`\`python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session

@router.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    # Use db session
    pass
\`\`\`

## Related Skills

- `python-patterns`
- `pydantic-validation`
```

### 例 3: Workflow スキル

**File:** `skills/refactoring-workflow/SKILL.md`

```markdown
---
name: refactoring-workflow
description: Systematic refactoring workflow for improving code quality without changing behavior.
origin: ECC
---

# Refactoring Workflow

## When to Activate

- Improving code structure
- Reducing technical debt
- Simplifying complex code
- Extracting reusable components

## Prerequisites

- All tests passing
- Git working directory clean
- Feature branch created

## Workflow Steps

### Step 1: Identify Refactoring Target

- Look for code smells (long methods, duplicate code, large classes)
- Check test coverage for target area
- Document current behavior

### Step 2: Ensure Tests Exist

\`\`\`bash
# Run tests to verify current behavior
npm test

# Check coverage for target files
npm run test:coverage
\`\`\`

### Step 3: Make Small Changes

- One refactoring at a time
- Run tests after each change
- Commit frequently

### Step 4: Verify Behavior Unchanged

\`\`\`bash
# Run full test suite
npm test

# Run E2E tests
npm run test:e2e
\`\`\`

## Common Refactorings

| Smell | Refactoring |
|-------|-------------|
| Long method | Extract method |
| Duplicate code | Extract to shared function |
| Large class | Extract class |
| Long parameter list | Introduce parameter object |

## Checklist

- [ ] Tests exist for target code
- [ ] Made small, focused changes
- [ ] Tests pass after each change
- [ ] Behavior unchanged
- [ ] Committed with clear message
```

---

## 追加リソース

- [CONTRIBUTING.md](../CONTRIBUTING.md) - 一般コントリビューションガイドライン
- [project-guidelines-template](./examples/project-guidelines-template.md) - プロジェクト固有スキルテンプレート
- [coding-standards](../skills/coding-standards/SKILL.md) - standards スキルの例
- [tdd-workflow](../skills/tdd-workflow/SKILL.md) - workflow スキルの例
- [security-review](../skills/security-review/SKILL.md) - domain knowledge スキルの例

---

**覚えておくこと**: 良いスキルはフォーカスされ、実行可能で、即座に有用である。自分が使いたいスキルを書こう。

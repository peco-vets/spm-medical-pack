---
name: git-workflow
description: Git ワークフローパターン（git workflow, branching, commit, merge, rebase）。ブランチング戦略、コミット規約、merge vs rebase、コンフリクト解決、あらゆる規模のチームでの共同開発ベストプラクティスを網羅する。
origin: ECC
---

# Git ワークフローパターン

Git バージョン管理・ブランチング戦略・共同開発のベストプラクティスである。

## 起動タイミング

- 新規プロジェクトの Git ワークフロー設定
- ブランチング戦略の決定（GitFlow、trunk-based、GitHub flow）
- コミットメッセージと PR 説明の記述
- マージコンフリクトの解決
- リリースとバージョンタグの管理
- 新メンバーの Git プラクティスオンボーディング

## ブランチング戦略

### GitHub Flow（シンプル、ほとんどに推奨）

継続デプロイと中小規模チームに最適である。

```
main (protected, always deployable)
  │
  ├── feature/user-auth      → PR → merge to main
  ├── feature/payment-flow   → PR → merge to main
  └── fix/login-bug          → PR → merge to main
```

**ルール:**
- `main` は常にデプロイ可能
- `main` から feature ブランチを作成
- レビュー準備ができたら PR を開く
- 承認と CI 合格後に `main` へマージ
- マージ後即デプロイ

### Trunk-Based 開発（高速チーム）

強力な CI/CD とフィーチャーフラグを持つチームに最適である。

```
main (trunk)
  │
  ├── short-lived feature (1-2 days max)
  ├── short-lived feature
  └── short-lived feature
```

**ルール:**
- 全員が `main` または非常に短命なブランチへコミット
- フィーチャーフラグで未完成作業を隠す
- マージ前に CI 合格必須
- 1日複数回デプロイ

### GitFlow（複雑、リリースサイクル駆動）

スケジュールリリースとエンタープライズプロジェクトに最適である。

```
main (production releases)
  │
  └── develop (integration branch)
        │
        ├── feature/user-auth
        ├── feature/payment
        │
        ├── release/1.0.0    → merge to main and develop
        │
        └── hotfix/critical  → merge to main and develop
```

**ルール:**
- `main` は本番品質コードのみ
- `develop` は統合ブランチ
- feature ブランチは `develop` から、`develop` にマージ
- release ブランチは `develop` から、`main` と `develop` にマージ
- hotfix ブランチは `main` から、両方にマージ

### どれを使うか

| 戦略 | チーム規模 | リリースケイデンス | 適用 |
|----------|-----------|-----------------|----------|
| GitHub Flow | 任意 | 継続 | SaaS、Web アプリ、スタートアップ |
| Trunk-Based | 5+ 経験者 | 1日複数 | 高速チーム、フィーチャーフラグ |
| GitFlow | 10+ | スケジュール | エンタープライズ、規制業界 |

## コミットメッセージ

### Conventional Commits フォーマット

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### タイプ

| Type | 用途 | 例 |
|------|---------|---------|
| `feat` | 新機能 | `feat(auth): add OAuth2 login` |
| `fix` | バグ修正 | `fix(api): handle null response in user endpoint` |
| `docs` | ドキュメント | `docs(readme): update installation instructions` |
| `style` | フォーマット、コード変更なし | `style: fix indentation in login component` |
| `refactor` | リファクタリング | `refactor(db): extract connection pool to module` |
| `test` | テスト追加・更新 | `test(auth): add unit tests for token validation` |
| `chore` | メンテナンス | `chore(deps): update dependencies` |
| `perf` | パフォーマンス改善 | `perf(query): add index to users table` |
| `ci` | CI/CD 変更 | `ci: add PostgreSQL service to test workflow` |
| `revert` | 直前コミット差し戻し | `revert: revert "feat(auth): add OAuth2 login"` |

### 良い例 vs 悪い例

```
# BAD: Vague, no context
git commit -m "fixed stuff"
git commit -m "updates"
git commit -m "WIP"

# GOOD: Clear, specific, explains why
git commit -m "fix(api): retry requests on 503 Service Unavailable

The external API occasionally returns 503 errors during peak hours.
Added exponential backoff retry logic with max 3 attempts.

Closes #123"
```

### コミットメッセージテンプレート

リポジトリルートに `.gitmessage` を作る。

```
# <type>(<scope>): <subject>
# # Types: feat, fix, docs, style, refactor, test, chore, perf, ci, revert
# Scope: api, ui, db, auth, etc.
# Subject: imperative mood, no period, max 50 chars
#
# [optional body] - explain why, not what
# [optional footer] - Breaking changes, closes #issue
```

`git config commit.template .gitmessage` で有効化する。

## Merge vs Rebase

### Merge（履歴保持）

```bash
# Creates a merge commit
git checkout main
git merge feature/user-auth

# Result:
# *   merge commit
# |\
# | * feature commits
# |/
# * main commits
```

**用途:**
- `main` への feature ブランチマージ
- 正確な履歴を保持したい
- 複数人がそのブランチで作業した
- ブランチが push 済みで他者が依存しうる

### Rebase（線形履歴）

```bash
# Rewrites feature commits onto target branch
git checkout feature/user-auth
git rebase main

# Result:
# * feature commits (rewritten)
# * main commits
```

**用途:**
- ローカル feature ブランチを最新 `main` で更新
- 線形でクリーンな履歴が欲しい
- ブランチがローカル限定（push 未）
- 自分しか作業していない

### Rebase ワークフロー

```bash
# Update feature branch with latest main (before PR)
git checkout feature/user-auth
git fetch origin
git rebase origin/main

# Fix any conflicts
# Tests should still pass

# Force push (only if you're the only contributor)
git push --force-with-lease origin feature/user-auth
```

### Rebase を避ける場合

```
# NEVER rebase branches that:
- Have been pushed to a shared repository
- Other people have based work on
- Are protected branches (main, develop)
- Are already merged

# Why: Rebase rewrites history, breaking others' work
```

## Pull Request ワークフロー

### PR タイトルフォーマット

```
<type>(<scope>): <description>

Examples:
feat(auth): add SSO support for enterprise users
fix(api): resolve race condition in order processing
docs(api): add OpenAPI specification for v2 endpoints
```

### PR 説明テンプレート

```markdown
## What

Brief description of what this PR does.

## Why

Explain the motivation and context.

## How

Key implementation details worth highlighting.

## Testing

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Screenshots (if applicable)

Before/after screenshots for UI changes.

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] Tests pass locally
- [ ] Related issues linked

Closes #123
```

### コードレビューチェックリスト

**レビュー担当者:**

- [ ] コードが明示問題を解決するか?
- [ ] エッジケースが未処理ではないか?
- [ ] コードが可読・メンテナブルか?
- [ ] 十分なテストがあるか?
- [ ] セキュリティ懸念があるか?
- [ ] コミット履歴がクリーン（必要なら squash）か?

**作成者:**

- [ ] レビュー依頼前にセルフレビュー完了
- [ ] CI 合格（test・lint・typecheck）
- [ ] PR サイズが妥当（< 500 行が理想）
- [ ] 単一機能/修正に関連
- [ ] 説明が変更を明確に説明

## コンフリクト解決

### コンフリクトの特定

```bash
# Check for conflicts before merge
git checkout main
git merge feature/user-auth --no-commit --no-ff

# If conflicts, Git will show:
# CONFLICT (content): Merge conflict in src/auth/login.ts
# Automatic merge failed; fix conflicts and then commit the result.
```

### コンフリクトの解決

```bash
# See conflicted files
git status

# View conflict markers in file
# <<<<<<< HEAD
# content from main
# =======
# content from feature branch
# >>>>>>> feature/user-auth

# Option 1: Manual resolution
# Edit file, remove markers, keep correct content

# Option 2: Use merge tool
git mergetool

# Option 3: Accept one side
git checkout --ours src/auth/login.ts    # Keep main version
git checkout --theirs src/auth/login.ts  # Keep feature version

# After resolving, stage and commit
git add src/auth/login.ts
git commit
```

### コンフリクト防止戦略

```bash
# 1. Keep feature branches small and short-lived
# 2. Rebase frequently onto main
git checkout feature/user-auth
git fetch origin
git rebase origin/main

# 3. Communicate with team about touching shared files
# 4. Use feature flags instead of long-lived branches
# 5. Review and merge PRs promptly
```

## ブランチ管理

### 命名規則

```
# Feature branches
feature/user-authentication
feature/JIRA-123-payment-integration

# Bug fixes
fix/login-redirect-loop
fix/456-null-pointer-exception

# Hotfixes (production issues)
hotfix/critical-security-patch
hotfix/database-connection-leak

# Releases
release/1.2.0
release/2024-01-hotfix

# Experiments/POCs
experiment/new-caching-strategy
poc/graphql-migration
```

### ブランチクリーンアップ

```bash
# Delete local branches that are merged
git branch --merged main | grep -v "^\*\|main" | xargs -n 1 git branch -d

# Delete remote-tracking references for deleted remote branches
git fetch -p

# Delete local branch
git branch -d feature/user-auth  # Safe delete (only if merged)
git branch -D feature/user-auth  # Force delete

# Delete remote branch
git push origin --delete feature/user-auth
```

### Stash ワークフロー

```bash
# Save work in progress
git stash push -m "WIP: user authentication"

# List stashes
git stash list

# Apply most recent stash
git stash pop

# Apply specific stash
git stash apply stash@{2}

# Drop stash
git stash drop stash@{0}
```

## リリース管理

### セマンティックバージョニング

```
MAJOR.MINOR.PATCH

MAJOR: Breaking changes
MINOR: New features, backward compatible
PATCH: Bug fixes, backward compatible

Examples:
1.0.0 → 1.0.1 (patch: bug fix)
1.0.1 → 1.1.0 (minor: new feature)
1.1.0 → 2.0.0 (major: breaking change)
```

### リリースの作成

```bash
# Create annotated tag
git tag -a v1.2.0 -m "Release v1.2.0

Features:
- Add user authentication
- Implement password reset

Fixes:
- Resolve login redirect issue

Breaking Changes:
- None"

# Push tag to remote
git push origin v1.2.0

# List tags
git tag -l

# Delete tag
git tag -d v1.2.0
git push origin --delete v1.2.0
```

### Changelog 生成

```bash
# Generate changelog from commits
git log v1.1.0..v1.2.0 --oneline --no-merges

# Or use conventional-changelog
npx conventional-changelog -i CHANGELOG.md -s
```

## Git 設定

### 必須設定

```bash
# User identity
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Default branch name
git config --global init.defaultBranch main

# Pull behavior (rebase instead of merge)
git config --global pull.rebase true

# Push behavior (push current branch only)
git config --global push.default current

# Auto-correct typos
git config --global help.autocorrect 1

# Better diff algorithm
git config --global diff.algorithm histogram

# Color output
git config --global color.ui auto
```

### 便利なエイリアス

```bash
# Add to ~/.gitconfig
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --oneline --graph --all
    amend = commit --amend --no-edit
    wip = commit -m "WIP"
    undo = reset --soft HEAD~1
    contributors = shortlog -sn
```

### Gitignore パターン

```gitignore
# Dependencies
node_modules/
vendor/

# Build outputs
dist/
build/
*.o
*.exe

# Environment files
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Test coverage
coverage/

# Cache
.cache/
*.tsbuildinfo
```

## よくあるワークフロー

### 新機能の開始

```bash
# 1. Update main branch
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b feature/user-auth

# 3. Make changes and commit
git add .
git commit -m "feat(auth): implement OAuth2 login"

# 4. Push to remote
git push -u origin feature/user-auth

# 5. Create Pull Request on GitHub/GitLab
```

### PR への新変更追加

```bash
# 1. Make additional changes
git add .
git commit -m "feat(auth): add error handling"

# 2. Push updates
git push origin feature/user-auth
```

### fork の upstream 同期

```bash
# 1. Add upstream remote (once)
git remote add upstream https://github.com/original/repo.git

# 2. Fetch upstream
git fetch upstream

# 3. Merge upstream/main into your main
git checkout main
git merge upstream/main

# 4. Push to your fork
git push origin main
```

### 間違いの取り消し

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Undo last commit pushed to remote
git revert HEAD
git push origin main

# Undo specific file changes
git checkout HEAD -- path/to/file

# Fix last commit message
git commit --amend -m "New message"

# Add forgotten file to last commit
git add forgotten-file
git commit --amend --no-edit
```

## Git フック

### Pre-Commit フック

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run linting
npm run lint || exit 1

# Run tests
npm test || exit 1

# Check for secrets
if git diff --cached | grep -E '(password|api_key|secret)'; then
    echo "Possible secret detected. Commit aborted."
    exit 1
fi
```

### Pre-Push フック

```bash
#!/bin/bash
# .git/hooks/pre-push

# Run full test suite
npm run test:all || exit 1

# Check for console.log statements
if git diff origin/main | grep -E 'console\.log'; then
    echo "Remove console.log statements before pushing."
    exit 1
fi
```

## アンチパターン

```
# BAD: Committing directly to main
git checkout main
git commit -m "fix bug"

# GOOD: Use feature branches and PRs

# BAD: Committing secrets
git add .env  # Contains API keys

# GOOD: Add to .gitignore, use environment variables

# BAD: Giant PRs (1000+ lines)
# GOOD: Break into smaller, focused PRs

# BAD: "Update" commit messages
git commit -m "update"
git commit -m "fix"

# GOOD: Descriptive messages
git commit -m "fix(auth): resolve redirect loop after login"

# BAD: Rewriting public history
git push --force origin main

# GOOD: Use revert for public branches
git revert HEAD

# BAD: Long-lived feature branches (weeks/months)
# GOOD: Keep branches short (days), rebase frequently

# BAD: Committing generated files
git add dist/
git add node_modules/

# GOOD: Add to .gitignore
```

## クイックリファレンス

| 作業 | コマンド |
|------|---------|
| ブランチ作成 | `git checkout -b feature/name` |
| ブランチ切替 | `git checkout branch-name` |
| ブランチ削除 | `git branch -d branch-name` |
| マージ | `git merge branch-name` |
| リベース | `git rebase main` |
| 履歴表示 | `git log --oneline --graph` |
| 変更表示 | `git diff` |
| ステージ | `git add .` または `git add -p` |
| コミット | `git commit -m "message"` |
| プッシュ | `git push origin branch-name` |
| プル | `git pull origin branch-name` |
| スタッシュ | `git stash push -m "message"` |
| 最終コミット取り消し | `git reset --soft HEAD~1` |
| コミット差し戻し | `git revert HEAD` |

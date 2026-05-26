---
name: skill-create
description: ローカルの git 履歴を分析してコーディングパターンを抽出し、SKILL.md ファイルを生成する。Skill Creator GitHub App のローカル版 / Analyze local git history to extract coding patterns and generate SKILL.md files. Local version of the Skill Creator GitHub App.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /skill-create - Local Skill Generation

あなたのリポジトリの git 履歴を分析してコーディングパターンを抽出し、チームのプラクティスを Claude に教える SKILL.md ファイルを生成する。

## Usage

```bash
/skill-create                    # Analyze current repo
/skill-create --commits 100      # Analyze last 100 commits
/skill-create --output ./skills  # Custom output directory
/skill-create --instincts        # Also generate instincts for continuous-learning-v2
```

## 何をするか

1. **Git 履歴をパース** - コミット、ファイル変更、パターンを分析する
2. **パターンを検出** - 繰り返されるワークフローと規約を特定する
3. **SKILL.md を生成** - 有効な Claude Code スキルファイルを作成する
4. **オプションで Instinct を作成** - continuous-learning-v2 システム用

## 分析ステップ

### Step 1: Git データを集める

```bash
# Get recent commits with file changes
git log --oneline -n ${COMMITS:-200} --name-only --pretty=format:"%H|%s|%ad" --date=short

# Get commit frequency by file
git log --oneline -n 200 --name-only | grep -v "^$" | grep -v "^[a-f0-9]" | sort | uniq -c | sort -rn | head -20

# Get commit message patterns
git log --oneline -n 200 | cut -d' ' -f2- | head -50
```

### Step 2: パターンを検出する

これらのパターンタイプを探す：

| Pattern | Detection Method |
|---------|-----------------|
| **コミット規約** | コミットメッセージへの regex（feat:、fix:、chore:） |
| **ファイルの共変更** | 常に一緒に変わるファイル |
| **ワークフローシーケンス** | 繰り返されるファイル変更パターン |
| **アーキテクチャ** | フォルダ構造と命名規約 |
| **テストパターン** | テストファイルの場所、命名、カバレッジ |

### Step 3: SKILL.md を生成する

出力形式：

```markdown
---
name: {repo-name}-patterns
description: Coding patterns extracted from {repo-name}
version: 1.0.0
source: local-git-analysis
analyzed_commits: {count}
---

# {Repo Name} Patterns

## Commit Conventions
{detected commit message patterns}

## Code Architecture
{detected folder structure and organization}

## Workflows
{detected repeating file change patterns}

## Testing Patterns
{detected test conventions}
```

### Step 4: Instinct を生成する（--instincts の場合）

continuous-learning-v2 統合用：

```yaml
---
id: {repo}-commit-convention
trigger: "when writing a commit message"
confidence: 0.8
domain: git
source: local-repo-analysis
---

# Use Conventional Commits

## Action
Prefix commits with: feat:, fix:, chore:, docs:, test:, refactor:

## Evidence
- Analyzed {n} commits
- {percentage}% follow conventional commit format
```

## 出力例

TypeScript プロジェクトで `/skill-create` を実行すると、以下のような出力が生成される：

- **Commit Conventions**：プロジェクトが conventional commits を使う（feat:、fix:、chore:、docs:）
- **Code Architecture**：src/ 配下に components/、hooks/、utils/、types/、services/ といったフォルダ構造
- **Workflows**：新コンポーネント追加時のステップ（コンポーネント作成 → テスト追加 → index.ts からエクスポート）、DB マイグレーション時のステップ
- **Testing Patterns**：`__tests__/` ディレクトリまたは `.test.ts` サフィックス、カバレッジ目標 80%+、フレームワーク Vitest

## GitHub App 統合

高度な機能（10k+ commits、チーム共有、auto-PR）には [Skill Creator GitHub App](https://github.com/apps/skill-creator) を使う：

- インストール：[github.com/apps/skill-creator](https://github.com/apps/skill-creator)
- 任意の issue に `/skill-creator analyze` でコメント
- 生成されたスキルを含む PR を受け取る

## 関連コマンド

- `/instinct-import` - 生成された本能をインポート
- `/instinct-status` - 学習された本能を表示
- `/evolve` - 本能をスキル/エージェントにクラスタリング

---

*[Everything Claude Code](https://github.com/affaan-m/everything-claude-code) の一部*

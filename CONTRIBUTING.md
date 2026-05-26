# Everything Claude Code へのコントリビューション

コントリビューションへのご関心に感謝する。本リポジトリは Claude Code ユーザー向けのコミュニティリソースである。

## 目次

- [対象とする貢献](#対象とする貢献)
- [クイックスタート](#クイックスタート)
- [Skill のコントリビューション](#skill-のコントリビューション)
- [Skill Adaptation Policy](#skill-adaptation-policy)
- [Agent のコントリビューション](#agent-のコントリビューション)
- [Hook のコントリビューション](#hook-のコントリビューション)
- [Command のコントリビューション](#command-のコントリビューション)
- [MCP とドキュメント (例: Context7)](#mcp-とドキュメント-例-context7)
- [クロスハーネスと翻訳](#クロスハーネスと翻訳)
- [プルリクエストプロセス](#プルリクエストプロセス)

---

## 対象とする貢献

### Agents
特定タスクを上手く扱う新エージェント:
- 言語特化レビュアー (Python, Go, Rust)
- フレームワーク専門家 (Django, Rails, Laravel, Spring)
- DevOps スペシャリスト (Kubernetes, Terraform, CI/CD)
- ドメイン専門家 (ML パイプライン、データエンジニアリング、モバイル)

### Skills
ワークフロー定義とドメイン知識:
- 言語のベストプラクティス
- フレームワークパターン
- テスト戦略
- アーキテクチャガイド

### Hooks
有用な自動化:
- Lint・フォーマットフック
- セキュリティチェック
- 検証フック
- 通知フック

### Commands
有用なワークフローを呼び出すスラッシュコマンド:
- デプロイコマンド
- テストコマンド
- コード生成コマンド

---

## クイックスタート

```bash
# 1. Fork and clone
gh repo fork affaan-m/everything-claude-code --clone
cd everything-claude-code

# 2. Create a branch
git checkout -b feat/my-contribution

# 3. Add your contribution (see sections below)

# 4. Test locally
cp -r skills/my-skill ~/.claude/skills/  # for skills
# Then test with Claude Code

# 5. Submit PR
git add . && git commit -m "feat: add my-skill" && git push -u origin feat/my-contribution
```

---

## Skill のコントリビューション

Skill は Claude Code がコンテキストに応じてロードする知識モジュールである。

> **包括的ガイド:** 効果的なスキル作成の詳細ガイダンスは [Skill Development Guide](docs/SKILL-DEVELOPMENT-GUIDE.md) を参照。以下を網羅する:
> - スキルアーキテクチャとカテゴリ
> - 例を用いた効果的なコンテンツの書き方
> - ベストプラクティスと一般的パターン
> - テストと検証
> - 完全な例のギャラリー

### ディレクトリ構成

```
skills/
└── your-skill-name/
    └── SKILL.md
```

### SKILL.md テンプレート

```markdown
---
name: your-skill-name
description: Brief description shown in skill list and used for auto-activation
origin: ECC
---

# Your Skill Title

Brief overview of what this skill covers.

## When to Activate

Describe scenarios where Claude should use this skill. This is critical for auto-activation.

## Core Concepts

Explain key patterns and guidelines.

## Code Examples

\`\`\`typescript
// Include practical, tested examples
function example() {
  // Well-commented code
}
\`\`\`

## Anti-Patterns

Show what NOT to do with examples.

## Best Practices

- Actionable guidelines
- Do's and don'ts
- Common pitfalls to avoid

## Related Skills

Link to complementary skills (e.g., `related-skill-1`, `related-skill-2`).
```

### Skill カテゴリ

| カテゴリ | 目的 | 例 |
|----------|------|----|
| **Language Standards** | イディオム、規約、ベストプラクティス | `python-patterns`, `golang-patterns` |
| **Framework Patterns** | フレームワーク固有のガイダンス | `django-patterns`, `nextjs-patterns` |
| **Workflow** | ステップ・バイ・ステップのプロセス | `tdd-workflow`, `refactoring-workflow` |
| **Domain Knowledge** | 専門ドメイン | `security-review`, `api-design` |
| **Tool Integration** | ツール・ライブラリ利用 | `docker-patterns`, `supabase-patterns` |
| **Template** | プロジェクト固有スキルテンプレート | `docs/examples/project-guidelines-template.md` |

### Skill Adaptation Policy

別のリポジトリ、プラグイン、ハーネス、個人のプロンプトパックからアイデアを移植する場合、PR を開く前に [Skill Adaptation Policy](docs/skill-adaptation-policy.md) を読むこと。

要約すれば:

- 外部プロダクトのアイデンティティではなく、根底にあるアイデアをコピーする
- ECC がサーフェスを大きく変更・拡張する場合はスキル名を変える
- 新たなデフォルトのサードパーティ依存より、ECC ネイティブのルール、スキル、スクリプト、MCP を優先する
- 未検証パッケージのインストールを伝えるだけが主な価値であるスキルは出さない

### Skill チェックリスト

- [ ] 1 ドメイン・1 技術にフォーカスしている (広すぎない)
- [ ] 自動有効化のための "When to Activate" セクションを含む
- [ ] 実用的でコピペ可能なコード例を含む
- [ ] アンチパターン (やってはいけないこと) を示す
- [ ] 500 行以下 (最大 800 行)
- [ ] 明確なセクションヘッダを使う
- [ ] Claude Code でテストされている
- [ ] 関連スキルへのリンクがある
- [ ] 機密データ (API キー、トークン、パス) が含まれない
- [ ] frontmatter の `name:` がディレクトリ名と一致している
- [ ] frontmatter の `description:` はインライン文字列か folded (`>`) スカラーであり、リテラルブロック (`|`, `|-`, `|+`) ではない(改行を保持するため、フラットテーブルレンダラーが壊れる)

### Skill 例

| Skill | カテゴリ | 目的 |
|-------|----------|------|
| `coding-standards/` | Language Standards | TypeScript/JavaScript パターン |
| `frontend-patterns/` | Framework Patterns | React と Next.js のベストプラクティス |
| `backend-patterns/` | Framework Patterns | API とデータベースパターン |
| `security-review/` | Domain Knowledge | セキュリティチェックリスト |
| `tdd-workflow/` | Workflow | テスト駆動開発プロセス |
| `docs/examples/project-guidelines-template.md` | Template | プロジェクト固有スキルテンプレート |

---

## Agent のコントリビューション

Agent は Task ツール経由で呼び出される専門アシスタントである。

### ファイル配置

```
agents/your-agent-name.md
```

### Agent テンプレート

```markdown
---
name: your-agent-name
description: What this agent does and when Claude should invoke it. Be specific!
tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
model: sonnet
---

You are a [role] specialist.

## Your Role

- Primary responsibility
- Secondary responsibility
- What you DO NOT do (boundaries)

## Workflow

### Step 1: Understand
How you approach the task.

### Step 2: Execute
How you perform the work.

### Step 3: Verify
How you validate results.

## Output Format

What you return to the user.

## Examples

### Example: [Scenario]
Input: [what user provides]
Action: [what you do]
Output: [what you return]
```

### Agent フィールド

| フィールド | 説明 | オプション |
|-----------|------|------------|
| `name` | 小文字、ハイフン区切り | `code-reviewer` |
| `description` | 呼び出し判断に使われる | 具体的に! |
| `tools` | 必要なものだけ | `Read, Write, Edit, Bash, Grep, Glob, WebFetch, Task`、または MCP ツール名 (例: `mcp__context7__resolve-library-id`, `mcp__context7__query-docs`) |
| `model` | 複雑度 | `haiku` (シンプル), `sonnet` (コーディング), `opus` (複雑) |

### Agent 例

| Agent | 目的 |
|-------|------|
| `tdd-guide.md` | テスト駆動開発 |
| `code-reviewer.md` | コードレビュー |
| `security-reviewer.md` | セキュリティスキャン |
| `build-error-resolver.md` | ビルドエラー修正 |

---

## Hook のコントリビューション

Hook は Claude Code イベントによってトリガされる自動挙動である。

### ファイル配置

```
hooks/hooks.json
```

### Hook 種別

| 種別 | トリガ | ユースケース |
|------|--------|--------------|
| `PreToolUse` | ツール実行前 | 検証、警告、ブロック |
| `PostToolUse` | ツール実行後 | フォーマット、チェック、通知 |
| `SessionStart` | セッション開始時 | コンテキストロード |
| `Stop` | セッション終了時 | クリーンアップ、監査 |

### Hook 形式

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "tool == \"Bash\" && tool_input.command matches \"rm -rf /\"",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[Hook] BLOCKED: Dangerous command' && exit 1"
          }
        ],
        "description": "Block dangerous rm commands"
      }
    ]
  }
}
```

### Matcher 文法

```javascript
// Match specific tools
tool == "Bash"
tool == "Edit"
tool == "Write"

// Match input patterns
tool_input.command matches "npm install"
tool_input.file_path matches "\\.tsx?$"

// Combine conditions
tool == "Bash" && tool_input.command matches "git push"
```

### Hook 例

```json
// Block dev servers outside tmux
{
  "matcher": "tool == \"Bash\" && tool_input.command matches \"npm run dev\"",
  "hooks": [{"type": "command", "command": "echo 'Use tmux for dev servers' && exit 1"}],
  "description": "Ensure dev servers run in tmux"
}

// Auto-format after editing TypeScript
{
  "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\.tsx?$\"",
  "hooks": [{"type": "command", "command": "npx prettier --write \"$file_path\""}],
  "description": "Format TypeScript files after edit"
}

// Warn before git push
{
  "matcher": "tool == \"Bash\" && tool_input.command matches \"git push\"",
  "hooks": [{"type": "command", "command": "echo '[Hook] Review changes before pushing'"}],
  "description": "Reminder to review before push"
}
```

### Hook チェックリスト

- [ ] matcher が具体的である (広すぎない)
- [ ] 明確なエラー・情報メッセージを含む
- [ ] 正しい exit code を使う (`exit 1` でブロック、`exit 0` で許可)
- [ ] 十分にテストされている
- [ ] description がある

---

## Command のコントリビューション

Command は `/command-name` でユーザーが呼び出すアクションである。

### ファイル配置

```
commands/your-command.md
```

### Command テンプレート

```markdown
---
description: Brief description shown in /help
---

# Command Name

## Purpose

What this command does.

## Usage

\`\`\`
/your-command [args]
\`\`\`

## Workflow

1. First step
2. Second step
3. Final step

## Output

What the user receives.
```

### Command 例

| Command | 目的 |
|---------|------|
| `commit.md` | git コミット作成 |
| `code-review.md` | コード変更レビュー |
| `tdd.md` | TDD ワークフロー |
| `e2e.md` | E2E テスト |

---

## MCP とドキュメント (例: Context7)

スキルとエージェントは **MCP (Model Context Protocol)** ツールを用いて、訓練データのみに依存せず最新データを取り込むことができる。これはドキュメントで特に有用である。

- **Context7** は `resolve-library-id` と `query-docs` を公開する MCP サーバーである。ユーザーがライブラリ、フレームワーク、API について質問する際に使い、回答が最新のドキュメントとコード例を反映するようにする。
- ライブドキュメントに依存する **skill** (例: セットアップ、API 利用) をコントリビュートする際は、該当 MCP ツールの使い方 (例: library ID を解決してから docs をクエリ) を記述し、`documentation-lookup` スキルや Context7 をパターンとして示すこと。
- ドキュメント・API 質問に答える **agent** をコントリビュートする際は、Context7 MCP ツール名 (例: `mcp__context7__resolve-library-id`, `mcp__context7__query-docs`) をエージェントの tools に含め、resolve → query ワークフローをドキュメント化すること。
- **mcp-configs/mcp-servers.json** は Context7 エントリを含む。ユーザーはハーネス (例: Claude Code, Cursor) でこれを有効化し、`skills/documentation-lookup/` の documentation-lookup スキルや `/docs` コマンドを使う。

---

## クロスハーネスと翻訳

### Skill サブセット (Codex と Cursor)

ECC は他のハーネス向けにスキルサブセットを提供している:

- **Codex:** `.agents/skills/` — `agents/openai.yaml` に列挙されたスキルが Codex によりロードされる。
- **Cursor:** `.cursor/skills/` — Cursor 向けにスキルのサブセットが同梱されている。

Codex や Cursor で利用可能にすべき **新スキルを追加** する際:

1. 通常通り `skills/your-skill-name/` 配下にスキルを追加する。
2. **Codex** で利用可能にする場合、`.agents/skills/` に追加 (スキルディレクトリのコピーまたは参照追加) し、必要なら `agents/openai.yaml` に参照を入れる。
3. **Cursor** で利用可能にする場合、Cursor のレイアウトに従って `.cursor/skills/` 配下に追加する。

各ディレクトリの既存スキルで期待される構造を確認すること。これらサブセットの同期は手動である。更新した場合は PR で言及すること。

### 翻訳

翻訳は `docs/` 配下 (例: `docs/zh-CN`, `docs/zh-TW`, `docs/ja-JP`) にある。翻訳済みのエージェント、コマンド、スキルを変更する場合、該当翻訳ファイルの更新を検討するか、Issue を開いてメンテナや翻訳者が更新できるようにすること。

---

## プルリクエストプロセス

### 1. PR タイトル形式

```
feat(skills): add rust-patterns skill
feat(agents): add api-designer agent
feat(hooks): add auto-format hook
fix(skills): update React patterns
docs: improve contributing guide
```

### 2. PR 説明

```markdown
## Summary
What you're adding and why.

## Type
- [ ] Skill
- [ ] Agent
- [ ] Hook
- [ ] Command

## Testing
How you tested this.

## Checklist
- [ ] Follows format guidelines
- [ ] Tested with Claude Code
- [ ] No sensitive info (API keys, paths)
- [ ] Clear descriptions
```

### 3. レビュープロセス

1. メンテナが 48 時間以内にレビュー
2. リクエストがあればフィードバックに対応
3. 承認後、main にマージ

---

## ガイドライン

### すべきこと
- コントリビューションを焦点を絞り、モジュラーに保つ
- 明確な説明を含める
- 提出前にテストする
- 既存パターンに従う
- 依存関係をドキュメント化する

### してはいけないこと
- 機密データ (API キー、トークン、パス) を含める
- 過度に複雑またはニッチな設定を加える
- 未テストのコントリビューションを提出する
- 既存機能の重複を作る

---

## ファイル命名

- 小文字とハイフンを使う: `python-reviewer.md`
- 説明的に: `workflow.md` ではなく `tdd-workflow.md`
- name とファイル名を一致させる

---

## 質問は?

- **Issues:** [github.com/affaan-m/everything-claude-code/issues](https://github.com/affaan-m/everything-claude-code/issues)
- **X/Twitter:** [@affaanmustafa](https://x.com/affaanmustafa)

---

コントリビューションに感謝する。共に優れたリソースを築こう。

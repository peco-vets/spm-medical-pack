---
description: 厳格な検証ループで実装計画を実行する / Execute an implementation plan with rigorous validation loops
argument-hint: <path/to/plan.md>
---

> Wirasm 氏による PRPs-agentic-eng から派生したものである。PRP ワークフローシリーズの一部である。

# PRP Implement

計画ファイルをステップバイステップで継続的検証と共に実行する。すべての変更が即座に検証される — 壊れた状態を決して蓄積しない。

**Core Philosophy**：検証ループは早期にミスをキャッチする。各変更後にチェックを実行する。問題を即座に修正する。

**Golden Rule**：検証が失敗したら、次に進む前に修正する。壊れた状態を決して蓄積しない。

---

## Phase 0 — DETECT

### パッケージマネージャ検出

| File Exists | Package Manager | Runner |
|---|---|---|
| `bun.lockb` | bun | `bun run` |
| `pnpm-lock.yaml` | pnpm | `pnpm run` |
| `yarn.lock` | yarn | `yarn` |
| `package-lock.json` | npm | `npm run` |
| `pyproject.toml` or `requirements.txt` | uv / pip | `uv run` or `python -m` |
| `Cargo.toml` | cargo | `cargo` |
| `go.mod` | go | `go` |

### 検証スクリプト

`package.json`（または同等のもの）で利用可能なスクリプトを確認する：

```bash
# For Node.js projects
cat package.json | grep -A 20 '"scripts"'
```

利用可能なコマンドを記録する：type-check、lint、test、build。

---

## Phase 1 — LOAD

計画ファイルを読む：

```bash
cat "$ARGUMENTS"
```

計画から以下のセクションを抽出する：
- **Summary** — 構築するもの
- **Patterns to Mirror** — 従うべきコード規約
- **Files to Change** — 何を作成または修正するか
- **Step-by-Step Tasks** — 実装シーケンス
- **Validation Commands** — 正確性を検証する方法
- **Acceptance Criteria** — 完了の定義

ファイルが存在しないか有効な計画でない場合：
```
Error: Plan file not found or invalid.
Run /prp-plan <feature-description> to create a plan first.
```

**CHECKPOINT**：計画を読み込んだ。すべてのセクションを特定した。タスクを抽出した。

---

## Phase 2 — PREPARE

### Git State

```bash
git branch --show-current
git status --porcelain
```

### Branch Decision

| Current State | Action |
|---|---|
| フィーチャーブランチにいる | 現在のブランチを使用 |
| main にいる、作業ツリーがクリーン | フィーチャーブランチを作成：`git checkout -b feat/{plan-name}` |
| main にいる、作業ツリーがダーティ | **STOP** — まず stash またはコミットをユーザーに求める |
| このフィーチャーの git worktree 内 | worktree を使う |

### Sync Remote

```bash
git pull --rebase origin $(git branch --show-current) 2>/dev/null || true
```

**CHECKPOINT**：正しいブランチにいる。作業ツリーが準備完了。リモートが同期された。

---

## Phase 3 — EXECUTE

計画から各タスクを順次処理する。

### タスクごとのループ

**Step-by-Step Tasks** の各タスクについて：

1. **MIRROR 参照を読む** — タスクの MIRROR フィールドで参照されたパターンファイルを開く。コードを書く前に規約を理解する。

2. **実装する** — パターンに正確に従ってコードを書く。GOTCHA 警告を適用する。指定された IMPORTS を使う。

3. **即座に検証する** — すべてのファイル変更後：
   ```bash
   # Run type-check (adjust command per project)
   [type-check command from Phase 0]
   ```
   type-check が失敗 → 次のファイルに進む前にエラーを修正する。

4. **進捗を追跡する** — ログ：`[done] Task N: [task name] — complete`

### 逸脱の処理

実装が計画から逸脱しなければならない場合：
- **WHAT** が変わったかを記録する
- **WHY** 変わったかを記録する
- 修正されたアプローチで続行する
- これらの逸脱はレポートに記録される

**CHECKPOINT**：すべてのタスクが実行された。逸脱がログされた。

---

## Phase 4 — VALIDATE

計画からすべての検証レベルを実行する。次に進む前に各レベルの問題を修正する。

### Level 1: 静的解析

```bash
# Type checking — zero errors required
[project type-check command]

# Linting — fix automatically where possible
[project lint command]
[project lint-fix command]
```

オートフィックス後に lint エラーが残れば、手動で修正する。

### Level 2: ユニットテスト

すべての新関数にテストを書く（計画の Testing Strategy で指定された通り）。

```bash
[project test command for affected area]
```

- すべての関数に少なくとも1つのテストが必要
- 計画にリストされたエッジケースをカバーする
- テストが失敗 → 実装を修正する（テストが間違っていない限り、テストではない）

### Level 3: ビルドチェック

```bash
[project build command]
```

ビルドはゼロエラーで成功する必要がある。

### Level 4: 統合テスト（該当する場合）

サーバー起動、テスト実行、サーバー停止のシーケンスを使う。サーバーが30秒以内に起動を待つヘルスチェックループを含める。

### Level 5: エッジケーステスト

計画の Testing Strategy チェックリストからエッジケースを実行する。

**CHECKPOINT**：5つの検証レベルすべてが通過。ゼロエラー。

---

## Phase 5 — REPORT

### 実装レポートを作成する

```bash
mkdir -p .claude/PRPs/reports
```

レポートを `.claude/PRPs/reports/{plan-name}-report.md` に書く。レポートには：Summary、Assessment vs Reality 表（Complexity、Confidence、Files Changed）、Tasks Completed 表、Validation Results 表、Files Changed 表、Deviations from Plan、Issues Encountered、Tests Written 表、Next Steps を含める。

### PRD を更新する（該当する場合）

この実装が PRD フェーズ用だった場合：
1. フェーズステータスを `in-progress` から `complete` に更新する
2. 参照としてレポートパスを追加する

### 計画をアーカイブする

```bash
mkdir -p .claude/PRPs/plans/completed
mv "$ARGUMENTS" .claude/PRPs/plans/completed/
```

**CHECKPOINT**：レポート作成。PRD 更新。計画アーカイブ。

---

## Phase 6 — OUTPUT

ユーザーに報告：Implementation Complete、Plan（→ completed/ にアーカイブ）、Branch、Status（全タスク完了）、Validation Summary 表、Files Changed、Deviations、Artifacts、PRD Progress（該当する場合）。

> 次のステップ：プルリクエストを作成するには `/prp-pr` を実行、または先に変更をレビューするには `/code-review` を実行。

---

## 失敗の処理

### Type Check が失敗
1. エラーメッセージを注意深く読む
2. ソースファイルの型エラーを修正
3. type-check を再実行
4. クリーンになるまで続行しない

### Tests が失敗
1. バグが実装にあるかテストにあるかを特定する
2. 根本原因を修正する（通常は実装）
3. テストを再実行する
4. グリーンになるまで続行しない

### Lint が失敗
1. まずオートフィックスを実行
2. エラーが残れば、手動で修正
3. lint を再実行
4. クリーンになるまで続行しない

### Build が失敗
1. 通常は型または import 問題 — エラーメッセージを確認
2. 問題のあるファイルを修正
3. build を再実行
4. 成功するまで続行しない

### 統合テストが失敗
1. サーバーが正しく起動したか確認
2. エンドポイント/ルートが存在することを検証
3. リクエストフォーマットが期待と一致するか確認
4. 修正して再実行

---

## 成功基準

- **TASKS_COMPLETE**：計画からすべてのタスクが実行された
- **TYPES_PASS**：ゼロ型エラー
- **LINT_PASS**：ゼロ lint エラー
- **TESTS_PASS**：すべてのテストグリーン、新しいテストが書かれた
- **BUILD_PASS**：ビルド成功
- **REPORT_CREATED**：実装レポートが保存された
- **PLAN_ARCHIVED**：計画が `completed/` に移動された

---

## 次のステップ

- コミット前に変更をレビューするには `/code-review` を実行
- 説明的なメッセージでコミットするには `/prp-commit` を実行
- プルリクエストを作成するには `/prp-pr` を実行
- PRD にさらにフェーズがあれば `/prp-plan <next-phase>` を実行

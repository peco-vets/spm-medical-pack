---
name: github-ops
description: GitHub リポジトリの運用・自動化・管理（GitHub ops, issue triage, PR management, CI/CD, release management）。gh CLI を用いた issue トリアージ、PR 管理、CI/CD 運用、リリース管理、セキュリティ監視。GitHub issue・PR・CI 状態・リリース・コントリビュータ・stale 項目・単純な git コマンドを超える GitHub オペレーションタスクを扱うときに用いる。
origin: ECC
---

# GitHub オペレーション

コミュニティ健全性・CI 信頼性・コントリビュータ体験に焦点を置いた GitHub リポジトリ管理を行う。

## 起動タイミング

- issue トリアージ（分類・ラベリング・返答・重複排除）
- PR 管理（レビュー状態・CI チェック・stale PR・マージ準備）
- CI/CD 失敗のデバッグ
- リリースと changelog の準備
- Dependabot とセキュリティアラートの監視
- OSS プロジェクトのコントリビュータ体験管理
- ユーザーが "check GitHub"、"triage issues"、"review PRs"、"merge"、"release"、"CI is broken" と発言

## ツール要件

- すべての GitHub API 操作に **gh CLI**
- `gh auth login` でリポジトリアクセスを構成

## Issue トリアージ

各 issue をタイプと優先度で分類する。

**タイプ:** bug、feature-request、question、documentation、enhancement、duplicate、invalid、good-first-issue

**優先度:** critical（破壊/セキュリティ）、high（顕著影響）、medium（あれば良い）、low（外観）

### トリアージワークフロー

1. issue タイトル・本文・コメントを読む
2. 既存 issue と重複しないか確認する（キーワード検索）
3. `gh issue edit --add-label` で適切なラベルを付ける
4. 質問の場合: 役立つ返答を作成・投稿する
5. 追加情報が必要なバグの場合: 再現手順を求める
6. good first issue の場合: `good-first-issue` ラベルを付ける
7. 重複の場合: オリジナルへのリンクをコメントし、`duplicate` ラベルを付ける

```bash
# Search for potential duplicates
gh issue list --search "keyword" --state all --limit 20

# Add labels
gh issue edit <number> --add-label "bug,high-priority"

# Comment on issue
gh issue comment <number> --body "Thanks for reporting. Could you share reproduction steps?"
```

## PR 管理

### レビューチェックリスト

1. CI 状態を確認: `gh pr checks <number>`
2. マージ可能か確認: `gh pr view <number> --json mergeable`
3. 経過時間と最終活動を確認
4. 5日以上レビューなしの PR をフラグする
5. コミュニティ PR の場合: テストと規約遵守を確認する

### Stale ポリシー

- 14日以上活動なしの issue: `stale` ラベルを付け、更新を求めるコメント
- 7日以上活動なしの PR: まだアクティブか確認するコメント
- 30日応答なしの stale issue は自動 close（`closed-stale` ラベル追加）

```bash
# Find stale issues (no activity in 14+ days)
gh issue list --label "stale" --state open

# Find PRs with no recent activity
gh pr list --json number,title,updatedAt --jq '.[] | select(.updatedAt < "2026-03-01")'
```

## CI/CD 運用

CI 失敗時:

1. ワークフロー実行を確認: `gh run view <run-id> --log-failed`
2. 失敗ステップを特定する
3. flaky test か実失敗か判別する
4. 実失敗の場合: 原因特定と修正提案
5. flaky の場合: 後日調査のためパターンを記録する

```bash
# List recent failed runs
gh run list --status failure --limit 10

# View failed run logs
gh run view <run-id> --log-failed

# Re-run a failed workflow
gh run rerun <run-id> --failed
```

## リリース管理

リリース準備時:

1. main で全 CI が green か確認する
2. 未リリース変更をレビュー: `gh pr list --state merged --base main`
3. PR タイトルから changelog 生成
4. リリース作成: `gh release create`

```bash
# List merged PRs since last release
gh pr list --state merged --base main --search "merged:>2026-03-01"

# Create a release
gh release create v1.2.0 --title "v1.2.0" --generate-notes

# Create a pre-release
gh release create v1.3.0-rc1 --prerelease --title "v1.3.0 Release Candidate 1"
```

## セキュリティ監視

```bash
# Check Dependabot alerts
gh api repos/{owner}/{repo}/dependabot/alerts --jq '.[].security_advisory.summary'

# Check secret scanning alerts
gh api repos/{owner}/{repo}/secret-scanning/alerts --jq '.[].state'

# Review and auto-merge safe dependency bumps
gh pr list --label "dependencies" --json number,title
```

- 安全な依存バンプをレビュー・自動マージする
- critical/high 重大度アラートは即フラグする
- 最低週次で新規 Dependabot アラートを確認する

## 品質ゲート

GitHub オペレーションタスク完了前に確認する:
- トリアージ済み issue すべてに適切なラベル
- 7日以上レビュー・コメントなしの PR がない
- CI 失敗が（単に再実行ではなく）調査されている
- リリースが正確な changelog を含む
- セキュリティアラートが認識・追跡されている

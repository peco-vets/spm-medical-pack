# リポジトリ・フォーク評価とセットアップ推奨事項

**Date:** 2026-03-21

---

## 利用可能なもの

### Repo: `Infiniteyieldai/everything-claude-code`

これは **`affaan-m/everything-claude-code` のフォーク** である(アップストリームプロジェクトはスター 50K 以上、フォーク 6K 以上)。

| 属性 | 値 |
|------|---|
| Version | 1.9.0 (current) |
| Status | クリーンフォーク — アップストリーム `main` より 1 コミット先行 (本セッションで追加した EVALUATION.md) |
| Remote branches | `main`, `claude/evaluate-repo-comparison-ASZ9Y` |
| Upstream sync | 完全同期 — マージ済み最終アップストリームコミットは zh-CN ドキュメント PR (#728) |
| License | MIT |

**作業対象として正しいリポジトリである。** 最新のアップストリームバージョンで、分岐やマージコンフリクトは無い。

---

### 現在の `~/.claude/` インストール

| コンポーネント | インストール済み | リポジトリでの利用可能数 |
|--------------|-----------------|------------------------|
| Agents | 0 | 28 |
| Skills | 0 | 116 |
| Commands | 0 | 59 |
| Rules | 0 | 60+ files (12 languages) |
| Hooks | 1 (git Stop check) | 完全な PreToolUse/PostToolUse 行列 |
| MCP configs | 0 | 1 (Context7) |

既存の Stop フック (`stop-hook-git-check.sh`) は堅実である — 未コミット・未プッシュの作業があるとセッション終了をブロックする。維持しておくべきである。

---

## インストールプロファイル推奨

リポジトリは 5 つのインストールプロファイルを提供する。主な用途に応じて選ぶ:

### Profile: `core` (最小限の有用構成)
> 最速でインストール可能。コマンド、コアエージェント、フックランタイム、品質ワークフローを取得できる。

**最適な用途:** ECC を試す、最小フットプリント、または制約された環境。

```bash
node scripts/install-plan.js --profile core
node scripts/install-apply.js
```

**インストール内容:** rules-core, agents-core, commands-core, hooks-runtime, platform-configs, workflow-quality

---

### Profile: `developer` (日常開発作業向け推奨)
> 多くの ECC ユーザー向けデフォルトエンジニアリングプロファイル。

**最適な用途:** アプリコードベース全般のソフトウェア開発。

```bash
node scripts/install-plan.js --profile developer
node scripts/install-apply.js
```

**core からの追加:** framework-language skills, database patterns, orchestration commands

---

### Profile: `security`
> ベースラインランタイム + セキュリティ特化エージェント・ルール。

**最適な用途:** セキュリティ重視ワークフロー、コード監査、脆弱性レビュー。

---

### Profile: `research`
> 調査、合成、出版ワークフロー。

**最適な用途:** コンテンツ作成、投資家資料、マーケットリサーチ、クロスポスト。

---

### Profile: `full`
> すべて — 18 モジュール全て。

**最適な用途:** 完全なツールキットを求めるパワーユーザー。

```bash
node scripts/install-plan.js --profile full
node scripts/install-apply.js
```

---

## 優先追加項目 (高価値・低リスク)

プロファイルに関係なく、以下のコンポーネントは即時価値をもたらす:

### 1. コアエージェント (最高 ROI)

| Agent | 重要性 |
|-------|--------|
| `planner.md` | 複雑タスクを実装計画に分解する |
| `code-reviewer.md` | 品質と保守性のレビュー |
| `tdd-guide.md` | TDD ワークフロー (RED→GREEN→IMPROVE) |
| `security-reviewer.md` | 脆弱性検出 |
| `architect.md` | システム設計とスケーラビリティ判断 |

### 2. 主要コマンド

| Command | 重要性 |
|---------|--------|
| `/plan` | コーディング前の実装計画 |
| `/tdd` | テスト駆動ワークフロー |
| `/code-review` | オンデマンドレビュー |
| `/build-fix` | ビルドエラー自動解決 |
| `/learn` | 現セッションからパターン抽出 |

### 3. フックアップグレード (`hooks/hooks.json` から)
リポジトリのフックシステムは、現状の単一 Stop フックに以下を追加する:

| Hook | トリガ | 価値 |
|------|--------|------|
| `block-no-verify` | PreToolUse: Bash | `--no-verify` git フラグ濫用をブロック |
| `pre-bash-git-push-reminder` | PreToolUse: Bash | プッシュ前レビューリマインダ |
| `doc-file-warning` | PreToolUse: Write | 非標準ドキュメントファイルを警告 |
| `suggest-compact` | PreToolUse: Edit/Write | 論理的な区切りでコンパクションを提案 |
| Continuous learning observer | PreToolUse: * | スキル改善のためツール利用パターンを記録 |

### 4. Rules (常時ガイドライン)
`rules/common/` ディレクトリは各セッションで発火するベースラインガイドラインを提供する:
- `security.md` — セキュリティガードレール
- `testing.md` — 80% 以上のカバレッジ要件
- `git-workflow.md` — Conventional Commits、ブランチ戦略
- `coding-style.md` — 言語横断スタイル標準

---

## フォークをどうするか

### Option A: アップストリームトラッカーとして使う (現状)
フォークを `affaan-m/everything-claude-code` アップストリームに同期し続ける。定期的にアップストリーム変更をマージする:
```bash
git fetch upstream
git merge upstream/main
```
ローカルクローンからインストールする。これはクリーンで保守しやすい。

### Option B: フォークをカスタマイズ
個人スキル、エージェント、コマンドをフォークに追加する。次の用途に適する:
- ビジネス固有ドメインスキル (自分の業種)
- チーム固有コーディング規約
- 自前スタック向けカスタムフック

フォークには既に EVALUATION.md と REPO-ASSESSMENT.md ドキュメントがある — 作業用フォークなら問題無い。

### Option C: npm からインストール (新規マシンに最も簡単)
```bash
npx ecc-universal install --profile developer
```
リポジトリをクローンする必要が無い。多くのユーザーにはこれが推奨インストール方法である。

---

## 推奨セットアップ手順

1. **既存の Stop フックを維持する** — 役目を果たしている
2. **ローカルフォークから developer プロファイルインストールを実行する**:
   ```bash
   cd /path/to/everything-claude-code
   node scripts/install-plan.js --profile developer
   node scripts/install-apply.js
   ```
3. **主スタック (TypeScript, Python, Go など) の言語ルールを追加する**:
   ```bash
   node scripts/install-plan.js --add rules/typescript
   node scripts/install-apply.js
   ```
4. **ライブドキュメント参照のため MCP Context7 を有効化する**:
   - `mcp-configs/mcp-servers.json` をプロジェクトの `.claude/` ディレクトリにコピーする
5. **フックをレビューする** — `hooks/hooks.json` の追加を選択的に有効化する。`block-no-verify` と `pre-bash-git-push-reminder` から始めるとよい

---

## まとめ

| 質問 | 回答 |
|------|------|
| フォークは健全か? | Yes — アップストリーム v1.9.0 と完全同期 |
| 検討すべき他のフォークは? | この環境では確認できない。アップストリーム `affaan-m/everything-claude-code` が信頼できる情報源である |
| 最適なインストールプロファイルは? | 日常開発作業には `developer` |
| 現状セットアップの最大ギャップは? | エージェント 0 件 — 最低限 planner, code-reviewer, tdd-guide, security-reviewer を追加すべき |
| 最速の成果は? | `node scripts/install-plan.js --profile core && node scripts/install-apply.js` を実行 |

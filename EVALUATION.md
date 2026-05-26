# 現状セットアップとリポジトリの比較評価

**Date:** 2026-03-21
**Branch:** `claude/evaluate-repo-comparison-ASZ9Y`

---

## 現状セットアップ (`~/.claude/`)

アクティブな Claude Code インストールはほぼ最小構成である:

| コンポーネント | 現状 |
|--------------|------|
| Agents | 0 |
| Skills | 0 installed |
| Commands | 0 |
| Hooks | 1 (Stop: git check) |
| Rules | 0 |
| MCP configs | 0 |

**インストール済みフック:**
- `Stop` → `stop-hook-git-check.sh` — 未コミット変更や未プッシュコミットがある場合にセッション終了をブロックする

**インストール済み権限:**
- `Skill` — スキル呼び出しを許可

**プラグイン:** `blocklist.json` のみ (アクティブプラグインはインストールされていない)

---

## 本リポジトリ (`everything-claude-code` v1.9.0)

| コンポーネント | リポジトリ |
|--------------|------------|
| Agents | 28 |
| Skills | 116 |
| Commands | 59 |
| Rules セット | 12 言語 + common (60 以上のルールファイル) |
| Hooks | 包括的なシステム (PreToolUse, PostToolUse, SessionStart, Stop) |
| MCP configs | 1 (Context7 ほか) |
| スキーマ | 9 JSON バリデータ |
| Scripts/CLI | 46 以上の Node.js モジュール + 複数の CLI |
| Tests | 58 テストファイル |
| Install profiles | core, developer, security, research, full |
| サポートハーネス | Claude Code, Codex, Cursor, OpenCode |

---

## ギャップ分析

### Hooks
- **現状:** 1 つの Stop フック (git ハイジーンチェック)
- **リポジトリ:** 以下を網羅するフック行列:
  - 危険コマンドのブロッキング (`rm -rf`, 強制プッシュ)
  - ファイル編集時の自動フォーマット
  - dev サーバーの tmux 強制
  - コスト追跡
  - セッション評価とガバナンス記録
  - MCP ヘルスモニタリング

### Agents (28 不足)
リポジトリは主要ワークフローごとに専門エージェントを提供する:
- 言語レビュアー: TypeScript, Python, Go, Java, Kotlin, Rust, C++, Flutter
- ビルドリゾルバ: Go, Java, Kotlin, Rust, C++, PyTorch
- ワークフローエージェント: planner, tdd-guide, code-reviewer, security-reviewer, architect
- 自動化: loop-operator, doc-updater, refactor-cleaner, harness-optimizer

### Skills (116 不足)
以下を網羅するドメイン知識モジュール:
- 言語パターン (Python, Go, Kotlin, Rust, C++, Java, Swift, Perl, Laravel, Django)
- テスト戦略 (TDD, E2E, カバレッジ)
- アーキテクチャパターン (バックエンド、フロントエンド、API 設計、DB マイグレーション)
- AI/ML ワークフロー (Claude API, eval ハーネス, エージェントループ, コスト意識パイプライン)
- ビジネスワークフロー (投資家資料、マーケットリサーチ、コンテンツエンジン)

### Commands (59 不足)
- `/tdd`, `/plan`, `/e2e`, `/code-review` — コア開発ワークフロー
- `/sessions`, `/save-session`, `/resume-session` — セッション永続化
- `/orchestrate`, `/multi-plan`, `/multi-execute` — マルチエージェント協調
- `/learn`, `/skill-create`, `/evolve` — 継続的改善
- `/build-fix`, `/verify`, `/quality-gate` — ビルド・品質自動化

### Rules (60 以上のファイル不足)
以下の言語固有コーディングスタイル、パターン、テスト、セキュリティガイドライン:
TypeScript, Python, Go, Java, Kotlin, Rust, C++, C#, Swift, Perl, PHP、および共通・横断ルール。

---

## 推奨事項

### 即時価値 (core インストール)
以下を取得するには `ecc install --profile core` を実行する:
- コアエージェント (code-reviewer, planner, tdd-guide, security-reviewer)
- 必須スキル (tdd-workflow, coding-standards, security-review)
- 主要コマンド (/tdd, /plan, /code-review, /build-fix)

### フルインストール
全 28 エージェント、116 スキル、59 コマンドを取得するには `ecc install --profile full` を実行する。

### Hooks アップグレード
現状の Stop フックは堅実である。リポジトリの `hooks.json` は以下を追加する:
- 危険コマンドのブロッキング (安全性)
- 自動フォーマット (品質)
- コスト追跡 (可観測性)
- セッション評価 (学習)

### Rules
言語ルール (例: TypeScript, Python) を追加すると、セッションごとのプロンプトに頼らず常時有効なコーディングガイドラインが得られる。

---

## 現状セットアップの良い点

- `stop-hook-git-check.sh` Stop フックは本番品質であり、既に良好な git ハイジーンを強制している
- `Skill` 権限が正しく構成されている
- セットアップはコンフリクトや雑然さが無くクリーンである

---

## まとめ

現状のセットアップは、適切に実装された 1 つの git ハイジーンフックを持つ、ほぼ白紙の状態である。本リポジトリはエージェント、スキル、コマンド、フック、ルールをカバーする完全な本番テスト済み強化レイヤを提供する。selective install システムにより、設定を肥大化させることなく必要なものだけを正確に追加できる。

# Command → Agent/Skill マップ

本ドキュメントは、各スラッシュコマンドとそれが呼び出す主要エージェントまたはスキル、加えて注目すべき直接呼び出しエージェントをリストする。どのコマンドがどのエージェントを使うかを発見し、リファクタリングの一貫性を保つために使う。

| Command | 主要 agent | 注記 |
|---------|------------|------|
| `/plan` | planner | コード前の実装計画 |
| `/tdd` | tdd-guide | テスト駆動開発 |
| `/code-review` | code-reviewer | 品質・セキュリティレビュー |
| `/build-fix` | build-error-resolver | ビルド・型エラー修正 |
| `/e2e` | e2e-runner | Playwright E2E テスト |
| `/refactor-clean` | refactor-cleaner | デッドコード除去 |
| `/update-docs` | doc-updater | ドキュメント同期 |
| `/update-codemaps` | doc-updater | コードマップ・アーキテクチャドキュメント |
| `/go-review` | go-reviewer | Go コードレビュー |
| `/go-test` | tdd-guide | Go TDD ワークフロー |
| `/go-build` | go-build-resolver | Go ビルドエラー修正 |
| `/python-review` | python-reviewer | Python コードレビュー |
| `/harness-audit` | — | ハーネススコアカード (単一エージェント無し) |
| `/loop-start` | loop-operator | 自律ループ開始 |
| `/loop-status` | loop-operator | ループステータス検査 |
| `/quality-gate` | — | 品質パイプライン (フック様) |
| `/model-route` | — | モデル推奨 (エージェント無し) |
| `/orchestrate` | planner, tdd-guide, code-reviewer, security-reviewer, architect | マルチエージェント引き継ぎ |
| `/multi-plan` | architect (Codex/Gemini プロンプト) | マルチモデル計画 |
| `/multi-execute` | architect / frontend プロンプト | マルチモデル実行 |
| `/multi-backend` | architect | バックエンドマルチサービス |
| `/multi-frontend` | architect | フロントエンドマルチサービス |
| `/multi-workflow` | architect | 汎用マルチサービス |
| `/learn` | — | continuous-learning スキル、instincts |
| `/learn-eval` | — | continuous-learning-v2、評価してから保存 |
| `/instinct-status` | — | continuous-learning-v2 |
| `/instinct-import` | — | continuous-learning-v2 |
| `/instinct-export` | — | continuous-learning-v2 |
| `/evolve` | — | continuous-learning-v2、instincts のクラスタ化 |
| `/promote` | — | continuous-learning-v2 |
| `/projects` | — | continuous-learning-v2 |
| `/skill-create` | — | skill-create-output スクリプト、git 履歴 |
| `/checkpoint` | — | verification-loop スキル |
| `/verify` | — | verification-loop スキル |
| `/eval` | — | eval-harness スキル |
| `/test-coverage` | — | カバレッジ分析 |
| `/sessions` | — | セッション履歴 |
| `/setup-pm` | — | パッケージマネージャセットアップスクリプト |
| `/claw` | — | NanoClaw CLI (scripts/claw.js) |
| `/pm2` | — | PM2 サービスライフサイクル |
| `/security-scan` | security-reviewer (skill) | security-scan スキル経由の AgentShield |

## 直接利用エージェント

| 直接 agent | 目的 | スコープ | 注記 |
|------------|------|----------|------|
| `typescript-reviewer` | TypeScript/JavaScript コードレビュー | TypeScript/JavaScript プロジェクト | レビューに TS/JS 特有の知見が必要で、専用スラッシュコマンドがまだ無い場合に、直接エージェントを呼び出す。 |

## コマンドが参照するスキル

- **continuous-learning**, **continuous-learning-v2**: `/learn`, `/learn-eval`, `/instinct-*`, `/evolve`, `/promote`, `/projects`
- **verification-loop**: `/checkpoint`, `/verify`
- **eval-harness**: `/eval`
- **security-scan**: `/security-scan` (AgentShield を実行)
- **strategic-compact**: コンパクションポイントで提案される (フック)

## このマップの使い方

- **発見可能性:** どのコマンドがどのエージェントをトリガするかを見つける (例: "code-reviewer なら `/code-review` を使う")。
- **リファクタリング:** エージェントを改名・削除する際、本ドキュメントとコマンドファイルで参照を検索する。
- **CI/ドキュメント:** カタログスクリプト (`node scripts/ci/catalog.js`) は agent/command/skill カウントを出力する。本マップはコマンド・エージェント関係でこれを補完する。

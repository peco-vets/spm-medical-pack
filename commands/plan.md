---
description: 要件を言い換え、リスクを評価し、ステップバイステップの実装計画を作成する。コードに触れる前にユーザーの CONFIRM を待つ / Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.
argument-hint: "[feature description | path/to/*.prd.md]"
---

# Plan Command

このコマンドは、コードを書く前に包括的な実装計画を作成する。自由形式の要件または PRD markdown ファイルを受け入れる。

デフォルトでインラインで実行する。デフォルトで Task ツールまたは任意のサブエージェントを呼ばない。これにより、エージェントファイルなしでコマンドを配布するプラグインインストールから `/plan` が使えるようになる。

## このコマンドが行うこと

1. **要件の言い換え** - 何を構築する必要があるかを明確にする
2. **リスクの特定** - 潜在的な問題やブロッカーを表面化する
3. **ステップ計画の作成** - 実装をフェーズに分解する
4. **確認を待つ** - 進む前にユーザー承認を必ず受ける

## 利用シーン

以下の場合に `/plan` を使用する：
- 新機能を開始する
- 重要なアーキテクチャ変更を行う
- 複雑なリファクタリングに取り組む
- 複数のファイル/コンポーネントが影響を受ける
- 要件が不明確または曖昧

## 動作方法

アシスタントは：

1. リクエストを**分析**し、要件を明確な用語で言い換える
2. リポジトリが利用可能な場合、関連するコードベースパターンで**計画をグラウンドする**
3. 具体的で実行可能なステップでフェーズに**分解する**
4. コンポーネント間の依存関係を**特定する**
5. リスクと潜在的ブロッカーを**評価する**
6. 複雑度を**推定する**（High/Medium/Low）
7. 計画を**提示**し、明示的な確認を待つ

## 入力モード

| 入力 | モード | 動作 |
|---|---|---|
| `path/to/name.prd.md` | PRD アーティファクトモード | PRD を読み、次の保留中デリバリマイルストーンまたは実装フェーズを選び、`.claude/plans/{name}.plan.md` を書く |
| 任意の他の markdown パス | 参照モード | コンテキストとしてファイルを読み、インライン計画を生成する |
| 自由形式テキスト | 会話モード | インライン計画を生成する |
| 空の入力 | 明確化モード | 何を計画すべきか尋ねる |

PRD アーティファクトモードでは、必要なら `.claude/plans/` を作成する。PRD が `Delivery Milestones` テーブルを含む場合、選択された行のみを `pending` から `in-progress` に更新し、その `Plan` セルを生成された計画パスに設定する。PRD が `Implementation Phases` 付きのレガシー `.claude/PRPs/prds/` フォーマットを使う場合、パスを移行せずに読む。

## パターングラウンディング

計画を書く前に、実装が反映すべき規約をコードベースで検索する。関連する各カテゴリのトップ例をファイル参照付きで捉える：

| カテゴリ | 何を捉えるか |
|---|---|
| Naming | 影響を受けるエリアでのファイル、関数、型、コマンド、スクリプトの命名 |
| Error handling | 失敗がどう発生、返却、ログ、または優雅に処理されるか |
| Logging | レベル、フォーマット、何がログされるか |
| Data access | リポジトリ、サービス、クエリ、またはファイルシステムパターン |
| Tests | テストファイルの場所、フレームワーク、フィクスチャ、アサーションスタイル |

類似コードが存在しない場合、明示的にそう述べる。パターンを発明しない。

## PRD アーティファクト出力

`.prd.md` ファイルで呼ばれた場合、計画を `.claude/plans/{kebab-case-name}.plan.md` に以下の構造で書く（テンプレートは `# Plan:` ヘッダーで始まり、Summary、Patterns to Mirror、Files to Change、Tasks、Validation、Risks、Acceptance セクションを含む）：

- **Source PRD**：PRD のパス
- **Selected Milestone**：マイルストーンまたはフェーズ名
- **Complexity**：Small / Medium / Large
- **Summary**：2-3 文
- **Patterns to Mirror**：Category、Source、Pattern の表
- **Files to Change**：File、Action（CREATE / UPDATE / DELETE）、Why の表
- **Tasks**：各タスクに Action、Mirror、Validate を含む
- **Validation**：プロジェクト固有の検証コマンド
- **Risks**：Risk、Likelihood、Mitigation の表
- **Acceptance**：すべてのタスク完了、検証通過、パターンが再発明されずに反映されたチェックリスト

アーティファクトを書いた後、そのパスを報告し、コードを書く前に確認を待つ。

## 使用例

User からのリクエスト例：「市場が解決したときにリアルタイム通知を追加したい」

アシスタントは以下のような実装計画を生成する：

- **Requirements Restatement**：ユーザーが監視している市場が解決したときに通知を送る／複数の通知チャネル（in-app、email、webhook）／信頼できる配信を確保／市場結果とユーザーのポジション結果を含める
- **Implementation Phases**：Phase 1（DB スキーマ）、Phase 2（Notification Service）、Phase 3（統合ポイント）、Phase 4（フロントエンドコンポーネント）
- **Dependencies**：Redis（キュー用）、Email サービス（SendGrid/Resend）、Supabase real-time subscriptions
- **Risks**：HIGH: Email deliverability（SPF/DKIM required）、MEDIUM: 1000+ ユーザー時のパフォーマンス、MEDIUM: 通知スパム、LOW: real-time subscription オーバーヘッド
- **Estimated Complexity**：MEDIUM（Backend: 4-6h、Frontend: 3-4h、Testing: 2-3h、合計: 9-13h）

**WAITING FOR CONFIRMATION**: この計画で進めるか？（yes/no/modify）

## 重要事項

**CRITICAL**：このコマンドは、ユーザーが "yes"、"proceed"、または類似の肯定的応答で明示的に計画を確認するまで、**いかなるコードも書かない**。

変更したい場合は、以下のように応答する：
- "modify: [your changes]"
- "different approach: [alternative]"
- "skip phase 2 and do phase 3 first"

## 他のコマンドとの統合

計画後：
- テスト駆動開発で実装するには `tdd-workflow` skill を使う
- ビルドエラーが発生した場合は `/build-fix` を使う
- 完成した実装をレビューするには `/code-review` を使う
- プルリクエストを開くには `/pr` または `/prp-pr` を使う

> **要件が先に必要か？** `/plan-prd` でリーンな PRD を `.claude/prds/{name}.prd.md` に作成する。
>
> **レガシーの PRP フローが必要か？** `/prp-plan` で `.claude/PRPs/` アーティファクトを使った深い PRP 計画を行う。それらの計画を厳格な検証ループで実行するには `/prp-implement` を使う。

## 任意の Planner エージェント

ECC は、エージェントファイルを含む手動インストール用に `planner` エージェントも提供する。ローカルランタイムが既にそのサブエージェントを公開しており、ユーザーが明示的に計画を委譲するよう求める場合のみ使用する。

`planner` サブエージェントが利用不可な場合、「Agent type 'planner' not found」エラーを表示する代わりに、インラインで計画を続行する。

手動インストールでは、ソースファイルは以下にある：
`agents/planner.md`

---
name: blueprint
description: >-
  1 行の目的を、複数セッション・複数エージェントのエンジニアリングプロジェクトの
  ステップバイステップ構築計画に変換する。各ステップにはセルフコンテインドな
  コンテキストブリーフがあり、フレッシュなエージェントがコールドで実行できる。
  敵対的レビューゲート、依存グラフ、並列ステップ検出、アンチパターンカタログ、
  プラン変異プロトコルを含む (blueprint, construction plan, multi-session, multi-agent, dependency graph)。
  TRIGGER when: user requests a plan, blueprint, or roadmap for a
  complex multi-PR task, or describes work that needs multiple sessions.
  DO NOT TRIGGER when: task is completable in a single PR or fewer
  than 3 tool calls, or user says "just do it".
origin: community
---

# Blueprint — 構築計画ジェネレータ

1 行の目的を、任意のコーディングエージェントがコールドで実行できるステップバイステップ構築計画に変換する。

## 利用するタイミング

- 明確な依存順序で大きな機能を複数 PR に分割する
- 複数セッションにまたがるリファクタやマイグレーションを計画する
- サブエージェント間の並列ワークストリームを調整する
- セッション間のコンテキスト喪失で再作業が発生するような任意のタスク

**以下には使用しない**: 単一の PR で完了できるタスク、3 ツール呼び出し未満のタスク、ユーザーが「just do it」と言うタスク。

## 仕組み

Blueprint は 5 フェーズパイプラインを実行する:

1. **Research** — プリフライトチェック (git・gh auth・remote・default branch) を行い、プロジェクト構造、既存プラン、メモリファイルを読んでコンテキストを集める。
2. **Design** — 目的を 1 PR サイズのステップ (典型的には 3〜12) に分解する。ステップごとに依存エッジ、並列/順次順序、モデル階層 (strongest vs default)、ロールバック戦略を割り当てる。
3. **Draft** — セルフコンテインドな Markdown プランファイルを `plans/` に書く。各ステップにコンテキストブリーフ、タスクリスト、検証コマンド、終了基準を含めるため、フレッシュなエージェントが前のステップを読まずに任意のステップを実行できる。
4. **Review** — 敵対的レビューを strongest モデルサブエージェント (例: Opus) にチェックリストとアンチパターンカタログに対して委譲する。最終化前にすべての critical な所見を修正する。
5. **Register** — プランを保存し、メモリインデックスを更新し、ステップ数と並列性サマリをユーザーに提示する。

Blueprint は git/gh の利用可能性を自動検出する。git + GitHub CLI があればフルブランチ/PR/CI ワークフロープランを生成する。なければ direct モード (in-place 編集、ブランチなし) に切り替える。

## 例

### 基本的な使い方

```
/blueprint myapp "migrate database to PostgreSQL"
```

以下のようなステップを持つ `plans/myapp-migrate-database-to-postgresql.md` を生成する:
- Step 1: PostgreSQL ドライバと接続設定を追加
- Step 2: 各テーブルのマイグレーションスクリプトを作成
- Step 3: 新しいドライバを使うようにリポジトリ層を更新
- Step 4: PostgreSQL に対する統合テストを追加
- Step 5: 古いデータベースコードと設定を削除

### マルチエージェントプロジェクト

```
/blueprint chatbot "extract LLM providers into a plugin system"
```

可能な場合並列ステップを持つプラン (例: プラグインインターフェースステップ完了後、「Anthropic プラグインを実装」と「OpenAI プラグインを実装」が並列実行)、モデル階層割り当て (インターフェース設計ステップに strongest、実装に default)、各ステップ後に検証される不変条件 (例:「すべての既存テストがパスする」「core にプロバイダインポートがない」) を生成する。

## 主な機能

- **コールドスタート実行** — 各ステップがセルフコンテインドなコンテキストブリーフを含む。前のコンテキスト不要。
- **敵対的レビューゲート** — すべてのプランは strongest モデルサブエージェントによって、完全性、依存正確性、アンチパターン検出をカバーするチェックリストに対してレビューされる。
- **ブランチ/PR/CI ワークフロー** — すべてのステップに組み込み。git/gh が不在のときは direct モードに優雅に降格する。
- **並列ステップ検出** — 依存グラフが共有ファイルや出力依存のないステップを特定する。
- **プラン変異プロトコル** — ステップは公式プロトコルと監査証跡を伴って分割、挿入、スキップ、並べ替え、放棄できる。
- **ランタイムリスクゼロ** — 純粋な Markdown スキル。リポジトリ全体は `.md` ファイルのみ — フックなし、シェルスクリプトなし、実行コードなし、`package.json` なし、ビルドステップなし。Claude Code のネイティブ Markdown スキルローダー以外、インストールや呼び出し時に何も実行されない。

## インストール

このスキルは Everything Claude Code に同梱されている。ECC がインストールされていれば別途インストール不要。

### フル ECC インストール

ECC リポジトリのチェックアウトから作業しているなら、スキルが存在することを次で確認する:

```bash
test -f skills/blueprint/SKILL.md
```

後で更新するには、更新前に ECC diff をレビューする:

```bash
cd /path/to/everything-claude-code
git fetch origin main
git log --oneline HEAD..origin/main       # review new commits before updating
git checkout <reviewed-full-sha>          # pin to a specific reviewed commit
```

### ベンダリングしたスタンドアロンインストール

フル ECC インストールの外でこのスキルだけをベンダリングしている場合、ECC リポジトリからレビュー済みファイルを `~/.claude/skills/blueprint/SKILL.md` にコピーする。ベンダリングしたコピーは git リモートを持たないため、`git pull` を実行する代わりに、レビュー済みの ECC コミットからファイルを再コピーして更新する。

## 要件

- Claude Code (`/blueprint` スラッシュコマンド用)
- Git + GitHub CLI (オプション — フルブランチ/PR/CI ワークフローを有効化。Blueprint は不在を検出して自動的に direct モードに切り替わる)

## ソース

antbotlab/blueprint にインスパイアされた — アップストリームプロジェクトとリファレンス設計。

---
name: skill-comply
description: スキル、ルール、エージェント定義が実際に守られているかを可視化する（visualize compliance of skills, rules, agent definitions）。3 つのプロンプト厳密性レベルでシナリオを自動生成し、エージェントを実行し、振る舞いシーケンスを分類し、完全なツール呼び出しタイムライン付きでコンプライアンス率を報告する。
origin: ECC
tools: Read, Bash
---

# skill-comply：自動コンプライアンス測定

コーディングエージェントが実際にスキル、ルール、エージェント定義に従っているかを以下によって測定する：
1. 任意の .md ファイルから期待される振る舞いシーケンス（仕様）を自動生成
2. プロンプト厳密性を減少させたシナリオを自動生成（サポート的 → 中立 → 競合）
3. `claude -p` を実行し stream-json 経由でツール呼び出しトレースをキャプチャ
4. 正規表現ではなく LLM を使ってツール呼び出しを仕様ステップに対して分類
5. 時間順序を決定的にチェック
6. 仕様、プロンプト、タイムライン付きの自己完結型レポートを生成

## サポート対象

- **Skills**（`skills/*/SKILL.md`）：search-first、TDD ガイドのようなワークフロースキル
- **Rules**（`rules/common/*.md`）：testing.md、security.md、git-workflow.md のような必須ルール
- **Agent 定義**（`agents/*.md`）：エージェントが期待されるときに呼び出されるかどうか（内部ワークフロー検証はまだサポートされていない）

## 起動するタイミング

- ユーザーが `/skill-comply <path>` を実行
- ユーザーが「このルールは実際に従われているか？」と尋ねる
- 新しいルール／スキルを追加した後、エージェントコンプライアンスを検証するため
- 品質メンテナンスの一環として定期的に

## 使い方

```bash
# Full run
uv run python -m scripts.run ~/.claude/rules/common/testing.md

# Dry run (no cost, spec + scenarios only)
uv run python -m scripts.run --dry-run ~/.claude/skills/search-first/SKILL.md

# Custom models
uv run python -m scripts.run --gen-model haiku --model sonnet <path>
```

## 重要な概念：プロンプト独立性

プロンプトが明示的にサポートしない場合でもスキル／ルールが従われているかを測定する。

## レポート内容

レポートは自己完結型で以下を含む：
1. 期待される振る舞いシーケンス（自動生成された仕様）
2. シナリオプロンプト（各厳密性レベルで何が尋ねられたか）
3. シナリオごとのコンプライアンススコア
4. LLM 分類ラベル付きツール呼び出しタイムライン

### Advanced（オプション）

フックに慣れたユーザー向けに、コンプライアンスが低いステップのためのフック昇格推奨もレポートに含まれる。これは情報提供 — 主な価値はコンプライアンスの可視性そのもの。

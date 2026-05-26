---
name: projects
description: 既知のプロジェクトとその本能（instinct）統計を一覧表示する / List known projects and their instinct statistics
command: true
---

# Projects Command

プロジェクトレジストリエントリと、continuous-learning-v2 のプロジェクトごとの本能/観測件数を一覧表示する。

## 実装

プラグインのルートパスを使って instinct CLI を実行する：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" projects
```

または `CLAUDE_PLUGIN_ROOT` が設定されていない（手動インストール）場合：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py projects
```

## Usage

```bash
/projects
```

## やること

1. `~/.claude/homunculus/projects.json` を読む
2. 各プロジェクトについて以下を表示する：
   - プロジェクト名、id、root、remote
   - 個人および継承された本能の数
   - 観測イベント数
   - 最終確認タイムスタンプ
3. グローバル本能の合計も表示する

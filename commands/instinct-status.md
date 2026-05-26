---
name: instinct-status
description: 学習された本能（project + global）を信頼度と共に表示する / Show learned instincts (project + global) with confidence
command: true
---

# Instinct Status Command

現在のプロジェクトの学習された本能と、グローバル本能をドメインごとにグループ化して表示する。

## 実装

プラグインのルートパスを使って instinct CLI を実行する：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" status
```

または `CLAUDE_PLUGIN_ROOT` が設定されていない（手動インストール）場合は以下を使用する：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py status
```

## Usage

```
/instinct-status
```

## やること

1. 現在のプロジェクトコンテキスト（git remote/path hash）を検出する
2. `~/.claude/homunculus/projects/<project-id>/instincts/` からプロジェクト本能を読む
3. `~/.claude/homunculus/instincts/` からグローバル本能を読む
4. 優先順位ルールでマージする（ID 衝突時はプロジェクトがグローバルを上書き）
5. ドメインごとにグループ化し、信頼度バーと観測統計と共に表示する

## 出力フォーマット

```
============================================================
  INSTINCT STATUS - 12 total
============================================================

  Project: my-app (a1b2c3d4e5f6)
  Project instincts: 8
  Global instincts:  4

## PROJECT-SCOPED (my-app)
  ### WORKFLOW (3)
    ███████░░░  70%  grep-before-edit [project]
              trigger: when modifying code

## GLOBAL (apply to all projects)
  ### SECURITY (2)
    █████████░  85%  validate-user-input [global]
              trigger: when handling user input
```

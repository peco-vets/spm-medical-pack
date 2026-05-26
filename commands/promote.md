---
name: promote
description: プロジェクトスコープの本能（instinct）をグローバルスコープへ昇格する / Promote project-scoped instincts to global scope
command: true
---

# Promote Command

continuous-learning-v2 で、プロジェクトスコープからグローバルスコープへ本能を昇格する。

## 実装

プラグインのルートパスを使って instinct CLI を実行する：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" promote [instinct-id] [--force] [--dry-run]
```

または `CLAUDE_PLUGIN_ROOT` が設定されていない（手動インストール）場合：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py promote [instinct-id] [--force] [--dry-run]
```

## Usage

```bash
/promote                      # Auto-detect promotion candidates
/promote --dry-run            # Preview auto-promotion candidates
/promote --force              # Promote all qualified candidates without prompt
/promote grep-before-edit     # Promote one specific instinct from current project
```

## やること

1. 現在のプロジェクトを検出する
2. `instinct-id` が提供されたら、その本能のみを昇格する（現在のプロジェクトに存在する場合）
3. それ以外の場合、以下を満たすクロスプロジェクト候補を見つける：
   - 少なくとも2つのプロジェクトに出現する
   - 信頼度しきい値を満たす
4. 昇格された本能を `scope: global` 付きで `~/.claude/homunculus/instincts/personal/` に書き出す

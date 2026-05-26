---
name: prune
description: 一度も昇格されなかった 30 日以上前の保留中本能を削除する / Delete pending instincts older than 30 days that were never promoted
command: true
---

# Prune Pending Instincts

自動生成されたが一度もレビューまたは昇格されなかった期限切れの保留中本能を削除する。

## 実装

プラグインのルートパスを使って instinct CLI を実行する：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" prune
```

または `CLAUDE_PLUGIN_ROOT` が設定されていない（手動インストール）場合：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py prune
```

## Usage

```
/prune                    # Delete instincts older than 30 days
/prune --max-age 60      # Custom age threshold (days)
/prune --dry-run         # Preview without deleting
```

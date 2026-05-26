---
name: skill-health
description: チャートと分析付きでスキルポートフォリオのヘルスダッシュボードを表示する / Show skill portfolio health dashboard with charts and analytics
command: true
---

# Skill Health Dashboard

成功率スパークライン、失敗パターンクラスタリング、保留中の修正、バージョン履歴を含む、ポートフォリオ内のすべてのスキルの包括的なヘルスダッシュボードを表示する。

## 実装

skill health CLI をダッシュボードモードで実行する：

```bash
ECC_ROOT="${CLAUDE_PLUGIN_ROOT:-$(node -e "...path-resolution-script...")}"
node "$ECC_ROOT/scripts/skills-health.js" --dashboard
```

特定のパネルのみ：

```bash
node "$ECC_ROOT/scripts/skills-health.js" --dashboard --panel failures
```

機械可読出力：

```bash
node "$ECC_ROOT/scripts/skills-health.js" --dashboard --json
```

## Usage

```
/skill-health                    # Full dashboard view
/skill-health --panel failures   # Only failure clustering panel
/skill-health --json             # Machine-readable JSON output
```

## やること

1. --dashboard フラグで skills-health.js スクリプトを実行する
2. 出力をユーザーに表示する
3. スキルが減少している場合、それらをハイライトし `/evolve` の実行を提案する
4. 保留中の修正がある場合、レビューを提案する

## パネル

- **Success Rate (30d)** — スキルごとの日次成功率を示すスパークラインチャート
- **Failure Patterns** — 水平棒グラフ付きでクラスタリングされた失敗理由
- **Pending Amendments** — レビュー待ちの修正提案
- **Version History** — スキルごとのバージョンスナップショットのタイムライン

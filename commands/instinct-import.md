---
name: instinct-import
description: ファイルまたは URL から project/global スコープへ本能（instincts）をインポートする / Import instincts from file or URL into project/global scope
command: true
---

# Instinct Import Command

## 実装

プラグインのルートパスを使って instinct CLI を実行する：

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" import <file-or-url> [--dry-run] [--force] [--min-confidence 0.7] [--scope project|global]
```

または `CLAUDE_PLUGIN_ROOT` が設定されていない（手動インストール）場合：

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py import <file-or-url>
```

ローカルファイルパスまたは HTTP(S) URL から本能をインポートする。

## Usage

```
/instinct-import team-instincts.yaml
/instinct-import https://github.com/org/repo/instincts.yaml
/instinct-import team-instincts.yaml --dry-run
/instinct-import team-instincts.yaml --scope global --force
```

## やること

1. 本能ファイルを取得する（ローカルパスまたは URL）
2. フォーマットをパースして検証する
3. 既存の本能との重複をチェックする
4. 新しい本能をマージまたは追加する
5. 継承された本能ディレクトリに保存する：
   - Project scope: `~/.claude/homunculus/projects/<project-id>/instincts/inherited/`
   - Global scope: `~/.claude/homunculus/instincts/inherited/`

## インポートプロセス

```
 Importing instincts from: team-instincts.yaml
================================================

Found 12 instincts to import.

Analyzing conflicts...

## New Instincts (8)
These will be added:
  ✓ use-zod-validation (confidence: 0.7)
  ✓ prefer-named-exports (confidence: 0.65)
  ✓ test-async-functions (confidence: 0.8)
  ...

## Duplicate Instincts (3)
Already have similar instincts:
  WARNING: prefer-functional-style
     Local: 0.8 confidence, 12 observations
     Import: 0.7 confidence
     → Keep local (higher confidence)

  WARNING: test-first-workflow
     Local: 0.75 confidence
     Import: 0.9 confidence
     → Update to import (higher confidence)

Import 8 new, update 1?
```

## マージ動作

既存の ID を持つ本能をインポートする場合：
- より高信頼度のインポートは更新候補となる
- 等しい/より低い信頼度のインポートはスキップされる
- `--force` を使わない限り、ユーザーが確認する

## ソース追跡

インポートされた本能には以下のマークが付く：
```yaml
source: inherited
scope: project
imported_from: "team-instincts.yaml"
project_id: "a1b2c3d4e5f6"
project_name: "my-project"
```

## フラグ

- `--dry-run`：インポートせずにプレビュー
- `--force`：確認プロンプトをスキップ
- `--min-confidence <n>`：しきい値以上の本能のみインポート
- `--scope <project|global>`：ターゲットスコープを選択（デフォルト：`project`）

## 出力

インポート後：
```
PASS: Import complete!

Added: 8 instincts
Updated: 1 instinct
Skipped: 3 instincts (equal/higher confidence already exists)

New instincts saved to: ~/.claude/homunculus/instincts/inherited/

Run /instinct-status to see all instincts.
```

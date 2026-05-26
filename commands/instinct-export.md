---
name: instinct-export
description: project/global スコープから本能（instincts）をファイルにエクスポートする / Export instincts from project/global scope to a file
command: /instinct-export
---

# Instinct Export Command

本能を共有可能な形式にエクスポートする。以下に最適：
- チームメイトとの共有
- 新しいマシンへの移行
- プロジェクト規約への貢献

## Usage

```
/instinct-export                           # Export all personal instincts
/instinct-export --domain testing          # Export only testing instincts
/instinct-export --min-confidence 0.7      # Only export high-confidence instincts
/instinct-export --output team-instincts.yaml
/instinct-export --scope project --output project-instincts.yaml
```

## やること

1. 現在のプロジェクトコンテキストを検出する
2. 選択されたスコープで本能を読み込む：
   - `project`：現在のプロジェクトのみ
   - `global`：グローバルのみ
   - `all`：project + global のマージ（デフォルト）
3. フィルター（`--domain`、`--min-confidence`）を適用する
4. YAML スタイルのエクスポートをファイルに書き出す（出力パスが未指定なら stdout）

## 出力フォーマット

YAML ファイルを作成する：

```yaml
# Instincts Export
# Generated: 2025-01-22
# Source: personal
# Count: 12 instincts

---
id: prefer-functional-style
trigger: "when writing new functions"
confidence: 0.8
domain: code-style
source: session-observation
scope: project
project_id: a1b2c3d4e5f6
project_name: my-app
---

# Prefer Functional Style

## Action
Use functional patterns over classes.
```

## フラグ

- `--domain <name>`：指定されたドメインのみエクスポート
- `--min-confidence <n>`：最低信頼度しきい値
- `--output <file>`：出力ファイルパス（省略時は stdout に出力）
- `--scope <project|global|all>`：エクスポートスコープ（デフォルト：`all`）

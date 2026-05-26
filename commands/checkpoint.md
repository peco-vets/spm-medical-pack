---
description: 検証チェック実行後にワークフローのチェックポイントを作成・検証・一覧表示する / Create, verify, or list workflow checkpoints after running verification checks.
---

# Checkpoint Command

ワークフローのチェックポイントを作成または検証する。

## Usage

`/checkpoint [create|verify|list] [name]`

## チェックポイントの作成

チェックポイント作成時：

1. `/verify quick` を実行して現在の状態がクリーンであることを確認する
2. チェックポイント名で git stash またはコミットを作成する
3. チェックポイントを `.claude/checkpoints.log` にログ出力する：

```bash
echo "$(date +%Y-%m-%d-%H:%M) | $CHECKPOINT_NAME | $(git rev-parse --short HEAD)" >> .claude/checkpoints.log
```

4. チェックポイント作成を報告する

## チェックポイントの検証

チェックポイントに対して検証時：

1. ログからチェックポイントを読み込む
2. 現在の状態をチェックポイントと比較する：
   - チェックポイント以降に追加されたファイル
   - チェックポイント以降に変更されたファイル
   - 現在のテスト合格率 vs 当時
   - 現在のカバレッジ vs 当時

3. レポート：
```
CHECKPOINT COMPARISON: $NAME
============================
Files changed: X
Tests: +Y passed / -Z failed
Coverage: +X% / -Y%
Build: [PASS/FAIL]
```

## チェックポイントの一覧

すべてのチェックポイントを以下と一緒に表示：
- 名前
- タイムスタンプ
- Git SHA
- ステータス（現在、遅れ、進み）

## ワークフロー

典型的なチェックポイントフロー：

```
[Start] --> /checkpoint create "feature-start"
   |
[Implement] --> /checkpoint create "core-done"
   |
[Test] --> /checkpoint verify "core-done"
   |
[Refactor] --> /checkpoint create "refactor-done"
   |
[PR] --> /checkpoint verify "feature-start"
```

## 引数

$ARGUMENTS:
- `create <name>` - 名前付きチェックポイントを作成
- `verify <name>` - 名前付きチェックポイントに対して検証
- `list` - すべてのチェックポイントを表示
- `clear` - 古いチェックポイントを削除（直近5件を保持）

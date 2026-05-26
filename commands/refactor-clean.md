---
description: 各変更後の検証付きで、デッドコードを安全に特定して削除する / Safely identify and remove dead code with verification after each change.
---

# Refactor Clean

すべてのステップでテスト検証付きで、デッドコードを安全に特定して削除する。

## Step 1: デッドコード検出

プロジェクトタイプに基づいて分析ツールを実行する：

| Tool | 何を見つけるか | Command |
|------|--------------|---------|
| knip | 未使用 export、ファイル、依存関係 | `npx knip` |
| depcheck | 未使用 npm 依存関係 | `npx depcheck` |
| ts-prune | 未使用 TypeScript export | `npx ts-prune` |
| vulture | 未使用 Python コード | `vulture src/` |
| deadcode | 未使用 Go コード | `deadcode ./...` |
| cargo-udeps | 未使用 Rust 依存関係 | `cargo +nightly udeps` |

ツールが利用できない場合、Grep を使って import がゼロの export を見つける：
```
# Find exports, then check if they're imported anywhere
```

## Step 2: 発見事項を分類する

発見事項を安全ティアにソートする：

| Tier | 例 | アクション |
|------|----------|--------|
| **SAFE** | 未使用ユーティリティ、テストヘルパー、内部関数 | 自信を持って削除 |
| **CAUTION** | コンポーネント、API ルート、ミドルウェア | 動的 import や外部消費者がないことを検証 |
| **DANGER** | config ファイル、エントリポイント、型定義 | 触る前に調査 |

## Step 3: 安全な削除ループ

各 SAFE アイテムについて：

1. **完全なテストスイートを実行** — ベースラインを確立（すべてグリーン）
2. **デッドコードを削除** — 外科的削除のために Edit ツールを使う
3. **テストスイートを再実行** — 何も壊れていないことを検証
4. **テストが失敗** — `git checkout -- <file>` で即座に元に戻し、このアイテムをスキップ
5. **テストが通過** — 次のアイテムへ進む

## Step 4: CAUTION アイテムの処理

CAUTION アイテムを削除する前に：
- 動的 import を検索：`import()`、`require()`、`__import__`
- 文字列参照を検索：config 内のルート名、コンポーネント名
- 公開パッケージ API からエクスポートされているか確認
- 外部消費者がないことを検証（publish されていれば dependents を確認）

## Step 5: 重複を統合する

デッドコードを削除した後、以下を探す：
- ほぼ重複した関数（80% 以上類似） — 1つにマージ
- 冗長な型定義 — 統合
- 価値を追加しないラッパー関数 — インライン化
- 目的のない re-export — 間接化を削除

## Step 6: サマリー

結果を報告する：

```
Dead Code Cleanup
──────────────────────────────
Deleted:   12 unused functions
           3 unused files
           5 unused dependencies
Skipped:   2 items (tests failed)
Saved:     ~450 lines removed
──────────────────────────────
All tests passing PASS:
```

## ルール

- **テスト実行前に削除しない**
- **一度に1つの削除** — アトミックな変更はロールバックを容易にする
- **不確実ならスキップ** — プロダクションを壊すよりデッドコードを残す方がよい
- **クリーニング中にリファクタしない** — 関心事を分離する（先にクリーン、後でリファクタ）

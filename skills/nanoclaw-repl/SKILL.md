---
name: nanoclaw-repl
description: claude -p 上に構築された ECC のゼロ依存セッション対応 REPL である NanoClaw v2 を運用・拡張する (Operate and extend NanoClaw v2, ECC's zero-dependency session-aware REPL built on claude -p)。
origin: ECC
---

# NanoClaw REPL

`scripts/claw.js` を実行・拡張するときにこのスキルを使う。

## 機能

- 永続的なマークダウンバックエンドセッション
- `/model` でのモデル切り替え
- `/load` での動的スキルロード
- `/branch` でのセッション分岐
- `/search` でのクロスセッション検索
- `/compact` での履歴圧縮
- `/export` での md/json/txt へのエクスポート
- `/metrics` でのセッションメトリクス

## 運用ガイダンス

1. セッションをタスク中心に保つ
2. 高リスク変更の前に分岐する
3. 主要マイルストーン後に圧縮する
4. 共有またはアーカイブ前にエクスポートする

## 拡張ルール

- 外部ランタイム依存ゼロを保つ
- マークダウン-アズ-データベース互換性を保持する
- コマンドハンドラを決定的かつローカルに保つ

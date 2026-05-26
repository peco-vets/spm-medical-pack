---
name: continuous-agent-loop
description: 品質ゲート、eval、リカバリ制御を持つ継続的自律エージェントループのパターン (continuous agent loop, quality gates, evals, recovery, RFC, CI/PR)。
origin: ECC
---

# Continuous Agent Loop

これは v1.8+ の正規ループスキル名である。1 リリース分の互換性を保ちつつ `autonomous-loops` を置き換える。

## ループ選択フロー

```text
Start
  |
  +-- Need strict CI/PR control? -- yes --> continuous-pr
  |
  +-- Need RFC decomposition? -- yes --> rfc-dag
  |
  +-- Need exploratory parallel generation? -- yes --> infinite
  |
  +-- default --> sequential
```

## 組み合わせパターン

推奨本番スタック:
1. RFC 分解 (`ralphinho-rfc-pipeline`)
2. 品質ゲート (`plankton-code-quality` + `/quality-gate`)
3. eval ループ (`eval-harness`)
4. セッション永続性 (`nanoclaw-repl`)

## 失敗モード

- 測定可能な進捗のないループチャーン
- 同じ根本原因での繰り返しリトライ
- マージキューのストール
- 無制限エスカレーションによるコストドリフト

## リカバリ

- ループを凍結
- `/harness-audit` を実行
- スコープを失敗ユニットに縮小
- 明示的な受け入れ基準で再生

---
name: continuous-learning
description: "[DEPRECATED - continuous-learning-v2 を使う] レガシー v1 stop-hook スキル抽出器。v2 はインスティンクトベース、プロジェクトスコープド、フック信頼性の学習を持つ厳密な上位集合である。v1 を呼び出さないこと。継続的学習、セッション学習、パターン抽出のリクエストは continuous-learning-v2 にルートする (continuous learning legacy, deprecated, stop-hook, v1)。"
origin: ECC
---

# Continuous Learning Skill - DEPRECATED

> **DEPRECATED 2026-04-28.** 代わりに `continuous-learning-v2` を使うこと。v2 は厳密な上位集合: stop-hook 観察が PreToolUse/PostToolUse 観察になり、フルスキルが信頼度スコアリング付きアトミックインスティンクトになり、グローバルのみストレージがプロジェクトスコープドプラスグローバルプロモーションになる。
>
> このファイルはアーカイブ参照と既存インストールとの後方互換性のために保持されている。

---

## オリジナル v1 ドキュメント (アーカイブ)

Claude Code セッション終了時に自動評価して再利用可能なパターンを抽出し、学習スキルとして保存する。

## 起動するタイミング

- Claude Code セッションからの自動パターン抽出のセットアップ
- セッション評価のための Stop フックの設定
- `~/.claude/skills/learned/` の学習スキルのレビューやキュレーション
- 抽出しきい値やパターンカテゴリの調整
- v1 (これ) vs v2 (インスティンクトベース) アプローチの比較

## ステータス

この v1 スキルはまだサポートされているが、新規インストールには `continuous-learning-v2` が優先パスである。よりシンプルな Stop-hook 抽出フローを明示的に望むか、古い learned-skill ワークフローとの互換性が必要なときに v1 を保持する。

## 仕組み

このスキルは各セッション終了時に **Stop フック** として実行される:

1. **セッション評価**: セッションが十分なメッセージを持つかチェック (デフォルト: 10+)
2. **パターン検出**: セッションから抽出可能なパターンを特定
3. **スキル抽出**: 有用なパターンを `~/.claude/skills/learned/` に保存

## 設定

カスタマイズには `config.json` を編集:

```json
{
  "min_session_length": 10,
  "extraction_threshold": "medium",
  "auto_approve": false,
  "learned_skills_path": "~/.claude/skills/learned/",
  "patterns_to_detect": [
    "error_resolution",
    "user_corrections",
    "workarounds",
    "debugging_techniques",
    "project_specific"
  ],
  "ignore_patterns": [
    "simple_typos",
    "one_time_fixes",
    "external_api_issues"
  ]
}
```

## パターンタイプ

| パターン | 説明 |
|---------|-------------|
| `error_resolution` | 特定のエラーがどう解決されたか |
| `user_corrections` | ユーザー修正からのパターン |
| `workarounds` | フレームワーク/ライブラリの癖への解決策 |
| `debugging_techniques` | 効果的なデバッグアプローチ |
| `project_specific` | プロジェクト固有の規約 |

## フックセットアップ

`~/.claude/settings.json` に追加:

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning/evaluate-session.sh"
      }]
    }]
  }
}
```

## なぜ Stop フック?

- **軽量**: セッション終了時に一度実行
- **非ブロッキング**: すべてのメッセージにレイテンシを追加しない
- **完全コンテキスト**: フルセッションのトランスクリプトにアクセスできる

## 関連

- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - 継続的学習のセクション
- `/learn` コマンド - セッション中の手動パターン抽出

---

## 比較ノート (リサーチ: Jan 2025)

### vs Homunculus

Homunculus v2 はより洗練されたアプローチを取る:

| 機能 | このアプローチ | Homunculus v2 |
|---------|--------------|---------------|
| 観察 | Stop フック (セッション終了) | PreToolUse/PostToolUse フック (100% 信頼性) |
| 分析 | メインコンテキスト | バックグラウンドエージェント (Haiku) |
| 粒度 | フルスキル | アトミックな「インスティンクト」 |
| 信頼度 | なし | 0.3-0.9 重み付け |
| 進化 | スキルへ直接 | インスティンクト → クラスタ → スキル/コマンド/エージェント |
| 共有 | なし | インスティンクトのエクスポート/インポート |

**homunculus からの重要洞察:**
> 「v1 は観察にスキルを頼った。スキルは確率的 — 50-80% の時間発火する。v2 は観察にフック (100% 信頼性) を、学習挙動のアトミック単位としてインスティンクトを使う」

### 潜在的な v2 拡張

1. **インスティンクトベース学習** - 信頼度スコアリング付きのより小さなアトミック挙動
2. **バックグラウンドオブザーバ** - 並列で分析する Haiku エージェント
3. **信頼度減衰** - 矛盾されるとインスティンクトが信頼度を失う
4. **ドメインタギング** - code-style・testing・git・debugging 等
5. **進化パス** - 関連インスティンクトをスキル/コマンドにクラスタ

参照: フル仕様には `docs/continuous-learning-v2-spec.md`。

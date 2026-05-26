---
name: context-budget
description: Claude Code セッションにわたるエージェント、スキル、MCP サーバ、ルールのコンテキストウィンドウ消費を監査する。肥大化、冗長コンポーネントを特定し、優先順位付きのトークン節約推奨を生成する (context budget, token, audit, bloat, MCP, skills, agents, optimization)。
origin: ECC
---

# Context Budget

Claude Code セッションでロードされたすべてのコンポーネントにわたるトークンオーバーヘッドを分析し、コンテキストスペースを取り戻すための実行可能な最適化を表面化する。

## 利用するタイミング

- セッションパフォーマンスが鈍く感じる、または出力品質が劣化している
- 多くのスキル・エージェント・MCP サーバを最近追加した
- 実際にどれだけのコンテキストヘッドルームがあるかを知りたい
- さらにコンポーネントを追加する計画があり余地があるか知る必要がある
- `/context-budget` コマンドを実行 (このスキルがバックする)

## 仕組み

### Phase 1: インベントリ

すべてのコンポーネントディレクトリをスキャンしトークン消費を推定する:

**Agents** (`agents/*.md`)
- ファイルごとの行数とトークン数をカウント (語数 × 1.3)
- `description` frontmatter の長さを抽出
- フラグ: 200 行を超えるファイル (重い)、30 語を超える description (肥大化した frontmatter)

**Skills** (`skills/*/SKILL.md`)
- SKILL.md ごとのトークン数をカウント
- フラグ: 400 行を超えるファイル
- `.agents/skills/` の重複コピーをチェック — 二重カウントを避けるため同一コピーをスキップ

**Rules** (`rules/**/*.md`)
- ファイルごとのトークン数をカウント
- フラグ: 100 行を超えるファイル
- 同じ言語モジュール内のルールファイル間のコンテンツ重複を検出

**MCP Servers** (`.mcp.json` またはアクティブな MCP 設定)
- 設定されたサーバと合計ツール数をカウント
- ツール当たり〜500 トークンでスキーマオーバーヘッドを推定
- フラグ: 20 を超えるツールを持つサーバ、シンプルな CLI コマンド (`gh`・`git`・`npm`・`supabase`・`vercel`) をラップするサーバ

**CLAUDE.md** (プロジェクト + ユーザーレベル)
- CLAUDE.md チェーン内のファイルごとのトークン数をカウント
- フラグ: 合計 300 行を超える

### Phase 2: 分類

すべてのコンポーネントをバケットにソートする:

| バケット | 基準 | アクション |
|--------|----------|--------|
| **常に必要** | CLAUDE.md で参照される、アクティブコマンドをバックする、現在のプロジェクトタイプにマッチする | Keep |
| **時々必要** | ドメイン固有 (例: 言語パターン)、CLAUDE.md で参照されない | オンデマンド起動を検討 |
| **稀に必要** | コマンド参照なし、重複コンテンツ、または明らかなプロジェクトマッチなし | 削除または遅延ロード |

### Phase 3: 問題検出

以下の問題パターンを特定する:

- **肥大化したエージェント description** — frontmatter の 30 語を超える description はすべての Task ツール起動にロードされる
- **重いエージェント** — 200 行を超えるファイルはスポーンごとに Task ツールコンテキストを膨らませる
- **冗長コンポーネント** — エージェントロジックを重複するスキル、CLAUDE.md を重複するルール
- **MCP 過剰購読** — 10 を超えるサーバ、または無料で利用可能な CLI ツールをラップするサーバ
- **CLAUDE.md 肥大化** — 冗長な説明、古いセクション、ルールであるべき指示

### Phase 4: レポート

コンテキスト予算レポートを生成する:

```
Context Budget Report
═══════════════════════════════════════

Total estimated overhead: ~XX,XXX tokens
Context model: Claude Sonnet (200K window)
Effective available context: ~XXX,XXX tokens (XX%)

Component Breakdown:
┌─────────────────┬────────┬───────────┐
│ Component       │ Count  │ Tokens    │
├─────────────────┼────────┼───────────┤
│ Agents          │ N      │ ~X,XXX    │
│ Skills          │ N      │ ~X,XXX    │
│ Rules           │ N      │ ~X,XXX    │
│ MCP tools       │ N      │ ~XX,XXX   │
│ CLAUDE.md       │ N      │ ~X,XXX    │
└─────────────────┴────────┴───────────┘

WARNING: Issues Found (N):
[ranked by token savings]

Top 3 Optimizations:
1. [action] → save ~X,XXX tokens
2. [action] → save ~X,XXX tokens
3. [action] → save ~X,XXX tokens

Potential savings: ~XX,XXX tokens (XX% of current overhead)
```

verbose モードでは、追加でファイルごとのトークン数、最も重いファイルの行ごとの内訳、重複コンポーネント間の特定の冗長行、ツール当たりのスキーマサイズ推定付き MCP ツールリストを出力する。

## 例

**基本監査**
```
User: /context-budget
Skill: Scans setup → 16 agents (12,400 tokens), 28 skills (6,200), 87 MCP tools (43,500), 2 CLAUDE.md (1,200)
       Flags: 3 heavy agents, 14 MCP servers (3 CLI-replaceable)
       Top saving: remove 3 MCP servers → -27,500 tokens (47% overhead reduction)
```

**verbose モード**
```
User: /context-budget --verbose
Skill: Full report + per-file breakdown showing planner.md (213 lines, 1,840 tokens),
       MCP tool list with per-tool sizes, duplicated rule lines side by side
```

**拡張前チェック**
```
User: I want to add 5 more MCP servers, do I have room?
Skill: Current overhead 33% → adding 5 servers (~50 tools) would add ~25,000 tokens → pushes to 45% overhead
       Recommendation: remove 2 CLI-replaceable servers first to stay under 40%
```

## ベストプラクティス

- **トークン推定**: 散文には `words × 1.3`、コード重視ファイルには `chars / 4` を使う
- **MCP が最大のレバー**: 各ツールスキーマは〜500 トークンのコスト。30 ツールサーバはすべてのスキル合計より多くコストがかかる
- **エージェント description は常にロードされる**: エージェントが決して呼び出されなくても、その description フィールドはすべての Task ツールコンテキストに存在する
- **デバッグのための verbose モード**: 通常の監査ではなく、オーバーヘッドを駆動する正確なファイルを特定する必要があるときに使う
- **変更後に監査**: 任意のエージェント・スキル・MCP サーバを追加した後に実行し、クリープを早期にキャッチする

---
name: cost-tracking
description: ローカルコスト追跡データベースから Claude Code のトークン使用量、支出、予算を追跡・レポートする。ユーザーがコスト、支出、使用量、トークン、予算、プロジェクト/ツール/セッション/日付ごとのコスト内訳について尋ねるときに使う (cost tracking, token usage, spending, budget, SQLite, Claude Code)。
origin: community
---

# Cost Tracking

このスキルを使ってローカル SQLite データベースから Claude Code のコストと使用履歴を分析する。`~/.claude-cost-tracker/usage.db` に使用量行を書き込むコスト追跡フックやプラグインを既に持っているユーザー向けに設計されている。

ソース: `MayurBhavsar` によるステイル化したコミュニティ PR #1304 から救出。

## 利用するタイミング

- ユーザーが「いくら使った?」「このセッションのコストは?」「トークン使用量は?」と尋ねる
- ユーザーが予算、支出制限、オーバーラン、コスト制御を言及する
- ユーザーがプロジェクト、ツール、セッション、モデル、日付ごとのコスト内訳を望む
- ユーザーが今日と昨日を比較したい、または最近のトレンドを検査したい
- ユーザーが最近の使用記録の CSV エクスポートを求める

## 仕組み

最初に前提条件を検証する:

```bash
command -v sqlite3 >/dev/null && echo "sqlite3 available" || echo "sqlite3 missing"
test -f ~/.claude-cost-tracker/usage.db && echo "Database found" || echo "Database not found"
```

データベースが欠落しているなら、使用量データを捏造しない。コスト追跡が設定されていないことをユーザーに伝え、信頼できるローカルコスト追跡フック/プラグインのインストールや有効化を提案する。

期待される `usage` テーブルは通常、ツール呼び出しまたはモデルインタラクションごとに 1 行を含む。カラム名はトラッカーごとに異なるが、下記の例は以下を仮定する:

| カラム | 意味 |
| --- | --- |
| `timestamp` | 使用量イベントの ISO タイムスタンプ |
| `project` | プロジェクトまたはリポジトリ名 |
| `tool_name` | ツールまたはイベント名 |
| `input_tokens` | 記録されたときの入力トークン数 |
| `output_tokens` | 記録されたときの出力トークン数 |
| `cost_usd` | USD で事前計算されたコスト |
| `session_id` | Claude Code セッション識別子 |
| `model` | イベントに使われたモデル |

価格を手計算するより `cost_usd` を優先する。モデル価格とキャッシュ価格は時間とともに変わり、トラッカーが各行がどう価格付けされたかの真実のソースであるべき。

## 例

### クイックサマリ

```bash
sqlite3 ~/.claude-cost-tracker/usage.db "
  SELECT
    'Today: $' || ROUND(COALESCE(SUM(CASE WHEN date(timestamp) = date('now') THEN cost_usd END), 0), 4) ||
    ' | Total: $' || ROUND(COALESCE(SUM(cost_usd), 0), 4) ||
    ' | Calls: ' || COUNT(*) ||
    ' | Sessions: ' || COUNT(DISTINCT session_id)
  FROM usage;
"
```

### プロジェクトごとのコスト

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT project, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY project
  ORDER BY cost DESC;
"
```

### ツールごとのコスト

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT tool_name, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY tool_name
  ORDER BY cost DESC;
"
```

### 過去 7 日

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT date(timestamp) AS date, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY date(timestamp)
  ORDER BY date DESC
  LIMIT 7;
"
```

### セッションドリルダウン

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT session_id,
    MIN(timestamp) AS started,
    MAX(timestamp) AS ended,
    ROUND(SUM(cost_usd), 4) AS cost,
    COUNT(*) AS calls
  FROM usage
  GROUP BY session_id
  ORDER BY started DESC
  LIMIT 10;
"
```

## レポーティングガイダンス

コストデータを提示する際、以下を含める:

1. 今日の支出と昨日の比較。
2. 追跡されたデータベース全体の総支出。
3. コストでランクされたトッププロジェクト。
4. コストでランクされたトップツール。
5. 十分なデータがあるときのセッション数とセッション当たり平均コスト。

少額には小数点第 4 位まで通貨フォーマット。大額には小数点第 2 位で十分。

## アンチパターン

- `cost_usd` が存在するときに生のトークン数からコストを推定しない。
- データベースが存在するか確認せずに仮定しない。
- 大きなデータベースで無制限の `SELECT *` エクスポートを実行しない。
- ユーザー向け回答で現在のモデル価格をハードコードしない。
- 任意コードを実行するレビュー未済のフックやプラグインのインストールを推奨しない。

## 関連

- `/cost-report` - 同じデータベースを使うコマンド形式のレポート。
- `cost-aware-llm-pipeline` - モデルルーティングと予算設計パターン。
- `token-budget-advisor` - コンテキストとトークン予算プランニング。
- `strategic-compact` - 繰り返しのトークン支出を減らすコンテキスト圧縮。

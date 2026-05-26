---
description: cost-tracker SQLite データベースからローカルの Claude Code コストレポートを生成する / Generate a local Claude Code cost report from a cost-tracker SQLite database.
argument-hint: [csv]
---

# Cost Report

ローカルのコスト追跡データベースをクエリし、日・プロジェクト・ツール・セッション別の利用レポートを提示する。このコマンドは、コスト追跡のフックまたはプラグインが既に `~/.claude-cost-tracker/usage.db` に利用行を書き込んでいることを前提とする。

## このコマンドが行うこと

1. `sqlite3` が利用可能かを確認する。
2. `~/.claude-cost-tracker/usage.db` が存在するかを確認する。
3. `usage` テーブルに対して集計クエリを実行する。
4. コンパクトなレポートを提示する。引数が `csv` の場合は直近の行を CSV としてエクスポートする。

## 前提条件

このデータベースはローカルのコストトラッカーによって埋められなければならない。ファイルがない場合、トラッカーがセットアップされていないことをユーザーに伝え、信頼できる Claude Code のコスト追跡フック/プラグインをまずインストールまたは有効化することを提案する。

```bash
test -f ~/.claude-cost-tracker/usage.db && echo "Database found" || echo "Database not found"
```

## サマリークエリ

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT
    ROUND(COALESCE(SUM(CASE WHEN date(timestamp) = date('now') THEN cost_usd END), 0), 4) AS today_cost,
    ROUND(COALESCE(SUM(CASE WHEN date(timestamp) = date('now', '-1 day') THEN cost_usd END), 0), 4) AS yesterday_cost,
    ROUND(COALESCE(SUM(cost_usd), 0), 4) AS total_cost,
    COUNT(*) AS total_calls,
    COUNT(DISTINCT session_id) AS sessions
  FROM usage;
"
```

## プロジェクト別内訳

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT project, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY project
  ORDER BY cost DESC;
"
```

## ツール別内訳

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT tool_name, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY tool_name
  ORDER BY cost DESC;
"
```

## 直近7日間

```bash
sqlite3 -header -column ~/.claude-cost-tracker/usage.db "
  SELECT date(timestamp) AS date, ROUND(SUM(cost_usd), 4) AS cost, COUNT(*) AS calls
  FROM usage
  GROUP BY date(timestamp)
  ORDER BY date DESC
  LIMIT 7;
"
```

## CSV エクスポート

ユーザーが `/cost-report csv` を要求する場合、明示的なカラムリストで直近の利用行をエクスポートする：

```bash
sqlite3 -csv -header ~/.claude-cost-tracker/usage.db "
  SELECT timestamp, project, tool_name, input_tokens, output_tokens, cost_usd, session_id, model
  FROM usage
  ORDER BY timestamp DESC
  LIMIT 100;
"
```

## レポートフォーマット

応答を以下のようにフォーマットする：

1. サマリー：今日、昨日、合計、コール数、セッション数。
2. プロジェクト別：合計コストで順位付けされたプロジェクト。
3. ツール別：合計コストで順位付けされたツール。
4. 直近7日間：日付、コスト、コール数。

ドル未満の金額には小数点以下4桁を使用する。このコマンド内で生のトークンから価格を推定してはならない。トラッカーが書き込んだ事前計算済みの `cost_usd` 値に依存すること。

## Source

`MayurBhavsar` による古いコミュニティ PR #1304 から救出した。

---
description: アクティブなループ状態、進捗、失敗シグナル、推奨される介入を調査する / Inspect active loop state, progress, failure signals, and recommended intervention.
---

# Loop Status Command

アクティブなループ状態、進捗、失敗シグナルを調査する。

このスラッシュコマンドは、現在のセッションがそれをデキューした後のみ実行できる。
ウェッジしたセッションや兄弟セッションを調査する必要がある場合は、別のターミナルから
パッケージされた CLI を実行する：

```bash
npx --package ecc-universal ecc loop-status --json
```

CLI は `~/.claude/projects/**` の下のローカル Claude transcript JSONL ファイルを
スキャンし、stale な `ScheduleWakeup` 呼び出しや `tool_result` がマッチしない `Bash`
ツール呼び出しを報告する。

## Usage

`/loop-status [--watch]`

## 報告内容

- アクティブなループパターン
- 現在のフェーズと最後に成功したチェックポイント
- 失敗しているチェック（もしあれば）
- 推定時間/コストのドリフト
- 推奨される介入（continue/pause/stop）

## クロスセッション CLI

- `ecc loop-status --json` は最近のローカル Claude transcript に対して機械可読なステータスを出力する。
- `ecc loop-status --home <dir>` は別のローカルプロファイルやマウントされたワークスペースを調査するときに別のホームディレクトリをスキャンする。
- `ecc loop-status --transcript <session.jsonl>` は1つの transcript を直接調査する。
- `ecc loop-status --bash-timeout-seconds 1800` は stale Bash しきい値を調整する。
- `ecc loop-status --exit-code` は stale ループまたはツールシグナルが見つかった場合に `2` で終了し、transcript がスキャンできない場合は `1` で終了する。
- `--exit-code` と `--watch` の併用は `--watch-count` を必須とし、watchdog スクリプトがプロセスの終了を永久に待たないようにする。
- `ecc loop-status --watch` は中断されるまでステータスを更新する。
- `ecc loop-status --watch --watch-count 3 --exit-code` は有界な回数だけ更新し、最高のステータスで終了する。
- `ecc loop-status --watch --watch-count 3` はスクリプトと引き継ぎのために有界な watch ストリームを出力する。
- `ecc loop-status --watch --write-dir ~/.claude/loops` は兄弟ターミナルや watchdog スクリプト用に `index.json` とセッションごとの JSON スナップショットを維持する。

## Watch モード

`--watch` が存在する場合、ステータスを定期的に更新する。`--json` と共に使うと、各
更新が1行に1つの JSON オブジェクトとして出力されるため、別のターミナルやスクリプトが
ストリームを消費できる。

## スナップショットファイル

別のプロセスが現在の Claude セッションが `/loop-status` をデキューするのを待たずに
ループ状態を調査する必要がある場合は、`--write-dir <dir>` を使う。CLI は以下を書き出す：

- 調査されたセッションごとに1行を持つ `index.json`。
- そのセッションの完全なステータスペイロードを持つ `<session-id>.json`。

これらのファイルはローカル transcript 分析のスナップショットである。Claude Code の
ランタイムツール呼び出しを制御またはタイムアウトしない。

## 引数

$ARGUMENTS:
- `--watch` 任意

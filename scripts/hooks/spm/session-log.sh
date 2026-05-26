#!/bin/bash
# spm-medical-pack: Stop hook
# セッション終了時に編集ファイル一覧・タイムスタンプを ~/.claude/session-logs/ に記録
# LLM 呼び出しは行わない（軽量・確実）。LLM 抽出は /distill-recent-session を後で実行する。

set -euo pipefail

LOG_DIR="$HOME/.claude/session-logs"
mkdir -p "$LOG_DIR"

# Stop hook は stdin で JSON を受け取る
# { "session_id": "...", "transcript_path": "...", "cwd": "...", ... }
INPUT=$(cat)

# タイムスタンプ
TS=$(date +"%Y-%m-%d_%H%M%S")
LOG_FILE="$LOG_DIR/$TS.md"

# 入力 JSON から情報抽出（jq があれば、なければ簡易 grep/sed）
if command -v jq >/dev/null 2>&1; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
  TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
  CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
else
  SESSION_ID=$(echo "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  TRANSCRIPT=$(echo "$INPUT" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  CWD=$(echo "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

SESSION_ID=${SESSION_ID:-unknown}
TRANSCRIPT=${TRANSCRIPT:-}
CWD=${CWD:-$(pwd)}

# transcript からツール使用統計を抽出（軽い）
EDITED_FILES=""
BASH_COMMANDS=""
TOOL_COUNT_EDIT=0
TOOL_COUNT_WRITE=0
TOOL_COUNT_BASH=0

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  if command -v jq >/dev/null 2>&1; then
    # Edit / Write された file_path を全件
    EDITED_FILES=$(jq -r 'select(.message.content) | .message.content[]? | select(.type == "tool_use") | select(.name == "Edit" or .name == "Write") | .input.file_path // empty' "$TRANSCRIPT" 2>/dev/null | sort -u || true)
    TOOL_COUNT_EDIT=$(jq -r 'select(.message.content) | .message.content[]? | select(.type == "tool_use" and .name == "Edit") | .name' "$TRANSCRIPT" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    TOOL_COUNT_WRITE=$(jq -r 'select(.message.content) | .message.content[]? | select(.type == "tool_use" and .name == "Write") | .name' "$TRANSCRIPT" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    TOOL_COUNT_BASH=$(jq -r 'select(.message.content) | .message.content[]? | select(.type == "tool_use" and .name == "Bash") | .name' "$TRANSCRIPT" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
  fi
fi

# ログ書き込み
cat > "$LOG_FILE" <<EOF
---
session_id: $SESSION_ID
timestamp: $TS
cwd: $CWD
transcript: $TRANSCRIPT
tool_counts:
  edit: $TOOL_COUNT_EDIT
  write: $TOOL_COUNT_WRITE
  bash: $TOOL_COUNT_BASH
---

# セッション $TS の記録

## 編集されたファイル

$(if [ -n "$EDITED_FILES" ]; then echo "$EDITED_FILES" | sed 's/^/- /'; else echo "（編集なし）"; fi)

## ツール呼出回数
- Edit: $TOOL_COUNT_EDIT
- Write: $TOOL_COUNT_WRITE
- Bash: $TOOL_COUNT_BASH

## ルール抽出ステータス
**未抽出** — /distill-recent-session で抽出可能

## 関連
- transcript: $TRANSCRIPT
- cwd: $CWD
EOF

echo "[spm-session-log] saved: $LOG_FILE" >&2
exit 0

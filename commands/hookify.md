---
description: 会話分析または明示的な指示から、不要な振る舞いを防ぐためのフックを作成する / Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions
---

会話パターンの分析または明示的なユーザー指示によって、不要な Claude Code の振る舞いを防ぐためのフックルールを作成する。

## Usage

`/hookify [description of behavior to prevent]`

引数が提供されない場合、現在の会話を分析して防ぐ価値のある振る舞いを見つける。

## ワークフロー

### Step 1: 振る舞いの情報を集める

- 引数あり：ユーザーの不要な振る舞いの説明をパースする
- 引数なし：`conversation-analyzer` エージェントを使って以下を見つける：
  - 明示的な訂正
  - 繰り返されるミスへのフラストレーションリアクション
  - 元に戻された変更
  - 繰り返される類似の問題

### Step 2: 発見事項を提示する

ユーザーに以下を表示する：

- 振る舞いの説明
- 提案されるイベントタイプ
- 提案されるパターンまたはマッチャー
- 提案されるアクション

### Step 3: ルールファイル生成

承認された各ルールについて、`.claude/hookify.{name}.local.md` にファイルを作成する：

```yaml
---
name: rule-name
enabled: true
event: bash|file|stop|prompt|all
action: block|warn
pattern: "regex pattern"
---
Message shown when rule triggers.
```

### Step 4: 確認

作成されたルールと、`/hookify-list` と `/hookify-configure` でそれらを管理する方法を報告する。

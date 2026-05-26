# セッションアダプタコントラクト

本ドキュメントは `ecc.session.v1` の canonical ECC セッションスナップショットコントラクトを定義する。

コントラクトは `scripts/lib/session-adapters/canonical-session.js` で実装されている。本ドキュメントはアダプタとコンシューマのための規範的仕様である。

## 目的

ECC は複数のセッションソースを持つ:

- tmux オーケストレーション worktree セッション
- Claude ローカルセッション履歴
- 将来のハーネスとコントロールプレーンバックエンド

アダプタはそれらソースをコントロールプレーン安全な 1 つのスナップショット形状に正規化する。検査、永続化、将来の UI レイヤがハーネス固有ファイルやランタイム詳細に依存しないようにするためである。

## Canonical スナップショット

すべてのアダプタはこのトップレベル形状の JSON シリアライズ可能オブジェクトを返さなければならない (MUST):

```json
{
  "schemaVersion": "ecc.session.v1",
  "adapterId": "dmux-tmux",
  "session": {
    "id": "workflow-visual-proof",
    "kind": "orchestrated",
    "state": "active",
    "repoRoot": "/tmp/repo",
    "sourceTarget": {
      "type": "session",
      "value": "workflow-visual-proof"
    }
  },
  "workers": [
    {
      "id": "seed-check",
      "label": "seed-check",
      "state": "running",
      "health": "healthy",
      "branch": "feature/seed-check",
      "worktree": "/tmp/worktree",
      "runtime": {
        "kind": "tmux-pane",
        "command": "codex",
        "pid": 1234,
        "active": false,
        "dead": false
      },
      "intent": {
        "objective": "Inspect seeded files.",
        "seedPaths": ["scripts/orchestrate-worktrees.js"]
      },
      "outputs": {
        "summary": [],
        "validation": [],
        "remainingRisks": []
      },
      "artifacts": {
        "statusFile": "/tmp/status.md",
        "taskFile": "/tmp/task.md",
        "handoffFile": "/tmp/handoff.md"
      }
    }
  ],
  "aggregates": {
    "workerCount": 1,
    "states": {
      "running": 1
    },
    "healths": {
      "healthy": 1
    }
  }
}
```

## 必須フィールド

### トップレベル

| Field | Type | 注記 |
| --- | --- | --- |
| `schemaVersion` | string | このコントラクトでは正確に `ecc.session.v1` でなければならない |
| `adapterId` | string | `dmux-tmux` や `claude-history` のような安定アダプタ識別子 |
| `session` | object | Canonical セッションメタデータ |
| `workers` | array | Canonical worker レコード。空でもよい |
| `aggregates` | object | 派生 worker カウント |

### `session`

| Field | Type | 注記 |
| --- | --- | --- |
| `id` | string | アダプタドメイン内の安定識別子 |
| `kind` | string | `orchestrated` や `history` のような高レベルセッションファミリー |
| `state` | string | Canonical セッション状態 |
| `sourceTarget` | object | セッションを開いたターゲットの provenance |

### `session.sourceTarget`

| Field | Type | 注記 |
| --- | --- | --- |
| `type` | string | `plan`、`session`、`claude-history`、`claude-alias`、`session-file` のようなルックアップクラス |
| `value` | string | 生ターゲット値または解決パス |

### `workers[]`

| Field | Type | 注記 |
| --- | --- | --- |
| `id` | string | アダプタスコープでの安定 worker 識別子 |
| `label` | string | オペレータ向けラベル |
| `state` | string | Canonical worker 状態 (ライフサイクル) |
| `health` | string | Canonical worker 健全度 (運用状態) |
| `runtime` | object | 実行/ランタイムメタデータ |
| `intent` | object | この worker/セッションが存在する理由 |
| `outputs` | object | 構造化結果とチェック |
| `artifacts` | object | アダプタ所有ファイル/パス参照 |

### `workers[].runtime`

| Field | Type | 注記 |
| --- | --- | --- |
| `kind` | string | `tmux-pane` や `claude-session` のようなランタイムファミリー |
| `active` | boolean | ランタイムが今アクティブか |
| `dead` | boolean | ランタイムが死亡/完了したことが分かっているか |

### `workers[].intent`

| Field | Type | 注記 |
| --- | --- | --- |
| `objective` | string | 主目的またはタイトル |
| `seedPaths` | string[] | worker/セッションに関連するシードまたはコンテキストパス |

### `workers[].outputs`

| Field | Type | 注記 |
| --- | --- | --- |
| `summary` | string[] | 完了した出力またはサマリアイテム |
| `validation` | string[] | 検証エビデンスまたはチェック |
| `remainingRisks` | string[] | オープンリスク、フォローアップ、またはノート |

### `aggregates`

| Field | Type | 注記 |
| --- | --- | --- |
| `workerCount` | integer | `workers.length` と等しくなければならない |
| `states` | object | `workers[].state` から派生するカウントマップ |
| `healths` | object | `workers[].health` から派生するカウントマップ |

## オプショナルフィールド

オプショナルフィールドは省略してもよい (MAY) が、発出される場合は文書化された型を保持しなければならない:

| Field | Type | 注記 |
| --- | --- | --- |
| `session.repoRoot` | `string \| null` | 既知の場合のリポジトリ/worktree ルート |
| `workers[].branch` | `string \| null` | 既知の場合のブランチ名 |
| `workers[].worktree` | `string \| null` | 既知の場合の worktree パス |
| `workers[].runtime.command` | `string \| null` | 既知の場合のアクティブコマンド |
| `workers[].runtime.pid` | `number \| null` | 既知の場合のプロセス id |
| `workers[].artifacts.*` | アダプタ定義 | アダプタが所有するファイルパスまたは構造化参照 |

アダプタ固有オプショナルフィールドは `runtime`、`artifacts`、または他の文書化されたネストオブジェクト内に属する。アダプタはこのコントラクトを更新せずに新しいトップレベルフィールドを発明してはならない (MUST NOT)。

## 状態セマンティクス

コントラクトは意図的に `session.state` と `workers[].state` を複数のハーネスに十分柔軟に保つが、現アダプタは以下の値を使う:

- `dmux-tmux`
  - session 状態: `active`、`completed`、`failed`、`idle`、`missing`
  - worker 状態: worker ステータスファイルから派生 (例: `running` や `completed`)
- `claude-history`
  - session 状態: `recorded`
  - worker 状態: `recorded`

コンシューマは未知の状態文字列を有効なアダプタ固有値として扱い、graceful に劣化させなければならない (MUST)。

## バージョニング戦略

`schemaVersion` のみが互換性ゲートである。コンシューマはこれで分岐しなければならない (MUST)。

### `ecc.session.v1` で許可されるもの

- 新しいオプショナルネストフィールドの追加
- 新しいアダプタ id の追加
- 新しい状態文字列値の追加
- 新しい health 文字列値の追加
- `workers[].artifacts` 内の新しい artifact キーの追加

### 新しいスキーマバージョンを必要とするもの

- 必須フィールドの削除
- フィールドの改名
- フィールド型の変更
- 既存フィールドの意味を非互換に変更
- 同じバージョン文字列を保ちつつデータをあるフィールドから別のフィールドに移動

これらのいずれかが発生した場合、プロデューサは `ecc.session.v2` のような新しいバージョン文字列を発出しなければならない (MUST)。

## アダプタ準拠要件

すべての ECC セッションアダプタは以下をしなければならない (MUST):

1. `schemaVersion: "ecc.session.v1"` を正確に発出する。
2. すべての必須フィールドと型を満たすスナップショットを返す。
3. 未知のオプショナルスカラー値には `null` を、未知のリスト値には空配列を使う。
4. アダプタ固有詳細を `runtime`、`artifacts`、または他の文書化されたネストオブジェクト内に保つ。
5. `aggregates.workerCount === workers.length` を保証する。
6. `aggregates.states` が発出された worker 状態と一致することを保証する。
7. `aggregates.healths` が発出された worker health 値と一致することを保証する。
7. プレーン JSON シリアライズ可能値のみを生成する。
8. 永続化またはダウンストリーム利用前に canonical 形状を検証する。
9. セッション記録 shim を通じて正規化された canonical スナップショットを永続化する。本リポジトリでは、shim は最初に `scripts/lib/state-store` を試み、state store モジュールがまだ利用不可な場合のみ JSON 記録ファイルにフォールバックする。

## コンシューマ期待

コンシューマは以下をすべきである (SHOULD):

- `ecc.session.v1` の文書化されたフィールドのみに依存する
- 未知のオプショナルフィールドを無視する
- `adapterId`、`session.kind`、`runtime.kind` を網羅的列挙ではなくルーティングヒントとして扱う
- `workers[].artifacts` 内のアダプタ固有 artifact キーを期待する

コンシューマは以下をしてはならない (MUST NOT):

- 文書化されていないフィールドからハーネス固有挙動を推論
- すべてのアダプタが tmux ペイン、git worktree、または markdown 調整ファイルを持つと仮定
- 状態文字列が見慣れないという理由だけでスナップショットを拒否

## 現アダプタマッピング

### `dmux-tmux`

- ソース: `scripts/lib/orchestration-session.js`
- セッション id: オーケストレーションセッション名
- セッション kind: `orchestrated`
- セッションソースターゲット: プランパスまたはセッション名
- Worker ランタイム kind: `tmux-pane`
- Artifacts: `statusFile`、`taskFile`、`handoffFile`

### `claude-history`

- ソース: `scripts/lib/session-manager.js`
- セッション id: Claude ショート id が存在する場合、なければセッションファイル名由来 id
- セッション kind: `history`
- セッションソースターゲット: 明示的履歴ターゲット、エイリアス、または `.tmp` セッションファイル
- Worker ランタイム kind: `claude-session`
- Intent シードパス: `### Context to Load` からパース
- Artifacts: `sessionFile`、`context`

## 検証リファレンス

リポジトリ実装は以下を検証する:

- 必須オブジェクト構造
- 必須文字列フィールド
- boolean ランタイムフラグ
- 文字列配列 outputs とシードパス
- aggregate カウント整合性

アダプタは検証失敗をユーザー入力エラーではなくコントラクトバグとして扱うべきである。

## 記録フォールバック挙動

JSON フォールバックレコーダは専用 state store が着地する前の一時的互換 shim である。挙動は:

- 最新スナップショットは常に in-place で置き換えられる
- 履歴は明確に異なるスナップショット本体のみを記録する
- 変更無しの繰り返し読み取りは重複履歴エントリを追加しない

これは `session-inspect` や他のポーリング様読み取りが、同じ変更無しセッションスナップショットに対して無制限に履歴を成長させないようにする。

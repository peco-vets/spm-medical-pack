# ECC 2.0 セッションアダプタディスカバリ

## 目的

本ドキュメントは、3 月 11 日 ECC 2.0 コントロールプレーン方針を、本リポジトリに既に存在するオーケストレーションコードに根ざした具体的なアダプタ・スナップショット設計に変える。

## 現在実装されている基盤

リポジトリには既に実際の初期版オーケストレーション基盤がある:

- `scripts/lib/tmux-worktree-orchestrator.js`
  が tmux ペインと分離 git worktree をプロビジョニング
- `scripts/orchestrate-worktrees.js`
  が現行セッションランチャー
- `scripts/lib/orchestration-session.js`
  が機械可読セッションスナップショットを収集
- `scripts/orchestration-status.js`
  がセッション名またはプランファイルからスナップショットをエクスポート
- `commands/sessions.md`
  が Claude のローカルストアから隣接セッション履歴コンセプトを公開
- `scripts/lib/session-adapters/canonical-session.js`
  が canonical な `ecc.session.v1` 正規化レイヤを定義
- `scripts/lib/session-adapters/dmux-tmux.js`
  が現行オーケストレーションスナップショットコレクタをアダプタ `dmux-tmux` としてラップ
- `scripts/lib/session-adapters/claude-history.js`
  が Claude ローカルセッション履歴を 2 つ目のアダプタとして正規化
- `scripts/lib/session-adapters/registry.js`
  が明示的ターゲットとターゲットタイプからアダプタを選択
- `scripts/session-inspect.js`
  がアダプタレジストリ経由で canonical な read-only セッションスナップショットを発出

実際、ECC は既に以下に答えられる:

- tmux オーケストレーションセッションにどの worker が存在するか
- 各 worker がどのペインにアタッチされているか
- 各 worker のどのタスク、ステータス、引き継ぎファイルが存在するか
- セッションがアクティブか、いくつのペイン/worker が存在するか
- 最新の Claude ローカルセッションが、オーケストレーションセッションと同じ canonical スナップショット形状でどう見えるか

これは基盤を証明するには十分である。汎用 ECC 2.0 コントロールプレーンとして資格を持つにはまだ十分ではない。

## 現行スナップショットが実際にモデル化するもの

`scripts/lib/orchestration-session.js` から出る現行スナップショットモデルは以下の有効フィールドを持つ:

```json
{
  "sessionName": "workflow-visual-proof",
  "coordinationDir": ".../.claude/orchestration/workflow-visual-proof",
  "repoRoot": "...",
  "targetType": "plan",
  "sessionActive": true,
  "paneCount": 2,
  "workerCount": 2,
  "workerStates": {
    "running": 1,
    "completed": 1
  },
  "panes": [
    {
      "paneId": "%95",
      "windowIndex": 1,
      "paneIndex": 0,
      "title": "seed-check",
      "currentCommand": "codex",
      "currentPath": "/tmp/worktree",
      "active": false,
      "dead": false,
      "pid": 1234
    }
  ],
  "workers": [
    {
      "workerSlug": "seed-check",
      "workerDir": ".../seed-check",
      "status": {
        "state": "running",
        "updated": "...",
        "branch": "...",
        "worktree": "...",
        "taskFile": "...",
        "handoffFile": "..."
      },
      "task": {
        "objective": "...",
        "seedPaths": ["scripts/orchestrate-worktrees.js"]
      },
      "handoff": {
        "summary": [],
        "validation": [],
        "remainingRisks": []
      },
      "files": {
        "status": ".../status.md",
        "task": ".../task.md",
        "handoff": ".../handoff.md"
      },
      "pane": {
        "paneId": "%95",
        "title": "seed-check"
      }
    }
  ]
}
```

これは既に有用なオペレータペイロードである。主な制限は、それが暗黙的に 1 つの実行スタイルに結びついていることである:

- tmux ペインアイデンティティ
- worker slug がペインタイトルと等しい
- markdown 調整ファイル
- plan-file またはセッション名ルックアップルール

## ECC 1.x と ECC 2.0 のギャップ

ECC 1.x には現在、2 つの異なる「セッション」サーフェスがある:

1. Claude ローカルセッション履歴
2. オーケストレーションランタイム/セッションスナップショット

これらサーフェスは隣接しているが統一されていない。

欠けている ECC 2.0 レイヤは、以下を正規化できるハーネス中立なセッションアダプタ境界である:

- tmux オーケストレーション worker
- プレーン Claude セッション
- Codex worktree セッション
- OpenCode セッション
- 将来の GitHub/App またはリモートコントロールセッション

そのアダプタレイヤが無いと、将来のオペレータ UI は tmux 固有詳細と調整 markdown を直接読まざるを得なくなる。

## アダプタ境界

ECC 2.0 は canonical セッションアダプタコントラクトを導入すべきである。

提案最小インターフェース:

```ts
type SessionAdapter = {
  id: string;
  canOpen(target: SessionTarget): boolean;
  open(target: SessionTarget): Promise<AdapterHandle>;
};

type AdapterHandle = {
  getSnapshot(): Promise<CanonicalSessionSnapshot>;
  streamEvents?(onEvent: (event: SessionEvent) => void): Promise<() => void>;
  runAction?(action: SessionAction): Promise<ActionResult>;
};
```

### Canonical スナップショット形状

提案初期版 canonical ペイロード:

```json
{
  "schemaVersion": "ecc.session.v1",
  "adapterId": "dmux-tmux",
  "session": {
    "id": "workflow-visual-proof",
    "kind": "orchestrated",
    "state": "active",
    "repoRoot": "...",
    "sourceTarget": {
      "type": "plan",
      "value": ".claude/plan/workflow-visual-proof.json"
    }
  },
  "workers": [
    {
      "id": "seed-check",
      "label": "seed-check",
      "state": "running",
      "branch": "...",
      "worktree": "...",
      "runtime": {
        "kind": "tmux-pane",
        "command": "codex",
        "pid": 1234,
        "active": false,
        "dead": false
      },
      "intent": {
        "objective": "...",
        "seedPaths": ["scripts/orchestrate-worktrees.js"]
      },
      "outputs": {
        "summary": [],
        "validation": [],
        "remainingRisks": []
      },
      "artifacts": {
        "statusFile": "...",
        "taskFile": "...",
        "handoffFile": "..."
      }
    }
  ],
  "aggregates": {
    "workerCount": 2,
    "states": {
      "running": 1,
      "completed": 1
    }
  }
}
```

これはコントロールプレーンコントラクトから tmux 固有詳細を削除しつつ、既に存在する有用なシグナルを保持する。

## 最初にサポートするアダプタ

### 1. `dmux-tmux`

`scripts/lib/orchestration-session.js` に既に存在するロジックをラップする。

これは基盤が既に実在するため、最も簡単な初期アダプタである。

### 2. `claude-history`

`commands/sessions.md` と既存セッションマネージャユーティリティが既に公開するデータを正規化する:

- session id / alias
- branch
- worktree
- project path
- recency / file size / item counts

これは ECC 2.0 のための非オーケストレーションベースラインを提供する。

### 3. `codex-worktree`

同じ canonical 形状を使うが、利用可能な箇所では tmux 仮定の代わりに Codex ネイティブ実行メタデータでバックする。

### 4. `opencode`

OpenCode セッションメタデータが正規化に十分安定すれば、同じアダプタ境界を使う。

## アダプタレイヤの外に留めるべきもの

アダプタレイヤは以下を所有すべきでない:

- マージシーケンシングのビジネスロジック
- オペレータ UI レイアウト
- 価格設定や収益化決定
- インストールプロファイル選択
- tmux ライフサイクルオーケストレーション自体

その役割はより狭い:

- セッションターゲットを検出する
- 正規化されたスナップショットをロードする
- オプションでランタイムイベントをストリームする
- オプションで安全なアクションを公開する

## 現行ファイルレイアウト

アダプタレイヤは現在以下にある:

```text
scripts/lib/session-adapters/
  canonical-session.js
  dmux-tmux.js
  claude-history.js
  registry.js
scripts/session-inspect.js
tests/lib/session-adapters.test.js
tests/scripts/session-inspect.test.js
```

現行オーケストレーションスナップショットパーサは現在、唯一のプロダクトコントラクトとして残るのではなく、アダプタ実装として消費されている。

## 直近の次ステップ

1. tmux + Claude-history を超えて抽象が動くよう、3 つ目のアダプタ(おそらく `codex-worktree`)を追加する。
2. UI 作業開始前に、canonical スナップショットに別個の `state` と `health` フィールドが必要か決定する。
3. イベントストリーミングが v1 に属するか、スナップショットレイヤが自己実証するまで除外したままか決定する。
4. オーケストレーション内部を直接読むのではなく、アダプタレジストリの上にのみオペレータ向けパネルを構築する。

## オープン課題

1. worker アイデンティティは worker slug、ブランチ、または安定 UUID でキーすべきか?
2. canonical レイヤで別個の `state` と `health` フィールドが必要か?
3. イベントストリーミングは v1 の一部であるべきか、ECC 2.0 はまずスナップショット専用で出荷すべきか?
4. スナップショットがローカルマシンを離れる前にどれだけのパス情報を redact すべきか?
5. アダプタレジストリは長期的に本リポジトリ内に居続けるべきか、インターフェース安定後に最終的な ECC 2.0 コントロールプレーンアプリに移すべきか?

## 推奨

現行 tmux/worktree 実装を最終プロダクトサーフェスとしてではなく、アダプタ `0` として扱う。

ECC 2.0 への最短パスは:

1. 現行オーケストレーション基盤を保持する
2. それを canonical セッションアダプタコントラクトでラップする
3. 1 つの非 tmux アダプタを追加する
4. その後にのみ、その上にオペレータパネルを構築し始める

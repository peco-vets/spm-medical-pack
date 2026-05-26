# トークン最適化ガイド

トークン消費を減らし、セッション品質を延長し、日次制限内でより多くの作業を行うための実用的設定と習慣。

> 関連: モデル選択戦略には `rules/common/performance.md`、自動 compaction 提案には `skills/strategic-compact/`。

---

## 推奨設定

これらは多くのユーザー向け推奨デフォルトである。パワーユーザーはワークロードに基づいて値をさらにチューニングできる — 例えば、単純タスクには `MAX_THINKING_TOKENS` を低く、複雑なアーキテクチャ作業には高く設定する。

`~/.claude/settings.json` に追加:

```json
{
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  }
}
```

### 各設定の効果

| 設定 | デフォルト | 推奨 | 効果 |
|------|-----------|------|------|
| `model` | opus | **sonnet** | Sonnet はコーディングタスクの約 80% を上手く処理する。複雑な推論は `/model opus` で Opus に切り替える。約 60% のコスト削減。 |
| `MAX_THINKING_TOKENS` | 31,999 | **10,000** | 拡張思考はリクエストごとに内部推論用に最大 31,999 出力トークンを予約する。これを減らすと隠れたコストを約 70% 削減できる。トリビアルなタスクには `0` で無効化。 |
| `CLAUDE_CODE_SUBAGENT_MODEL` | _(メインを継承)_ | **haiku** | サブエージェント (Task ツール) はこのモデルで動作する。Haiku は約 80% 安く、探索、ファイル読み取り、テスト実行に十分。 |
| `ECC_CONTEXT_MONITOR_COST_WARNINGS` | on | **サブスクリプションユーザーには off** | コンテキスト枯渇、スコープ、ループ警告を保ちつつ、エージェント向け API レート見積もり警告を抑制する。 |

### auto-compaction オーバーライドに関するコミュニティノート

最近の一部 Claude Code ビルドでは、`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` が compaction 閾値を下げることしかできないというコミュニティ報告があり、デフォルト以下の値が遅くではなく早く compact する可能性がある。あなたのセットアップでそれが起こるなら、オーバーライドを削除し、手動 `/compact` と ECC の `strategic-compact` ガイダンスに依存する。[トラブルシューティング](./TROUBLESHOOTING.md) を参照。

### 拡張思考の切り替え

- **Alt+T** (Windows/Linux) または **Option+T** (macOS) — オン/オフ切り替え
- **Ctrl+O** — 思考出力を見る (verbose モード)

---

## モデル選択

タスクに正しいモデルを使う:

| モデル | 最適な用途 | コスト |
|--------|-----------|--------|
| **Haiku** | サブエージェント探索、ファイル読み取り、単純ルックアップ | 最低 |
| **Sonnet** | 日常コーディング、レビュー、テスト書き、実装 | 中 |
| **Opus** | 複雑なアーキテクチャ、マルチステップ推論、繊細な問題のデバッグ | 最高 |

セッション中にモデルを切り替える:

```
/model sonnet     # default for most work
/model opus       # complex reasoning
/model haiku      # quick lookups
```

---

## コンテキスト管理

### コマンド

| コマンド | 利用タイミング |
|---------|---------------|
| `/clear` | 無関係なタスク間。陳腐コンテキストは後続メッセージごとにトークンを浪費する。 |
| `/compact` | 論理的タスクブレークポイントで (計画後、デバッグ後、フォーカス切替前)。 |
| `/cost` | 現セッションのトークン支出を確認する。 |

### API レートコスト見積もり警告

ECC のコンテキストモニタはローカルフックテレメトリから API レートコスト見積もりを発出できる。Claude サブスクリプションを使っていてそれら見積もりが実際の請求を反映しない場合、エージェント向けコスト警告のみを無効化する:

```bash
export ECC_CONTEXT_MONITOR_COST_WARNINGS=off
```

Windows PowerShell:

```powershell
[Environment]::SetEnvironmentVariable('ECC_CONTEXT_MONITOR_COST_WARNINGS', 'off', 'User')
```

これはコンテキスト枯渇警告、スコープ警告、ループ警告、`/cost`、またはコストテレメトリファイルを無効化しない。

### 戦略的 compaction

`strategic-compact` スキル (`skills/strategic-compact/` 内) は、タスク中にトリガしうる自動 compaction に依存する代わりに、論理的間隔で `/compact` を提案する。フックセットアップ指示はスキルの README を参照。

**compact するとき:**
- 探索後、実装前
- マイルストーン完了後
- デバッグ後、新作業継続前
- 主要コンテキストシフト前

**compact しないとき:**
- 関連変更の実装中
- アクティブ問題のデバッグ中
- マルチファイルリファクタ中

### サブエージェントがコンテキストを保護する

メインセッションで多くのファイルを読む代わりに、探索にサブエージェント (Task ツール) を使う。サブエージェントは 20 ファイルを読むが、サマリのみを返す — メインコンテキストはクリーンに保たれる。

---

## MCP サーバー管理

有効化された各 MCP サーバーはコンテキストウィンドウにツール定義を追加する。README は警告する: **プロジェクトごとに有効化を 10 以下に保つ**。

ヒント:
- アクティブサーバーとそのコンテキストコストを見るには `/mcp` を実行
- ライブランタイム変更を望むときは `/mcp` を使って Claude Code MCP サーバーを無効化する。Claude Code はそれらランタイム無効化を `~/.claude.json` に永続化する。
- 利用可能な場合 CLI ツールを優先する (GitHub MCP より `gh`、AWS MCP より `aws`)
- 既にロードされた Claude Code MCP サーバーを無効化するために `.claude/settings.json` や `.claude/settings.local.json` に依存しない。それには `/mcp` を使う。
- `ECC_DISABLED_MCPS` はインストール/同期フロー (`install.sh`、`npx ecc-install`、Codex MCP マージなど) 中の ECC 生成 MCP 設定出力にのみ影響する。これはライブ Claude Code トグルではない。
- `memory` MCP サーバーはデフォルトで設定されるが、どのスキル、エージェント、フックでも使われない — 無効化を検討する

---

## Agent Teams コスト警告

[Agent Teams](https://code.claude.com/docs/en/agent-teams) (実験的) は複数の独立コンテキストウィンドウを spawn する。各チームメイトはトークンを別個に消費する。

- 並列性が明確な価値を加えるタスク (マルチモジュール作業、並列レビュー) にのみ使う
- 単純な順次タスクには、サブエージェント (Task ツール) がよりトークン効率的
- 設定で有効化: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

---

## 将来: configure-ecc 統合

`configure-ecc` インストールウィザードは、セットアップ中にこれら環境変数の設定をコストトレードオフの説明とともに提供できる。これは新ユーザーが制限にぶつかった後にこれら設定を発見する代わりに、初日から最適化する助けになる。

---

## クイックリファレンス

```bash
# Daily workflow
/model sonnet              # Start here
/model opus                # Only for complex reasoning
/clear                     # Between unrelated tasks
/compact                   # At logical breakpoints
/cost                      # Check spending

# Environment variables (add to ~/.claude/settings.json "env" block)
MAX_THINKING_TOKENS=10000
CLAUDE_CODE_SUBAGENT_MODEL=haiku
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

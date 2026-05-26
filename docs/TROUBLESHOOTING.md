# トラブルシューティング

ECC ユーザーに影響しうる現在の Claude Code バグに対するコミュニティ報告ワークアラウンド。

これらはアップストリーム Claude Code 挙動であり、ECC バグではない。以下のエントリは Claude Code `v2.1.79` (macOS、重いフック利用、MCP コネクタ有効) で [issue #644](https://github.com/affaan-m/everything-claude-code/issues/644) に集められた本番テスト済みワークアラウンドをまとめる。アップストリーム修正が着地するまでの実用的なストップギャップとして扱う。

## オープン Claude Code バグへのコミュニティワークアラウンド

### 成功したフックでの誤った "Hook Error" ラベル

**症状:** フックは成功するが、Claude Code はトランスクリプトで `Hook Error` を依然表示する。

**助けになるもの:**

- フックの最初で stdin を消費する (シェルフックでは `input=$(cat)`)。親プロセスが未消費パイプを見ないようにする。
- 単純な allow/block フックでは、人間可読診断を stderr に送り、フック実装が明示的に構造化 stdout を必要としない限り stdout を静かに保つ。
- 実行可能でない場合、ノイジーな子プロセス stderr をリダイレクトする。
- 正しい exit code を使う: `0` で許可、`2` でブロック、他の非ゼロ exit はエラーとして扱われる。

**例:**

```bash
# Good: block with stderr message and exit 2
input=$(cat)
echo "[BLOCKED] Reason here" >&2
exit 2
```

### `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` で期待より早い compaction

**症状:** `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` を下げると compaction が遅くではなく早く発生する。

**助けになるもの:**

- 一部の現 Claude Code ビルドでは、低い値は compaction 閾値を延長する代わりに減らす可能性がある。
- より多くの作業余地を望むなら、`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` を削除し、論理的タスク境界で手動 `/compact` を優先する。
- 低い auto-compact 閾値を強制する代わりに、ECC の `strategic-compact` ガイダンスを使う。

### MCP コネクタが接続済みに見えるが compaction 後に失敗

**症状:** UI でコネクタが依然認証済みに見えても、compaction 後に Gmail や Google Drive MCP ツールが失敗する。

**助けになるもの:**

- compaction 後に該当コネクタをオフにしてオンに戻す。
- Claude Code ビルドがサポートする場合、compaction 後にコネクタ認証を再チェックするよう警告する `PostCompact` リマインダフックを追加する。
- これを永久修正ではなく auth-state リカバリステップとして扱う。

### フック編集がホットリロードしない

**症状:** `settings.json` フックの変更がセッション再起動まで有効にならない。

**助けになるもの:**

- フック変更後に Claude Code セッションを再起動する。
- 上級ユーザーは `kill -HUP $PPID` 周辺のローカル `/reload` コマンドをスクリプト化することがあるが、ECC はシェル依存で普遍的に信頼できないためそれを出荷しない。

### 繰り返される `529 Overloaded` レスポンス

**症状:** 高いフック/ツール/コンテキスト圧力下で Claude Code が失敗し始める。

**助けになるもの:**

- セットアップがサポートするなら `ENABLE_TOOL_SEARCH=auto:5` でツール定義圧力を減らす。
- ルーチン作業では `MAX_THINKING_TOKENS` を下げる。
- セットアップがそのノブを公開するなら、サブエージェント作業を `CLAUDE_CODE_SUBAGENT_MODEL=haiku` のような安価モデルにルーティングする。
- プロジェクトごとに未使用 MCP サーバーを無効化する。
- 自動 compaction を待つ代わりに、自然なブレークポイントで手動 compact する。

## 関連 ECC ドキュメント

- 短いフック/compaction/MCP リカバリチェックリストには [hook-bug-workarounds.md](./hook-bug-workarounds.md)。
- ECC の文書化されたフックライフサイクルと exit code 挙動には [hooks/README.md](../hooks/README.md)。
- コストとコンテキスト管理設定には [token-optimization.md](./token-optimization.md)。
- 元のレポートとテスト済み環境には [issue #644](https://github.com/affaan-m/everything-claude-code/issues/644)。

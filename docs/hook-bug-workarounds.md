# フックバグワークアラウンド

ECC のフックが多用されるセットアップに影響しうる現在の Claude Code バグに対するコミュニティテスト済みワークアラウンド。

このページは意図的に狭い: より長いトラブルシューティングサーフェスから、推測的またはサポート無しの設定アドバイスを繰り返さずに、最高シグナルの運用修正を集める。これらはアップストリーム Claude Code 挙動であり、ECC バグではない。

## このページを使うとき

以下を特定的にデバッグしているときに本ページを使う:

- 成功したフック実行での誤った `Hook Error` ラベル
- 期待より早い compaction
- 認証済みに見えるが compaction 後に失敗する MCP コネクタ
- ホットリロードしないフック編集
- 重いフック/ツール圧力下での繰り返される `529 Overloaded` レスポンス

より完全な ECC トラブルシューティングサーフェスには [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) を使う。

## 高シグナルワークアラウンド

### 誤った `Hook Error` ラベル

助けになるもの:

- シェルフックの最初で stdin を消費する (`input=$(cat)`)。
- フックが明示的に構造化 stdout を必要としない限り、単純な allow/block フックで stdout を静かに保つ。
- 人間可読診断を stderr に送る。
- 正しい exit code を使う: `0` 許可、`2` ブロック、他の非ゼロ値はエラーとして扱われる。

```bash
input=$(cat)
echo "[BLOCKED] Reason here" >&2
exit 2
```

### 期待より早い compaction

助けになるもの:

- ビルドで下げると早い compaction が起こるなら `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` を削除する。
- 自然なタスク境界で手動 `/compact` を優先する。
- 低い閾値を強制する代わりに ECC の `strategic-compact` ガイダンスを使う。

### MCP 認証がライブに見えるが compaction 後に失敗

助けになるもの:

- compaction 後に該当コネクタをオフにしてオンに戻す。
- Claude Code ビルドがサポートする場合、コネクタ認証の再チェックを伝える軽量 `PostCompact` リマインダフックを追加する。
- 永久修正ではなくリカバリリマインダとして扱う。

### フック編集がホットリロードしない

助けになるもの:

- フック変更後に Claude Code セッションを再起動する。
- 上級ユーザーはシェルローカル reload ヘルパーを使うことがあるが、ECC はそれらアプローチがシェル・プラットフォーム依存のため出荷しない。

### 繰り返される `529 Overloaded`

助けになるもの:

- セットアップがサポートするなら `ENABLE_TOOL_SEARCH=auto:5` でツール定義圧力を減らす。
- ルーチン作業では `MAX_THINKING_TOKENS` を下げる。
- セットアップがそのノブを公開するなら、サブエージェント作業を `CLAUDE_CODE_SUBAGENT_MODEL=haiku` のような安価モデルにルーティングする。
- プロジェクトごとに未使用 MCP サーバーを無効化する。
- 自動 compaction を待つ代わりに、自然なブレークポイントで手動 compact する。

## 関連 ECC ドキュメント

- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- [token-optimization.md](./token-optimization.md)
- [hooks/README.md](../hooks/README.md)
- [issue #644](https://github.com/affaan-m/everything-claude-code/issues/644)

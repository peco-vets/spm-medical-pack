# セキュリティポリシー

## サポート対象バージョン

| Version | サポート対象       |
| ------- | ------------------ |
| 1.9.x   | :white_check_mark: |
| 1.8.x   | :white_check_mark: |
| < 1.8   | :x:                |

## 脆弱性報告

ECC に脆弱性を発見した場合、責任を持って報告すること。

**セキュリティ脆弱性については public GitHub Issue を作成しないこと。**

代わりに **<security@ecc.tools>** へ以下を含めてメールで報告すること:

- 脆弱性の説明
- 再現手順
- 影響を受けるバージョン
- 想定される影響評価

期待できる対応:

- 48 時間以内の **受領確認**
- 7 日以内の **ステータス更新**
- クリティカル問題は 30 日以内の **修正または緩和策**

脆弱性が受理された場合、当方は以下を行う:

- リリースノートでの謝辞(匿名希望の場合を除く)
- 適時の修正
- 開示タイミングの調整

脆弱性が却下された場合、理由を説明し、他所で報告すべきかについてガイダンスを提供する。

## スコープ

本ポリシーが対象とするもの:

- ECC プラグインおよび本リポジトリ内のすべてのスクリプト
- マシン上で実行されるフックスクリプト
- インストール・アンインストール・修復ライフサイクルスクリプト
- ECC と共に配布される MCP 設定
- AgentShield セキュリティスキャナ ([github.com/affaan-m/agentshield](https://github.com/affaan-m/agentshield))

## 運用ガイダンス

### シークレット取り扱い

`mcp-configs/mcp-servers.json` は **テンプレート** である。すべての `YOUR_*_HERE` 値は、インストール時に環境変数またはシークレットマネージャから置き換える必要がある。実認証情報を絶対にコミットしない。シークレットを誤ってコミットしてしまった場合は、直ちにローテートし履歴を書き直す。単純な revert に依存しないこと。

同じルールはユーザースコープの Claude Code 設定 (`~/.claude/settings.json` または `%USERPROFILE%\.claude\settings.json`) にも適用される。このファイルはリポジトリ外だが、`claude doctor` 出力、スクリーンショット、バグ報告で共有されることがよくある。`mcpServers[*].env` ブロックに PAT、API キー、OAuth トークンをハードコードしないこと。MCP サーバーが既にサポートする OS キーチェーンや環境変数から、スポーン時に解決する。簡易監査:

```bash
# macOS / Linux
grep -EnH '(TOKEN|SECRET|KEY|PASSWORD)\s*"\s*:\s*"[A-Za-z0-9_-]{16,}"' ~/.claude/settings.json
# Windows PowerShell
Select-String -Path "$env:USERPROFILE\.claude\settings.json" -Pattern '(TOKEN|SECRET|KEY|PASSWORD)"\s*:\s*"[A-Za-z0-9_-]{16,}"'
```

監査がマッチした場合は、発行元プロバイダでシークレットをローテートし、ファイル外に移す (プロバイダごとの環境変数、または対応サーバーであれば `credentialHelper` を利用する)。

### ローカル MCP ポート

一部の同梱 MCP サーバーは localhost ポートへの平文 HTTP で接続する (例: `devfleet` は `http://localhost:18801/mcp`)。初回利用前に、リッスンプロセスを検証する:

```bash
# Windows
netstat -ano | findstr :18801
# macOS / Linux
lsof -iTCP:18801 -sTCP:LISTEN
```

PID を期待される devfleet バイナリと比較する。そのポート上の他のプロセスは MCP トラフィックを傍受しうる。

## トリアージ: 怪しい `<system-reminder>` ブロック

ECC は Claude Code 内で動作する。Claude Code は毎ターン **エフェメラルなクライアントサイドシステムリマインダ** をモデル入力に注入する (TodoWrite ナッジ、日付変更通知、ファイル変更通知など)。これらのブロックは:

- 通常、*"ignore if not applicable"* や *"NEVER mention this reminder to the user"* / *"Don't tell the user this, since they are already aware"* といった文言で終わる。この文言は Anthropic 自身のプロンプトであり、悪意ある末尾ではない。
- CLI がターンごとに追加するもので、`~/.claude/projects/<slug>/<sessionId>.jsonl` のセッショントランスクリプトには **永続化されない**。

この組み合わせにより、ツール結果に付加されたプロンプトインジェクションと誤認しやすい。攻撃として扱う前に以下を検証する:

1. ブロックは本リポジトリのファイルに実在するか? `grep -rEn "system-reminder|NEVER mention|DO NOT mention" .`。何も無ければ、リポジトリが運んでいるものではない。
2. ブロックはトランスクリプトに格納されているか? 現在のセッションの `.jsonl` を検査する。正確なテキストが `tool_result` の body 内に現れなければ、それはクライアント注入のエフェメラルリマインダであり、任意のツールからのペイロードではない。
3. 内容は Anthropic の既知リマインダ (TodoWrite ナッジ、日付変更、ファイル変更通知) と文脈的に整合するか? Yes なら、エフェメラルリマインダ機構であり対応不要である。

ブロックが **両方** (a) `tool_result` 内のトランスクリプトに存在し **かつ** (b) 実際に読まれたファイルや URL に帰属しない場合のみ Anthropic にエスカレーションする。最小報告: 新規セッション、クリーンなローカルファイルの read、観測された正確なテキスト、トランスクリプト抜粋。送付先は <https://github.com/anthropics/claude-code/issues> (非機密) または <mailto:security@anthropic.com> (エンバーゴ級)。

エフェメラルリマインダに応じてリポジトリファイルをサニタイズしないこと。それらは運搬経路ではない。

## セキュリティリソース

- **AgentShield**: エージェント設定の脆弱性スキャン — `npx ecc-agentshield scan`
- **セキュリティガイド**: [The Shorthand Guide to Everything Agentic Security](./the-security-guide.md)
- **サプライチェーンインシデント対応**: [npm/GitHub Actions package-registry playbook](./docs/security/supply-chain-incident-response.md)
- **OWASP MCP Top 10**: [owasp.org/www-project-mcp-top-10](https://owasp.org/www-project-mcp-top-10/)
- **OWASP Agentic Applications Top 10**: [genai.owasp.org](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/)

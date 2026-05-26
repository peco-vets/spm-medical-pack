---
name: mcp-server-patterns
description: Node/TypeScript SDK で MCP サーバーを構築する — tools、resources、prompts、Zod バリデーション、stdio 対 Streamable HTTP。最新 API には Context7 や公式 MCP ドキュメントを使用 (Build MCP servers with Node/TypeScript SDK — tools, resources, prompts, Zod validation, stdio vs Streamable HTTP)。
origin: ECC
---

# MCP サーバーパターン

Model Context Protocol (MCP) は、AI アシスタントがサーバーからツールを呼び出し、リソースを読み取り、プロンプトを使うことを可能にする。MCP サーバーの構築・保守時にこのスキルを使う。SDK API は進化する。現在のメソッド名とシグネチャは Context7 (query-docs で "MCP") または公式 MCP ドキュメントを確認すること。

機能がルール、スキル、MCP、または通常の CLI/API ワークフローのどれであるべきかという、より広範なルーティング決定については [docs/capability-surface-selection.md](../../docs/capability-surface-selection.md) を参照。

## 使用するタイミング

新しい MCP サーバーの実装、ツールやリソースの追加、stdio 対 HTTP の選択、SDK のアップグレード、MCP 登録とトランスポートの問題のデバッグ時に使用する。

## 動作の仕組み

### コア概念

- **Tools**: モデルが呼び出せるアクション (例: 検索、コマンド実行)。SDK バージョンに応じて `registerTool()` または `tool()` で登録する
- **Resources**: モデルが取得できる読み取り専用データ (例: ファイル内容、API レスポンス)。`registerResource()` または `resource()` で登録する。ハンドラは通常 `uri` 引数を受け取る
- **Prompts**: クライアントが表示できる再利用可能でパラメータ化されたプロンプトテンプレート (例: Claude Desktop)。`registerPrompt()` または同等で登録する
- **Transport**: ローカルクライアント (例: Claude Desktop) には stdio、リモート (Cursor、クラウド) には Streamable HTTP が優先される。レガシー HTTP/SSE は後方互換性用

Node/TypeScript SDK は `tool()` / `resource()` または `registerTool()` / `registerResource()` を公開する可能性がある。公式 SDK は時間と共に変化してきた。常に現在の [MCP docs](https://modelcontextprotocol.io) または Context7 と照合すること。

### stdio との接続

ローカルクライアントの場合、stdio トランスポートを作成しサーバーの connect メソッドに渡す。正確な API は SDK バージョンによって異なる (例: コンストラクタ対ファクトリ)。現在のパターンには公式 MCP ドキュメントを参照するか Context7 で "MCP stdio server" を問い合わせること。

サーバーロジック (tools + resources) をトランスポートから独立させ、エントリポイントで stdio または HTTP をプラグインできるようにする。

### リモート (Streamable HTTP)

Cursor、クラウド、その他のリモートクライアントには **Streamable HTTP** を使う (現在の仕様では MCP HTTP エンドポイントごとに 1 つ)。後方互換性が必要な場合のみレガシー HTTP/SSE をサポートする。

## 例

### インストールとサーバーセットアップ

```bash
npm install @modelcontextprotocol/sdk zod
```

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

const server = new McpServer({ name: "my-server", version: "1.0.0" });
```

SDK バージョンが提供する API を使って tools とリソースを登録する。あるバージョンでは `server.tool(name, description, schema, handler)` (位置引数) を使い、他のバージョンでは `server.tool({ name, description, inputSchema }, handler)` または `registerTool()` を使う。リソースも同様 — API が提供する場合はハンドラに `uri` を含める。コピーペーストエラーを避けるため、現在の `@modelcontextprotocol/sdk` シグネチャは公式 MCP ドキュメントまたは Context7 を確認すること。

入力検証には **Zod** (または SDK の優先スキーマ形式) を使う。

## ベストプラクティス

- **スキーマファースト**: すべてのツールに入力スキーマを定義し、パラメータと戻り値の形を文書化する
- **エラー**: 生のスタックトレースを避け、モデルが解釈できる構造化エラーやメッセージを返す
- **冪等性**: 可能な限り冪等なツールを優先し、再試行を安全にする
- **レートとコスト**: 外部 API を呼び出すツールには、レート制限とコストを考慮し、ツール説明に文書化する
- **バージョニング**: package.json で SDK バージョンをピンし、アップグレード時にリリースノートを確認する

## 公式 SDK とドキュメント

- **JavaScript/TypeScript**: `@modelcontextprotocol/sdk` (npm)。現在の登録とトランスポートパターンには Context7 でライブラリ名 "MCP" を使う
- **Go**: GitHub 上の公式 Go SDK (`modelcontextprotocol/go-sdk`)
- **C#**: .NET 用の公式 C# SDK

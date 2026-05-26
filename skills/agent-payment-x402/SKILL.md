---
name: agent-payment-x402
description: タスク単位の予算、支出制御、ノンカストディアルウォレットを備えた x402 支払い実行を AI エージェントに追加する。agentwallet-sdk を介した Base、および OKX Payments / OKX Agent Payments Protocol を介した X Layer をサポートする (agent payment x402, HTTP 402, spending policy, non-custodial wallet, Base, X Layer, OKX Payments)。
origin: community
---

# エージェント支払い実行 (x402)

組み込みの支出制御を備えたポリシーゲート付き支払いを AI エージェントが行えるようにする。x402 HTTP 支払いプロトコルと MCP ツールを使い、エージェントがカストディアルリスクなしに外部サービス・API・他エージェントに支払えるようにする。

## 利用するタイミング

利用する場面: エージェントが API 呼び出しに支払う、サービスを購入する、他エージェントと決済する、タスク単位の支出制限を強制する、ノンカストディアルウォレットを管理する。cost-aware-llm-pipeline スキルや security-review スキルと自然に組み合わせられる。

## ディシジョンツリー

エージェントが有料 API へのアクセスを購入するのか、他者へ課金するのかに基づいて統合パスを選ぶ:

| ニーズ | 推奨パス |
|------|------------------|
| Base や他の agentwallet 対応チェーン上の 402 ゲート API にエージェントが支払う | `agentwallet-sdk` を厳格な支出ポリシーで MCP 支払いサーバーとして使う |
| X Layer 上の 402 ゲート API にエージェントが支払う | `okx/onchainos-skills` の OKX Agent Payments Protocol を使う。`okx-x402-payment` は非推奨のレガシーエイリアス |
| TypeScript API がエージェントに課金する | Express、Hono、Fastify、または Next.js の OKX Payments TypeScript セラー SDK ドキュメントを使う |
| Go API がエージェントに課金する | Gin、Echo、または `net/http` の OKX Payments Go セラー SDK ドキュメントを使う |
| Rust API がエージェントに課金する | Axum の OKX Payments Rust セラー SDK ドキュメントを使う |
| Java API がエージェントに課金する | Spring Boot 2/3、Java EE、または Jakarta の OKX Payments Java セラー SDK ドキュメントを使う |
| Python API がエージェントに課金する | 実装前に現行 OKX Payments リポジトリを確認する。Python セラーガイドは利用できない可能性がある |

## サポートされるネットワーク

- `agentwallet-sdk`: 本番化の前にパッケージドキュメントで現行のネットワーク対応を確認する。Base Sepolia が最も安全な開発デフォルト。Base mainnet は元のスキルが想定する本番パス。
- OKX Payments / X Layer: 現行のセラードキュメントは X Layer (`eip155:196`) と USDT0 決済を対象とする。支払いパッケージとファシリテーターの挙動は急速に変化しうるため、本番コードを生成する前に現行 SDK ドキュメントを取得する。

## 仕組み

### x402 プロトコル
x402 は HTTP 402 (Payment Required) を機械交渉可能なフローへと拡張する。サーバが `402` を返すと、エージェントの支払いツールが価格を交渉し、予算を確認し、トランザクションに署名し、オーケストレーターが設定したポリシーと確認境界の内側でのみリトライする。

### 支出制御
すべての支払いツール呼び出しは `SpendingPolicy` を強制する:
- **タスク単位予算** — 単一のエージェントアクションの最大支出
- **セッション単位予算** — セッション全体の累積上限
- **許可リスト宛先** — エージェントが支払える宛先/サービスを制限する
- **レート制限** — 分/時間ごとの最大トランザクション数

### ノンカストディアルウォレット
エージェントは ERC-4337 スマートアカウントを介して自身の鍵を保持する。オーケストレーターが委譲前にポリシーを設定する。エージェントは境界内でのみ支出可能。プール資金なし、カストディアルリスクなし。

## MCP 統合

支払い層は任意の Claude Code またはエージェントハーネスのセットアップにはまる標準 MCP ツールを公開する。

> **セキュリティ注意**: 必ずパッケージバージョンを固定する。このツールは秘密鍵を管理する — 固定されていない `npx` インストールはサプライチェーンリスクを生む。

### Option A: agentwallet-sdk (Base / マルチチェーン)

```json
{
  "mcpServers": {
    "agentpay": {
      "command": "npx",
      "args": ["agentwallet-sdk@6.0.0"]
    }
  }
}
```

### 利用可能なツール (エージェント呼び出し可)

| ツール | 用途 |
|------|---------|
| `get_balance` | エージェントウォレット残高を確認 |
| `send_payment` | アドレスまたは ENS に支払いを送信 |
| `check_spending` | 残予算を照会 |
| `list_transactions` | すべての支払いの監査証跡 |

> **Note**: 支出ポリシーはエージェント自身ではなくエージェントへ委譲する前に **オーケストレーター** によって設定される。これによりエージェントが自身の支出制限を引き上げることを防ぐ。オーケストレーション層またはプリタスクフックの `set_policy` を介して設定し、決してエージェント呼び出し可能ツールとして設定しない。

### Option B: OKX Agent Payments Protocol (X Layer)

X Layer x402、Multi-Party Payment (MPP)、セッション支払い、課金、A2A 課金フローにはこのパスを使う。

買い手側エージェントフローの場合:

1. 現行の `okx/onchainos-skills` リポジトリをインストールまたは参照する。
2. ディスパッチャーとして `skills/okx-agent-payments-protocol/SKILL.md` を使う。
3. `skills/okx-x402-payment/SKILL.md` は正規スキルではなく、非推奨の互換性エイリアスとして扱う。
4. ウォレットステータス確認や支払いアクションの前にユーザーの明示的な確認を必須とする。汎用ツール呼び出しの背後に支払い実行を隠さない。

売り手側 API フローの場合、コードを生成する前に最新の言語別ガイドを取得する:

| ランタイム | 現行ガイド |
|---------|---------------|
| TypeScript | `https://raw.githubusercontent.com/okx/payments/main/typescript/SELLER.md` |
| Go | `https://raw.githubusercontent.com/okx/payments/main/go/x402/SELLER.md` |
| Rust | `https://raw.githubusercontent.com/okx/payments/main/rust/x402/SELLER.md` |
| Java | `https://raw.githubusercontent.com/okx/payments/main/java/SELLER.md` |

現行 OKX リポジトリを確認せずに古いドキュメントの例をコピーしないこと。現行の OKX ガイダンスはディスパッチャーとして `okx-agent-payments-protocol` を使用し、Java セラードキュメントも現在利用可能である。

## 例

### MCP クライアントでの予算強制

agentpay MCP サーバーを呼び出すオーケストレーターを構築する際、有料ツール呼び出しをディスパッチする前に予算を強制する。

> **前提条件**: MCP 設定を追加する前にパッケージをインストールしておく — `-y` なしの `npx` は非対話環境で確認を求めるためサーバがハングする: `npm install -g agentwallet-sdk@6.0.0`

```typescript
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

async function main() {
  // 1. Validate credentials before constructing the transport.
  //    A missing key must fail immediately — never let the subprocess start without auth.
  const walletKey = process.env.WALLET_PRIVATE_KEY;
  if (!walletKey) {
    throw new Error("WALLET_PRIVATE_KEY is not set — refusing to start payment server");
  }

  // Connect to the agentpay MCP server via stdio transport.
  // Whitelist only the env vars the server needs — never forward all of process.env
  // to a third-party subprocess that manages private keys.
  const transport = new StdioClientTransport({
    command: "npx",
    args: ["agentwallet-sdk@6.0.0"],
    env: {
      PATH: process.env.PATH ?? "",
      NODE_ENV: process.env.NODE_ENV ?? "production",
      WALLET_PRIVATE_KEY: walletKey,
    },
  });
  const agentpay = new Client({ name: "orchestrator", version: "1.0.0" });
  await agentpay.connect(transport);

  // 2. Set spending policy before delegating to the agent.
  //    Always verify success — a silent failure means no controls are active.
  const policyResult = await agentpay.callTool({
    name: "set_policy",
    arguments: {
      per_task_budget: 0.50,
      per_session_budget: 5.00,
      allowlisted_recipients: ["api.example.com"],
    },
  });
  if (policyResult.isError) {
    throw new Error(
      `Failed to set spending policy — do not delegate: ${JSON.stringify(policyResult.content)}`
    );
  }

  // 3. Use preToolCheck before any paid action
  await preToolCheck(agentpay, 0.01);
}

// Pre-tool hook: fail-closed budget enforcement with four distinct error paths.
async function preToolCheck(agentpay: Client, apiCost: number): Promise<void> {
  // Path 1: Reject invalid input (NaN/Infinity bypass the < comparison)
  if (!Number.isFinite(apiCost) || apiCost < 0) {
    throw new Error(`Invalid apiCost: ${apiCost} — action blocked`);
  }

  // Path 2: Transport/connectivity failure
  let result;
  try {
    result = await agentpay.callTool({ name: "check_spending" });
  } catch (err) {
    throw new Error(`Payment service unreachable — action blocked: ${err}`);
  }

  // Path 3: Tool returned an error (e.g., auth failure, wallet not initialised)
  if (result.isError) {
    throw new Error(
      `check_spending failed — action blocked: ${JSON.stringify(result.content)}`
    );
  }

  // Path 4: Parse and validate the response shape
  let remaining: number;
  try {
    const parsed = JSON.parse(
      (result.content as Array<{ text: string }>)[0].text
    );
    if (!Number.isFinite(parsed?.remaining)) {
      throw new TypeError("missing or non-finite 'remaining' field");
    }
    remaining = parsed.remaining;
  } catch (err) {
    throw new Error(
      `check_spending returned unexpected format — action blocked: ${err}`
    );
  }

  // Path 5: Budget exceeded
  if (remaining < apiCost) {
    throw new Error(
      `Budget exceeded: need $${apiCost} but only $${remaining} remaining`
    );
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
```

## ベストプラクティス

- **委譲前に予算を設定する**: サブエージェントを起動する際、オーケストレーション層を介して SpendingPolicy を付与する。エージェントに無制限の支出を与えないこと。
- **依存関係を固定する**: MCP 設定で常に厳密なバージョンを指定する (例: `agentwallet-sdk@6.0.0`)。本番デプロイ前にパッケージの完全性を検証する。
- **監査証跡**: ポストタスクフックで `list_transactions` を使い、何にいくら使ったかを記録する。
- **フェイルクローズド**: 支払いツールが到達不能なら有料アクションをブロックする — 計測されないアクセスにフォールバックしないこと。
- **security-review と組み合わせる**: 支払いツールは高権限である。シェルアクセスと同様の精査を適用する。
- **まずテストネットでテストする**: 開発には Base Sepolia を使い、本番では Base mainnet に切り替える。

## 本番リファレンス

- **npm**: [`agentwallet-sdk`](https://www.npmjs.com/package/agentwallet-sdk)
- **NVIDIA NeMo Agent Toolkit に統合済**: [PR #17](https://github.com/NVIDIA/NeMo-Agent-Toolkit-Examples/pull/17) — NVIDIA のエージェント例向け x402 支払いツール
- **プロトコル仕様**: [x402.org](https://x402.org)
- **OKX Payments SDKs**: [`okx/payments`](https://github.com/okx/payments) — X Layer x402 の TypeScript、Go、Rust、Java セラー統合
- **OKX Agent Payments Protocol スキル**: [`okx/onchainos-skills`](https://github.com/okx/onchainos-skills/tree/main/skills/okx-agent-payments-protocol)
- **OKX Payments 概要**: [web3.okx.com/onchainos/dev-docs/payments/overview](https://web3.okx.com/onchainos/dev-docs/payments/overview)

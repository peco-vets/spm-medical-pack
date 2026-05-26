---
name: llm-trading-agent-security
description: ウォレットやトランザクション権限を持つ自律トレーディングエージェントのセキュリティパターン。プロンプトインジェクション、支出限度、送信前シミュレーション、サーキットブレーカー、MEV 保護、鍵処理をカバー (Security patterns for autonomous trading agents with wallet or transaction authority; prompt injection, spend limits, pre-send simulation, circuit breakers, MEV protection, key handling)。
origin: ECC direct-port adaptation
version: "1.0.0"
---

# LLM トレーディングエージェントセキュリティ

自律トレーディングエージェントは通常の LLM アプリよりも厳しい脅威モデルを持つ: インジェクションや悪いツールパスは直接資産損失に変わり得る。

## 使用するタイミング

- トランザクションを署名・送信する AI エージェントを構築する場合
- トレーディングボットやオンチェーン実行アシスタントを監査する場合
- エージェント用のウォレット鍵管理を設計する場合
- LLM に注文発注、スワップ、トレジャリー操作へのアクセスを与える場合

## 動作の仕組み

防御を層化する。単一チェックでは不十分である。プロンプト衛生、支出ポリシー、シミュレーション、実行制限、ウォレット分離を独立した制御として扱うこと。

## 例

### プロンプトインジェクションを金融攻撃として扱う

```python
import re

INJECTION_PATTERNS = [
    r'ignore (previous|all) instructions',
    r'new (task|directive|instruction)',
    r'system prompt',
    r'send .{0,50} to 0x[0-9a-fA-F]{40}',
    r'transfer .{0,50} to',
    r'approve .{0,50} for',
]

def sanitize_onchain_data(text: str) -> str:
    for pattern in INJECTION_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            raise ValueError(f"Potential prompt injection: {text[:100]}")
    return text
```

トークン名、ペアラベル、Webhook、ソーシャルフィードを実行可能プロンプトに盲目的に注入しないこと。

### ハード支出限度

```python
from decimal import Decimal

MAX_SINGLE_TX_USD = Decimal("500")
MAX_DAILY_SPEND_USD = Decimal("2000")

class SpendLimitError(Exception):
    pass

class SpendLimitGuard:
    def check_and_record(self, usd_amount: Decimal) -> None:
        if usd_amount > MAX_SINGLE_TX_USD:
            raise SpendLimitError(f"Single tx ${usd_amount} exceeds max ${MAX_SINGLE_TX_USD}")

        daily = self._get_24h_spend()
        if daily + usd_amount > MAX_DAILY_SPEND_USD:
            raise SpendLimitError(f"Daily limit: ${daily} + ${usd_amount} > ${MAX_DAILY_SPEND_USD}")

        self._record_spend(usd_amount)
```

### 送信前にシミュレート

```python
class SlippageError(Exception):
    pass

async def safe_execute(self, tx: dict, expected_min_out: int | None = None) -> str:
    sim_result = await self.w3.eth.call(tx)

    if expected_min_out is None:
        raise ValueError("min_amount_out is required before send")

    actual_out = decode_uint256(sim_result)
    if actual_out < expected_min_out:
        raise SlippageError(f"Simulation: {actual_out} < {expected_min_out}")

    signed = self.account.sign_transaction(tx)
    return await self.w3.eth.send_raw_transaction(signed.raw_transaction)
```

### サーキットブレーカー

```python
class TradingCircuitBreaker:
    MAX_CONSECUTIVE_LOSSES = 3
    MAX_HOURLY_LOSS_PCT = 0.05

    def check(self, portfolio_value: float) -> None:
        if self.consecutive_losses >= self.MAX_CONSECUTIVE_LOSSES:
            self.halt("Too many consecutive losses")

        if self.hour_start_value <= 0:
            self.halt("Invalid hour_start_value")
            return

        hourly_pnl = (portfolio_value - self.hour_start_value) / self.hour_start_value
        if hourly_pnl < -self.MAX_HOURLY_LOSS_PCT:
            self.halt(f"Hourly PnL {hourly_pnl:.1%} below threshold")
```

### ウォレット分離

```python
import os
from eth_account import Account

private_key = os.environ.get("TRADING_WALLET_PRIVATE_KEY")
if not private_key:
    raise EnvironmentError("TRADING_WALLET_PRIVATE_KEY not set")

account = Account.from_key(private_key)
```

必要なセッション資金のみを持つ専用ホットウォレットを使う。エージェントを主要トレジャリーウォレットに向けないこと。

### MEV とデッドライン保護

```python
import time

PRIVATE_RPC = "https://rpc.flashbots.net"
MAX_SLIPPAGE_BPS = {"stable": 10, "volatile": 50}
deadline = int(time.time()) + 60
```

## デプロイ前チェックリスト

- 外部データは LLM コンテキストに入る前にサニタイズされている
- 支出限度はモデル出力から独立して強制されている
- トランザクションは送信前にシミュレートされている
- `min_amount_out` は必須
- サーキットブレーカーはドローダウンや無効状態で停止する
- 鍵は env またはシークレットマネージャーから来る。コードやログには絶対に置かない
- 適切な場合はプライベートメンプールや保護されたルーティングを使用
- スリッページとデッドラインは戦略ごとに設定
- すべてのエージェント決定は監査ログに記録される。成功した送信だけではない

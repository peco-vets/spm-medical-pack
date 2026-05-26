---
name: evm-token-decimals
description: EVM チェーン横断で起きる小数桁数の暗黙的不一致バグを防止する（EVM token decimals, decimal mismatch, ERC-20）。ランタイムでの decimals 取得、チェーン対応キャッシュ、ブリッジ済みトークンの精度ドリフト、bot・ダッシュボード・DeFi ツール向けの安全な正規化を網羅する。
origin: ECC direct-port adaptation
version: "1.0.0"
---

# EVM トークン Decimals

サイレントな小数桁数不一致は、エラーを出さずに残高や USD 値が桁違いに狂う最も典型的な原因の1つである。

## 利用タイミング

- Python・TypeScript・Solidity で ERC-20 残高を読む
- オンチェーン残高から法定通貨換算を計算する
- 複数 EVM チェーン間でトークン額を比較する
- ブリッジされたアセットを扱う
- ポートフォリオトラッカー・bot・アグリゲータを構築する

## 仕組み

ステーブルコインがどのチェーンでも同じ小数桁数とは限らない。`decimals()` をランタイムで取得し、`(chain_id, token_address)` でキャッシュし、値計算には小数安全な演算を使う。

## 例

### ランタイムで decimals を取得する

```python
from decimal import Decimal
from web3 import Web3

ERC20_ABI = [
    {"name": "decimals", "type": "function", "inputs": [],
     "outputs": [{"type": "uint8"}], "stateMutability": "view"},
    {"name": "balanceOf", "type": "function",
     "inputs": [{"name": "account", "type": "address"}],
     "outputs": [{"type": "uint256"}], "stateMutability": "view"},
]

def get_token_balance(w3: Web3, token_address: str, wallet: str) -> Decimal:
    contract = w3.eth.contract(
        address=Web3.to_checksum_address(token_address),
        abi=ERC20_ABI,
    )
    decimals = contract.functions.decimals().call()
    raw = contract.functions.balanceOf(Web3.to_checksum_address(wallet)).call()
    return Decimal(raw) / Decimal(10 ** decimals)
```

シンボルが他のどこかで通常6桁になることがあるので、`1_000_000` をハードコードしない。

### チェーンとトークンでキャッシュする

```python
from functools import lru_cache

@lru_cache(maxsize=512)
def get_decimals(chain_id: int, token_address: str) -> int:
    w3 = get_web3_for_chain(chain_id)
    contract = w3.eth.contract(
        address=Web3.to_checksum_address(token_address),
        abi=ERC20_ABI,
    )
    return contract.functions.decimals().call()
```

### 例外的なトークンを防御的に扱う

```python
try:
    decimals = contract.functions.decimals().call()
except Exception:
    logging.warning(
        "decimals() reverted on %s (chain %s), defaulting to 18",
        token_address,
        chain_id,
    )
    decimals = 18
```

フォールバックをログし可視化する。旧式または非標準のトークンは現存する。

### Solidity で 18-decimal WAD に正規化する

```solidity
interface IERC20Metadata {
    function decimals() external view returns (uint8);
}

function normalizeToWad(address token, uint256 amount) internal view returns (uint256) {
    uint8 d = IERC20Metadata(token).decimals();
    if (d == 18) return amount;
    if (d < 18) return amount * 10 ** (18 - d);
    return amount / 10 ** (d - 18);
}
```

### ethers を用いた TypeScript

```typescript
import { Contract, formatUnits } from 'ethers';

const ERC20_ABI = [
  'function decimals() view returns (uint8)',
  'function balanceOf(address) view returns (uint256)',
];

async function getBalance(provider: any, tokenAddress: string, wallet: string): Promise<string> {
  const token = new Contract(tokenAddress, ERC20_ABI, provider);
  const [decimals, raw] = await Promise.all([
    token.decimals(),
    token.balanceOf(wallet),
  ]);
  return formatUnits(raw, decimals);
}
```

### 簡易オンチェーンチェック

```bash
cast call <token_address> "decimals()(uint8)" --rpc-url <rpc>
```

## ルール

- 必ずランタイムで `decimals()` を取得する
- シンボルではなく、チェーン + トークンアドレスでキャッシュする
- float ではなく `Decimal`・`BigInt` または等価の厳密演算を使う
- ブリッジまたはラッパー変更後は decimals を再取得する
- 比較・価格計算の前に内部会計を一貫して正規化する

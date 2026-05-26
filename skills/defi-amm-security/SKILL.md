---
name: defi-amm-security
description: Solidity の AMM コントラクト・流動性プール・swap フロー向けセキュリティチェックリスト（DeFi AMM security）。reentrancy・CEI 順序・donation/inflation 攻撃・oracle manipulation・slippage・admin controls・integer math を網羅する。
origin: ECC direct-port adaptation
version: "1.0.0"
---

# DeFi AMM セキュリティ

Solidity の AMM コントラクト・LP ボールト・swap 関数における重大な脆弱性パターンと、堅牢化された実装である。

## 利用タイミング

- Solidity の AMM または流動性プールコントラクトを書く・監査する場合
- トークン残高を保持する swap・deposit・withdraw・mint・burn フローを実装する場合
- share や reserve の計算に `token.balanceOf(address(this))` を用いるコントラクトをレビューする場合
- DeFi プロトコルへ fee setter・pauser・oracle 更新などの admin 機能を追加する場合

## 仕組み

これはチェックリストとパターンライブラリの両方として用いる。すべてのユーザーエントリポイントを下記カテゴリと照合し、手書きのバリアントよりも堅牢化された例を優先する。

## 実行時の安全性

本スキルのシェルコマンドはローカル監査用の例である。信頼できるチェックアウト、または使い捨てサンドボックスでのみ実行し、信頼できないコントラクト名・パス・RPC URL・秘密鍵・ユーザー入力フラグをシェルコマンドに混入させないこと。ツールのインストールや、ローカル/有料リソースを大量消費しうる長時間の fuzzing・静的解析ジョブの実行前には事前確認をとること。

シークレット・秘密鍵・シードフレーズ・API トークン・本番署名クレデンシャルを、コマンド例・ログ・レポートに含めてはならない。

## 例

### Reentrancy: CEI 順序を強制する

脆弱な例:

```solidity
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount);
    token.transfer(msg.sender, amount);
    balances[msg.sender] -= amount;
}
```

安全な例:

```solidity
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

function withdraw(uint256 amount) external nonReentrant {
    require(balances[msg.sender] >= amount, "Insufficient");
    balances[msg.sender] -= amount;
    token.safeTransfer(msg.sender, amount);
}
```

堅牢なライブラリが存在する場合に、自前の guard を書いてはならない。

### Donation/inflation 攻撃

share の計算に `token.balanceOf(address(this))` を直接使うと、攻撃者が意図しない経路でコントラクトへトークンを送ることで分母を操作できる。

```solidity
// Vulnerable
function deposit(uint256 assets) external returns (uint256 shares) {
    shares = (assets * totalShares) / token.balanceOf(address(this));
}
```

```solidity
// Safe
uint256 private _totalAssets;

function deposit(uint256 assets) external nonReentrant returns (uint256 shares) {
    uint256 balBefore = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), assets);
    uint256 received = token.balanceOf(address(this)) - balBefore;

    shares = totalShares == 0 ? received : (received * totalShares) / _totalAssets;
    _totalAssets += received;
    totalShares += shares;
}
```

内部会計を保持し、実際に受領したトークン量を計測する。

### Oracle manipulation

スポット価格はフラッシュローンで操作可能である。TWAP を優先する。

```solidity
uint32[] memory secondsAgos = new uint32[](2);
secondsAgos[0] = 1800;
secondsAgos[1] = 0;
(int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);
int24 twapTick = int24(
    (tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(30 minutes))
);
uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(twapTick);
```

### スリッページ保護

すべての swap 経路は呼び出し元提供のスリッページと deadline を必要とする。

```solidity
function swap(
    uint256 amountIn,
    uint256 amountOutMin,
    uint256 deadline
) external returns (uint256 amountOut) {
    require(block.timestamp <= deadline, "Expired");
    amountOut = _calculateOut(amountIn);
    require(amountOut >= amountOutMin, "Slippage exceeded");
    _executeSwap(amountIn, amountOut);
}
```

### 安全な reserve 計算

```solidity
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";

uint256 result = FullMath.mulDiv(a, b, c);
```

大きな reserve 計算では、オーバーフローリスクのある単純な `a * b / c` を避ける。

### Admin controls

```solidity
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MyAMM is Ownable2Step {
    function setFee(uint256 fee) external onlyOwner { ... }
    function pause() external onlyOwner { ... }
}
```

オーナーシップ移転には明示的な受諾を優先し、すべての特権パスをガードする。

## セキュリティチェックリスト

- reentrancy 露出のエントリポイントが `nonReentrant` を使う
- CEI 順序が守られている
- share の計算が raw な `balanceOf(address(this))` に依存しない
- ERC-20 転送が `SafeERC20` を使う
- deposit が実受領トークン量を計測する
- oracle 読み込みが TWAP または他の操作耐性ソースを使う
- swap が `amountOutMin` と `deadline` を必須にする
- オーバーフロー敏感な reserve 計算が `mulDiv` 等の安全プリミティブを使う
- admin 関数がアクセス制御されている
- 緊急 pause が存在し、テスト済みである
- 静的解析と fuzzing が本番前に実行されている

## 監査ツール

```bash
pip install slither-analyzer
slither . --exclude-dependencies

echidna-test . --contract YourAMM --config echidna.yaml

forge test --fuzz-runs 10000
```

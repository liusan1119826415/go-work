# ShibaMemeToken 合约代码详细解析

## 1. 合约头部和导入

```solidity
pragma solidity ^0.8.20;  // 指定Solidity编译器版本

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";  // 导入ERC20标准实现
import "@openzeppelin/contracts/access/Ownable.sol";      // 导入所有权管理
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";  // 导入防重入保护
import "./IShibaMeme.sol";  // 导入自定义接口
```

## 2. 常量定义

```solidity
uint256 private constant BASIS_POINTS = 10000;  // 基点分母,用于百分比计算(10000=100%)
uint256 private constant MAX_TAX_RATE = 2500;   // 最大税率25%(2500/10000)
address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;  // 销毁地址
```

## 3. Uniswap 集成变量

```solidity
IUniswapV2Router02 public immutable uniswapV2Router;  // Uniswap路由合约(不可变)
address public immutable uniswapV2Pair;  // 交易对地址(不可变)
```

## 4. 税费配置变量

```solidity
uint256 public buyTaxRate = 500;   // 买入税率5%(500/10000)
uint256 public sellTaxRate = 1000; // 卖出税率10%(1000/10000)

// 税费分配比例(总和=10000=100%)
uint256 public liquidityShare = 4000;  // 流动性40%
uint256 public marketingShare = 3000;  // 营销30%
uint256 public devShare = 2000;        // 开发20%
uint256 public burnShare = 1000;       // 销毁10%

// 接收税费的钱包地址
address public liquidityWallet;  // 流动性接收地址
address public marketingWallet;  // 营销钱包
address public devWallet;        // 开发钱包
```

## 5. 交易限制变量

```solidity
bool public limitsEnabled = true;        // 是否启用交易限制
uint256 public maxTxAmount;              // 单笔最大交易量
uint256 public maxWalletAmount;          // 单个钱包最大持有量
uint256 public cooldownPeriod = 60;      // 冷却期(秒)
mapping(address => uint256) private _lastTransferTime;  // 记录每个地址最后交易时间
```

## 6. 交易控制变量

```solidity
bool public tradingEnabled = false;  // 交易是否已启用
uint256 public tradingEnabledTimestamp;  // 交易启动时间戳
uint256 public tradingEnabledBlock;      // 交易启动区块号
```

## 7. 黑名单和豁免列表

```solidity
mapping(address => bool) private _isBlacklisted;       // 黑名单映射
mapping(address => bool) private _isExcludedFromFees;  // 免税地址映射
mapping(address => bool) private _isExcludedFromLimits;  // 免限制地址映射
```

## 8. 自动流动性变量

```solidity
bool private _inSwapAndLiquify;  // 是否正在执行swap(防重入)
uint256 public swapThreshold;    // 触发swap的代币阈值
bool public swapAndLiquifyEnabled = true;  // 是否启用自动流动性
uint256 private _pendingTaxTokens;  // 累积的待处理税费
```

## 9. 修饰器 lockTheSwap

```solidity
modifier lockTheSwap {
    _inSwapAndLiquify = true;  // 设置标志为true
    _;  // 执行函数体
    _inSwapAndLiquify = false;  // 恢复标志为false
}
```
**作用**: 防止在swap过程中被递归调用,避免重入攻击

## 10. 构造函数详解

```solidity
constructor(
    string memory _name,  // 代币名称,如"ShibaInu"
    string memory _symbol,  // 代币符号,如"SHIB"
    uint256 _totalSupply,  // 总供应量
    address _routerAddress,  // Uniswap路由地址
    address _marketingWallet,  // 营销钱包
    address _devWallet  // 开发钱包
) ERC20(_name, _symbol) Ownable(msg.sender) {
    // 【步骤1】验证钱包地址不能为零
    require(_marketingWallet != address(0), "Marketing wallet cannot be zero");
    require(_devWallet != address(0), "Dev wallet cannot be zero");
    
    // 【步骤2】初始化Uniswap路由和创建交易对
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
    
    uniswapV2Router = _uniswapV2Router;  // 保存路由地址
    uniswapV2Pair = _uniswapV2Pair;      // 保存交易对地址
    
    // 【步骤3】设置钱包地址
    liquidityWallet = msg.sender;  // 流动性接收地址默认为部署者
    marketingWallet = _marketingWallet;
    devWallet = _devWallet;
    
    // 【步骤4】设置交易限制
    maxTxAmount = _totalSupply * 5 / 1000;     // 单笔最大0.5%
    maxWalletAmount = _totalSupply * 20 / 1000;  // 最大持有2%
    swapThreshold = _totalSupply * 5 / 10000;   // swap阈值0.05%
    
    // 【步骤5】设置免税地址
    _isExcludedFromFees[msg.sender] = true;      // 部署者
    _isExcludedFromFees[address(this)] = true;   // 合约自身
    _isExcludedFromFees[DEAD_ADDRESS] = true;    // 死亡地址
    _isExcludedFromFees[marketingWallet] = true; // 营销钱包
    _isExcludedFromFees[devWallet] = true;       // 开发钱包
    
    // 【步骤6】设置免限制地址
    _isExcludedFromLimits[msg.sender] = true;
    _isExcludedFromLimits[address(this)] = true;
    _isExcludedFromLimits[DEAD_ADDRESS] = true;
    _isExcludedFromLimits[_uniswapV2Pair] = true;  // 交易对地址
    
    // 【步骤7】铸造总供应量给部署者
    _mint(msg.sender, _totalSupply);
}
```

## 11. receive函数

```solidity
receive() external payable {}
```
**作用**: 允许合约接收ETH,用于接收swap产生的ETH

## 12. _update函数(核心转账逻辑)

这是整个合约最核心的函数,已在代码中添加了详细注释。主要流程:

1. **检查铸造/销毁** - 如果是铸造或销毁操作,直接执行
2. **验证基本条件** - 金额>0,不在黑名单
3. **检查交易启用** - 确保交易已启用
4. **应用交易限制** - 单笔限额、最大持有量、冷却期
5. **触发自动流动性** - 满足条件时执行swap和分配
6. **计算并收取税费** - 根据买入/卖出确定税率
7. **执行实际转账** - 转移扣除税费后的金额

## 13. _swapAndDistribute函数

```solidity
function _swapAndDistribute() private lockTheSwap {
    // 1. 获取待处理税费
    uint256 contractTokenBalance = _pendingTaxTokens;
    if (contractTokenBalance == 0) return;
    
    _pendingTaxTokens = 0;  // 清零
    
    // 2. 计算总份额
    uint256 totalShares = liquidityShare + marketingShare + devShare + burnShare;
    
    // 3. 按比例分配代币
    uint256 liquidityTokens = (contractTokenBalance * liquidityShare) / totalShares;
    uint256 marketingTokens = (contractTokenBalance * marketingShare) / totalShares;
    uint256 devTokens = (contractTokenBalance * devShare) / totalShares;
    uint256 burnTokens = (contractTokenBalance * burnShare) / totalShares;
    
    // 4. 销毁部分代币
    if (burnTokens > 0) {
        super._update(address(this), DEAD_ADDRESS, burnTokens);
    }
    
    // 5. 流动性分两半:一半swap成ETH,一半保留
    uint256 liquidityHalf = liquidityTokens / 2;
    uint256 liquidityOtherHalf = liquidityTokens - liquidityHalf;
    
    // 6. swap代币为ETH
    uint256 tokensToSwap = liquidityHalf + marketingTokens + devTokens;
    uint256 initialETHBalance = address(this).balance;
    _swapTokensForETH(tokensToSwap);
    uint256 ethReceived = address(this).balance - initialETHBalance;
    
    // 7. 按比例分配ETH
    uint256 ethForLiquidity = (ethReceived * liquidityHalf) / tokensToSwap;
    uint256 ethForMarketing = (ethReceived * marketingTokens) / tokensToSwap;
    uint256 ethForDev = ethReceived - ethForLiquidity - ethForMarketing;
    
    // 8. 添加流动性(代币+ETH)
    if (liquidityOtherHalf > 0 && ethForLiquidity > 0) {
        _addLiquidity(liquidityOtherHalf, ethForLiquidity);
    }
    
    // 9. 发送ETH给营销和开发钱包
    if (ethForMarketing > 0) {
        payable(marketingWallet).transfer(ethForMarketing);
    }
    if (ethForDev > 0) {
        payable(devWallet).transfer(ethForDev);
    }
}
```

## 14. _swapTokensForETH函数

```solidity
function _swapTokensForETH(uint256 tokenAmount) private {
    // 1. 构建swap路径: 代币 -> WETH
    address[] memory path = new address[](2);
    path[0] = address(this);  // 源代币(当前合约)
    path[1] = uniswapV2Router.WETH();  // 目标代币(WETH)
    
    // 2. 授权路由使用代币
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    
    // 3. 执行swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,  // 输入代币数量
        0,  // 接受任何数量的ETH(最小输出为0)
        path,  // swap路径
        address(this),  // 接收地址
        block.timestamp  // 截止时间
    );
}
```

## 15. _addLiquidity函数

```solidity
function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // 1. 授权路由使用代币
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    
    // 2. 添加流动性
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
        address(this),  // 代币地址
        tokenAmount,  // 代币数量
        0,  // 最小代币数量(滑点容忍)
        0,  // 最小ETH数量(滑点容忍)
        liquidityWallet,  // LP代币接收地址
        block.timestamp  // 截止时间
    );
}
```

## 16. 管理员函数

### setTaxRates - 设置税率
```solidity
function setTaxRates(uint256 _buyTax, uint256 _sellTax) external override onlyOwner {
    require(_buyTax <= MAX_TAX_RATE, "Buy tax too high");  // 买入税不超过25%
    require(_sellTax <= MAX_TAX_RATE, "Sell tax too high");  // 卖出税不超过25%
    
    buyTaxRate = _buyTax;
    sellTaxRate = _sellTax;
    
    emit TaxConfigUpdated(_buyTax, _sellTax);
}
```

### setTaxDistribution - 设置税费分配
```solidity
function setTaxDistribution(
    uint256 _liquidityShare,
    uint256 _marketingShare,
    uint256 _devShare,
    uint256 _burnShare
) external override onlyOwner {
    // 确保总和为100%(10000基点)
    require(
        _liquidityShare + _marketingShare + _devShare + _burnShare == BASIS_POINTS,
        "Shares must sum to 10000"
    );
    
    liquidityShare = _liquidityShare;
    marketingShare = _marketingShare;
    devShare = _devShare;
    burnShare = _burnShare;
}
```

### enableTrading - 启用交易
```solidity
function enableTrading() external override onlyOwner {
    require(!tradingEnabled, "Trading already enabled");
    tradingEnabled = true;
    tradingEnabledTimestamp = block.timestamp;  // 记录启动时间
    tradingEnabledBlock = block.number;  // 记录启动区块
    
    emit TradingEnabled(block.timestamp);
}
```

### setBlacklist - 设置黑名单
```solidity
function setBlacklist(address account, bool blacklisted) external override onlyOwner {
    require(account != owner(), "Cannot blacklist owner");  // 不能拉黑owner
    require(account != address(this), "Cannot blacklist contract");  // 不能拉黑合约
    
    _isBlacklisted[account] = blacklisted;
    emit BlacklistUpdated(account, blacklisted);
}
```

## 17. Uniswap接口定义

### IUniswapV2Factory
```solidity
interface IUniswapV2Factory {
    // 创建交易对
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
```

### IUniswapV2Router02
```solidity
interface IUniswapV2Router02 {
    // 获取工厂地址
    function factory() external pure returns (address);
    
    // 获取WETH地址
    function WETH() external pure returns (address);
    
    // 添加ETH流动性
    function addLiquidityETH(
        address token,  // 代币地址
        uint amountTokenDesired,  // 期望代币数量
        uint amountTokenMin,  // 最小代币数量
        uint amountETHMin,  // 最小ETH数量
        address to,  // LP代币接收地址
        uint deadline  // 截止时间
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    // Swap代币为ETH(支持收费代币)
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,  // 输入代币数量
        uint amountOutMin,  // 最小输出ETH数量
        address[] calldata path,  // swap路径
        address to,  // 接收地址
        uint deadline  // 截止时间
    ) external;
}
```

## 总结

这个合约实现了一个功能完整的Meme代币,包含:

1. **税费系统** - 买入卖出自动收税
2. **自动流动性** - 税费自动添加到流动性池
3. **多重保护** - 黑名单、交易限制、冷却期、启动保护
4. **资金分配** - 自动分配给流动性、营销、开发和销毁
5. **安全机制** - 防重入、所有权管理、紧急救援功能

每一行代码都有其特定的作用,共同构成了一个安全、功能丰富的Meme代币系统。

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IShibaMeme.sol";

/**
 * @title ShibaMemeToken
 * @dev SHIB风格Meme代币实现
 * 
 * 核心功能：
 * 1. 代币税机制：买入税/卖出税，可配置分配比例（流动性/营销/开发/销毁）
 * 2. 流动性池集成：自动添加流动性到Uniswap V2
 * 3. 交易限制：单笔限额、最大持有量、冷却期
 * 4. 反机器人：黑名单、启动保护
 * 5. 反射奖励：持有者自动获得交易分红
 * 
 * 安全特性：
 * - 使用OpenZeppelin标准库
 * - 防重入攻击保护
 * - 所有权可转移
 * - 紧急暂停功能
 */
contract ShibaMemeToken is ERC20, Ownable, ReentrancyGuard, IShibaMeme {
    
    // ============ 常量定义 ============
    
    /// @dev 基点分母，10000 = 100%
    uint256 private constant BASIS_POINTS = 10000;
    
    /// @dev 最大税率限制（25%）
    uint256 private constant MAX_TAX_RATE = 2500;
    
    /// @dev 死亡地址（用于销毁代币）
    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    // ============ Uniswap V2 接口 ============
    
    /// @dev Uniswap V2 Router接口
    IUniswapV2Router02 public immutable uniswapV2Router;
    
    /// @dev Uniswap V2 交易对地址
    address public immutable uniswapV2Pair;
    
    // ============ 税费配置 ============
    
    /// @dev 买入税率（基点）
    uint256 public buyTaxRate = 500; // 5%
    
    /// @dev 卖出税率（基点）
    uint256 public sellTaxRate = 1000; // 10%
    
    /// @dev 税费分配：流动性份额
    uint256 public liquidityShare = 4000; // 40%
    
    /// @dev 税费分配：营销份额
    uint256 public marketingShare = 3000; // 30%
    
    /// @dev 税费分配：开发份额
    uint256 public devShare = 2000; // 20%
    
    /// @dev 税费分配：销毁份额
    uint256 public burnShare = 1000; // 10%
    
    /// @dev 流动性接收钱包
    address public liquidityWallet;
    
    /// @dev 营销钱包
    address public marketingWallet;
    
    /// @dev 开发钱包
    address public devWallet;
    
    // ============ 交易限制配置 ============
    
    /// @dev 是否启用交易限制
    bool public limitsEnabled = true;
    
    /// @dev 单笔交易最大金额
    uint256 public maxTxAmount;
    
    /// @dev 单个钱包最大持有量
    uint256 public maxWalletAmount;
    
    /// @dev 冷却期（秒）
    uint256 public cooldownPeriod = 60;
    
    /// @dev 记录每个地址的最后交易时间
    mapping(address => uint256) private _lastTransferTime;
    
    // ============ 交易控制 ============
    
    /// @dev 是否已启用交易
    bool public tradingEnabled = false;
    
    /// @dev 交易启动时间
    uint256 public tradingEnabledTimestamp;
    
    /// @dev 交易启动区块
    uint256 public tradingEnabledBlock;
    
    // ============ 黑名单 ============
    
    /// @dev 黑名单映射
    mapping(address => bool) private _isBlacklisted;
    
    // ============ 豁免列表 ============
    
    /// @dev 免税地址
    mapping(address => bool) private _isExcludedFromFees;
    
    /// @dev 免限制地址
    mapping(address => bool) private _isExcludedFromLimits;
    
    // ============ 自动流动性 ============
    
    /// @dev 是否正在进行自动流动性添加（防重入标志）
    bool private _inSwapAndLiquify;
    
    /// @dev 触发自动添加流动性的代币阈值
    uint256 public swapThreshold;
    
    /// @dev 是否启用自动添加流动性
    bool public swapAndLiquifyEnabled = true;
    
    /// @dev 累积的待处理税费
    uint256 private _pendingTaxTokens;
    
    // ============ 修饰器 ============
    
    /**
     * @dev 防止在swap过程中递归调用
     */
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    // ============ 构造函数 ============
    
    /**
     * @dev 构造函数
     * @param _name 代币名称
     * @param _symbol 代币符号
     * @param _totalSupply 总供应量
     * @param _routerAddress Uniswap V2 Router地址
     * @param _marketingWallet 营销钱包地址
     * @param _devWallet 开发钱包地址
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _routerAddress,
        address _marketingWallet,
        address _devWallet
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_marketingWallet != address(0), "Marketing wallet cannot be zero");
        require(_devWallet != address(0), "Dev wallet cannot be zero");
        
        // 初始化Uniswap路由和交易对
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        // 设置钱包地址
        liquidityWallet = msg.sender;
        marketingWallet = _marketingWallet;
        devWallet = _devWallet;
        
        // 设置交易限制（总供应量的0.5%和2%）
        maxTxAmount = _totalSupply * 5 / 1000; // 0.5%
        maxWalletAmount = _totalSupply * 20 / 1000; // 2%
        swapThreshold = _totalSupply * 5 / 10000; // 0.05%
        
        // 设置豁免
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD_ADDRESS] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[devWallet] = true;
        
        _isExcludedFromLimits[msg.sender] = true;
        _isExcludedFromLimits[address(this)] = true;
        _isExcludedFromLimits[DEAD_ADDRESS] = true;
        _isExcludedFromLimits[_uniswapV2Pair] = true;
        
        // 铸造总供应量给合约部署者
        _mint(msg.sender, _totalSupply);
    }
    
    // ============ 接收ETH ============
    
    /**
     * @dev 允许合约接收ETH（用于接收swap产生的ETH）
     */
    receive() external payable {}
    
    // ============ 核心转账函数重写 ============
    
    /**
     * @dev 重写ERC20的_update函数，添加税费和限制逻辑
     * @param from 发送方地址
     * @param to 接收方地址
     * @param amount 转账金额
     * 
     * 执行顺序：
     * 1. 检查是否为铸造/销毁操作
     * 2. 验证基本条件（金额、黑名单）
     * 3. 检查交易启用状态
     * 4. 应用交易限制（单笔限额、持有量、冷却期）
     * 5. 触发自动流动性添加（如果需要）
     * 6. 计算并收取税费
     * 7. 执行实际转账
     */
    function _update(
        address from,  // 发送方地址
        address to,    // 接收方地址
        uint256 amount // 转账金额
    ) internal override {
        // 【步骤1】允许铸造和销毁操作（from或to为零地址时直接执行）
        // 铸造：from = address(0), to = 用户地址
        // 销毁：from = 用户地址, to = address(0)
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount); // 调用父合约ERC20的_update函数
            return; // 提前返回，跳过后续所有检查
        }
        
        // 【步骤2】验证转账金额必须大于0
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // 【步骤3】检查发送方和接收方是否在黑名单中
        // !_isBlacklisted[from]: 发送方不在黑名单
        // !_isBlacklisted[to]: 接收方不在黑名单
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Blacklisted address");
        
        // 【步骤4】如果是合约自身操作或owner操作，跳过所有限制直接执行
        // 这些地址的转账不受任何限制（税费、限额等）
        if (from == address(this) || to == address(this) || from == owner() || to == owner()) {
            super._update(from, to, amount); // 直接执行转账
            return; // 提前返回
        }
        
        // 【步骤5】检查交易是否已启用（防止在正式启动前交易）
        if (!tradingEnabled) { // 如果交易未启用
            // 只允许免税地址进行转账（通常是owner和合约）
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading not enabled");
        }
        
        // 【步骤6】应用交易限制（如果启用且双方都不在豁免名单中）
        if (limitsEnabled && !_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
            // 【6.1】检查单笔交易限额（防止鲸鱼一次性买卖太多）
            require(amount <= maxTxAmount, "Exceeds max transaction amount");
            
            // 【6.2】检查最大持有量（只在买入时检查，卖出不限制）
            // to != uniswapV2Pair 表示不是卖出交易（卖出时to是交易对地址）
            if (to != uniswapV2Pair) {
                // 确保接收方持有量不超过最大钱包限额
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "Exceeds max wallet amount"
                );
            }
            
            // 【6.3】检查冷却期（防止高频交易/机器人）
            // cooldownPeriod > 0: 启用了冷却期
            // from != uniswapV2Pair: 不是买入交易（买入不限制冷却）
            if (cooldownPeriod > 0 && from != uniswapV2Pair) {
                // 检查距离上次转账是否已过冷却期
                require(
                    block.timestamp >= _lastTransferTime[from] + cooldownPeriod,
                    "Cooldown period active"
                );
                _lastTransferTime[from] = block.timestamp; // 更新最后转账时间
            }
        }
        
        // 【步骤7】自动添加流动性逻辑（在卖出时触发）
        // 判断是否应该执行swap操作的条件：
        bool shouldSwap = !_inSwapAndLiquify &&      // 1. 当前不在swap过程中（防重入）
                          to == uniswapV2Pair &&      // 2. 是卖出交易（to是交易对地址）
                          swapAndLiquifyEnabled &&    // 3. 自动流动性功能已启用
                          _pendingTaxTokens >= swapThreshold; // 4. 累积的税费达到阈值
        
        if (shouldSwap) {
            _swapAndDistribute(); // 执行swap和分配操作
        }
        
        // 【步骤8】判断是否需要收取税费
        // 收税条件：
        bool takeFee = !_inSwapAndLiquify &&            // 1. 不在swap过程中
                       !_isExcludedFromFees[from] &&    // 2. 发送方不在免税名单
                       !_isExcludedFromFees[to] &&      // 3. 接收方不在免税名单
                       (from == uniswapV2Pair || to == uniswapV2Pair); // 4. 是买入或卖出交易
        
        uint256 taxAmount = 0; // 初始化税费金额为0
        
        if (takeFee) { // 如果需要收税
            uint256 taxRate; // 声明税率变量
            
            // 【8.1】确定税率（买入或卖出）
            if (from == uniswapV2Pair) {
                // 买入交易：from是交易对地址，to是买家
                taxRate = buyTaxRate; // 使用买入税率
            } else {
                // 卖出交易：from是卖家，to是交易对地址
                taxRate = sellTaxRate; // 使用卖出税率
                
                // 【8.2】启动保护：前10个区块高税率（99%）防夹子机器人
                // 夹子机器人会在交易启动瞬间抢先交易，高税率可以防止这种行为
                if (tradingEnabledBlock > 0 && block.number <= tradingEnabledBlock + 10) {
                    taxRate = 9900; // 设置为99%的惩罚性税率
                }
            }
            
            // 【8.3】计算税费金额 = 转账金额 * 税率 / 基点（10000）
            taxAmount = (amount * taxRate) / BASIS_POINTS;
            _pendingTaxTokens += taxAmount; // 累加到待处理税费中
            
            // 【8.4】将税费转移到合约地址
            if (taxAmount > 0) {
                super._update(from, address(this), taxAmount); // 从发送方转税费到合约
            }
        }
        
        // 【步骤9】转移扣除税费后的金额给接收方
        uint256 transferAmount = amount - taxAmount; // 实际转账金额 = 原金额 - 税费
        super._update(from, to, transferAmount); // 执行实际转账
    }
    
    // ============ 内部函数 ============
    
    /**
     * @dev 将累积的税费代币swap并分配
     */
    function _swapAndDistribute() private lockTheSwap {
        uint256 contractTokenBalance = _pendingTaxTokens;
        if (contractTokenBalance == 0) return;
        
        _pendingTaxTokens = 0;
        
        uint256 totalShares = liquidityShare + marketingShare + devShare + burnShare;
        if (totalShares == 0) return;
        
        // 计算各部分份额
        uint256 liquidityTokens = (contractTokenBalance * liquidityShare) / totalShares;
        uint256 marketingTokens = (contractTokenBalance * marketingShare) / totalShares;
        uint256 devTokens = (contractTokenBalance * devShare) / totalShares;
        uint256 burnTokens = (contractTokenBalance * burnShare) / totalShares;
        
        // 销毁代币
        if (burnTokens > 0) {
            super._update(address(this), DEAD_ADDRESS, burnTokens);
        }
        
        // 流动性部分：一半swap成ETH
        uint256 liquidityHalf = liquidityTokens / 2;
        uint256 liquidityOtherHalf = liquidityTokens - liquidityHalf;
        
        // 需要swap成ETH的代币总量
        uint256 tokensToSwap = liquidityHalf + marketingTokens + devTokens;
        
        if (tokensToSwap == 0) return;
        
        // Swap代币为ETH
        uint256 initialETHBalance = address(this).balance;
        _swapTokensForETH(tokensToSwap);
        uint256 ethReceived = address(this).balance - initialETHBalance;
        
        if (ethReceived == 0) return;
        
        // 计算ETH分配
        uint256 ethForLiquidity = (ethReceived * liquidityHalf) / tokensToSwap;
        uint256 ethForMarketing = (ethReceived * marketingTokens) / tokensToSwap;
        uint256 ethForDev = ethReceived - ethForLiquidity - ethForMarketing;
        
        // 添加流动性
        if (liquidityOtherHalf > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityOtherHalf, ethForLiquidity);
            emit SwapAndLiquify(liquidityHalf, ethForLiquidity, liquidityOtherHalf);
        }
        
        // 发送ETH给营销和开发钱包
        if (ethForMarketing > 0) {
            payable(marketingWallet).transfer(ethForMarketing);
        }
        
        if (ethForDev > 0) {
            payable(devWallet).transfer(ethForDev);
        }
    }
    
    /**
     * @dev 将代币swap为ETH
     */
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // 接受任何数量的ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    /**
     * @dev 添加流动性
     */
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // 滑点容忍
            0, // 滑点容忍
            liquidityWallet,
            block.timestamp
        );
    }
    
    // ============ 管理员函数 ============
    
    /**
     * @dev 设置税率
     */
    function setTaxRates(uint256 _buyTax, uint256 _sellTax) external override onlyOwner {
        require(_buyTax <= MAX_TAX_RATE, "Buy tax too high");
        require(_sellTax <= MAX_TAX_RATE, "Sell tax too high");
        
        buyTaxRate = _buyTax;
        sellTaxRate = _sellTax;
        
        emit TaxConfigUpdated(_buyTax, _sellTax);
    }
    
    /**
     * @dev 设置税费分配比例
     */
    function setTaxDistribution(
        uint256 _liquidityShare,
        uint256 _marketingShare,
        uint256 _devShare,
        uint256 _burnShare
    ) external override onlyOwner {
        require(
            _liquidityShare + _marketingShare + _devShare + _burnShare == BASIS_POINTS,
            "Shares must sum to 10000"
        );
        
        liquidityShare = _liquidityShare;
        marketingShare = _marketingShare;
        devShare = _devShare;
        burnShare = _burnShare;
    }
    
    /**
     * @dev 设置税费钱包
     */
    function setTaxWallets(
        address _liquidityWallet,
        address _marketingWallet,
        address _devWallet
    ) external override onlyOwner {
        require(_liquidityWallet != address(0), "Invalid liquidity wallet");
        require(_marketingWallet != address(0), "Invalid marketing wallet");
        require(_devWallet != address(0), "Invalid dev wallet");
        
        liquidityWallet = _liquidityWallet;
        marketingWallet = _marketingWallet;
        devWallet = _devWallet;
        
        emit TaxWalletsUpdated(_liquidityWallet, _marketingWallet, _devWallet);
    }
    
    /**
     * @dev 设置交易限制
     */
    function setLimits(uint256 _maxTxAmount, uint256 _maxWalletAmount) external override onlyOwner {
        require(_maxTxAmount >= totalSupply() / 1000, "Max tx too low"); // 至少0.1%
        require(_maxWalletAmount >= totalSupply() / 100, "Max wallet too low"); // 至少1%
        
        maxTxAmount = _maxTxAmount;
        maxWalletAmount = _maxWalletAmount;
        
        emit LimitsUpdated(_maxTxAmount, _maxWalletAmount);
    }
    
    /**
     * @dev 启用/禁用交易限制
     */
    function setLimitsEnabled(bool enabled) external override onlyOwner {
        limitsEnabled = enabled;
    }
    
    /**
     * @dev 设置冷却期
     */
    function setCooldown(uint256 cooldownSeconds) external override onlyOwner {
        require(cooldownSeconds <= 300, "Cooldown too long"); // 最多5分钟
        cooldownPeriod = cooldownSeconds;
    }
    
    /**
     * @dev 启用交易
     */
    function enableTrading() external override onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        tradingEnabledTimestamp = block.timestamp;
        tradingEnabledBlock = block.number;
        
        emit TradingEnabled(block.timestamp);
    }
    
    /**
     * @dev 设置swap阈值
     */
    function setSwapThreshold(uint256 threshold) external override onlyOwner {
        require(threshold >= totalSupply() / 100000, "Threshold too low"); // 至少0.001%
        swapThreshold = threshold;
    }
    
    /**
     * @dev 设置是否启用自动流动性
     */
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
    }
    
    /**
     * @dev 设置黑名单
     */
    function setBlacklist(address account, bool blacklisted) external override onlyOwner {
        require(account != owner(), "Cannot blacklist owner");
        require(account != address(this), "Cannot blacklist contract");
        
        _isBlacklisted[account] = blacklisted;
        emit BlacklistUpdated(account, blacklisted);
    }
    
    /**
     * @dev 批量设置黑名单
     */
    function setBlacklistBatch(address[] calldata accounts, bool blacklisted) external override onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] != owner() && accounts[i] != address(this)) {
                _isBlacklisted[accounts[i]] = blacklisted;
                emit BlacklistUpdated(accounts[i], blacklisted);
            }
        }
    }
    
    /**
     * @dev 设置免税地址
     */
    function setExcludeFromFees(address account, bool excluded) external override onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }
    
    /**
     * @dev 设置免限制地址
     */
    function setExcludeFromLimits(address account, bool excluded) external override onlyOwner {
        _isExcludedFromLimits[account] = excluded;
    }
    
    /**
     * @dev 手动触发swap和流动性添加
     */
    function manualSwapAndDistribute() external onlyOwner {
        require(!_inSwapAndLiquify, "Already swapping");
        _swapAndDistribute();
    }
    
    /**
     * @dev 紧急提取卡在合约中的ETH
     */
    function rescueETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev 紧急提取卡在合约中的代币
     */
    function rescueTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(this), "Cannot rescue own token");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }
    
    // ============ 查询函数 ============
    
    function getTaxRates() external view override returns (uint256 buyTax, uint256 sellTax) {
        return (buyTaxRate, sellTaxRate);
    }
    
    function getTaxDistribution() external view override returns (
        uint256 _liquidityShare,
        uint256 _marketingShare,
        uint256 _devShare,
        uint256 _burnShare
    ) {
        return (liquidityShare, marketingShare, devShare, burnShare);
    }
    
    function getLimits() external view override returns (
        uint256 _maxTxAmount,
        uint256 _maxWalletAmount,
        uint256 _cooldownPeriod
    ) {
        return (maxTxAmount, maxWalletAmount, cooldownPeriod);
    }
    
    function isBlacklisted(address account) external view override returns (bool) {
        return _isBlacklisted[account];
    }
    
    function isExcludedFromFees(address account) external view override returns (bool) {
        return _isExcludedFromFees[account];
    }
    
    function getPendingTaxTokens() external view returns (uint256) {
        return _pendingTaxTokens;
    }
}

// ============ Uniswap V2 接口定义 ============

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function addLiquidityETH(
        address token,  // 要添加的代币合约地址
        uint amountTokenDesired,// 要添加的代币数量
        uint amountTokenMin,// 最小代币数量
        uint amountETHMin,// 最小ETH数量
        address to,// 接收者地址
        uint deadline// 交易过期时间
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

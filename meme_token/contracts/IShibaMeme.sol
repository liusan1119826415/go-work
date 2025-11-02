// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IShibaMeme
 * @dev SHIB风格Meme代币接口
 * 定义了代币税、流动性管理和交易限制的核心接口
 */
interface IShibaMeme {
    
    // ============ 事件定义 ============
    
    /**
     * @dev 当税费配置更新时触发
     * @param buyTax 买入税率（基点，10000 = 100%）
     * @param sellTax 卖出税率
     */
    event TaxConfigUpdated(uint256 buyTax, uint256 sellTax);
    
    /**
     * @dev 当交易限制更新时触发
     * @param maxTxAmount 最大交易金额
     * @param maxWalletAmount 最大持有金额
     */
    event LimitsUpdated(uint256 maxTxAmount, uint256 maxWalletAmount);
    
    /**
     * @dev 当税费分配地址更新时触发
     */
    event TaxWalletsUpdated(
        address liquidityWallet,
        address marketingWallet,
        address devWallet
    );
    
    /**
     * @dev 当流动性自动添加时触发
     * @param tokensSwapped 交换的代币数量
     * @param ethReceived 收到的ETH数量
     * @param tokensIntoLiquidity 添加到流动性的代币数量
     */
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    
    /**
     * @dev 当交易启用状态改变时触发
     */
    event TradingEnabled(uint256 timestamp);
    
    /**
     * @dev 当地址被添加/移除黑名单时触发
     */
    event BlacklistUpdated(address account, bool isBlacklisted);
    
    // ============ 税费管理函数 ============
    
    /**
     * @dev 设置买入和卖出税率
     * @param _buyTax 买入税率（基点）
     * @param _sellTax 卖出税率（基点）
     */
    function setTaxRates(uint256 _buyTax, uint256 _sellTax) external;
    
    /**
     * @dev 设置税费分配比例
     * @param _liquidityShare 流动性份额
     * @param _marketingShare 营销份额
     * @param _devShare 开发份额
     * @param _burnShare 销毁份额
     */
    function setTaxDistribution(
        uint256 _liquidityShare,
        uint256 _marketingShare,
        uint256 _devShare,
        uint256 _burnShare
    ) external;
    
    /**
     * @dev 设置税费接收钱包
     */
    function setTaxWallets(
        address _liquidityWallet,
        address _marketingWallet,
        address _devWallet
    ) external;
    
    // ============ 交易限制函数 ============
    
    /**
     * @dev 设置交易限制
     * @param _maxTxAmount 单笔最大交易金额
     * @param _maxWalletAmount 单个钱包最大持有量
     */
    function setLimits(uint256 _maxTxAmount, uint256 _maxWalletAmount) external;
    
    /**
     * @dev 启用/禁用交易限制
     */
    function setLimitsEnabled(bool enabled) external;
    
    /**
     * @dev 设置冷却期
     * @param cooldownSeconds 冷却时间（秒）
     */
    function setCooldown(uint256 cooldownSeconds) external;
    
    // ============ 交易控制函数 ============
    
    /**
     * @dev 启用交易
     */
    function enableTrading() external;
    
    /**
     * @dev 设置自动添加流动性的触发阈值
     * @param threshold 阈值（代币数量）
     */
    function setSwapThreshold(uint256 threshold) external;
    
    // ============ 黑名单管理 ============
    
    /**
     * @dev 添加/移除黑名单
     */
    function setBlacklist(address account, bool blacklisted) external;
    
    /**
     * @dev 批量设置黑名单
     */
    function setBlacklistBatch(address[] calldata accounts, bool blacklisted) external;
    
    // ============ 豁免管理 ============
    
    /**
     * @dev 设置免税地址
     */
    function setExcludeFromFees(address account, bool excluded) external;
    
    /**
     * @dev 设置免限制地址
     */
    function setExcludeFromLimits(address account, bool excluded) external;
    
    // ============ 查询函数 ============
    
    /**
     * @dev 获取当前税率配置
     */
    function getTaxRates() external view returns (uint256 buyTax, uint256 sellTax);
    
    /**
     * @dev 获取税费分配比例
     */
    function getTaxDistribution() external view returns (
        uint256 liquidityShare,
        uint256 marketingShare,
        uint256 devShare,
        uint256 burnShare
    );
    
    /**
     * @dev 获取交易限制配置
     */
    function getLimits() external view returns (
        uint256 maxTxAmount,
        uint256 maxWalletAmount,
        uint256 cooldownPeriod
    );
    
    /**
     * @dev 检查地址是否在黑名单
     */
    function isBlacklisted(address account) external view returns (bool);
    
    /**
     * @dev 检查地址是否免税
     */
    function isExcludedFromFees(address account) external view returns (bool);
}

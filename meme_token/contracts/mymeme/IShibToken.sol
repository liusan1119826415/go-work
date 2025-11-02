//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IShibToken {

    //事件定义
     event taxConfigUpdate(uint256 buyTax, uint256 sellTax);

    //当税费分配地址更新时触发

     event taxWalletUpdate(address liquidityWallet, address marketingWallet, address devWallet);  


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
     //设置买入和卖出税费
     function setTaxRates(uint256 _buyTax, uint256 _sellTax) external;

     /**
      * 设置税额分配比例
      *
      */

     function setTaxDistribution(
        uint256 _liquidityTax,
        uint256 _marketingTax,
        uint256 _devTax,
        uint256 _burnTax
     )external;

     //设置税费接收钱包

     function setTaxWallet(
        address _liquidityTaxWallet,
        address _marketingTaxWallet,
        address _devTaxWallet
     )external;

     //下面交易限制函数
     
     //设置免税地址
     function setExcludedFromFees(address _address, bool excluded)external;

     

    //设置免交易限制地址

    function setExcludedFromLimit(address _address, bool excluded) external;

    //设置冷却时间

    function setCooldownPeriod(uint256 _time)external;

    //设置交易限制
    function setLimits(uint256 _maxTxAmount, uint256 _maxWalletAmount) external;

    //设置是否启动交易限制

    function setLimitEnable(bool _enabled)external;

    //设置黑名单地址

    function setBackAddress(address _backAddress, bool is_back)external;

    //批量设置黑名单
    function setBatchBackAddress(address[] calldata _backaddress, bool is_back) external;



    //设置自动流动厥值

    function setSwapThreshold(uint256 _swapThreshold) external;

    //获取买入卖出的税率
    function getTaxRate() external view returns(uint256, uint256);





}
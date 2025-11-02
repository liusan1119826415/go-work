//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IShibToken.sol";
contract ShibToken is ERC20, Ownable,IShibToken{
    

    //定义买入tax
    uint256 public buyTax=50; //5%
   //定义卖出tax
    uint256 public sellTax=100;//10%


    //税额分配流动性份额
    uint256 public liquidityShare=400; //40%

    //营销份额
    uint256 public marketingShare=300; //30%

    //开发份额

    uint256 public devShare= 200; //20%

    //最大交易单笔金额
    uint256 public maxTxWallet;

    //单个钱包最大持有量
    uint256 public maxWalletAmount;

    //销毁份额
    uint256 public burnShare = 100; //10%

    

    /// @dev 死亡地址（用于销毁代币）
    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    //开发钱包

    address public devAddress;

     //流动性接收钱包
    address public liquidityReceiver;

    //营销钱包

    address public marketingAddress;


    //是否交易限制
    bool public limitEnable=true;

    //是否启动交易
    bool public tradingEnabled = false;
    

    //冷却期
    uint256 public cooldownPeriod=60;

    //
    address private uniswapV2Pair;

   

    //触发流动性的代币厥值
    uint256 public swapThreshold;

    //最后交易时间
    mapping (address=>uint256) private cooldown;

    //黑名单
    mapping(address=>bool) private backList;

    //交易免税地址

    mapping(address=>bool) private _isExcludedFromFees;

    //免限制地址
    mapping(address=>bool) private _isExcludedFromLimits;

    /// @dev 是否正在进行自动流动性添加（防重入标志）
    bool private _inSwapAndLiquify;

    /// @dev 累积的待处理税费
    uint256 private _pendingTaxTokens;

    IUniswapV2Router02 public immutable uniswapV2Router;


    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _routeAddress,
        address _marketingAddress,
        address _devAddress

    ) ERC20(_name,_symbol) Ownable(msg.sender){

         require(_marketingAddress != address(0),"Invalid Marketing Address");

         require(_devAddress != address(0),"Invalid Dev Address");

         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routeAddress);

         address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
         uniswapV2Router = _uniswapV2Router;
         uniswapV2Pair = _uniswapV2Pair;
         liquidityReceiver = msg.sender;
         marketingAddress = _marketingAddress;
         devAddress = _devAddress;

         //最大单笔交易金额
         maxTxWallet = _totalSupply * 50/1000; //0.5%
         maxWalletAmount = _totalSupply * 20/100; //2%
         swapThreshold = _totalSupply * 5/10000;//0.05%
         //设置免税地址
         _isExcludedFromFees[msg.sender] = true;
         _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD_ADDRESS] = true;
         _isExcludedFromFees[_marketingAddress] = true;
         _isExcludedFromFees[_devAddress] = true;

         //设置免限制地址

         _isExcludedFromLimits[msg.sender] = true;
         _isExcludedFromLimits[address(this)] = true;
         _isExcludedFromLimits[DEAD_ADDRESS] = true;
         _isExcludedFromLimits[_uniswapV2Pair] = true;

         _mint(msg.sender, _totalSupply);


    }

    modifier lockTheSwap(){
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }


    /**
     * @dev 接收eth 
     */
     receive() external payable {}


     //重写erc20 _update

     function _update(address from, address to, uint256 amount) internal override {
        //筹造和销毁 不需要处理
        if( from == address(0) || to == address(0)){
            super._update(from, to, amount);
            return;
        }

        //转账金额必须大于0 
        require(amount > 0, "Transfer amount must be greater than zero");
        //检查黑名单
        require(!backList[from] && !backList[to], "address is in blacklist");
         //如果是合约本身或者合约所有者
        if(from == address(this) || to == address(this) || from == owner() || to == owner()){
            super._update(from,to,amount);
            return;
        }

        //如果交易未开启
        if(!tradingEnabled){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not enabled");
        }

        //如果交易限制开启
        if(limitEnable && !_isExcludedFromLimits[from] && !_isExcludedFromLimits[to] ){
            //查询单笔
            require(amount <= maxTxWallet,"Amount exceeds the maxTxWallet");
             //检查钱包最大持有量 to != pair 是买入  
            if( to != uniswapV2Pair ){
                require(balanceOf(to)+amount <= maxWalletAmount,"Amount exceeds the maxWalletAmount");
            }

            //检查卖出冷却期
  
            if(cooldownPeriod>0 && from != uniswapV2Pair){
                require(block.timestamp>= cooldown[from] + cooldownPeriod, "Cooldown period not over");
                cooldown[from] = block.timestamp;
            }

            //自动添加流动资金
            bool swapShould = !_inSwapAndLiquify && 
                             _pendingTaxTokens >= swapThreshold &&
                              to == uniswapV2Pair; //卖出交易
             if(swapShould){
                swapBack();
            }
        }



       

     }
     //将累计的tax 分配到营销钱包和开发钱包
     function swapBack() private lockTheSwap(){

        uint256 amountToSwap = _pendingTaxTokens;
        if(amountToSwap == 0) return;

        _pendingTaxTokens = 0;

        uint256 totalShare = marketingShare + devShare + burnShare+ liquidityShare;
        if(totalShare == 0) return;

        //计算各部分额度
        uint256 marketAmount = (amountToSwap * marketingShare) / totalShare;   
        uint256 devAmount = (amountToSwap * devShare)/totalShare;

        uint256 liquidityAmount = (amountToSwap * liquidityShare)/totalShare;

        uint256 burnAmount = (amountToSwap * burnShare)/totalShare;

        if(burnAmount > 0){
            //销毁代币
            super._update(address(this),DEAD_ADDRESS, burnAmount);
        }

        uint256 liquidityHft = liquidityAmount /2 ;
        uint256 liquidityHft2 = liquidityAmount - liquidityHft;

        //需要转换为eth
        uint256 tokenSwap = marketAmount + devAmount + liquidityHft;

        if(tokenSwap == 0) return;

        //Swap 代币为ETH
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(tokenSwap);
        uint256 ethBalance = address(this).balance - initialETHBalance;

        if( ethBalance == 0) return;

        //计算eth 分配
        uint256 ethForMarketing = (ethBalance * marketAmount)/tokenSwap;

        uint256 ethForDev = (ethBalance * devAmount)/tokenSwap;

        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;

        //添加流动性
        if(liquidityHft2>0 && ethForLiquidity>0){
            _addliquidity(liquidityHft2, ethForLiquidity);
            emit SwapAndLiquify(liquidityHft, ethForLiquidity, liquidityHft2);
        }

        if(ethForMarketing>0){
            //发送到营销钱包
            payable(marketingAddress).transfer(ethForMarketing);
        }

        if(ethForDev>0){
            //发送到开发钱包
            payable(devAddress).transfer(ethForDev);
        }


         
     }

    /**
     * @dev 兑换代币为eth
     */
     function _swapTokenForETH(uint256 tokenAmount) private {
         address[] memory path = new address[](2);
         path[0] = address(this);
         path[1] = uniswapV2Router.WETH();
         _approve(address(this), address(uniswapV2Router), tokenAmount);

         uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
             tokenAmount,
             0,//接受任何数量的eth
             path,
             address(this),
             block.timestamp
            );
     }

     /**
      * @dev 添加流动性
      */
      function _addliquidity(uint256 tokenAmount, uint256 ethAmount) private {
         
         _approve(address(this), address(uniswapV2Router), tokenAmount);
         uniswapV2Router.addLiquidityETH {value: ethAmount}(
            address(this), 
            tokenAmount, 
            0, // 滑点容忍
            0, // 滑点容忍
            liquidityReceiver, 
            block.timestamp
            );
      }

      //设置买入和卖出税费
      function setTaxRates(uint256 _buyTax, uint256 _sellTax) external override onlyOwner() {
        require(_buyTax <= 100 && _sellTax <= 100, "Taxes must be between 0 and 100");

        buyTax = _buyTax;
        sellTax = _sellTax;
        emit taxConfigUpdate(_buyTax, _sellTax);
      }


      //设置税额分配比例

      function setTaxDistribution(
        uint256 _liquidityTax, 
        uint256 _marketingTax, 
        uint256 _devTax, 
        uint256 _burnTax
        ) external override onlyOwner(){
         liquidityShare = _liquidityTax;
         marketingShare = _marketingTax;
         devShare = _devTax;
         burnShare = _burnTax;

      }

      //设置税费接收钱包
      function setTaxWallet(
        address _liquidityWallet,
        address _marketingWallet,
        address _devWallet
      )external override onlyOwner(){
         require(_liquidityWallet != address(0),"Invalid liquidity wallet address");
         require(_marketingWallet != address(0),"Invalid marketing wallet address");
         require(_devWallet != address(0),"Invalid dev wallet address");
        liquidityReceiver = _liquidityWallet;
        marketingAddress = _marketingWallet;
        devAddress = _devWallet;

        emit taxWalletUpdate(_liquidityWallet, _marketingWallet, _devWallet);

      }

      //设置免税地址

      function setExcludedFromFees(address account, bool excluded) external override onlyOwner(){

        _isExcludedFromFees[account] = excluded;


      }

      //设置免交易限制地址
      function setExcludedFromLimit(address account, bool excluded) external override onlyOwner(){
          _isExcludedFromLimits[account] = excluded;
      }

      //设置冷却时间

      function setCooldownPeriod(uint256 _time) external override onlyOwner(){
          cooldownPeriod = _time;

      }

      //设置交易限制金额
      function setLimits(uint256 _maxTxAmount, uint256 _maxWalletAmount) external override onlyOwner(){

          require(_maxTxAmount >= totalSupply() / 1000, "Max tx amount must be at least 0.1% of total supply");
          require(_maxWalletAmount >= totalSupply() / 100, "Max wallet amount must be at least 0.1% of total supply");
          maxTxWallet = _maxTxAmount;
          maxWalletAmount = _maxWalletAmount;
      }

      //设置交易限制开关

      function setLimitEnable(bool _enable) external override onlyOwner(){
           limitEnable = _enable;
      }

      //设置黑名单地址
      function setBackAddress(address _address, bool _isBack) external override onlyOwner(){
        require(_address != address(0), "Cannot blacklist contract");
        require(_address != owner(), "Cannot blacklist owner");

        backList[_address] = _isBack;
      }

      //批量设置黑名单地址
      function setBatchBackAddress(address[] calldata _backAddress, bool _isBack) external override onlyOwner(){
          
          for(uint i=0; i<_backAddress.length; i++){
            if(_backAddress[i] != address(0) && _backAddress[i] != owner()){
               backList[_backAddress[i]] = _isBack;
            }
            
          }

      }

      //获取买入卖出税率
      function getTaxRate() external view override returns(uint256 _buyTax, uint256 _sellTax){
         return (buyTax,sellTax);
      }

      //获取交易限制

      function getLimits() external view returns(uint256 _maxTxAmount, uint256 _maxWalletAmount, uint256 _cooldown){
        return (maxTxWallet,maxWalletAmount,cooldownPeriod);
      }

      //获取是否是免税地址
      function isExcludedFromFees(address account) external view returns(bool){
         return _isExcludedFromFees[account];
      }

      //设置流动厥值
      function setSwapThreshold(uint256 _swapThreshold) external override onlyOwner(){
          require(_swapThreshold >= totalSupply()/100000,"Threshold too low");
          swapThreshold = _swapThreshold;
      }

      function setTradeEnabled() external onlyOwner(){
           require(!tradingEnabled, "Trading already enabled");
           tradingEnabled = true;
      }
      
      //紧急提取合约里面的eth
      function withdrawEth() external onlyOwner(){
          payable(owner()).transfer(address(this).balance);
      }



    


}

interface IUniswapV2Factory {

    function createPair(address tokenA, address tokenB) external returns (address pair);

}


interface IUniswapV2Router02 {

    function factory() external pure returns (address);
    
    function WETH() external pure returns (address);
    

    function addLiquidityETH(
         address token, //代币
         uint amountTokenDesired,//购买代币数量
         uint amountTokenMin,//最小代币数量
         uint amountETHMin,//最小ETH数量
         address to,//购买者地址
         uint deadline//过期时间
     ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,//代币数量
        uint amountOutMin,//最小ETH数量
        address[] calldata path,//路径
        address to,//接收者地址
        uint deadline//过期时间
    ) external;
    
}
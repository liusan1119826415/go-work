//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
contract tokenTax is ERC20, Ownable{


     uint256 public buyTax = 5;

     uint256 public sellTax = 6;

     address public uinswapAddress;

     uint256 public maxTax = 25;

     uint256 private cooldownPeriod = 60;

     mapping(address=>uint256) public lastTransferTime;
     
     constructor() ERC20("tokenTax","tax") Ownable(msg.sender){
         _mint(msg.sender, 1000000*10**decimals());
     }

     modifier onlyTax(uint256 _tax){
         require(_tax <= maxTax,"tax too high");
         _;
     }

     //设置uinswap地址
     function setUinswapAddress(address _address) external {
        uinswapAddress = _address;
     }

     //修改买入税率
     function setBuyTax(uint256 _tax) external onlyOwner() onlyTax(_tax){
        buyTax = _tax;
     }

     //设置卖出税率
     function setSellTax(uint256 _tax) external onlyOwner() onlyTax(_tax){
        sellTax = _tax;
     }


     function _update(address from, address to, uint256 amount) internal override {
        // 铸币或销毁代币时不收税
        if(from == address(0) || to == address(0)){
            super._update(from, to, amount);
            return;
        }
         //限制同一地址转账的冷却期60秒
         if(from  != uinswapAddress && from != address(0)){
               require(block.timestamp - lastTransferTime[from] <=cooldownPeriod,"After 60 seconds of transaction at the same address");
               lastTransferTime[from] = block.timestamp;
         }

        //如果是买入（从Uniswap买入）
        if(from == uinswapAddress){
            //收取买入的税率
            uint256 tax = amount*buyTax/100;
            uint256 taxBuyAmount = amount - tax;
            super._update(from,address(this),tax);
            super._update(from,to,taxBuyAmount);
            return;
        }

        //如果是卖出（卖给Uniswap）
        if (to == uinswapAddress){
            //收取卖出的税率
             uint256 tax = amount * sellTax /100;
             uint256 taxAmount = amount - tax;
             super._update(from, address(this), tax);
             super._update(from, to, taxAmount);
             return;
        }

        //钱包间转账不收取税率
        super._update(from, to, amount);


     }









}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
contract limitToken is ERC20, Ownable{
    
    uint256 public maxWalletAmount;

    uint256 public limitAmount;

    mapping(address=>bool) public backAddress;

    constructor() ERC20("limitToken","LT")Ownable(msg.sender){
        uint256 totalSupply = 1000000 * 10 ** decimals();
        maxWalletAmount = totalSupply * 2 / 100; //2% 最大持有

        limitAmount = totalSupply * 5/1000; //单笔最多0.5%限制
        _mint(msg.sender, totalSupply);
    }


    function mint(address to , uint256 amount) external onlyOwner() {
        _mint(to,amount);
    }

    function burn(address from , uint256 amount) external onlyOwner() {
        _burn(from, amount);
    }

//calldata 只读不能 修改
//memory 可读可写
    function setBackAddress(address _backAddress) external onlyOwner(){
        require(_backAddress != owner(),"owner can not be backAddress");
        require(_backAddress != address(this),"backAddress can not be zero address");
        backAddress[_backAddress] = true;
    }



    function _update(address from, address to, uint256 amount) internal override {
        require(!backAddress[from],"backAddress can not transfer");
        require(!backAddress[to],"backAddress can not transfer");
        //销毁和筹造不限制
        if(from == address(0) || to == address(0)){
            super._update(from, to, amount);
            return;
        }

        //单笔交易最多总供应量的5%
        if(from != owner() && to != owner()){
         require(amount <= limitAmount, "Maximum per transaction");
         //检查持有者量
         require(balanceOf(to) + amount <= maxWalletAmount,"Exceeding the maximum holding amount");
        }
        
        super._update(from, to, amount);
    } 
}
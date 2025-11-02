//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract myFirstToken is ERC20, Ownable {


    mapping(address=>bool) public mints;

    //总转账次数
    uint256 public totalTransferCount;
    //每个地址转账次数
    mapping(address=>uint256) public addressTransferCount;

    //定义转账的事件
    event transferLogs(address indexed from,address indexed to, uint256 amount,uint256 timestamp);

   constructor() ERC20("myFirstToken","MFT") Ownable(msg.sender){
      //发布1000000个
      _mint(msg.sender, 1000000*10**decimals());
   }

   modifier onlyMint(){
      require(mints[msg.sender]== true,"not allowed to mint");
      _;
   }

   //筹造币
   function mint(address to , uint256 amount) external  onlyMint(){
      _mint(to, amount);
   }

   function setMint(address _address, bool _ismint) external onlyOwner(){
      mints[_address] = _ismint;
   }

   function transfer(address to, uint256 amount) public override returns (bool) {
      require(to != address(0),"to can not be zero address");
      require(balanceOf(msg.sender) >= amount,"not enough balance");
      _transfer(msg.sender, to, amount);
      
      return true;
   }

   //获取转账次数

   function getTransferCount(address _address) external view returns(uint256){
      return addressTransferCount[_address];
   }

   //总转账次数
   function getTotalTransferCount() external view returns(uint256){
      return totalTransferCount;

   }

   function _update(address from,address to,uint256 amount) internal override{

      super._update(from, to, amount);
      if(from != address(0) && to != address(0)){
         totalTransferCount++;
         addressTransferCount[from]++;
         addressTransferCount[to]++;
      }
      emit transferLogs(from, to, amount, block.timestamp);
   }

   






   


}
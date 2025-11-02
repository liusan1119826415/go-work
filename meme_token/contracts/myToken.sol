//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract myToken is ERC20, Ownable {
   

  mapping(address=>bool) public isMinter;


  uint256 public totalTransfer;

  //买入税率
  uint256 public buyTax = 10;
  //卖出税率
  uint256 public sellTax = 20;

  address private uinswapPair;

  address private transAddress;

  //单笔交易限制
  uint256 public maxTax = 5;

 


  mapping(address=>uint256) public addressTotal;



  event transFrom(address indexed from, address indexed to, uint256 value,uint256 timestamp);

  constructor() ERC20("MyToken","MTK") Ownable(msg.sender){
       isMinter[msg.sender] = true;
      _mint(msg.sender,1000000*10**decimals());
  }

  modifier onlyMinter(){
       require(isMinter[msg.sender],"not minter");
       _;
  }

  function mint(address to, uint256 amount) external onlyMinter{
     _mint(to, amount);
  }

  function setMinter(address _minter) external onlyMinter{
       isMinter[_minter] = true;
  }


  function _update(address from, address to, uint256 value) internal override {

 
   if(from == owner() || to == owner()){
      //Owner豁免
      super._update(from, to, value);
   }else{
        //单笔交易最大总供应量的5%
       require(value<=totalSupply()*maxTax/100,"single transaction exceeds the maximum limit");
  
   }
  }
//     uint256 tax_fee;
//     //判断交易类型
//       if(from == uinswapPair){
//          tax_fee = value * buyTax/100;
//       }else if(to == uinswapPair){
//          tax_fee = value * sellTax/100;

//       }else{
//          //转账不收税费
//          tax_fee = 0;
         
//       }

//       if(tax_fee > 0){
//          super._update(from, to, tax_fee);
//       }
      
//       super._update(from,to,value-tax_fee);
//   }

//   function _update(address from, address to, uint256 value) internal override {

//       if(from == address(0) || to == address(0)){
//           super._update(from, to, value);
//           return;
//       }
//        // 
//           if(msg.sender == owner()){
//                super._update(from, to,value);
//                return;
//           }

//           totalTransfer ++;
//           addressTotal[from] ++;
//           addressTotal[to] ++;
//           //收取10%的税费
//           uint256 tax_fee = value * 10/100;
//           //转税费
//           super._update(from, transAddress, tax_fee);
//          //转剩余的90%
//           super._update(from, to, value-tax_fee);
          
      
         
          

        
//         emit transFrom(from, to , value,block.timestamp);
//   }


  function getTotalTransfer() external view returns(uint256){
     return totalTransfer;
  }

  function getAddressTotal(address _address) external view returns(uint256){
     return addressTotal[_address];
  }

  //销毁代币
  function burn(address _address, uint256 _value) external onlyOwner{
     _burn(_address, _value);
  }

  //设置uinswap对账地址
  function setUinswapPair(address _uinswapPair) external onlyOwner(){
     require(_uinswapPair != address(0), "Invalid address");
    uinswapPair = _uinswapPair;
  }

  //设置交易税
  function setMaxTax(uint256 _buyTax, uint256 _sellTax) external onlyOwner(){
   require(_buyTax <= 25,"buyTax too high");
   require(_sellTax <= 25,"sellTax too high");
   buyTax = _buyTax;
   sellTax = _sellTax;
  }









}
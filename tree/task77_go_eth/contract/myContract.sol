//SPDX-Licence-Identifier: MIT


pragma solidity ^0.8;

contract myContract {

    //状态变量

    uint256 public count;

    address public owner;


    constructor(){
        owner = msg.sender;
    }

    //事件定义

    event CountChanged(uint256 newCount, address indexed sender);
    
    //权限模式
    modifier onlyOwner(){
        require(msg.sender == owner,"not owner");
        _;
    }


    function someAction() public onlyOwner() {
        count++;
        emit CountChanged(count, msg.sender);
    }


    

    //错误定义

    //修饰器

    //构造函数

    //函数

}
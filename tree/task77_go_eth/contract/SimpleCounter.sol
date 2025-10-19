//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/**
* @title 简单的计数合约
* @dev 这是一个简单的计数合约，包含增加，减少和重置
 */

contract SimpleCounter  {
    
    //状态变量
    uint256 private count;

    address public owner;


    //事件定义
    event CountIncremented(uint256 newCount,address indexed by, uint256 timestamp);

    event CountDecremented(uint256 newCount, address indexed by, uint256 timestamp);
   

    //构造函数
    constructor(uint256 _initialCount) {
        count = _initialCount;
        owner = msg.sender;
    }



    //增加
    function increment(uint256 _value) public {
        count += _value;
        emit CountIncremented(count, msg.sender, block.timestamp);
    }

    //减少
    function decrement(uint256 _value) public {
        require(count >= _value, "count cannot be less than zero");
        count -= _value;
        emit CountDecremented(count, msg.sender, block.timestamp);
    }






}
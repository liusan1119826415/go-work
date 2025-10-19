// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleStorage
 * @dev 简单的存储合约，演示基本的读写操作
 */
contract SimpleStorage {
    // 状态变量
    uint256 private storedData;
    address public owner;
    
    // 事件
    event DataStored(address indexed setter, uint256 oldValue, uint256 newValue);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // 修饰器
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // 构造函数
    constructor(uint256 initialValue) {
        storedData = initialValue;
        owner = msg.sender;
        emit DataStored(msg.sender, 0, initialValue);
    }
    
    /**
     * @dev 存储一个新值
     * @param x 要存储的值
     */
    function set(uint256 x) public {
        uint256 oldValue = storedData;
        storedData = x;
        emit DataStored(msg.sender, oldValue, x);
    }
    
    /**
     * @dev 获取存储的值
     * @return 当前存储的值
     */
    function get() public view returns (uint256) {
        return storedData;
    }
    
    /**
     * @dev 增加存储的值
     * @param x 要增加的数量
     */
    function increment(uint256 x) public {
        uint256 oldValue = storedData;
        storedData += x;
        emit DataStored(msg.sender, oldValue, storedData);
    }
    
    /**
     * @dev 转移合约所有权
     * @param newOwner 新所有者地址
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

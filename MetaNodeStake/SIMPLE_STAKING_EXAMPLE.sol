// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title 简单质押合约示例
 * @dev 用于演示质押合约的核心实现逻辑
 */
contract SimpleStaking is ReentrancyGuard {
    // 质押池信息
    struct PoolInfo {
        IERC20 token;           // 质押代币
        uint256 totalStaked;    // 总质押量
        uint256 lastRewardTime; // 上次奖励更新时间
        uint256 accRewardPerShare; // 每份额累积奖励
    }
    
    // 用户信息
    struct UserInfo {
        uint256 stakedAmount;   // 质押数量
        uint256 rewardDebt;     // 奖励债务
    }
    
    // 状态变量
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public rewardPerSecond = 1e15; // 每秒奖励数量
    address public owner;
    
    // 事件
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    
    // 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // 构造函数
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev 添加质押池
     * @param _token 质押代币地址
     */
    function addPool(IERC20 _token) public onlyOwner {
        poolInfo.push(PoolInfo({
            token: _token,
            totalStaked: 0,
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0
        }));
    }
    
    /**
     * @dev 更新池子奖励
     * @param _pid 池子ID
     */
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        
        // 如果没有质押量或时间未变化，直接返回
        if (block.timestamp <= pool.lastRewardTime || pool.totalStaked == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        
        // 计算奖励
        uint256 timeElapsed = block.timestamp - pool.lastRewardTime;
        uint256 reward = timeElapsed * rewardPerSecond;
        
        // 更新累积奖励
        pool.accRewardPerShare = pool.accRewardPerShare + (reward * 1e12) / pool.totalStaked;
        pool.lastRewardTime = block.timestamp;
    }
    
    /**
     * @dev 计算用户待领取奖励
     * @param _pid 池子ID
     * @param _user 用户地址
     */
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        
        uint256 accRewardPerShare = pool.accRewardPerShare;
        
        // 如果有新的奖励未更新，先计算
        if (block.timestamp > pool.lastRewardTime && pool.totalStaked > 0) {
            uint256 timeElapsed = block.timestamp - pool.lastRewardTime;
            uint256 reward = timeElapsed * rewardPerSecond;
            accRewardPerShare = accRewardPerShare + (reward * 1e12) / pool.totalStaked;
        }
        
        return (user.stakedAmount * accRewardPerShare) / 1e12 - user.rewardDebt;
    }
    
    /**
     * @dev 质押代币
     * @param _pid 池子ID
     * @param _amount 质押数量
     */
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        // 先更新池子奖励
        updatePool(_pid);
        
        // 如果用户已有质押，先领取奖励
        if (user.stakedAmount > 0) {
            uint256 pending = (user.stakedAmount * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
            if (pending > 0) {
                // 这里简化处理，实际应转账奖励代币
                // IERC20(rewardToken).transfer(msg.sender, pending);
            }
        }
        
        // 转入质押代币
        if (_amount > 0) {
            pool.token.transferFrom(msg.sender, address(this), _amount);
            user.stakedAmount = user.stakedAmount + _amount;
            pool.totalStaked = pool.totalStaked + _amount;
        }
        
        // 更新用户奖励债务
        user.rewardDebt = (user.stakedAmount * pool.accRewardPerShare) / 1e12;
        
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    /**
     * @dev 解质押代币
     * @param _pid 池子ID
     * @param _amount 解质押数量
     */
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.stakedAmount >= _amount, "Insufficient staked amount");
        
        // 先更新池子奖励
        updatePool(_pid);
        
        // 领取奖励
        uint256 pending = (user.stakedAmount * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
        if (pending > 0) {
            // 这里简化处理，实际应转账奖励代币
            // IERC20(rewardToken).transfer(msg.sender, pending);
        }
        
        // 解质押代币
        if (_amount > 0) {
            user.stakedAmount = user.stakedAmount - _amount;
            pool.totalStaked = pool.totalStaked - _amount;
            pool.token.transfer(msg.sender, _amount);
        }
        
        // 更新用户奖励债务
        user.rewardDebt = (user.stakedAmount * pool.accRewardPerShare) / 1e12;
        
        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    /**
     * @dev 领取奖励
     * @param _pid 池子ID
     */
    function claim(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        // 先更新池子奖励
        updatePool(_pid);
        
        // 计算奖励
        uint256 pending = (user.stakedAmount * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
        require(pending > 0, "No pending rewards");
        
        // 这里简化处理，实际应转账奖励代币
        // IERC20(rewardToken).transfer(msg.sender, pending);
        
        // 更新用户奖励债务
        user.rewardDebt = (user.stakedAmount * pool.accRewardPerShare) / 1e12;
        
        emit Claim(msg.sender, _pid, pending);
    }
    
    /**
     * @dev 紧急提取（不领取奖励）
     * @param _pid 池子ID
     */
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.stakedAmount > 0, "No staked amount");
        
        uint256 amount = user.stakedAmount;
        
        // 清除用户信息
        user.stakedAmount = 0;
        user.rewardDebt = 0;
        
        // 更新池子总质押量
        pool.totalStaked = pool.totalStaked - amount;
        
        // 转出质押代币
        pool.token.transfer(msg.sender, amount);
    }
}
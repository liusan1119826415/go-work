# 质押合约实现指南

## 前言

本指南专为已有Solidity语法基础但缺乏质押合约实现经验的开发者设计。通过本指南，您将学习如何从零开始实现一个完整的质押系统。

## 质押合约核心概念

### 1. 质押机制原理
质押（Staking）是DeFi应用中的核心机制之一，允许用户锁定其代币以获得奖励。主要涉及：
- 用户将代币存入合约
- 合约根据规则计算奖励
- 用户可提取奖励和本金

### 2. 核心组件
- **质押池（Pool）**：管理特定代币的质押
- **用户信息（UserInfo）**：记录用户质押状态
- **奖励计算**：基于时间、数量等因素计算奖励
- **权限控制**：确保只有授权用户可执行敏感操作

## 质押合约实现步骤

### 第一步：基础结构设计

#### 1. 导入必要库
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
```

#### 2. 定义数据结构
```solidity
// 质押池结构
struct Pool {
    address stTokenAddress;           // 质押代币地址
    uint256 poolWeight;               // 质押池权重
    uint256 lastRewardBlock;          // 最后一次计算奖励的区块号
    uint256 accMetaNodePerShare;      // 每份额累积的奖励数量
    uint256 totalStaked;              // 池中总质押代币量
    uint256 minDepositAmount;         // 最小质押金额
    uint256 unstakeLockedBlocks;      // 解除质押的锁定区块数
}

// 用户信息结构
struct UserInfo {
    uint256 stAmount;                 // 用户质押的代币数量
    uint256 rewardDebt;               // 奖励债务
}
```

### 第二步：状态变量定义

```solidity
// 合约角色定义
bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

// 奖励代币合约
IERC20 public metaNodeToken;

// 质押池映射
mapping(uint256 => Pool) public pools;
// 用户信息映射
mapping(uint256 => mapping(address => UserInfo)) public users;

// 质押池计数器
uint256 public poolCounter;
// 每区块奖励数量
uint256 public metaNodePerBlock = 1e18;
```

### 第三步：核心功能实现

#### 1. 质押功能实现
```solidity
function deposit(uint256 _pid, uint256 _amount) public payable nonReentrant {
    Pool storage pool = pools[_pid];
    UserInfo storage user = users[_pid][msg.sender];
    
    require(_amount >= pool.minDepositAmount, "Amount is less than minimum deposit requirement");
    
    updatePool(_pid);
    
    // 更新用户奖励信息
    uint256 pending = user.stAmount.mul(pools[_pid].accMetaNodePerShare).div(1e12).sub(user.rewardDebt);
    if (pending > 0) {
        metaNodeToken.transfer(msg.sender, pending);
    }
    
    // 处理native currency和ERC20代币的不同情况
    if (pool.stTokenAddress == address(0)) {
        // Native currency质押
        require(msg.value == _amount, "Incorrect ETH amount sent");
    } else {
        // ERC20代币质押
        require(msg.value == 0, "No ETH should be sent for ERC20 staking");
        IERC20(pool.stTokenAddress).transferFrom(msg.sender, address(this), _amount);
    }
    
    user.stAmount = user.stAmount.add(_amount);
    pool.totalStaked = pool.totalStaked.add(_amount);
    
    user.rewardDebt = user.stAmount.mul(pools[_pid].accMetaNodePerShare).div(1e12);
    
    emit Deposited(msg.sender, _pid, _amount);
}
```

#### 2. 奖励计算实现
```solidity
function updatePool(uint256 _pid) internal {
    Pool storage pool = pools[_pid];
    if (block.number <= pool.lastRewardBlock) {
        return;
    }
    
    if (pool.totalStaked == 0) {
        pool.lastRewardBlock = block.number;
        return;
    }
    
    uint256 reward = getPoolReward(_pid);
    if (reward > 0) {
        pool.accMetaNodePerShare = pool.accMetaNodePerShare.add(
            reward.mul(1e12).div(pool.totalStaked)
        );
    }
    
    pool.lastRewardBlock = block.number;
}

function getPoolReward(uint256 _pid) public view returns (uint256) {
    Pool storage pool = pools[_pid];
    uint256 blockCount = block.number.sub(pool.lastRewardBlock);
    if (blockCount == 0) {
        return 0;
    }
    
    return blockCount.mul(metaNodePerBlock).mul(pool.poolWeight).div(1000);
}

function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
    Pool storage pool = pools[_pid];
    UserInfo storage user = users[_pid][_user];
    
    uint256 accMetaNodePerShare = pool.accMetaNodePerShare;
    if (block.number > pool.lastRewardBlock && pool.totalStaked > 0) {
        uint256 reward = getPoolReward(_pid);
        if (reward > 0) {
            accMetaNodePerShare = accMetaNodePerShare.add(
                reward.mul(1e12).div(pool.totalStaked)
            );
        }
    }
    
    return user.stAmount.mul(accMetaNodePerShare).div(1e12).sub(user.rewardDebt);
}
```

#### 3. 解质押功能实现
```solidity
function requestUnstake(uint256 _pid, uint256 _amount) public nonReentrant {
    Pool storage pool = pools[_pid];
    UserInfo storage user = users[_pid][msg.sender];
    
    require(_amount > 0, "Amount must be greater than 0");
    require(user.stAmount >= _amount, "Insufficient staked amount");
    
    updatePool(_pid);
    
    // 更新用户奖励信息
    uint256 pending = user.stAmount.mul(pools[_pid].accMetaNodePerShare).div(1e12).sub(user.rewardDebt);
    if (pending > 0) {
        metaNodeToken.transfer(msg.sender, pending);
    }
    
    user.stAmount = user.stAmount.sub(_amount);
    pool.totalStaked = pool.totalStaked.sub(_amount);
    
    user.rewardDebt = user.stAmount.mul(pools[_pid].accMetaNodePerShare).div(1e12);
    
    emit Unstaked(msg.sender, _pid, _amount);
}
```

### 第四步：管理功能实现

#### 1. 添加质押池
```solidity
function addPool(
    address _stTokenAddress,
    uint256 _poolWeight,
    uint256 _minDepositAmount,
    uint256 _unstakeLockedBlocks
) public onlyRole(OPERATOR_ROLE) {
    pools[poolCounter] = Pool({
        stTokenAddress: _stTokenAddress,
        poolWeight: _poolWeight,
        lastRewardBlock: block.number,
        accMetaNodePerShare: 0,
        totalStaked: 0,
        minDepositAmount: _minDepositAmount,
        unstakeLockedBlocks: _unstakeLockedBlocks
    });
    
    emit PoolAdded(poolCounter, _stTokenAddress, _poolWeight, _minDepositAmount, _unstakeLockedBlocks);
    poolCounter++;
}
```

#### 2. 更新质押池配置
```solidity
function updatePoolConfig(
    uint256 _pid,
    uint256 _poolWeight,
    uint256 _minDepositAmount,
    uint256 _unstakeLockedBlocks
) public onlyRole(OPERATOR_ROLE) {
    updatePool(_pid);
    
    Pool storage pool = pools[_pid];
    pool.poolWeight = _poolWeight;
    pool.minDepositAmount = _minDepositAmount;
    pool.unstakeLockedBlocks = _unstakeLockedBlocks;
    
    emit PoolUpdated(_pid, _poolWeight, _minDepositAmount, _unstakeLockedBlocks);
}
```

## 关键技术要点

### 1. 安全防护措施
- 使用 `ReentrancyGuard` 防止重入攻击
- 使用 `AccessControlEnumerable` 实现权限控制
- 严格的输入验证和边界检查
- 使用 SafeMath 防止整数溢出

### 2. 奖励计算优化
- 使用累积奖励机制避免频繁计算
- 精度处理确保计算准确性
- 批量更新提高效率

### 3. 用户体验优化
- 支持 Native Currency 和 ERC20 代币
- 灵活的质押池配置
- 实时奖励计算和显示

## 实践建议

### 1. 循序渐进开发
1. 先实现基础的质押和解质押功能
2. 再添加奖励计算机制
3. 最后完善管理功能和安全措施

### 2. 充分测试
- 编写单元测试覆盖各种场景
- 测试边界条件和异常情况
- 进行安全审计和漏洞检查

### 3. 持续优化
- 根据测试结果优化Gas消耗
- 改进用户体验和界面交互
- 完善文档和注释

## 常见问题解答

### Q1: 如何处理不同代币的质押？
A: 通过判断 `stTokenAddress` 是否为 `address(0)` 来区分 Native Currency 和 ERC20 代币，分别处理质押逻辑。

### Q2: 奖励计算如何保证准确性？
A: 使用累积奖励机制，通过 `accMetaNodePerShare` 记录每份额累积奖励，结合用户份额和奖励债务计算准确奖励。

### Q3: 如何防止重入攻击？
A: 继承 `ReentrancyGuard` 合约，并在关键函数上添加 `nonReentrant` 修饰符。

### Q4: 如何管理多个质押池？
A: 使用 `poolCounter` 作为索引，通过 `pools` 映射存储各个质押池信息，支持动态添加和配置。

## 总结

通过本指南，您已经学习了质押合约的核心实现方法。建议您：
1. 仔细研究示例代码，理解每个函数的作用
2. 动手实现一个简单的质押合约
3. 逐步添加更多功能和安全措施
4. 进行充分测试确保功能正确性

质押合约是DeFi应用的基础组件，掌握其实现方法将为您开发更复杂的区块链应用奠定坚实基础。
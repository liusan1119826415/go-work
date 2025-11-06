// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MetaNodeStake
 * @dev 基于区块链的质押系统，支持多种代币的质押和奖励分配
 */
contract MetaNodeStake is AccessControlEnumerable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // 质押池结构
    struct Pool {
        address stTokenAddress;           // 质押代币地址 (address(0) 表示 native currency)
        uint256 poolWeight;               // 质押池权重
        uint256 lastRewardBlock;          // 最后一次计算奖励的区块号
        uint256 accMetaNodePerShare;      // 每份额累积的 MetaNode 数量 (使用12位精度)
        uint256 totalStaked;              // 池中总质押代币量
        uint256 minDepositAmount;         // 最小质押金额
        uint256 unstakeLockedBlocks;      // 解除质押的锁定区块数
    }

    // 用户信息结构
    struct UserInfo {
        uint256 stAmount;                 // 用户质押的代币数量
        uint256 rewardDebt;               // 奖励债务
    }

    // 解质押请求
    struct UnstakeRequest {
        uint256 amount;                   // 解质押数量
        uint256 unlockBlock;              // 解锁区块号
    }

    // MetaNode 代币地址
    IERC20 public metaNodeToken;

    // 质押池映射
    mapping(uint256 => Pool) public pools;
    // 用户信息映射 (pid => user => UserInfo)
    mapping(uint256 => mapping(address => UserInfo)) public users;
    // 用户解质押请求 (pid => user => UnstakeRequest[])
    mapping(uint256 => mapping(address => UnstakeRequest[])) public unstakeRequests;
    
    // 质押池计数器
    uint256 public poolCounter;
    
    // 每区块奖励数量
    uint256 public metaNodePerBlock = 1e18; // 默认每区块1个MetaNode

    // 事件定义
    event PoolAdded(uint256 indexed pid, address stTokenAddress, uint256 poolWeight, uint256 minDepositAmount, uint256 unstakeLockedBlocks);
    event PoolUpdated(uint256 indexed pid, uint256 poolWeight, uint256 minDepositAmount, uint256 unstakeLockedBlocks);
    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Unstaked(address indexed user, uint256 indexed pid, uint256 amount);
    event Claimed(address indexed user, uint256 indexed pid, uint256 amount);
    event UnstakeRequested(address indexed user, uint256 indexed pid, uint256 amount, uint256 unlockBlock);
    event UnstakeWithdrawn(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event MetaNodePerBlockUpdated(uint256 newAmount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @dev 构造函数
     * @param _metaNodeToken MetaNode代币地址
     */
    constructor(address _metaNodeToken) {
        metaNodeToken = IERC20(_metaNodeToken);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        poolCounter = 0;
    }

    /**
     * @dev Modifier 检查是否为有效的质押池
     */
    modifier validPool(uint256 _pid) {
        require(_pid < poolCounter, "Invalid pool ID");
        _;
    }

    /**
     * @dev 获取当前区块号
     */
    function getCurrentBlock() public view returns (uint256) {
        return block.number;
    }

    /**
     * @dev 更新所有池子的累积奖励
     */
    function massUpdatePools() public {
        for (uint256 i = 0; i < poolCounter; i++) {
            updatePool(i);
        }
    }

    /**
     * @dev 更新池子的累积奖励
     * @param _pid 质押池ID
     */
    function updatePool(uint256 _pid) public validPool(_pid) {
        Pool storage pool = pools[_pid];
        if (getCurrentBlock() <= pool.lastRewardBlock) {
            return;
        }
        
        if (pool.totalStaked == 0) {
            pool.lastRewardBlock = getCurrentBlock();
            return;
        }
        
        uint256 reward = getPoolReward(_pid);
        if (reward > 0) {
            // 这里应该铸造或转移奖励代币到合约，简化处理
            pool.accMetaNodePerShare = pool.accMetaNodePerShare.add(
                reward.mul(1e12).div(pool.totalStaked)
            );
        }
        
        pool.lastRewardBlock = getCurrentBlock();
    }

    /**
     * @dev 计算池子的奖励
     * @param _pid 质押池ID
     */
    function getPoolReward(uint256 _pid) public view validPool(_pid) returns (uint256) {
        Pool storage pool = pools[_pid];
        uint256 blockCount = getCurrentBlock().sub(pool.lastRewardBlock);
        if (blockCount == 0) {
            return 0;
        }
        
        return blockCount.mul(metaNodePerBlock).mul(pool.poolWeight).div(1000);
    }

    /**
     * @dev 计算用户的待领取奖励
     * @param _pid 质押池ID
     * @param _user 用户地址
     */
    function pendingReward(uint256 _pid, address _user) external view validPool(_pid) returns (uint256) {
        Pool storage pool = pools[_pid];
        UserInfo storage user = users[_pid][_user];
        
        uint256 accMetaNodePerShare = pool.accMetaNodePerShare;
        if (getCurrentBlock() > pool.lastRewardBlock && pool.totalStaked > 0) {
            uint256 reward = getPoolReward(_pid);
            if (reward > 0) {
                accMetaNodePerShare = accMetaNodePerShare.add(
                    reward.mul(1e12).div(pool.totalStaked)
                );
            }
        }
        
        return user.stAmount.mul(accMetaNodePerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev 添加新的质押池
     * @param _stTokenAddress 质押代币地址 (address(0) 表示 native currency)
     * @param _poolWeight 池权重
     * @param _minDepositAmount 最小质押金额
     * @param _unstakeLockedBlocks 解除质押锁定区块数
     */
    function addPool(
        address _stTokenAddress,
        uint256 _poolWeight,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks
    ) public onlyRole(OPERATOR_ROLE) {
        pools[poolCounter] = Pool({
            stTokenAddress: _stTokenAddress,
            poolWeight: _poolWeight,
            lastRewardBlock: getCurrentBlock(),
            accMetaNodePerShare: 0,
            totalStaked: 0,
            minDepositAmount: _minDepositAmount,
            unstakeLockedBlocks: _unstakeLockedBlocks
        });
        
        emit PoolAdded(poolCounter, _stTokenAddress, _poolWeight, _minDepositAmount, _unstakeLockedBlocks);
        poolCounter++;
    }

    /**
     * @dev 更新质押池配置
     * @param _pid 质押池ID
     * @param _poolWeight 新的池权重
     * @param _minDepositAmount 新的最小质押金额
     * @param _unstakeLockedBlocks 新的解除质押锁定区块数
     */
    function updatePoolConfig(
        uint256 _pid,
        uint256 _poolWeight,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks
    ) public onlyRole(OPERATOR_ROLE) validPool(_pid) {
        updatePool(_pid);
        
        Pool storage pool = pools[_pid];
        pool.poolWeight = _poolWeight;
        pool.minDepositAmount = _minDepositAmount;
        pool.unstakeLockedBlocks = _unstakeLockedBlocks;
        
        emit PoolUpdated(_pid, _poolWeight, _minDepositAmount, _unstakeLockedBlocks);
    }

    /**
     * @dev 设置每区块奖励数量
     * @param _metaNodePerBlock 每区块奖励数量
     */
    function setMetaNodePerBlock(uint256 _metaNodePerBlock) public onlyRole(OPERATOR_ROLE) {
        metaNodePerBlock = _metaNodePerBlock;
        emit MetaNodePerBlockUpdated(_metaNodePerBlock);
    }

    /**
     * @dev 质押代币
     * @param _pid 质押池ID
     * @param _amount 质押数量
     */
    function deposit(uint256 _pid, uint256 _amount) public payable validPool(_pid) whenNotPaused nonReentrant {
        Pool storage pool = pools[_pid];
        UserInfo storage user = users[_pid][msg.sender];
        
        require(_amount >= pool.minDepositAmount, "Amount is less than minimum deposit requirement");
        
        updatePool(_pid);
        
        // 更新用户奖励信息
        uint256 pending = user.stAmount.mul(pools[_pid].accMetaNodePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            metaNodeToken.transfer(msg.sender, pending);
            emit RewardPaid(msg.sender, _pid, pending);
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

    /**
     * @dev 请求解除质押
     * @param _pid 质押池ID
     * @param _amount 解除质押数量
     */
    function requestUnstake(uint256 _pid, uint256 _amount) public validPool(_pid) whenNotPaused nonReentrant {
        Pool storage pool = pools[_pid];
        UserInfo storage user = users[_pid][msg.sender];
        
        require(_amount > 0, "Amount must be greater than 0");
        require(user.stAmount >= _amount, "Insufficient staked amount");
        
        updatePool(_pid);
        
        // 更新用户奖励信息
        uint256 pending = user.stAmount.mul(pools[_pid].accMetaNodePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            metaNodeToken.transfer(msg.sender, pending);
            emit RewardPaid(msg.sender, _pid, pending);
        }
        
        user.stAmount = user.stAmount.sub(_amount);
        pool.totalStaked = pool.totalStaked.sub(_amount);
        
        user.rewardDebt = user.stAmount.mul(pools[_pid].accMetaNodePerShare).div(1e12);
        
        // 创建解质押请求
        uint256 unlockBlock = getCurrentBlock().add(pool.unstakeLockedBlocks);
        unstakeRequests[_pid][msg.sender].push(UnstakeRequest({
            amount: _amount,
            unlockBlock: unlockBlock
        }));
        
        emit UnstakeRequested(msg.sender, _pid, _amount, unlockBlock);
    }

    /**
     * @dev 提取已解锁的质押代币
     * @param _pid 质押池ID
     */
    function withdrawUnstaked(uint256 _pid) public validPool(_pid) whenNotPaused nonReentrant {
        UnstakeRequest[] storage requests = unstakeRequests[_pid][msg.sender];
        require(requests.length > 0, "No unstake requests");
        
        updatePool(_pid);
        
        uint256 totalAmount = 0;
        uint256 i = 0;
        
        // 处理所有已解锁的请求
        while (i < requests.length) {
            if (getCurrentBlock() >= requests[i].unlockBlock) {
                totalAmount = totalAmount.add(requests[i].amount);
                // 从数组中移除已处理的请求
                for (uint256 j = i; j < requests.length - 1; j++) {
                    requests[j] = requests[j + 1];
                }
                requests.pop();
            } else {
                i++;
            }
        }
        
        require(totalAmount > 0, "No unlocked amounts to withdraw");
        
        Pool storage pool = pools[_pid];
        if (pool.stTokenAddress == address(0)) {
            // Native currency提取
            payable(msg.sender).transfer(totalAmount);
        } else {
            // ERC20代币提取
            IERC20(pool.stTokenAddress).transfer(msg.sender, totalAmount);
        }
        
        emit UnstakeWithdrawn(msg.sender, _pid, totalAmount);
    }

    /**
     * @dev 紧急提取（不领取奖励）
     * @param _pid 质押池ID
     */
    function emergencyWithdraw(uint256 _pid) public validPool(_pid) whenNotPaused nonReentrant {
        Pool storage pool = pools[_pid];
        UserInfo storage user = users[_pid][msg.sender];
        
        require(user.stAmount > 0, "No staked amount");
        
        uint256 amount = user.stAmount;
        
        // 清除用户信息
        user.stAmount = 0;
        user.rewardDebt = 0;
        
        pool.totalStaked = pool.totalStaked.sub(amount);
        
        // 提取质押代币
        if (pool.stTokenAddress == address(0)) {
            // Native currency提取
            payable(msg.sender).transfer(amount);
        } else {
            // ERC20代币提取
            IERC20(pool.stTokenAddress).transfer(msg.sender, amount);
        }
        
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @dev 领取奖励
     * @param _pid 质押池ID
     */
    function claimReward(uint256 _pid) public validPool(_pid) whenNotPaused nonReentrant {
        UserInfo storage user = users[_pid][msg.sender];
        require(user.stAmount > 0, "No staked amount");
        
        updatePool(_pid);
        
        uint256 pending = user.stAmount.mul(pools[_pid].accMetaNodePerShare).div(1e12).sub(user.rewardDebt);
        require(pending > 0, "No pending rewards");
        
        metaNodeToken.transfer(msg.sender, pending);
        user.rewardDebt = user.stAmount.mul(pools[_pid].accMetaNodePerShare).div(1e12);
        
        emit Claimed(msg.sender, _pid, pending);
        emit RewardPaid(msg.sender, _pid, pending);
    }

    /**
     * @dev 获取用户未提取的解质押请求
     * @param _pid 质押池ID
     * @param _user 用户地址
     */
    function getUnstakeRequests(uint256 _pid, address _user) public view validPool(_pid) returns (UnstakeRequest[] memory) {
        return unstakeRequests[_pid][_user];
    }

    /**
     * @dev 获取可提取的解质押数量
     * @param _pid 质押池ID
     */
    function getWithdrawableAmount(uint256 _pid) public view validPool(_pid) returns (uint256) {
        UnstakeRequest[] storage requests = unstakeRequests[_pid][msg.sender];
        uint256 totalAmount = 0;
        
        for (uint256 i = 0; i < requests.length; i++) {
            if (getCurrentBlock() >= requests[i].unlockBlock) {
                totalAmount = totalAmount.add(requests[i].amount);
            }
        }
        
        return totalAmount;
    }

    // 接收ETH函数
    receive() external payable {}
}
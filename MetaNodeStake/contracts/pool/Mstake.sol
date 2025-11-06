//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Mstake is AccessControlEnumerable, ReentrancyGuard, Pausable{
      using SafeMath for uint256;
      //质押pool 结构
      struct Pool {
        address stTokenAddress; //质押代币地址
        uint256 poolWeight; //质押池权重
        uint256 lastRewardBlock; //最后一次计算奖励的区块号
        uint256 accRewardPerShare; //每代币累计奖励数
        uint256 totalStaked; //总质押数
        uint256 minDepositAmount; //最小质押金额
        uint256 unstakeLockedBlock; //质押解锁区块号
      }

      //用户结构
      struct userInfo {
        uint256 stAmount; //用户质押的代币金额
        uint256 rewardDebt; //奖励债务

      }

      bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
      bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
      bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
      //奖励代币合约

      IERC20 public metaNodeToken;

      //质押池映射地址
      mapping(uint256=>Pool) public pools;

      //用户质押地址
      mapping(uint256=>mapping(address=>userInfo)) public users;
      // 用户解质押请求 (pid => user => UnstakeRequest[])
      mapping(uint256=>mapping(address=>UnstakeRequest[])) public unstakeRequests;
     //质押池计算器
      uint256 public poolCounter;
      //每区块奖励数量
      uint256 public metaNodePerBlock = 1e18;


      // 解质押请求
      struct UnstakeRequest {
          uint256 amount;                   // 解质押数量
          uint256 unlockBlock;              // 解锁区块号
          bool withdrawn;                  // 是否已提现  
      }

      //事件定义
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

      //构造函数
      constructor(address _metaNodeToken){
         metaNodeToken = IERC20(_metaNodeToken);
         _setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
         _setupRole(UPGRADER_ROLE,msg.sender);
         _setupRole(PAUSER_ROLE, msg.sender);
         _setupRole(OPERATOR_ROLE, msg.sender);
         poolCounter = 0;

      }


      modifier validPool(uint256 _pid){
        require(_pid < poolCounter,"Invalid pool ID");
        _;
      }

      //获取当前区块号
      function getCurrentBlock() public view returns(uint256){
        return block.number;
      }

      //更新所有池子的累计金额
      function massUpdatePools() public {
        for (uint256 i=0; i<poolCounter; i++){
           updatePool(i);
        }
      }

      function updatePool(uint256 _pid) public validPool(_pid){
         Pool storage pool = pools[_pid];
         if(getCurrentBlock() <= pool.lastRewardBlock) return;

         if(pool.totalStaked == 0){
             pool.lastRewardBlock = getCurrentBlock();
             return;
         }
         //获取池子奖励
         uint256 reward = getPoolReward(_pid);
         if(reward >0){
           pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(pool.totalStaked));
         }

         pool.lastRewardBlock = getCurrentBlock();
      }


      function getPoolReward(uint256 _pid) public view validPool(_pid) returns (uint256) {
        Pool storage pool = pools[_pid];
        uint256 blockCount = getCurrentBlock().sub(pool.lastRewardBlock);
        if(blockCount == 0){
          return 0;
        }

        return blockCount.mul(metaNodePerBlock).mul(pool.poolWeight).div(1000);
      }

      //质押代币

      function deposit(uint256 _pid, uint256 _amount) public payable validPool(_pid) whenNotPaused nonReentrant{
        Pool storage pool = pools[_pid];
        userInfo storage user = users[_pid][msg.sender];

        require(_amount > pool.minDepositAmount,"Amount must be greater than min deposit amount");
        updatePool(_pid);

        //更新用户奖励信息
        uint256 pending = user.stAmount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0){
          //支付奖励
           metaNodeToken.transfer(msg.sender, pending);
          //触发支付奖励事件
           emit RewardPaid(msg.sender, _pid, pending);
        }

        //处理native currency和ERC20代币的不同情况
        if(pool.stTokenAddress == address(0)){

          require(msg.value == _amount,"Incorrect ETH amount sent");
        }else{
          //ERC20质押
          require(msg.value == 0,"No ETH should be sent for ERC20 staking");
          IERC20(pool.stTokenAddress).transferFrom(msg.sender,address(this),_amount);


        }


        user.stAmount = user.stAmount.add(_amount);
        pool.totalStaked = pool.totalStaked.add(_amount);

        user.rewardDebt = user.stAmount.mul(pool.accRewardPerShare).div(1e12);

        emit Deposited(msg.sender, _pid, _amount);


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
        uint256 _unstakeLockedBlocks) public onlyRole(OPERATOR_ROLE) {
    
        pools[poolCounter] = Pool({
            stTokenAddress:_stTokenAddress,
            poolWeight : _poolWeight,
            lastRewardBlock: getCurrentBlock(),
            accRewardPerShare:0,
            totalStaked:0,
            minDepositAmount:_minDepositAmount,
            unstakeLockedBlocks:_unstakeLockedBlocks
        });
        emit PoolAdded(poolCounter,_stTokenAddress,_poolWeight,_minDepositAmount,_unstakeLockedBlocks);
        
        poolCounter++;
    
    }

    /** 
    * @dev 更新质押池配置
    * @param _pid
    * @param _poolWeight 
    * @param _minDepositAmount 新的最小质押金额
    * @param _unstakeLockedBlocks 新的解除质押锁定区块数
    *
    **/
    function updatePoolConfig(uint256 _pid, uint256 _poolWeight, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks) public OnlyRole(OPERATOR_ROLE) validPool(_pid){
         
         updatePool(_pid);

         Pool storage pool = pools[_pid];
         pool.poolWeight = _poolWeight;
         pool.minDepositAmount = _minDepositAmount;
         pool.unstakeLockedBlocks = _unstakeLockedBlocks;
         emit PoolUpdated(_pid, _poolWeight,_minDepositAmount,_unstakeLockedBlocks);

    }

    /**
     *@dev 设置每区块奖励区块数量
     *@param _metaNodePerBlock
     *
     */

     function setMetaNodePerBlock(uint256 _metaNodePerBlock) external OnlyRole(OPERATOR_ROLE){
        metaNodePerBlock = _metaNodePerBlock;
        emit MetaNodePerBlockUpdated(_metaNodePerBlock);
     }

     /**
      *@dev 解除质押
      *@param _pid
      *@param _amount
      * 
      */
      function requestUnstake(uint256 _pid, uint256 _amount) external validPool(_pid) whenNotPaused nonReentrant{
            Pool storage pool = pools[_pid];
            userInfo storage user = users[_pid][msg.sender];
            require(_amount>0,"Amount must be greater than 0");
            require(user.stAmount>= _amount,"Insufficient staked amount");

            updatePool(_pid);

            //更新用户奖励
            uint256 pending = user.stAmount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending>0){
              metaNodeToken.transfer(msg.sender,pending);
              emit RewardPaid(msg.sender, _pid, pending);
            }

            user.stAmount = user.stAmount.sub(_amount);

            pool.totalStaked = pool.totalStaked.sub(_amount);

            user.rewardDebt = user.stAmount.mul(pool.accRewardPerShare).div(1e12);
            //创建解质押请求
            uint256 unlockBlock = getCurrentBlock().add(pool.unstakeLockedBlock);

            unstakeRequests[_pid][msg.sender].push(UnstakeRequest({
               amount:_amount,
               unlockBlock:unlockBlock,
               withdrawn:false
            }));

            emit UnstakeRequested(msg.sender,_pid,_amount,unlockBlock);



      }
      /**
       * 提取已解锁的质押代币
        */

      function withdrawUnstaked(uint256 _pid) public validPool(_pid)whenNotPaused nonReentrant{

            UnstakeRequest[] storage requests = unstakeRequests[_pid][msg.sender];
            require(requests.length >0 ,"No unstake requests"); 

            updatePool(_pid);

            uint256 totalAmount = 0;
            uint256 i =0;
            while(i < requests.length){
               if(!requests[i].withdrawn && getCurrentBlock() >= requests[i].unlockBlock){
                   totalAmount = totalAmount.add(requests[i].amount);
                   
                  //  for(uint256 j=i;j< requests.length -1; j++){
                  //      requests[j] = requests[j + 1];
                  //  }
                  //  requests.pop();
                  requests[i].withdrawn = true;
               }else{
                i++;
               }
            }

            require(totalAmount > 0,"No unlocked amounts to withdraw");

            Pool pool = pools[_pid];
            if(pool.stTokenAddress == address(0)){
              payable(msg.sender).transfer(totalAmount);
            }else{
              IERC20(pool.stTokenAddress).transfer(msg.sender,totalAmount);
            }

            emit UnstakeWithdrawn(msg.sender, _pid, totalAmount);

      } 


      /** 
       *@dev 紧急提取
       *
       */
       function emergencyWithdraw(uint256 _pid) public validPool(_pid) whenNotPaused nonReentrant{
                Pool storage pool = pools[_pid];
                userInfo storage user = users[_pid][msg.sender];
                require(user.stAmount>0,"No staked amount");
                uint256 amount = user.stAmount;
                //清除用户信息
                user.stAmount = 0;
                user.rewardDebt = 0;
                pool.totalStaked = pool.totalStaked.sub(amount);
                //提取代币
                if(pool.stTokenAddress == address(0)){
                  payable(msg.sender).transfer(amount);
                }else{
                  IERC20(pool.stTokenAddress).transfer(msg.sender,amount);
                }

                emit EmergencyWithdraw(msg.sender, _pid, amount);
   
       }

       /**
        * @dev 领取奖励
        * @param _pid 质押池ID
        */
      function claimRewards(uint256 _pid) external validPool(_pid) whenNotPaused nonReentrant{
        
            userInfo storage user = users[_pid][msg.sender];

            require(user.stAmount>0,"No staked amount");

            updatePool(_pid);

            uint256 pending = user.stAmount.mul(pool.accMetaNodePerShare).div(1e12).sub(user.rewardDebt);

            require(pending > 0,"No pending rewards");

            metaNodeToken.transfer(msg.sender,pending);

            user.rewardDebt = user.stAmount.mul(pool.accMetaNodePerShare).div(1e12);

            emit Claimed(msg.sender, _pid, pending);
            emit RewardPaid(msg.sender, _pid, pending);
      }

      /**
        * @dev 获取用户未提取的解质押请求
        * @param _pid 质押池ID
        * @param _user 用户地址
        */

        function getUnstakeRequests(uint256 _pid, address _user) external view returns (UnstakeRequest[] memory){
                return unstakeRequests[_pid][_user];
        }

        /**
          * @dev 获取可提取的解质押数量
          * @param _pid 质押池ID
          */

        function  getWithdrawableAmount(uint256 _pid) external view returns (uint256){
                
                UnstakeRequest[] storage requests = unstakeRequests[_pid][msg.sender];
                uint256 totalAmount =0;

                for(uint256 i=0; i<requests.length;i++){
                  if(getCurrentBlock()>= requests[i].unlockBlock){
                     totalAmount = totalAmount.add(requests[i].amount);
                  }
                }

                return totalAmount;
        }

      receive() external payable{}




}

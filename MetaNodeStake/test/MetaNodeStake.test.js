const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MetaNodeStake", function () {
  let metaNodeToken, metaNodeStake;
  let owner, addr1, addr2, addr3;
  let poolIdETH = 0;
  let poolIdERC20 = 1;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    // 部署MetaNodeToken
    const MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
    const initialSupply = ethers.utils.parseEther("1000000"); // 1,000,000 tokens
    metaNodeToken = await MetaNodeToken.deploy(initialSupply);
    await metaNodeToken.deployed();

    // 转移一些代币给测试账户
    await metaNodeToken.transfer(addr1.address, ethers.utils.parseEther("1000"));
    await metaNodeToken.transfer(addr2.address, ethers.utils.parseEther("1000"));

    // 部署MetaNodeStake
    const MetaNodeStake = await ethers.getContractFactory("MetaNodeStake");
    metaNodeStake = await MetaNodeStake.deploy(metaNodeToken.address);
    await metaNodeStake.deployed();

    // 添加质押池
    await metaNodeStake.addPool(
      ethers.constants.AddressZero, // Native currency
      100, // pool weight
      ethers.utils.parseEther("0.1"), // min deposit 0.1 ETH
      10 // 10 blocks lock period
    );

    await metaNodeStake.addPool(
      metaNodeToken.address, // MetaNodeToken
      200, // pool weight
      ethers.utils.parseEther("10"), // min deposit 10 tokens
      20 // 20 blocks lock period
    );

    // 向质押合约转移一些奖励代币
    await metaNodeToken.transfer(metaNodeStake.address, ethers.utils.parseEther("50000"));
  });

  describe("Deployment", function () {
    it("Should set the right metaNodeToken", async function () {
      expect(await metaNodeStake.metaNodeToken()).to.equal(metaNodeToken.address);
    });

    it("Should set the right owner", async function () {
      expect(await metaNodeStake.hasRole(await metaNodeStake.DEFAULT_ADMIN_ROLE(), owner.address)).to.be.true;
    });

    it("Should have 2 pools", async function () {
      expect(await metaNodeStake.poolCounter()).to.equal(2);
    });
  });

  describe("Pool Management", function () {
    it("Should add a new pool", async function () {
      await metaNodeStake.addPool(
        addr3.address, // Some token address
        150, // pool weight
        ethers.utils.parseEther("5"), // min deposit 5 tokens
        15 // 15 blocks lock period
      );
      
      expect(await metaNodeStake.poolCounter()).to.equal(3);
    });

    it("Should update pool config", async function () {
      await metaNodeStake.updatePoolConfig(
        poolIdETH,
        150, // new pool weight
        ethers.utils.parseEther("0.2"), // new min deposit
        15 // new lock period
      );
      
      const pool = await metaNodeStake.pools(poolIdETH);
      expect(pool.poolWeight).to.equal(150);
      expect(pool.minDepositAmount).to.equal(ethers.utils.parseEther("0.2"));
      expect(pool.unstakeLockedBlocks).to.equal(15);
    });
  });

  describe("Staking ETH", function () {
    it("Should allow staking ETH", async function () {
      const stakeAmount = ethers.utils.parseEther("1");
      
      await expect(metaNodeStake.connect(addr1).deposit(
        poolIdETH, 
        stakeAmount, 
        { value: stakeAmount }
      )).to.emit(metaNodeStake, "Deposited");
      
      const userInfo = await metaNodeStake.users(poolIdETH, addr1.address);
      expect(userInfo.stAmount).to.equal(stakeAmount);
    });

    it("Should reject staking below minimum amount", async function () {
      const stakeAmount = ethers.utils.parseEther("0.05"); // Below minimum of 0.1
      
      await expect(metaNodeStake.connect(addr1).deposit(
        poolIdETH, 
        stakeAmount, 
        { value: stakeAmount }
      )).to.be.revertedWith("Amount is less than minimum deposit requirement");
    });
  });

  describe("Staking ERC20", function () {
    it("Should allow staking ERC20 tokens", async function () {
      const stakeAmount = ethers.utils.parseEther("50");
      
      // 授权质押合约使用代币
      await metaNodeToken.connect(addr1).approve(metaNodeStake.address, stakeAmount);
      
      await expect(metaNodeStake.connect(addr1).deposit(
        poolIdERC20, 
        stakeAmount
      )).to.emit(metaNodeStake, "Deposited");
      
      const userInfo = await metaNodeStake.users(poolIdERC20, addr1.address);
      expect(userInfo.stAmount).to.equal(stakeAmount);
    });

    it("Should reject staking below minimum amount", async function () {
      const stakeAmount = ethers.utils.parseEther("5"); // Below minimum of 10
      
      await metaNodeToken.connect(addr1).approve(metaNodeStake.address, stakeAmount);
      
      await expect(metaNodeStake.connect(addr1).deposit(
        poolIdERC20, 
        stakeAmount
      )).to.be.revertedWith("Amount is less than minimum deposit requirement");
    });
  });

  describe("Unstaking", function () {
    it("Should allow requesting unstake", async function () {
      const stakeAmount = ethers.utils.parseEther("1");
      const unstakeAmount = ethers.utils.parseEther("0.5");
      
      // 先质押
      await metaNodeStake.connect(addr1).deposit(
        poolIdETH, 
        stakeAmount, 
        { value: stakeAmount }
      );
      
      // 请求解除质押
      await expect(metaNodeStake.connect(addr1).requestUnstake(
        poolIdETH, 
        unstakeAmount
      )).to.emit(metaNodeStake, "UnstakeRequested");
      
      // 检查用户余额
      const userInfo = await metaNodeStake.users(poolIdETH, addr1.address);
      expect(userInfo.stAmount).to.equal(stakeAmount.sub(unstakeAmount));
    });

    it("Should allow withdrawing after lock period", async function () {
      const stakeAmount = ethers.utils.parseEther("1");
      const unstakeAmount = ethers.utils.parseEther("0.5");
      
      // 先质押
      await metaNodeStake.connect(addr1).deposit(
        poolIdETH, 
        stakeAmount, 
        { value: stakeAmount }
      );
      
      // 请求解除质押
      await metaNodeStake.connect(addr1).requestUnstake(
        poolIdETH, 
        unstakeAmount
      );
      
      // 增加区块高度以解锁
      for (let i = 0; i < 10; i++) {
        await ethers.provider.send("evm_mine");
      }
      
      // 提取已解锁的代币
      const initialBalance = await ethers.provider.getBalance(addr1.address);
      await metaNodeStake.connect(addr1).withdrawUnstaked(poolIdETH);
      const finalBalance = await ethers.provider.getBalance(addr1.address);
      
      expect(finalBalance).to.be.above(initialBalance);
    });
  });

  describe("Rewards", function () {
    it("Should calculate pending rewards", async function () {
      const stakeAmount = ethers.utils.parseEther("1");
      
      // 质押
      await metaNodeStake.connect(addr1).deposit(
        poolIdETH, 
        stakeAmount, 
        { value: stakeAmount }
      );
      
      // 增加区块高度以产生奖励
      for (let i = 0; i < 100; i++) {
        await ethers.provider.send("evm_mine");
      }
      
      // 检查待领取奖励
      const pendingReward = await metaNodeStake.pendingReward(poolIdETH, addr1.address);
      expect(pendingReward).to.be.above(0);
    });

    it("Should allow claiming rewards", async function () {
      const stakeAmount = ethers.utils.parseEther("1");
      
      // 质押
      await metaNodeStake.connect(addr1).deposit(
        poolIdETH, 
        stakeAmount, 
        { value: stakeAmount }
      );
      
      // 增加区块高度以产生奖励
      for (let i = 0; i < 100; i++) {
        await ethers.provider.send("evm_mine");
      }
      
      // 领取奖励前的余额
      const initialTokenBalance = await metaNodeToken.balanceOf(addr1.address);
      
      // 领取奖励
      await metaNodeStake.connect(addr1).claimReward(poolIdETH);
      
      // 领取奖励后的余额
      const finalTokenBalance = await metaNodeToken.balanceOf(addr1.address);
      
      expect(finalTokenBalance).to.be.above(initialTokenBalance);
    });
  });
});
// test/CrossChainAuction.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");

describe("CrossChainAuction - ERC20 and ETH Bidding", function () {
  const SOURCE_CHAIN_ID = 1;
  const TARGET_CHAIN_ID = 2;
  
  // 部署夹具函数（包含ERC20代币）
  async function deployAuctionWithTokensFixture() {
    const [owner, seller, bidder1, bidder2, proxyAdmin] = await ethers.getSigners();

    // 部署NFT合约
    const MyNftERC721 = await ethers.getContractFactory("MyNftERC721");
    const nft = await MyNftERC721.deploy();
    await nft.waitForDeployment();
    const nftAddress = await nft.getAddress();

    // 部署ERC20代币
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const usdc = await MockERC20.deploy("USD Coin", "USDC", 6);
    await usdc.waitForDeployment();
    const usdcAddress = await usdc.getAddress();

    const dai = await MockERC20.deploy("DAI Stablecoin", "DAI", 18);
    await dai.waitForDeployment();
    const daiAddress = await dai.getAddress();

    // 给测试用户分配ERC20代币
    await usdc.mintForTest(seller.address, ethers.parseUnits("10000", 6));
    await usdc.mintForTest(bidder1.address, ethers.parseUnits("10000", 6));
    await usdc.mintForTest(bidder2.address, ethers.parseUnits("10000", 6));
    
    await dai.mintForTest(seller.address, ethers.parseEther("10000"));
    await dai.mintForTest(bidder1.address, ethers.parseEther("10000"));
    await dai.mintForTest(bidder2.address, ethers.parseEther("10000"));

    // 部署拍卖逻辑合约
    const Auction = await ethers.getContractFactory("Auction");
    const auctionImpl = await Auction.deploy();
    await auctionImpl.waitForDeployment();
    const auctionImplAddress = await auctionImpl.getAddress();

    // 部署代理管理员
    const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin");
    const proxyAdminContract = await ProxyAdmin.deploy(proxyAdmin.address);
    await proxyAdminContract.waitForDeployment();
    const proxyAdminAddress = await proxyAdminContract.getAddress();

    // 模拟CCIP路由器
    const MockCCIPRouter = await ethers.getContractFactory("MockCCIPRouter");
    const ccipRouter = await MockCCIPRouter.deploy();
    await ccipRouter.waitForDeployment();
    const routerAddress = await ccipRouter.getAddress();

    // 部署跨链拍卖工厂
    const AuctionFactor = await ethers.getContractFactory("AuctionFactor");
    const auctionFactor = await AuctionFactor.deploy(
      auctionImplAddress,
      proxyAdminAddress,
      routerAddress,
      SOURCE_CHAIN_ID
    );
    await auctionFactor.waitForDeployment();
    const auctionFactorAddress = await auctionFactor.getAddress();

    // 为跨链消息支付费用注入资金
    await owner.sendTransaction({ to: auctionFactorAddress, value: ethers.parseEther("1") });

    // 部署目标链的拍卖工厂（模拟远程链）
    const auctionFactorTarget = await AuctionFactor.deploy(
      auctionImplAddress,
      proxyAdminAddress,
      routerAddress,
      TARGET_CHAIN_ID
    );
    await auctionFactorTarget.waitForDeployment();
    const auctionFactorTargetAddress = await auctionFactorTarget.getAddress();

    // 目标链工厂也需要费用
    await owner.sendTransaction({ to: auctionFactorTargetAddress, value: ethers.parseEther("1") });

    // 设置远程拍卖工厂地址
    await auctionFactor.connect(proxyAdmin).setRemoteAuctionFactor(
      TARGET_CHAIN_ID,
      auctionFactorTargetAddress
    );

    await auctionFactorTarget.connect(proxyAdmin).setRemoteAuctionFactor(
      SOURCE_CHAIN_ID,
      auctionFactorAddress
    );

    const aggregator = await ethers.getContractFactory("AggreagatorV3");
    // 为了测试稳定，将所有代币价格统一为1e18，避免跨代币比较的尺度问题
    const aggregatorV3 = await aggregator.deploy(ethers.parseEther("1"))
    await aggregatorV3.waitForDeployment();
    const aggregatorEthAddress = await aggregatorV3.getAddress();

    await auctionFactor.setPriceFeed(ethers.ZeroAddress, aggregatorEthAddress);

    const aggregatorDaiAddress = await aggregator.deploy(ethers.parseEther("1"));


    await aggregatorDaiAddress.waitForDeployment();

    const daiPriceFeedAddress = await aggregatorDaiAddress.getAddress();

    await auctionFactor.setPriceFeed(daiAddress,daiPriceFeedAddress);

    const aggregatorUsdcAddress = await aggregator.deploy(ethers.parseEther("1"));
    await aggregatorUsdcAddress.waitForDeployment();

    await auctionFactor.setPriceFeed(usdcAddress, await aggregatorUsdcAddress.getAddress());

    // 设置NFT的跨链拍卖权限
    await nft.setCrossChainAuction(auctionFactorAddress);

    return {
      owner,
      seller,
      bidder1,
      bidder2,
      proxyAdmin: proxyAdminContract,
      nft,
      nftAddress,
      usdc,
      usdcAddress,
      dai,
      daiAddress,
      auctionImpl,
      auctionFactor,
      auctionFactorAddress,
      auctionFactorTarget,
      auctionFactorTargetAddress,
      ccipRouter
    };
  }

  describe("ETH出价测试", function () {
    it("应该允许ETH出价普通拍卖", async function () {
      const { auctionFactor, nft, seller, bidder1 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseEther("1.0");
      await auctionFactor.connect(seller).createAuction(duration, minBid, await nft.getAddress(), tokenId);

      // ETH出价
      const bidAmount = ethers.parseEther("1.5");
      
      // 验证出价前后余额变化
      const initialBalance = await ethers.provider.getBalance(bidder1.address);
      
      await expect(
        auctionFactor.connect(bidder1).placeBid(0, bidAmount, ethers.ZeroAddress, { value: bidAmount })
      ).to.not.be.reverted;

      // 验证ETH被锁定在合约中
      const auctionAddress = await auctionFactor.auctionMap(0);
      const auctionBalance = await ethers.provider.getBalance(auctionAddress);
      expect(auctionBalance).to.equal(bidAmount);
    });

   it("应该允许ETH出价跨链拍卖", async function () {
  const { auctionFactor, nft, seller, bidder1, ccipRouter } = await loadFixture(deployAuctionWithTokensFixture);
  
  const tokenId = 1;
  
  // 1. 铸造NFT
  console.log("1. 铸造NFT...");
  await nft.mintNFT(seller.address, tokenId);
  
  // 2. 授权工厂
  console.log("2. 授权工厂...");
  await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);
  
  // 3. 检查授权状态
  const approved = await nft.getApproved(tokenId);
  console.log("NFT授权地址:", approved);
  
  const duration = 3600;
  const minBid = ethers.parseEther("1.0");
  
  console.log("3. 创建跨链拍卖...");
  
  // 添加事件监听来调试
  auctionFactor.on("CrossChainAuctionCreated", (auctionId, nftContract, tokenId, sourceChain, targetChain) => {
    console.log("跨链拍卖创建事件:", { auctionId, nftContract, tokenId, sourceChain, targetChain });
  });
  
  try {
    const tx = await auctionFactor.connect(seller).createCrossChainAuction(
      duration,
      minBid,
      await nft.getAddress(),
      tokenId,
      TARGET_CHAIN_ID
    );
    
    console.log("4. 交易已发送，等待确认...");
    const receipt = await tx.wait();
    console.log("交易成功，gasUsed:", receipt.gasUsed.toString());
    
    // 检查拍卖是否创建
    const auctionAddress = await auctionFactor.auctionMap(0);
    console.log("拍卖合约地址:", auctionAddress);
    
    const bidAmount = ethers.parseEther("2.0");
    const signature = "0x";
    
    console.log("5. 进行跨链出价...");
    
    await expect(
      auctionFactor.connect(bidder1).placeCrossChainBid(
        0,
        bidAmount,
        ethers.ZeroAddress,
        TARGET_CHAIN_ID,
        signature,
        { value: bidAmount }
      )
    ).to.emit(auctionFactor, "CrossChainBidPlaced");
    
  } catch (error) {
    console.error("错误详情:", error);
    throw error;
  }
});

    it("应该防止ETH出价金额不足", async function () {
      const { auctionFactor, nft, seller, bidder1 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseEther("1.0");
      await auctionFactor.connect(seller).createAuction(duration, minBid, await nft.getAddress(), tokenId);

      const bidAmount = ethers.parseEther("1.5");
      const insufficientAmount = ethers.parseEther("1.0"); // 发送金额小于出价金额

      await expect(
        auctionFactor.connect(bidder1).placeBid(0, bidAmount, ethers.ZeroAddress, { value: insufficientAmount })
      ).to.be.reverted; // 具体错误信息取决于Auction合约的实现
    });
  });

  describe("ERC20出价测试", function () {
    it("应该允许USDC出价普通拍卖", async function () {
      const { auctionFactor, nft, usdc, seller, bidder1 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseUnits("100", 6); // 100 USDC
      await auctionFactor.connect(seller).createAuction(duration, minBid, await nft.getAddress(), tokenId);

      // 授权拍卖工厂使用USDC
      const bidAmount = ethers.parseUnits("150", 6); // 150 USDC
      await usdc.connect(bidder1).approve(await auctionFactor.getAddress(), bidAmount);

      // 验证出价前后余额变化
      const initialBalance = await usdc.balanceOf(bidder1.address);
      
      await expect(
        auctionFactor.connect(bidder1).placeBid(0, bidAmount, await usdc.getAddress())
      ).to.not.be.reverted;

      const finalBalance = await usdc.balanceOf(bidder1.address);
      expect(finalBalance).to.equal(initialBalance - bidAmount);

      // 验证代币被转移到拍卖合约
      const auctionAddress = await auctionFactor.auctionMap(0);
      const auctionBalance = await usdc.balanceOf(auctionAddress);
      expect(auctionBalance).to.equal(bidAmount);
    });

    it("应该允许DAI出价跨链拍卖", async function () {
      const { auctionFactor, nft, dai, seller, bidder1 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseEther("100"); // 100 DAI
      await auctionFactor.connect(seller).createCrossChainAuction(
        duration,
        minBid,
        await nft.getAddress(),
        tokenId,
        TARGET_CHAIN_ID
      );

      const bidAmount = ethers.parseEther("150"); // 150 DAI
      const signature = "0x";

      // 授权DAI
      await dai.connect(bidder1).approve(await auctionFactor.getAddress(), bidAmount);

      await expect(
        auctionFactor.connect(bidder1).placeCrossChainBid(
          0,
          bidAmount,
          await dai.getAddress(),
          TARGET_CHAIN_ID,
          signature
        )
      ).to.emit(auctionFactor, "CrossChainBidPlaced");
    });

    it("应该防止ERC20出价未授权", async function () {
      const { auctionFactor, nft, usdc, seller, bidder1 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseUnits("100", 6);
      await auctionFactor.connect(seller).createAuction(duration, minBid, await nft.getAddress(), tokenId);

      const bidAmount = ethers.parseUnits("150", 6);

      // 不进行授权直接出价
      await expect(
        auctionFactor.connect(bidder1).placeBid(0, bidAmount, await usdc.getAddress())
      ).to.be.revertedWithCustomError(usdc, "ERC20InsufficientAllowance");
    });

    it("应该防止ERC20出价余额不足", async function () {
      const { auctionFactor, nft, usdc, seller, bidder1 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseUnits("100", 6);
      await auctionFactor.connect(seller).createAuction(duration, minBid, await nft.getAddress(), tokenId);

      // 使用超过余额的金额出价
      const balance = await usdc.balanceOf(bidder1.address);
      const excessiveBid = balance + ethers.parseUnits("1", 6);

      await usdc.connect(bidder1).approve(await auctionFactor.getAddress(), excessiveBid);

      await expect(
        auctionFactor.connect(bidder1).placeBid(0, excessiveBid, await usdc.getAddress())
      ).to.be.revertedWithCustomError(usdc, "ERC20InsufficientBalance");
    });
  });

  describe("混合出价场景测试", function () {
    it("应该处理多个ERC20代币出价", async function () {
      const { auctionFactor, nft, usdc, dai, seller, bidder1, bidder2 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseEther("1.0"); // 使用ETH作为基准
      await auctionFactor.connect(seller).createAuction(duration, minBid, await nft.getAddress(), tokenId);

      // Bidder1 使用USDC出价（等价约150 ETH）
      const usdcBid = ethers.parseUnits("150", 6);
      await usdc.connect(bidder1).approve(await auctionFactor.getAddress(), usdcBid);
      await auctionFactor.connect(bidder1).placeBid(0, usdcBid, await usdc.getAddress());

      // Bidder2 使用DAI出价（更高）
      const daiBid = ethers.parseEther("200.0"); // 更高于150
      await dai.connect(bidder2).approve(await auctionFactor.getAddress(), daiBid);
      await auctionFactor.connect(bidder2).placeBid(0, daiBid, await dai.getAddress());

      // Bidder1 使用ETH再次出价（最高）
      const ethBid = ethers.parseEther("250.0");
      await auctionFactor.connect(bidder1).placeBid(0, ethBid, ethers.ZeroAddress, { value: ethBid });

      // 验证最高出价者是bidder1，使用ETH
      // 这里需要根据Auction合约的具体实现来验证
    });

    it("应该处理跨链混合出价", async function () {
      const { auctionFactor, nft, usdc, seller, bidder1, bidder2 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseEther("1.0");
      await auctionFactor.connect(seller).createCrossChainAuction(
        duration,
        minBid,
        await nft.getAddress(),
        tokenId,
        TARGET_CHAIN_ID
      );

      const signature = "0x";

      // 本地ETH出价
      const ethBid = ethers.parseEther("150");
      await auctionFactor.connect(bidder1).placeBid(0, ethBid, ethers.ZeroAddress, { value: ethBid });

      // 跨链USDC出价（更高）
      const usdcBid = ethers.parseUnits("200", 6);
      await usdc.connect(bidder2).approve(await auctionFactor.getAddress(), usdcBid);
      await auctionFactor.connect(bidder2).placeCrossChainBid(
        0,
        usdcBid,
        await usdc.getAddress(),
        TARGET_CHAIN_ID,
        signature
      );

      // 验证出价记录
      // 需要根据具体实现添加验证逻辑
    });
  });

  describe("出价结算测试", function () {
    it("应该正确结算ETH出价拍卖", async function () {
      const { auctionFactor, nft, seller, bidder1 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseEther("1.0");
      await auctionFactor.connect(seller).createAuction(duration, minBid, await nft.getAddress(), tokenId);

      const bidAmount = ethers.parseEther("1.5");
      await auctionFactor.connect(bidder1).placeBid(0, bidAmount, ethers.ZeroAddress, { value: bidAmount });

      // 前进时间并结算
      await time.increase(duration + 1);
      await auctionFactor.connect(seller).endAuction(0);

      // 验证资金分配（需要根据Auction合约实现）
    });

    it("应该正确结算ERC20出价拍卖", async function () {
      const { auctionFactor, nft, usdc, seller, bidder1 } = await loadFixture(deployAuctionWithTokensFixture);
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      const duration = 3600;
      const minBid = ethers.parseUnits("100", 6);
      await auctionFactor.connect(seller).createAuction(duration, minBid, await nft.getAddress(), tokenId);

      const bidAmount = ethers.parseUnits("150", 6);
      await usdc.connect(bidder1).approve(await auctionFactor.getAddress(), bidAmount);
      await auctionFactor.connect(bidder1).placeBid(0, bidAmount, await usdc.getAddress());

      // 前进时间并结算
      await time.increase(duration + 1);
      await auctionFactor.connect(seller).endAuction(0);

      // 验证代币转移（需要根据Auction合约实现）
    });
  });

  describe("价格预言机集成测试", function () {
    it("应该支持不同代币的价格比较", async function () {
      const { auctionFactor, nft, usdc, dai, seller } = await loadFixture(deployAuctionWithTokensFixture);
      
      // 设置价格预言机（需要先部署预言机Mock）
      // 这里假设有设置价格预言机的功能
      
      const tokenId = 1;
      await nft.mintNFT(seller.address, tokenId);
      await nft.connect(seller).approve(await auctionFactor.getAddress(), tokenId);

      // 创建以ETH计价的拍卖，但允许ERC20出价
      const duration = 3600;
      const minBidInEth = ethers.parseEther("1.0");
      await auctionFactor.connect(seller).createAuction(duration, minBidInEth, await nft.getAddress(), tokenId);

      // 测试不同代币的出价价值比较
      // 需要价格预言机支持
    });
  });
});
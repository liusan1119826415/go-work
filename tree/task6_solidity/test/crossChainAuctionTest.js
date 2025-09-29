const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CrossChainAuction", function () {
  let nft, auctionImpl, proxyAdmin, auctionFactor;
  let nftAddress,auctionImplAddress,proxyAdminAddress,auctionFactorAddress;
  let owner, seller, bidder;

  before(async function () {
    [owner, seller, bidder] = await ethers.getSigners();

    // 部署合约
    const MyNftERC721 = await ethers.getContractFactory("MyNftERC721");
     nft = await MyNftERC721.deploy();
 
    await nft.waitForDeployment();

    nftAddress = await nft.getAddress();
    
    
    const Auction = await ethers.getContractFactory("Auction");
     auctionImpl = await Auction.deploy();

    await auctionImpl.waitForDeployment();

    auctionImplAddress = await auctionImpl.getAddress();
    
    const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin");
    proxyAdmin = await ProxyAdmin.deploy(seller.address);

    await proxyAdmin.waitForDeployment();

    proxyAdminAddress = await proxyAdmin.getAddress();


    
    const AuctionFactor = await ethers.getContractFactory("AuctionFactor");
    auctionFactor = await AuctionFactor.deploy(auctionImplAddress, proxyAdminAddress);
    
    await auctionFactor.waitForDeployment();
    auctionFactorAddress = await auctionFactor.getAddress();
    // 初始化
    await nft.setCrossChainAuction(auctionFactorAddress);
  });

  it("should create a cross-chain auction", async function () {
    // 铸造NFT
    const tokenId = 1;
    console.log("====nft====",nft)
    await nft.mintNFT(seller.address, tokenId);
    
    // 授权拍卖工厂操作NFT
    await nft.connect(seller).approve(auctionFactorAddress, tokenId);
    
    // 创建跨链拍卖
    const duration = 3600; // 1小时
    const minBid = ethers.parseEther("1");
    const targetChainId = 2; // 假设目标链ID为2
    
    await expect(
      auctionFactor.connect(seller).createCrossChainAuction(
        duration,
        minBid,
        nftAddress,
        tokenId,
        targetChainId
      )
    ).to.emit(auctionFactor, "CrossChainAuctionCreated");
  });

  it("should place a cross-chain bid", async function () {
    const auctionId = 0;
    const bidAmount = ethers.parseEther("1.1");
    const sourceChainId = 2; // 假设源链ID为2
    
    // 模拟跨链消息签名
    const signature = "0x"; // 实际测试中需要生成有效签名
    
    await expect(
      auctionFactor.connect(bidder).placeCrossChainBid(
        auctionId,
        bidAmount,
        ethers.ZeroAddress, // ETH出价
        sourceChainId,
        signature
      )
    ).to.emit(auctionFactor, "CrossChainBidPlaced");
  });

  it("should settle a cross-chain auction", async function () {
    const auctionId = 0;
    const sourceChainId = 2
    ;
    
    // 模拟跨链消息签名
    const signature = "0x"; // 实际测试中需要生成有效签名
    
    // 增加时间到拍卖结束
    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine");
    
    await expect(
      auctionFactor.connect(seller).settleCrossChainAuction(
        auctionId,
        sourceChainId,
        signature
      )
    ).to.emit(auctionFactor, "CrossChainAuctionEnded");
  });
});

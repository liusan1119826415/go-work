// scripts/deployCrossChainAuction.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const router = process.env.CCIP_ROUTER;
  const chainId = Number(process.env.CURRENT_CHAIN_ID || 11155111);
  if (!router) throw new Error("CCIP_ROUTER env not set");

  // 1) 部署 Auction 实现
  const Auction = await ethers.getContractFactory("Auction");
  const auctionImpl = await Auction.deploy();
  await auctionImpl.waitForDeployment();
  const auctionImplAddress = await auctionImpl.getAddress();
  console.log("Auction impl:", auctionImplAddress);

  // 2) 部署 ProxyAdmin
  const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin");
  const proxyAdmin = await ProxyAdmin.deploy(deployer.address);
  await proxyAdmin.waitForDeployment();
  const proxyAdminAddress = await proxyAdmin.getAddress();
  console.log("ProxyAdmin:", proxyAdminAddress);

  // 3) 部署 AuctionFactor（CCIPReceiver 需要 router）
  const AuctionFactor = await ethers.getContractFactory("AuctionFactor");
  const factor = await AuctionFactor.deploy(
    auctionImplAddress,
    proxyAdminAddress,
    router,
    chainId
  );
  await factor.waitForDeployment();
  const factorAddress = await factor.getAddress();
  console.log("AuctionFactor:", factorAddress);

  // 4) 设置价格预言机（示例：ETH、USDC、DAI 都用统一1e18 mock）
  const Aggregator = await ethers.getContractFactory("AggreagatorV3");
  const price = ethers.parseEther("1");
  const ethFeed = await Aggregator.deploy(price);
  await ethFeed.waitForDeployment();
  await (await factor.setPriceFeed(ethers.ZeroAddress, await ethFeed.getAddress())).wait();

  // 如果你要支持具体代币，替换为实际token地址
  // const tokens = (process.env.ERC20S || "").split(",").filter(Boolean);
  // for (const token of tokens) {
  //   const feed = await Aggregator.deploy(price);
  //   await feed.waitForDeployment();
  //   await (await factor.setPriceFeed(token, await feed.getAddress())).wait();
  // }

  // // 5) (可选) 注入CCIP费用
  // const feeFund = ethers.parseEther(process.env.CCIP_FUND || "0.05");
  // if (feeFund > 0n) {
  //   await (await deployer.sendTransaction({ to: factorAddress, value: feeFund })).wait();
  //   console.log("Funded factor with:", feeFund.toString());
  // }

  console.log("Done.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

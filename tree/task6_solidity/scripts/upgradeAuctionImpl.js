// scripts/upgradeAuctionImpl.js
const { ethers } = require("hardhat");

async function main() {
  const newImplName = process.env.NEW_IMPL_NAME || "Auction";
  const factorAddress = process.env.FACTOR_ADDRESS;
  if (!factorAddress) throw new Error("FACTOR_ADDRESS env not set");

  const Auction = await ethers.getContractFactory(newImplName);
  const newImpl = await Auction.deploy();
  await newImpl.waitForDeployment();
  const newImplAddr = await newImpl.getAddress();
  console.log("New Auction impl:", newImplAddr);

  const factor = await ethers.getContractAt("AuctionFactor", factorAddress);
  await (await factor.upgradeAuctionImplementation(newImplAddr)).wait();
  console.log("Implementation upgraded in factory.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});



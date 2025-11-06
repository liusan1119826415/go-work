const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // 部署MetaNodeToken
  const MetaNodeToken = await ethers.getContractFactory("MetaNodeToken");
  const initialSupply = ethers.utils.parseEther("1000000"); // 1,000,000 tokens
  const metaNodeToken = await MetaNodeToken.deploy(initialSupply);
  await metaNodeToken.deployed();
  console.log("MetaNodeToken deployed to:", metaNodeToken.address);

  // 部署MetaNodeStake
  const MetaNodeStake = await ethers.getContractFactory("MetaNodeStake");
  const metaNodeStake = await MetaNodeStake.deploy(metaNodeToken.address);
  await metaNodeStake.deployed();
  console.log("MetaNodeStake deployed to:", metaNodeStake.address);

  // 添加流动性池 (Native Currency池)
  const tx1 = await metaNodeStake.addPool(
    ethers.constants.AddressZero, // Native currency
    100, // pool weight
    ethers.utils.parseEther("0.1"), // min deposit 0.1 ETH
    10 // 10 blocks lock period
  );
  await tx1.wait();
  console.log("Native currency pool added");

  // 添加ERC20代币池
  const tx2 = await metaNodeStake.addPool(
    metaNodeToken.address, // MetaNodeToken
    200, // pool weight
    ethers.utils.parseEther("10"), // min deposit 10 tokens
    20 // 20 blocks lock period
  );
  await tx2.wait();
  console.log("MetaNodeToken pool added");

  console.log("Deployment completed!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
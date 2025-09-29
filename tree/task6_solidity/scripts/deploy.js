const {ethers, upgrades } = require("hardhat");

async function main(){
    
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    //获取NFT合约
    const myNft = await ethers.getContractFactory("MyNftERC721");
    console.log("Deploying MyNftERC721...");
    const myNftContract = await myNft.deploy();
    await myNftContract.waitForDeployment();
    const MyNFTContractAddress = await myNftContract.getAddress()
    console.log("MyNftERC721 deployed to:",  MyNFTContractAddress);

    //拍卖合约部署
    const Auction = await ethers.getContractFactory("Auction");
    const auctionImpl = await Auction.deploy();
    await auctionImpl.waitForDeployment();
    const AuctionContractAddress = await auctionImpl.getAddress();
    console.log("Auction Implementation deployed to:", AuctionContractAddress);
    
    //获取代理合约
    const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin")

    const proxyAdmin = await ProxyAdmin.deploy(deployer.address);
    await proxyAdmin.waitForDeployment();
    const proxyAdminAddress = await proxyAdmin.getAddress();
    console.log("ProxyAdmin deployed to:", proxyAdminAddress);


    //部署工厂合约

    const AuctionFactory = await ethers.getContractFactory("AuctionFactor");
    const auctionFactory = await AuctionFactory.deploy(AuctionContractAddress,proxyAdminAddress)
    await auctionFactory.waitForDeployment();
    console.log("AuctionFactory deployed to:", auctionFactory.getAddress());

    console.log("Deployment complete.");
}

main().catch((error)=>{
    console.error(error);
    process.exit(1);
})


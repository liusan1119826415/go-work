const {expect} = require("chai");
const {ethers, upgrades} = require("hardhat");


describe("Auction Test",function(){

    
    it("Setup",async()=>{
        await main();
    })

    
})

function generateRandomString(length = 10) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() * characters.length));
    }
    return result;
}



async function main(){
   

        let owner,seller,bidder1,bidder2;
        [owner,seller,bidder1,bidder2] = await ethers.getSigners();

        //部署NFT合约
        const myNft = await ethers.getContractFactory("MyNftERC721");
        const nftToken = await myNft.deploy();

        await nftToken.waitForDeployment();
        const nftAddress = await nftToken.getAddress();
        // const tokenId = 1;
        // await nftToken.mintNFT(seller.address,tokenId);
        console.log("MyNftERC721 deployed to:", nftAddress);

        const myERC20 = await ethers.getContractFactory("MyERC20");
        const wec20Token = await myERC20.deploy();
        await wec20Token.waitForDeployment();
        const usdcAddress = await wec20Token.getAddress();
        console.log("MyERC20 deployed to:", usdcAddress);

         //部署Auction实现合约
         const Auction = await ethers.getContractFactory("Auction");
         const auction = await Auction.deploy();
         await auction.waitForDeployment();
         const auctionContractAddress = await auction.getAddress();
         console.log("Auction Implementation deployed to:", auctionContractAddress);
         //代理合约地址

         const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin")
         const proxyAdmin = await ProxyAdmin.deploy(seller.address);
         await proxyAdmin.waitForDeployment();

         const proxyAdminAddress = await proxyAdmin.getAddress();

          //部署工厂合约
    
        const AuctionFactory = await ethers.getContractFactory("AuctionFactor");
        const auctionFactory = await AuctionFactory.deploy(auctionContractAddress,proxyAdminAddress)
        await auctionFactory.waitForDeployment();

        const auctionContractFactory = await auctionFactory.getAddress()

        let tx = await wec20Token.connect(owner).transfer(bidder1.address,ethers.parseEther("1000"));
        await tx.wait();

        const aggregator = await ethers.getContractFactory("AggreagatorV3");
        const priceFeed = await aggregator.deploy(ethers.parseEther("10000"))
         await priceFeed.waitForDeployment()
        const priceFeedEthAddress = await priceFeed.getAddress();
        console.log("AggregatorV3 ETH deployed to:", priceFeedEthAddress);

        await auctionFactory.setPriceFeed(ethers.ZeroAddress, priceFeedEthAddress);

        const priceFeedUsdc = await aggregator.deploy(ethers.parseEther("1"))
        await priceFeedUsdc.waitForDeployment()
        const priceFeedUsdcAddress = await priceFeedUsdc.getAddress();
        console.log("AggregatorV3 USDC to:", priceFeedUsdcAddress);

        await auctionFactory.setPriceFeed(usdcAddress, priceFeedUsdcAddress);




        const token2Usd = [{
            token:ethers.ZeroAddress,
            priceFeed:priceFeedEthAddress
        },{
            token:usdcAddress,
            priceFeed:priceFeedUsdcAddress
        }]

        for(let i=0; i< token2Usd.length;i++){
            const {token,priceFeed} = token2Usd[i];
            await auctionFactory.setPriceFeed(token,priceFeed);
            console.log(`Set price feed for token ${token} to ${priceFeed}`);
        }

        //mint 10 个NFT
        for (let i=0;i<10;i++){
            await nftToken.mintNFT(seller.address,i);
        }

        expect(await nftToken.ownerOf(0)).to.equal(seller.address);
     
  

                await nftToken.connect(seller).approve(auctionContractFactory,0);

                console.log(`Seller ${seller.address} 已授权工厂合约 ${auctionContractFactory} 操作 TokenID 0`);
       
        
                const createAuctionTx = await auctionFactory.connect(seller).createAuction(
                    10,
                    ethers.parseEther("0.001"),
                    nftAddress,
                    0
                );
                console.log("交易已发送，等待确认...");
                const createAuctionReceipt = await createAuctionTx.wait();
                console.log("交易已确认，区块号:", createAuctionReceipt.blockNumber);
                
                // 方法1：使用接口解析日志（推荐）
                let auctionAddress;
                for (const log of createAuctionReceipt.logs) {
                    try {
                        const parsedLog = auctionFactory.interface.parseLog(log);
                        if (parsedLog && parsedLog.name === "AuctionCreated") {
                            auctionAddress = parsedLog.args.auctionAddress;
                            console.log("找到 AuctionCreated 事件，拍卖地址:", auctionAddress);
                            break;
                        }
                    } catch (error) {
                        // 忽略无法解析的日志
                        continue;
                    }
                }

          
                console.log("创建拍卖成功：", auctionAddress);

             
                try {
                    tx = await auctionFactory.connect(bidder1).placeBid(
                        0, // auctionId
                        0, // amount
                        ethers.ZeroAddress, // tokenAddress
                        { value: ethers.parseEther("0.01") }
                    );
                    console.log("交易已发送，等待确认...");
                    const receipt = await tx.wait();
                    console.log("交易成功，gas used:", receipt.gasUsed.toString());
                } catch (error) {
                    console.error("=== 详细错误信息 ===");
                    console.error("错误消息:", error.message);
                    console.error("错误原因:", error.reason);
                    console.error("交易hash:", error.txHash);
                    console.error("错误数据:", error.data);
                    
                    // 尝试解析revert原因
                    if (error.data && error.data !== '0x') {
                        try {
                            const revertReason = ethers.toUtf8String(error.data.slice(138));
                            console.error("Revert原因:", revertReason);
                        } catch (e) {
                            console.error("无法解析revert原因");
                        }
                    }
                    throw error;
                }
                console.log("Bidder1 placed a bid of 0.01 ETH");


                tx = await wec20Token.connect(owner).transfer(bidder2.address, ethers.parseEther("1000")); // 添加这行
                await tx.wait();


                const auctionContractAddressTwo = await auctionFactory.getAuctionMap(0);
                // usdc参与竞价
                tx = await wec20Token.connect(bidder2).approve(auctionContractAddressTwo, ethers.MaxUint256);
                await tx.wait();

                console.log("Bidder2 已批准工厂合约花费其 USDC 代币",auctionContractAddressTwo);

                const allowance = await wec20Token.allowance(bidder2.address, auctionContractAddressTwo);
                console.log("Bidder2对拍卖合约的批准额度:", allowance.toString());
        
                tx = await auctionFactory.connect(bidder2).placeBid(0,  ethers.parseEther("101"), usdcAddress);
                await tx.wait();

                await new Promise((resolve) => setTimeout(resolve, 10 * 1000));

                await auctionFactory.connect(seller).endAuction(0);

                // 验证结果
                const auctionInfo = await auctionFactory.getAuction(0);
                console.log("拍卖信息:", auctionInfo);
                expect(auctionInfo.highestBidder).to.equal(bidder2.address);
                expect(auctionInfo.highestBid).to.equal(ethers.parseEther("101"));
                expect(await nftToken.ownerOf(0)).to.equal(bidder2.address);


}
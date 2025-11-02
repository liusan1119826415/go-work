const {ethers} = require("hardhat")
const {expect} = require("chai")


describe("TokenTax",function(){

    let tokenTax,deployer,user1,user2,user3,user4,tokenAddress;
    
    this.beforeEach(async function(){
        [deployer,user1,user2,user3,user4,user5,user6] = await ethers.getSigners();

        //部署tokentax合约

        const TokenTax = await ethers.getContractFactory("tokenTax")
        tokenTax = await TokenTax.deploy();
        await tokenTax.waitForDeployment();

        tokenAddress = await tokenTax.getAddress();

        

        
    })

    it("should buytax transer", async()=>{

        const deployBalance = await tokenTax.balanceOf(deployer.address);

        console.log("deployBalance:",deployBalance);

        await tokenTax.setBuyTax(5);

        await tokenTax.setSellTax(6);

        // 钱包间转账不收税
        await tokenTax.transfer(user1.address,ethers.parseEther("1000"))
        
        const user1Balance = await tokenTax.balanceOf(user1.address);
        expect(user1Balance).to.eq(ethers.parseEther("1000"))
   
    })

    // it("should charge buy tax from uniswap", async()=>{
    //     // 设置user2作为uniswap地址
    //     await tokenTax.setUinswapAddress(user2.address)
        
    //     // 先给user2转一些代币，模拟流动性池
    //     await tokenTax.transfer(user2.address, ethers.parseEther("10000"))
        
    //     // 从uniswap买入1000个代币，应该收取5%的税
    //     // user2 (uniswap) -> user1 转账1000，user1应该收到950，合约收到50
    //     await tokenTax.connect(user2).transfer(user1.address, ethers.parseEther("1000"))
        
    //     const user1Balance = await tokenTax.balanceOf(user1.address)
    //     const contractBalance = await tokenTax.balanceOf(await tokenTax.getAddress())
        
    //     // user1应该收到 1000 - 50(5%税) = 950
    //     expect(user1Balance).to.eq(ethers.parseEther("950"))
    //     // 合约应该收到50的税费
    //     expect(contractBalance).to.eq(ethers.parseEther("50"))
    // })

    // it("should charge sell tax to uniswap", async()=>{
    //     // 设置user3作为uniswap地址
    //     await tokenTax.setUinswapAddress(user3.address)
        
    //     // 先给user1转一些代币
    //     await tokenTax.transfer(user1.address, ethers.parseEther("2000"))
        
    //     // user1卖给uniswap 1000个代币，应该收取6%的税
    //     // user1 -> user3(uniswap) 转账1000，uniswap应该收到940，合约收到60
    //     await tokenTax.connect(user1).transfer(user3.address, ethers.parseEther("1000"))
        
    //     const user3Balance = await tokenTax.balanceOf(user3.address)
    //     const contractBalance = await tokenTax.balanceOf(await tokenTax.getAddress())
        
    //     // uniswap应该收到 1000 - 60(6%税) = 940
    //     expect(user3Balance).to.eq(ethers.parseEther("940"))
    //     // 合约应该收到60的税费
    //     expect(contractBalance).to.eq(ethers.parseEther("60"))
    // })


    it("should buy tax",async()=>{
         //设置uinswap地址
        await tokenTax.setUinswapAddress(user2.address);
        //先给user2 转10000个增加流动性
        await tokenTax.transfer(user2.address,ethers.parseEther("10000"))

        console.log("===contractBalance2221===",await tokenTax.balanceOf(tokenAddress))
        //在uinswap地址买入一些代币
        const tx = await tokenTax.connect(user2).transfer(user3.address,ethers.parseEther("1000"))
    


        //验证user3 账户是扣除5% 的税费

        const user3Balance = await tokenTax.balanceOf(user3.address)

        expect(user3Balance).to.eq(ethers.parseEther("950"))

        const tokenBalance = await tokenTax.balanceOf(tokenAddress)

        console.log("tokenBalance", tokenBalance)

        expect(tokenBalance).to.eq(ethers.parseEther("650"))

    })


    it("should sell tax", async ()=>{
        //设置uinswap地址
        await tokenTax.setUinswapAddress(user5.address)
        //转一些代币到user4 增加流动性
        await tokenTax.transfer(user4.address,ethers.parseEther("20000"))

        await tokenTax.connect(user4).transfer(user5.address,ethers.parseEther("1000"))

        
        const user5Balance = await tokenTax.balanceOf(user5.address)

        expect(user5Balance).to.eq(ethers.parseEther("940"))

        const contractBalance22 = await tokenTax.balanceOf(tokenAddress)

        console.log("contractBalance22:",contractBalance22)
        expect(contractBalance22).to.eq(ethers.parseEther("60"))


    })



    
})
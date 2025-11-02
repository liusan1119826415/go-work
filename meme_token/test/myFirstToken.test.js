const {ethers} = require("hardhat")
const {expect} = require("chai")


describe("MyFirstToken",function(){
    let MyFirstToken,mytoken, deployer,user1,user2,user3;

    this.beforeEach(async()=>{
        [deployer,user1,user2,user3] = await ethers.getSigners()
         MyFirstToken = await ethers.getContractFactory("myFirstToken")
         mytoken = await MyFirstToken.deploy()
        await mytoken.waitForDeployment()
    })

     it("should check balance",async function () {
            
        const addressToken = await mytoken.getAddress()

        console.log("打印地址",addressToken)
        //获取deployer余额

        const deployBalance = await mytoken.balanceOf(deployer.address)

        console.log("deployer 余额", deployBalance)
    })

    it("should mint token",async function () {
        //设置mint权限
        await mytoken.setMint(user1.address,true)

        await mytoken.connect(user1).mint(user1.address,1000)

    })

    it("should transfer",async function(){
        const transferAmount = ethers.parseEther("1000")
        
        // 执行转账并捕获事件
        const tx = await mytoken.transfer(user2.address, transferAmount)
        
        // 验证余额
        const user2Balance = await mytoken.balanceOf(user2.address)
        expect(user2Balance).to.eq(transferAmount)
        
       //验证事件是否被触发
       await expect(tx).to.emit(mytoken,"transferLogs").withArgs(deployer.address,user2.address,transferAmount,(timestamp)=>timestamp>0) 

       //获取转账次数
       const transferCount = await mytoken.getTransferCount(deployer.address)
       expect(transferCount).to.eq(1)
    })
})
const {ethers} = require("hardhat")

const {expect} = require("chai")


describe("limitToken",function(){
     
    let limitToken,deploy,user1,user2,user3,user4;

    this.beforeEach(async()=>{
          [deploy,user1,user2,user3,user4] = await ethers.getSigners();

          const LimitToken = await ethers.getContractFactory("limitToken");

          limitToken = await LimitToken.deploy();

          await limitToken.waitForDeployment();

          const limitAddress = await limitToken.getAddress()
          console.log("===limitAddress===",limitAddress)
    })

    it("limit single", async()=>{
           
           const tx = await limitToken.transfer(user1.address,ethers.parseEther("6000"))
           
           const user1Balance = await limitToken.balanceOf(user1.address)
           console.log("===user1Balance===",user1Balance)
           //测试不是owner账户转账
           const tx1 = await limitToken.connect(user1).transfer(user2.address,ethers.parseEther("6000"))


    })
})
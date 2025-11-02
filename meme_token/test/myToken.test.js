const {ethers} = require('hardhat');
const {expect} = require('chai')



describe('Mytoken',function(){
    
    it('should deploy',async function () {

        //获取部署者的账户
        const [deploy,user1,user2] = await ethers.getSigners()

        console.log('deploy',deploy)
        const myToken = await ethers.getContractFactory('myToken')
        token = await myToken.deploy()
        await token.waitForDeployment()
        const tokenContractAddress = await token.getAddress()
        console.log("myToken deployed to:", tokenContractAddress)

        //查询余额
        const deployBalance = await token.balanceOf(deploy.address)

        console.log('deployBalance',deployBalance)

        expect(deployBalance).to.eq(ethers.parseEther('1000000'))


        // 1. Owner转100给user1（免税）
        //owner 余额
        const ownerBalance = await token.balanceOf(deploy.address)
        console.log('ownerBalance',ownerBalance)

        const user1Balance = await token.balanceOf(user1.address)
        console.log('userBalance',user1Balance)

        //user2 余额

        const user2Balance = await token.balanceOf(user2.address)
        console.log('user2Balance',user2Balance)

        // Owner转账会触发2个Transfer事件（税费+实际转账），所以不用withArgs验证具体参数
        await token.transfer(user1.address, ethers.parseEther('100'))
    
        // 验证user1余额（收到90个代币，扣除了10%税费）

        const user1BalanceAfter = await token.balanceOf(user1.address)
        const expectedAmount = user1Balance + ethers.parseEther('100') // 90%
        expect(user1BalanceAfter).to.equal(expectedAmount)




        await token.connect(user1).transfer(user2.address, ethers.parseEther('100'))
        const user2BalanceAfter2 = await token.balanceOf(user2.address)

        expect(user2BalanceAfter2).to.eq(ethers.parseEther('90'))
        
        //验证铸造和销毁不收税
        await token.mint(user2.address, ethers.parseEther('100'))

        const user2BalanceLast = await token.balanceOf(user2.address)

        expect(user2BalanceLast).to.eq(ethers.parseEther('190'))
        
        //验证销毁不收税
        await token.burn(user2.address, ethers.parseEther('100'))

        const user2BalanceLast2 = await token.balanceOf(user2.address)
        expect(user2BalanceLast2).to.eq(ethers.parseEther('90'))
        
    })

   
    

})
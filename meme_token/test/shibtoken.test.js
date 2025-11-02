const {ethers} = require("hardhat")
const { expect} = require("chai")
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

/**
 * @dev test shibToken
 *  shibtoken 测试
 * 
 */

describe("shibToken",function(){

      async function deployShibTokenFixture(){
        const [owner, marketingWallet, devWallet, user1,user2, user3] = await ethers.getSigners()


       //部署模拟的uniswap router

       const UniswapV3Mock = await ethers.getContractFactory("UniswapV3Mock")

       const uniswapV3TokenMock = await UniswapV3Mock.deploy()

       await uniswapV3TokenMock.waitForDeployment()


       const UniswapV3Router02Mock = await ethers.getContractFactory("UniswapV3Router02Mock")

       const uniswapV3Router02Mock = await UniswapV3Router02Mock.deploy(await uniswapV3TokenMock.getAddress())

       await uniswapV3Router02Mock.waitForDeployment()



        const ShibToken = await ethers.getContractFactory("ShibToken")

        const totalSupply = ethers.parseEther("1000000000000")
        const shibTokenContract = await ShibToken.deploy(
            "ShibToken",
            "SHIBI",
            totalSupply,
            await uniswapV3Router02Mock.getAddress(),
            marketingWallet.address,
            devWallet.address


        )
        await shibTokenContract.waitForDeployment()

        const shibTokenAddress = await shibTokenContract.getAddress()
        console.log("=====shibTokenAddress:", shibTokenAddress)


       return {shibTokenContract, uniswapV3Router02Mock, owner, marketingWallet, devWallet, user1,user2, user3, totalSupply}
      }


      describe("deployment",function(){
          it("检查正确设置代币名称",async()=>{
              const { shibTokenContract } = await loadFixture(deployShibTokenFixture);

              expect(await shibTokenContract.name()).to.eq("ShibToken")

              expect(await shibTokenContract.symbol()).to.eq("SHIBI")
          })

          it("检查供应量", async()=>{
            const {shibTokenContract, owner, totalSupply} = await loadFixture(deployShibTokenFixture);

              expect(await shibTokenContract.balanceOf(owner.address)).to.eq(totalSupply)

              expect(await shibTokenContract.totalSupply()).to.eq(totalSupply)
              
          })

          it("检查正确初始化的税率",async()=>{
               const {shibTokenContract} = await loadFixture(deployShibTokenFixture)
               const {_buyTax, _sellTax} = await shibTokenContract.getTaxRate()

               expect(_buyTax).to.equal(50)
               expect(_sellTax).to.equal(100)
          })

          it("正确初始化交易限制",async()=>{
             const {shibTokenContract, totalSupply} = await loadFixture(deployShibTokenFixture)

              const {_maxTxAmount, _maxWalletAmount,_cooldown} = await shibTokenContract.getLimits()

              expect(_maxTxAmount).to.equal(totalSupply * 50n/1000n)
              expect(_maxWalletAmount).to.equal(totalSupply * 20n/100n)

              expect(_cooldown).to.equal(60)

          })

          it("将owner 设置为免税地址",async()=>{
              const {shibTokenContract, owner} = await loadFixture(deployShibTokenFixture)
              const isExcludedFromFees = await shibTokenContract.isExcludedFromFees(owner.address);
              expect(isExcludedFromFees).to.be.true
          })
      })

      describe("测试transfer", function(){
        //   it("测试黑名单不能转账",async()=>{
        //     const {shibTokenContract,owner, user1, user2} = await loadFixture(deployShibTokenFixture)

        //     //先owner 转账为user1
        //     await shibTokenContract.transfer(user1.address,ethers.parseEther("1000"))

        //     const user1Balance = await shibTokenContract.balanceOf(user1.address)
        //     expect(user1Balance).to.equal(ethers.parseEther("1000"))

        //     const tx = await shibTokenContract.connect(user1).transfer(user2.address,ethers.parseEther("100"))
            
        //   })

          it("测试启动交易后是否正常交易",async()=>{
             const {shibTokenContract,user1,user2} = await loadFixture(deployShibTokenFixture)

             await shibTokenContract.setTradeEnabled()

             await shibTokenContract.transfer(user1.address,ethers.parseEther("10000"))

             const user1Balance = await shibTokenContract.balanceOf(user1.address)
             console.log("user1Balance:",user1Balance)
             await ethers.provider.send("evm_increaseTime", [61]);
             await ethers.provider.send("evm_mine", [])

             await expect(
                shibTokenContract.connect(user1).transfer(user2.address, ethers.parseEther("100"))
            ).to.not.be.reverted;
          })
      })

      describe("交易限制测试", function () { 

        it("测试超过maxTaxAmount限制",async()=>{
            const {shibTokenContract,owner,user1,user2} = await loadFixture(deployShibTokenFixture);
            await shibTokenContract.setTradeEnabled()

            //先转给user1 
            const {_maxTxAmount,_maxWalletAmount, _cooldown} = await shibTokenContract.getLimits();

            console.log(_maxTxAmount)

            await shibTokenContract.transfer(user1.address,_maxTxAmount*3n)
            await ethers.provider.send("evm_increaseTime", [61]);
            await ethers.provider.send("evm_mine");

            //user1 尝试转账超额转账
            const exceedAmount = _maxTxAmount + ethers.parseEther("1")
             await expect(
                shibTokenContract.connect(user1).transfer(user2.address, exceedAmount)
            ).to.be.revertedWith("maxTxWallet");
        })

        it("检测钱包持有超过maxWalletAmount",async()=>{ 
               const{shibTokenContract,owner,user1,user2} = await loadFixture(deployShibTokenFixture)

               await shibTokenContract.setTradeEnabled()

               const maxWallet = await shibTokenContract.maxWalletAmount()

               console.log("=========maxWallet:",maxWallet)

               //给user2转账达到上限
               await shibTokenContract.transfer(user2.address,maxWallet)

               await ethers.provider.send("evm_increaseTime",[61])
               await ethers.provider.send("evm_mine")

               await shibTokenContract.transfer(user1.address, ethers.parseEther("1000"))
               await ethers.provider.send("evm_increaseTime",[61])
               await ethers.provider.send("evm_mine")

               //user1 再次转给user2 是否会失败
               await expect(
                  shibTokenContract.connect(user1).transfer(user2.address, ethers.parseEther("1"))
              ).to.be.revertedWith("maxWalletAmount");
         })

         it("检测冷却期", async()=>{ 
          const {shibTokenContract,owner,user1,user2} = await loadFixture(deployShibTokenFixture)

          await shibTokenContract.setTradeEnabled()

          await shibTokenContract.transfer(user1.address, ethers.parseEther("1000"))
          //第一次转账
          await shibTokenContract.connect(user1).transfer(user2.address, ethers.parseEther("500"))

          await expect(
              shibTokenContract.connect(user1).transfer(user2.address, ethers.parseEther("300"))
          ).to.be.revertedWith("Cooldown");
        })

        it("owner应该能够修改交易限制",async()=>{ 
          const {shibTokenContract, totalSupply} = await loadFixture(deployShibTokenFixture)
          const newMaxTx = totalSupply * 10n/1000n; //0.1%
          const newMaxWallet = totalSupply * 30n/100n; //0.3%

          await shibTokenContract.setLimits(newMaxTx, newMaxWallet)

          const {_maxTxAmount, _maxWalletAmount, _cooldown}= await shibTokenContract.getLimits() 
          
          console.log("++++++++",newMaxTx)
          console.log("++++++++",newMaxWallet)
          expect(_maxTxAmount).to.equal(newMaxTx)
          expect(_maxWalletAmount).to.equal(newMaxWallet)


          })

          it("拒绝设置过低的限制",async()=>{ 
            const {shibTokenContract, totalSupply} = await loadFixture(deployShibTokenFixture)
            const tooLowTx = totalSupply/2000n; //0.05%(低于0.1%)
            const tooLowWallet = totalSupply/200n; //0.5% (低于0.1%)

            await expect(
                shibTokenContract.setLimits(tooLowTx, tooLowWallet)
            ).to.be.revertedWith("total supply");

          })


      })

      //=========税费测试=========

      describe("税费测试",async()=>{ 

          it("owner 能够设置买入和卖出税费",async()=>{ 
            const {shibTokenContract,owner} = await loadFixture(deployShibTokenFixture)

            const newBuyTax = 30;
            const newSellTax = 90;

            await shibTokenContract.setTaxRates(newBuyTax, newSellTax)
            const buyTax = await shibTokenContract.buyTax()
            const sellTax = await shibTokenContract.sellTax()
            expect(buyTax).to.eq(newBuyTax)

            expect(sellTax).to.eq(newSellTax)
            

         })

         it("owner 设置税率分配比例",async()=>{ 
          const {shibTokenContract} = await loadFixture(deployShibTokenFixture)
          const newLiquidityShare = 300;
          const newMarketingShare = 300;
          const newDevShare = 200;
          const newBurnShare = 200;

          await shibTokenContract.setTaxDistribution(newLiquidityShare,newMarketingShare,newDevShare,newBurnShare)
          const liquidityShare = await shibTokenContract.liquidityShare()
          const marketingShare = await shibTokenContract.marketingShare()
          const devShare = await shibTokenContract.devShare()
          const burnShare = await shibTokenContract.burnShare()

          expect(liquidityShare).to.eq(newLiquidityShare)
          expect(marketingShare).to.eq(newMarketingShare)

          expect(devShare).to.eq(newDevShare)
          expect(burnShare).to.eq(newBurnShare)


         })

         it("更改税费地址", async()=>{ 
          const {shibTokenContract, owner, user1,user2,user3} = await loadFixture(deployShibTokenFixture)
          await shibTokenContract.setTaxWallet(user1.address,user2.address,user3.address)
          const devAddress = await shibTokenContract.devAddress()
          const marketingAddress = await shibTokenContract.marketingAddress()
          const liquidityAddress = await shibTokenContract.liquidityReceiver()

          
          
          expect(liquidityAddress).to.eq(user1.address)
          expect(marketingAddress).to.eq(user2.address)
          expect(devAddress).to.eq(user3.address)
          

         })
      })

      //=========黑名单测试=========
      describe("黑名单测试",function(){
        it("owner能够添加黑名单用户",async()=>{
          const {shibTokenContract, owner, user1,user2,user3} = await loadFixture(deployShibTokenFixture)
          await shibTokenContract.transfer(user1.address, ethers.parseEther("1000"))
          
          await shibTokenContract.setBackAddress(user1.address,true)
        
          //检查黑名单能否转账
          await shibTokenContract.connect(user1).transfer(user2.address, ethers.parseEther("500"))
        
        })

        it("阻止owner添加自己到黑名单",async()=>{
            const {shibTokenContract, owner} = await loadFixture(deployShibTokenFixture)
            await expect(
                shibTokenContract.setBackAddress(owner.address,true)
            ).to.be.revertedWith("owner");

        })
       
      })

      //=========免税/免限制测试=======
      describe("免税/免限制测试",function(){
         
        it("owner能够添加免税用户",async()=>{ 
          const {shibTokenContract, owner, user1,user2,user3} = await loadFixture(deployShibTokenFixture)

          await shibTokenContract.setExcludedFromFees(user1.address,true)

           expect(await shibTokenContract.isExcludedFromFees(user1.address)).to.be.true
   
        })

        it("owner应该能够设置免限制地址",async()=>{ 
          const {shibTokenContract, owner, user1,user2,user3} = await loadFixture(deployShibTokenFixture)

          await shibTokenContract.setExcludedFromLimit(user1.address,true)

          await shibTokenContract.setTradeEnabled()

          const maxWalletAmount = await shibTokenContract.maxWalletAmount()
          const exceedAmount = maxWalletAmount + ethers.parseEther("1000")
          await expect(shibTokenContract.transfer(user1.address, exceedAmount)).to.not.be.reverted;

   
            })
      })

      describe("gas优化测试",function(){
        it("gas优化测试",async()=>{ 
          const {shibTokenContract, owner, user1,user2,user3} = await loadFixture(deployShibTokenFixture)

          await shibTokenContract.setTradeEnabled()
          const tx = await shibTokenContract.transfer(user1.address, ethers.parseEther("1000"))

          const receipt = await tx.wait();
          console.log(`Gas used: ${receipt.gasUsed.toString()}`);
        })  
      })





  

})
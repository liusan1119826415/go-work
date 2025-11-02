const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

/**
 * ShibaMemeToken 合约测试套件
 * 
 * 测试覆盖：
 * 1. 基础ERC20功能
 * 2. 代币税机制
 * 3. 交易限制
 * 4. 流动性池集成
 * 5. 黑名单功能
 * 6. 管理员权限
 */
describe("ShibaMemeToken", function () {
    
    // ============ 测试辅助函数 ============
    
    /**
     * 部署合约固件
     */
    async function deployTokenFixture() {
        const [owner, marketingWallet, devWallet, user1, user2, user3] = await ethers.getSigners();
        
        // 部署模拟的Uniswap V2 Router
        const UniswapV2Factory = await ethers.getContractFactory("UniswapV2FactoryMock");
        const factory = await UniswapV2Factory.deploy();
        
        const UniswapV2Router = await ethers.getContractFactory("UniswapV2Router02Mock");
        const router = await UniswapV2Router.deploy(await factory.getAddress());
        
        // 部署代币合约
        const ShibaMemeToken = await ethers.getContractFactory("ShibaMemeToken");
        const totalSupply = ethers.parseEther("1000000000000"); // 1万亿代币
        
        const token = await ShibaMemeToken.deploy(
            "Shiba Meme",
            "SHIBM",
            totalSupply,
            await router.getAddress(),
            marketingWallet.address,
            devWallet.address
        );
        
        return { token, router, owner, marketingWallet, devWallet, user1, user2, user3, totalSupply };
    }
    
    // ============ 部署与初始化测试 ============
    
    describe("Deployment", function () {
        it("应该正确设置代币名称和符号", async function () {
            const { token } = await loadFixture(deployTokenFixture);
            
            expect(await token.name()).to.equal("Shiba Meme");
            expect(await token.symbol()).to.equal("SHIBM");
        });
        
        it("应该将总供应量铸造给owner", async function () {
            const { token, owner, totalSupply } = await loadFixture(deployTokenFixture);
            
            expect(await token.balanceOf(owner.address)).to.equal(totalSupply);
            expect(await token.totalSupply()).to.equal(totalSupply);
        });
        
        it("应该正确初始化税率", async function () {
            const { token } = await loadFixture(deployTokenFixture);
            
            const [buyTax, sellTax] = await token.getTaxRates();
            expect(buyTax).to.equal(500); // 5%
            expect(sellTax).to.equal(1000); // 10%
        });
        
        it("应该正确初始化交易限制", async function () {
            const { token, totalSupply } = await loadFixture(deployTokenFixture);
            
            const [maxTx, maxWallet, cooldown] = await token.getLimits();
            expect(maxTx).to.equal(totalSupply * 5n / 1000n); // 0.5%
            expect(maxWallet).to.equal(totalSupply * 20n / 1000n); // 2%
            expect(cooldown).to.equal(60);
        });
        
        it("应该将owner设为免税和免限制", async function () {
            const { token, owner } = await loadFixture(deployTokenFixture);
            
            expect(await token.isExcludedFromFees(owner.address)).to.be.true;
        });
    });
    
    // ============ 基础转账测试 ============
    
    describe("Basic Transfers", function () {
        it("应该允许owner在交易未启用时转账", async function () {
            const { token, owner, user1 } = await loadFixture(deployTokenFixture);
            
            const amount = ethers.parseEther("1000");
            await expect(token.transfer(user1.address, amount))
                .to.changeTokenBalances(token, [owner, user1], [-amount, amount]);
        });
        
        it("应该阻止非白名单用户在交易未启用时转账", async function () {
            const { token, owner, user1, user2 } = await loadFixture(deployTokenFixture);
            
            // owner先转给user1
            await token.transfer(user1.address, ethers.parseEther("1000"));
            
            // user1尝试转给user2（应该失败）
            await expect(
                token.connect(user1).transfer(user2.address, ethers.parseEther("100"))
            ).to.be.revertedWith("Trading not enabled");
        });
        
        it("启用交易后应该允许正常转账", async function () {
            const { token, owner, user1, user2 } = await loadFixture(deployTokenFixture);
            
            // 启用交易
            await token.enableTrading();
            
            // owner转给user1
            await token.transfer(user1.address, ethers.parseEther("10000"));
            
            // user1转给user2（需要等待冷却期）
            await ethers.provider.send("evm_increaseTime", [61]);
            await ethers.provider.send("evm_mine");
            
            await expect(
                token.connect(user1).transfer(user2.address, ethers.parseEther("100"))
            ).to.not.be.reverted;
        });
    });
    
    // ============ 交易限制测试 ============
    
    describe("Transaction Limits", function () {
        it("应该阻止超过maxTxAmount的交易", async function () {
            const { token, owner, user1, user2 } = await loadFixture(deployTokenFixture);
            
            await token.enableTrading();
            
            // 先转给user1一些代币
            const maxTx = await token.maxTxAmount();
            await token.transfer(user1.address, maxTx * 3n);
            
            await ethers.provider.send("evm_increaseTime", [61]);
            await ethers.provider.send("evm_mine");
            
            // user1尝试超额转账
            const exceedAmount = maxTx + ethers.parseEther("1");
            
            await expect(
                token.connect(user1).transfer(user2.address, exceedAmount)
            ).to.be.revertedWith("Exceeds max transaction amount");
        });
        
        it("应该阻止钱包持有超过maxWalletAmount", async function () {
            const { token, owner, user1, user2 } = await loadFixture(deployTokenFixture);
            
            await token.enableTrading();
            
            const maxWallet = await token.maxWalletAmount();
            
            // 给user2转账达到上限
            await token.transfer(user2.address, maxWallet);
            
            await ethers.provider.send("evm_increaseTime", [61]);
            await ethers.provider.send("evm_mine");
            
            // 给user1一些代币
            await token.transfer(user1.address, ethers.parseEther("1000"));
            
            await ethers.provider.send("evm_increaseTime", [61]);
            await ethers.provider.send("evm_mine");
            
            // user1再次转给user2应该失败
            await expect(
                token.connect(user1).transfer(user2.address, ethers.parseEther("1"))
            ).to.be.revertedWith("Exceeds max wallet amount");
        });
        
        it("应该强制执行冷却期", async function () {
            const { token, owner, user1, user2 } = await loadFixture(deployTokenFixture);
            
            await token.enableTrading();
            await token.transfer(user1.address, ethers.parseEther("10000"));
            
            // 第一次转账
            await token.connect(user1).transfer(user2.address, ethers.parseEther("100"));
            
            // 立即再次转账应该失败
            await expect(
                token.connect(user1).transfer(user2.address, ethers.parseEther("100"))
            ).to.be.revertedWith("Cooldown period active");
            
            // 等待冷却期后应该成功
            await ethers.provider.send("evm_increaseTime", [61]);
            await ethers.provider.send("evm_mine");
            
            await expect(
                token.connect(user1).transfer(user2.address, ethers.parseEther("100"))
            ).to.not.be.reverted;
        });
        
        it("owner应该能够修改交易限制", async function () {
            const { token, totalSupply } = await loadFixture(deployTokenFixture);
            
            const newMaxTx = totalSupply * 10n / 1000n; // 1%
            const newMaxWallet = totalSupply * 30n / 1000n; // 3%
            
            await expect(token.setLimits(newMaxTx, newMaxWallet))
                .to.emit(token, "LimitsUpdated")
                .withArgs(newMaxTx, newMaxWallet);
            
            const [maxTx, maxWallet] = await token.getLimits();
            expect(maxTx).to.equal(newMaxTx);
            expect(maxWallet).to.equal(newMaxWallet);
        });
        
        it("应该拒绝设置过低的限制", async function () {
            const { token, totalSupply } = await loadFixture(deployTokenFixture);
            
            const tooLowTx = totalSupply / 2000n; // 0.05% (低于0.1%)
            const tooLowWallet = totalSupply / 200n; // 0.5% (低于1%)
            
            await expect(
                token.setLimits(tooLowTx, tooLowWallet)
            ).to.be.revertedWith("Max tx too low");
        });
        
        it("owner应该能够禁用交易限制", async function () {
            const { token, owner, user1 } = await loadFixture(deployTokenFixture);
            
            await token.enableTrading();
            await token.setLimitsEnabled(false);
            
            const maxWallet = await token.maxWalletAmount();
            const exceedAmount = maxWallet + ethers.parseEther("1000");
            
            // 禁用限制后应该允许超额转账
            await expect(token.transfer(user1.address, exceedAmount)).to.not.be.reverted;
        });
    });
    
    // ============ 税费测试 ============
    
    describe("Tax Mechanism", function () {
        it("owner应该能够修改税率", async function () {
            const { token } = await loadFixture(deployTokenFixture);
            
            const newBuyTax = 300; // 3%
            const newSellTax = 800; // 8%
            
            await expect(token.setTaxRates(newBuyTax, newSellTax))
                .to.emit(token, "TaxConfigUpdated")
                .withArgs(newBuyTax, newSellTax);
            
            const [buyTax, sellTax] = await token.getTaxRates();
            expect(buyTax).to.equal(newBuyTax);
            expect(sellTax).to.equal(newSellTax);
        });
        
        it("应该拒绝设置过高的税率", async function () {
            const { token } = await loadFixture(deployTokenFixture);
            
            await expect(
                token.setTaxRates(3000, 2000) // 30%, 20% (超过25%上限)
            ).to.be.revertedWith("Buy tax too high");
            
            await expect(
                token.setTaxRates(1000, 3000)
            ).to.be.revertedWith("Sell tax too high");
        });
        
        it("owner应该能够修改税费分配比例", async function () {
            const { token } = await loadFixture(deployTokenFixture);
            
            // 新的分配：50%流动性，30%营销，10%开发，10%销毁
            await token.setTaxDistribution(5000, 3000, 1000, 1000);
            
            const [liq, mark, dev, burn] = await token.getTaxDistribution();
            expect(liq).to.equal(5000);
            expect(mark).to.equal(3000);
            expect(dev).to.equal(1000);
            expect(burn).to.equal(1000);
        });
        
        it("应该拒绝总和不等于100%的分配比例", async function () {
            const { token } = await loadFixture(deployTokenFixture);
            
            await expect(
                token.setTaxDistribution(5000, 3000, 1000, 500) // 总和95%
            ).to.be.revertedWith("Shares must sum to 10000");
        });
        
        it("owner应该能够更新税费钱包地址", async function () {
            const { token, user1, user2, user3 } = await loadFixture(deployTokenFixture);
            
            await expect(
                token.setTaxWallets(user1.address, user2.address, user3.address)
            ).to.emit(token, "TaxWalletsUpdated")
              .withArgs(user1.address, user2.address, user3.address);
            
            expect(await token.liquidityWallet()).to.equal(user1.address);
            expect(await token.marketingWallet()).to.equal(user2.address);
            expect(await token.devWallet()).to.equal(user3.address);
        });
    });
    
    // ============ 黑名单测试 ============
    
    describe("Blacklist", function () {
        it("owner应该能够将地址加入黑名单", async function () {
            const { token, user1 } = await loadFixture(deployTokenFixture);
            
            await expect(token.setBlacklist(user1.address, true))
                .to.emit(token, "BlacklistUpdated")
                .withArgs(user1.address, true);
            
            expect(await token.isBlacklisted(user1.address)).to.be.true;
        });
        
        it("应该阻止黑名单地址进行转账", async function () {
            const { token, owner, user1, user2 } = await loadFixture(deployTokenFixture);
            
            await token.enableTrading();
            await token.transfer(user1.address, ethers.parseEther("1000"));
            
            // 将user1加入黑名单
            await token.setBlacklist(user1.address, true);
            
            await expect(
                token.connect(user1).transfer(user2.address, ethers.parseEther("100"))
            ).to.be.revertedWith("Blacklisted address");
        });
        
        it("应该能够批量设置黑名单", async function () {
            const { token, user1, user2, user3 } = await loadFixture(deployTokenFixture);
            
            await token.setBlacklistBatch(
                [user1.address, user2.address, user3.address],
                true
            );
            
            expect(await token.isBlacklisted(user1.address)).to.be.true;
            expect(await token.isBlacklisted(user2.address)).to.be.true;
            expect(await token.isBlacklisted(user3.address)).to.be.true;
        });
        
        it("应该阻止将owner加入黑名单", async function () {
            const { token, owner } = await loadFixture(deployTokenFixture);
            
            // 尝试将owner加入黑名单（会被require阻止）
            await expect(
                token.setBlacklist(owner.address, true)
            ).to.be.revertedWith("Cannot blacklist owner");
            
            // owner不应该被加入黑名单
            expect(await token.isBlacklisted(owner.address)).to.be.false;
        });
    });
    
    // ============ 权限控制测试 ============
    
    describe("Access Control", function () {
        it("非owner不应该能够修改税率", async function () {
            const { token, user1 } = await loadFixture(deployTokenFixture);
            
            await expect(
                token.connect(user1).setTaxRates(100, 200)
            ).to.be.reverted;
        });
        
        it("非owner不应该能够修改交易限制", async function () {
            const { token, user1 } = await loadFixture(deployTokenFixture);
            
            await expect(
                token.connect(user1).setLimits(
                    ethers.parseEther("1000000"),
                    ethers.parseEther("5000000")
                )
            ).to.be.reverted;
        });
        
        it("非owner不应该能够启用交易", async function () {
            const { token, user1 } = await loadFixture(deployTokenFixture);
            
            await expect(
                token.connect(user1).enableTrading()
            ).to.be.reverted;
        });
        
        it("非owner不应该能够设置黑名单", async function () {
            const { token, user1, user2 } = await loadFixture(deployTokenFixture);
            
            await expect(
                token.connect(user1).setBlacklist(user2.address, true)
            ).to.be.reverted;
        });
    });
    
    // ============ 启用交易测试 ============
    
    describe("Trading Enablement", function () {
        it("应该能够启用交易", async function () {
            const { token } = await loadFixture(deployTokenFixture);
            
            expect(await token.tradingEnabled()).to.be.false;
            
            await expect(token.enableTrading())
                .to.emit(token, "TradingEnabled");
            
            expect(await token.tradingEnabled()).to.be.true;
        });
        
        it("不应该允许重复启用交易", async function () {
            const { token } = await loadFixture(deployTokenFixture);
            
            await token.enableTrading();
            
            await expect(
                token.enableTrading()
            ).to.be.revertedWith("Trading already enabled");
        });
    });
    
    // ============ 免税/免限制测试 ============
    
    describe("Exclusions", function () {
        it("owner应该能够设置免税地址", async function () {
            const { token, user1 } = await loadFixture(deployTokenFixture);
            
            await token.setExcludeFromFees(user1.address, true);
            expect(await token.isExcludedFromFees(user1.address)).to.be.true;
            
            await token.setExcludeFromFees(user1.address, false);
            expect(await token.isExcludedFromFees(user1.address)).to.be.false;
        });
        
        it("owner应该能够设置免限制地址", async function () {
            const { token, user1 } = await loadFixture(deployTokenFixture);
            
            await token.setExcludeFromLimits(user1.address, true);
            
            // 验证免限制生效（可以接收超过maxWallet的代币）
            await token.enableTrading();
            const maxWallet = await token.maxWalletAmount();
            const exceedAmount = maxWallet + ethers.parseEther("1000");
            
            await expect(token.transfer(user1.address, exceedAmount)).to.not.be.reverted;
        });
    });
    
    // ============ 边界条件测试 ============
    
    describe("Edge Cases", function () {
        it("应该拒绝零地址转账", async function () {
            const { token } = await loadFixture(deployTokenFixture);
            
            await expect(
                token.transfer(ethers.ZeroAddress, ethers.parseEther("100"))
            ).to.be.reverted; // OpenZeppelin 5.0使用自定义错误
        });
        
        it("应该拒绝零金额转账", async function () {
            const { token, user1 } = await loadFixture(deployTokenFixture);
            
            await expect(
                token.transfer(user1.address, 0)
            ).to.be.revertedWith("Transfer amount must be greater than zero");
        });
        
        it("应该能够正确处理小额转账", async function () {
            const { token, user1 } = await loadFixture(deployTokenFixture);
            
            await token.enableTrading();
            const smallAmount = 1n; // 1 wei
            
            await expect(token.transfer(user1.address, smallAmount)).to.not.be.reverted;
        });
    });
    
    // ============ Gas优化测试 ============
    
    describe("Gas Optimization", function () {
        it("应该记录普通转账的Gas消耗", async function () {
            const { token, owner, user1 } = await loadFixture(deployTokenFixture);
            
            await token.enableTrading();
            const tx = await token.transfer(user1.address, ethers.parseEther("1000"));
            const receipt = await tx.wait();
            
            console.log(`普通转账 Gas消耗: ${receipt.gasUsed.toString()}`);
        });
    });
});

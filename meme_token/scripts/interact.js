const { ethers } = require("hardhat");

/**
 * 合约交互示例脚本
 * 展示如何与已部署的ShibaMemeToken合约进行交互
 */
async function main() {
    console.log("========================================");
    console.log("ShibaMemeToken 合约交互示例");
    console.log("========================================\n");
    
    // ============ 配置 ============
    
    const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS || "YOUR_TOKEN_ADDRESS";
    const [owner] = await ethers.getSigners();
    
    console.log("📍 操作账户:", owner.address);
    console.log("📍 合约地址:", TOKEN_ADDRESS);
    console.log();
    
    // ============ 获取合约实例 ============
    
    const token = await ethers.getContractAt("ShibaMemeToken", TOKEN_ADDRESS);
    
    // ============ 查询基本信息 ============
    
    console.log("📊 代币基本信息:");
    console.log("   名称:", await token.name());
    console.log("   符号:", await token.symbol());
    console.log("   总供应量:", ethers.formatEther(await token.totalSupply()));
    console.log("   Owner余额:", ethers.formatEther(await token.balanceOf(owner.address)));
    console.log();
    
    // ============ 查询税费配置 ============
    
    console.log("💸 税费配置:");
    const [buyTax, sellTax] = await token.getTaxRates();
    console.log("   买入税:", buyTax.toString(), "基点 (" + (Number(buyTax) / 100).toFixed(2) + "%)");
    console.log("   卖出税:", sellTax.toString(), "基点 (" + (Number(sellTax) / 100).toFixed(2) + "%)");
    
    const [liq, mark, dev, burn] = await token.getTaxDistribution();
    console.log("   流动性份额:", (Number(liq) / 100).toFixed(2) + "%");
    console.log("   营销份额:", (Number(mark) / 100).toFixed(2) + "%");
    console.log("   开发份额:", (Number(dev) / 100).toFixed(2) + "%");
    console.log("   销毁份额:", (Number(burn) / 100).toFixed(2) + "%");
    console.log();
    
    // ============ 查询交易限制 ============
    
    console.log("🚦 交易限制:");
    const [maxTx, maxWallet, cooldown] = await token.getLimits();
    console.log("   限制启用:", await token.limitsEnabled());
    console.log("   最大交易额:", ethers.formatEther(maxTx));
    console.log("   最大持有量:", ethers.formatEther(maxWallet));
    console.log("   冷却期:", cooldown.toString(), "秒");
    console.log();
    
    // ============ 查询交易状态 ============
    
    console.log("🔄 交易状态:");
    console.log("   交易已启用:", await token.tradingEnabled());
    const tradingTime = await token.tradingEnabledTimestamp();
    if (tradingTime > 0) {
        console.log("   启用时间:", new Date(Number(tradingTime) * 1000).toLocaleString());
    }
    console.log();
    
    // ============ 查询Uniswap信息 ============
    
    console.log("🔗 Uniswap信息:");
    console.log("   Router地址:", await token.uniswapV2Router());
    console.log("   交易对地址:", await token.uniswapV2Pair());
    console.log("   自动流动性启用:", await token.swapAndLiquifyEnabled());
    console.log("   Swap阈值:", ethers.formatEther(await token.swapThreshold()));
    console.log("   待处理税费:", ethers.formatEther(await token.getPendingTaxTokens()));
    console.log();
    
    // ============ 管理功能示例 ============
    
    console.log("========================================");
    console.log("🛠️  管理功能示例 (取消注释以执行):");
    console.log("========================================\n");
    
    // 示例1：修改税率
    console.log("// 修改税率为 买入3% / 卖出8%");
    console.log("// await token.setTaxRates(300, 800);");
    console.log();
    
    // 示例2：修改税费分配
    console.log("// 修改税费分配为 流动性50% / 营销30% / 开发10% / 销毁10%");
    console.log("// await token.setTaxDistribution(5000, 3000, 1000, 1000);");
    console.log();
    
    // 示例3：调整交易限制
    console.log("// 调整最大交易额为总供应量的1%");
    console.log("// const newMaxTx = (await token.totalSupply()) * 10n / 1000n;");
    console.log("// const newMaxWallet = (await token.totalSupply()) * 30n / 1000n;");
    console.log("// await token.setLimits(newMaxTx, newMaxWallet);");
    console.log();
    
    // 示例4：设置免税地址
    console.log("// 设置某地址免税");
    console.log("// const exemptAddress = '0x...';");
    console.log("// await token.setExcludeFromFees(exemptAddress, true);");
    console.log();
    
    // 示例5：添加黑名单
    console.log("// 添加地址到黑名单");
    console.log("// const blacklistAddress = '0x...';");
    console.log("// await token.setBlacklist(blacklistAddress, true);");
    console.log();
    
    // 示例6：启用交易
    console.log("// 启用交易（只能执行一次）");
    console.log("// await token.enableTrading();");
    console.log();
    
    // 示例7：禁用交易限制
    console.log("// 禁用交易限制（通常在项目成熟后）");
    console.log("// await token.setLimitsEnabled(false);");
    console.log();
    
    // 示例8：手动触发swap
    console.log("// 手动触发税费分配");
    console.log("// await token.manualSwapAndDistribute();");
    console.log();
    
    // 示例9：更新税费钱包
    console.log("// 更新税费接收钱包");
    console.log("// const newLiqWallet = '0x...';");
    console.log("// const newMarkWallet = '0x...';");
    console.log("// const newDevWallet = '0x...';");
    console.log("// await token.setTaxWallets(newLiqWallet, newMarkWallet, newDevWallet);");
    console.log();
    
    // 示例10：调整冷却期
    console.log("// 调整冷却期为30秒");
    console.log("// await token.setCooldown(30);");
    console.log();
    
    console.log("========================================");
    console.log("✨ 查询完成!");
    console.log("========================================");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ 执行失败:");
        console.error(error);
        process.exit(1);
    });

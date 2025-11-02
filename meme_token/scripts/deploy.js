const { ethers } = require("hardhat");

/**
 * 部署ShibaMemeToken合约的脚本
 * 
 * 使用方法：
 * - 本地测试网：npx hardhat run scripts/deploy.js
 * - Sepolia测试网：npx hardhat run scripts/deploy.js --network sepolia
 */
async function main() {
    console.log("========================================");
    console.log("开始部署 SHIB风格Meme代币合约");
    console.log("========================================\n");
    
    // 获取部署者账户
    const [deployer] = await ethers.getSigners();
    console.log("📍 部署账户:", deployer.address);
    
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("💰 账户余额:", ethers.formatEther(balance), "ETH\n");
    
    // ============ 配置参数 ============
    
    const config = {
        // 代币基本信息
        name: "Shiba Meme Token",
        symbol: "SHIBM",
        totalSupply: ethers.parseEther("1000000000000"), // 1万亿代币
        
        // Uniswap V2 Router地址
        // Ethereum Mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // Sepolia Testnet: 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
        routerAddress: process.env.UNISWAP_ROUTER || "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        
        // 税费接收钱包（请根据实际情况修改）
        marketingWallet: process.env.MARKETING_WALLET || deployer.address,
        devWallet: process.env.DEV_WALLET || deployer.address
    };
    
    console.log("📋 部署配置:");
    console.log("   代币名称:", config.name);
    console.log("   代币符号:", config.symbol);
    console.log("   总供应量:", ethers.formatEther(config.totalSupply));
    console.log("   Router地址:", config.routerAddress);
    console.log("   营销钱包:", config.marketingWallet);
    console.log("   开发钱包:", config.devWallet);
    console.log();
    
    // ============ 部署合约 ============
    
    console.log("🚀 开始部署合约...\n");
    
    const ShibaMemeToken = await ethers.getContractFactory("ShibaMemeToken");
    
    const token = await ShibaMemeToken.deploy(
        config.name,
        config.symbol,
        config.totalSupply,
        config.routerAddress,
        config.marketingWallet,
        config.devWallet
    );
    
    await token.waitForDeployment();
    
    const tokenAddress = await token.getAddress();
    
    console.log("✅ 合约部署成功!");
    console.log("📍 合约地址:", tokenAddress);
    console.log();
    
    // ============ 获取交易对地址 ============
    
    const pairAddress = await token.uniswapV2Pair();
    console.log("🔗 Uniswap交易对地址:", pairAddress);
    console.log();
    
    // ============ 验证初始配置 ============
    
    console.log("🔍 验证合约配置:");
    
    const [buyTax, sellTax] = await token.getTaxRates();
    console.log("   买入税:", buyTax.toString(), "基点 (", (Number(buyTax) / 100).toFixed(2), "%)");
    console.log("   卖出税:", sellTax.toString(), "基点 (", (Number(sellTax) / 100).toFixed(2), "%)");
    
    const [maxTx, maxWallet, cooldown] = await token.getLimits();
    console.log("   最大交易额:", ethers.formatEther(maxTx), "代币");
    console.log("   最大持有量:", ethers.formatEther(maxWallet), "代币");
    console.log("   冷却期:", cooldown.toString(), "秒");
    
    const ownerBalance = await token.balanceOf(deployer.address);
    console.log("   Owner余额:", ethers.formatEther(ownerBalance), "代币");
    console.log();
    
    // ============ 部署后提示 ============
    
    console.log("========================================");
    console.log("📝 后续操作步骤:");
    console.log("========================================\n");
    
    console.log("1️⃣  添加流动性:");
    console.log("   - 访问 Uniswap 或 直接调用合约");
    console.log("   - 添加 SHIBM/ETH 流动性池");
    console.log("   - 建议初始流动性：至少 1 ETH\n");
    
    console.log("2️⃣  启用交易:");
    console.log("   await token.enableTrading();\n");
    
    console.log("3️⃣  配置税费（可选）:");
    console.log("   await token.setTaxRates(buyTax, sellTax);");
    console.log("   await token.setTaxDistribution(liq, mark, dev, burn);\n");
    
    console.log("4️⃣  调整限制（可选）:");
    console.log("   await token.setLimits(maxTx, maxWallet);");
    console.log("   await token.setCooldown(seconds);\n");
    
    console.log("5️⃣  验证合约（推荐）:");
    console.log("   npx hardhat verify --network <network>", tokenAddress);
    console.log("   后续参数:");
    console.log("   \"" + config.name + "\"");
    console.log("   \"" + config.symbol + "\"");
    console.log("   \"" + config.totalSupply.toString() + "\"");
    console.log("   \"" + config.routerAddress + "\"");
    console.log("   \"" + config.marketingWallet + "\"");
    console.log("   \"" + config.devWallet + "\"");
    console.log();
    
    console.log("⚠️  重要提示:");
    console.log("   - 添加流动性后请锁定LP代币");
    console.log("   - 启用交易前确保已添加流动性");
    console.log("   - 建议逐步放宽交易限制");
    console.log("   - 定期检查合约安全性");
    console.log();
    
    // ============ 保存部署信息 ============
    
    const deploymentInfo = {
        network: (await ethers.provider.getNetwork()).name,
        chainId: (await ethers.provider.getNetwork()).chainId,
        deployer: deployer.address,
        timestamp: new Date().toISOString(),
        contracts: {
            token: tokenAddress,
            pair: pairAddress
        },
        config: {
            name: config.name,
            symbol: config.symbol,
            totalSupply: config.totalSupply.toString(),
            routerAddress: config.routerAddress,
            marketingWallet: config.marketingWallet,
            devWallet: config.devWallet
        },
        initialSettings: {
            buyTax: buyTax.toString(),
            sellTax: sellTax.toString(),
            maxTxAmount: maxTx.toString(),
            maxWalletAmount: maxWallet.toString(),
            cooldownPeriod: cooldown.toString()
        }
    };
    
    const fs = require("fs");
    const path = require("path");
    
    const deploymentsDir = path.join(__dirname, "..", "deployments");
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir);
    }
    
    const filename = `deployment-${Date.now()}.json`;
    const filepath = path.join(deploymentsDir, filename);
    
    fs.writeFileSync(filepath, JSON.stringify(deploymentInfo, null, 2));
    
    console.log("💾 部署信息已保存至:", filepath);
    console.log();
    console.log("========================================");
    console.log("✨ 部署完成!");
    console.log("========================================");
}

// 执行部署
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ 部署失败:");
        console.error(error);
        process.exit(1);
    });

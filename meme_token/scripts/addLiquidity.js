const { ethers } = require("hardhat");

/**
 * 添加流动性的辅助脚本
 * 
 * 使用前请确保：
 * 1. 已部署代币合约
 * 2. 有足够的代币和ETH余额
 */
async function main() {
    console.log("========================================");
    console.log("添加Uniswap V2流动性");
    console.log("========================================\n");
    
    // ============ 配置 ============
    
    // 从环境变量或手动设置
    const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS || "YOUR_TOKEN_ADDRESS";
    const ROUTER_ADDRESS = process.env.UNISWAP_ROUTER || "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
    
    // 流动性数量（根据实际情况调整）
    const TOKEN_AMOUNT = ethers.parseEther("500000000000"); // 5000亿代币
    const ETH_AMOUNT = ethers.parseEther("1"); // 1 ETH
    
    const [signer] = await ethers.getSigners();
    console.log("📍 操作账户:", signer.address);
    console.log();
    
    // ============ 获取合约实例 ============
    
    const token = await ethers.getContractAt("ShibaMemeToken", TOKEN_ADDRESS);
    const routerABI = [
        "function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity)"
    ];
    const router = new ethers.Contract(ROUTER_ADDRESS, routerABI, signer);
    
    console.log("📋 配置信息:");
    console.log("   代币地址:", TOKEN_ADDRESS);
    console.log("   Router地址:", ROUTER_ADDRESS);
    console.log("   添加代币数量:", ethers.formatEther(TOKEN_AMOUNT));
    console.log("   添加ETH数量:", ethers.formatEther(ETH_AMOUNT));
    console.log();
    
    // ============ 检查余额 ============
    
    const tokenBalance = await token.balanceOf(signer.address);
    const ethBalance = await ethers.provider.getBalance(signer.address);
    
    console.log("💰 账户余额:");
    console.log("   代币:", ethers.formatEther(tokenBalance));
    console.log("   ETH:", ethers.formatEther(ethBalance));
    console.log();
    
    if (tokenBalance < TOKEN_AMOUNT) {
        console.error("❌ 代币余额不足!");
        return;
    }
    
    if (ethBalance < ETH_AMOUNT) {
        console.error("❌ ETH余额不足!");
        return;
    }
    
    // ============ 授权代币 ============
    
    console.log("🔐 授权Router使用代币...");
    const approveTx = await token.approve(ROUTER_ADDRESS, TOKEN_AMOUNT);
    await approveTx.wait();
    console.log("✅ 授权完成\n");
    
    // ============ 添加流动性 ============
    
    console.log("💧 添加流动性...");
    
    const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20分钟后过期
    
    const addLiquidityTx = await router.addLiquidityETH(
        TOKEN_ADDRESS,
        TOKEN_AMOUNT,
        0, // amountTokenMin (设为0，生产环境应设置滑点保护)
        0, // amountETHMin
        signer.address,
        deadline,
        { value: ETH_AMOUNT }
    );
    
    console.log("⏳ 等待交易确认...");
    const receipt = await addLiquidityTx.wait();
    
    console.log("✅ 流动性添加成功!");
    console.log("📍 交易哈希:", receipt.hash);
    console.log();
    
    // ============ 获取交易对地址 ============
    
    const pairAddress = await token.uniswapV2Pair();
    console.log("🔗 交易对地址:", pairAddress);
    console.log();
    
    // ============ 后续步骤提示 ============
    
    console.log("========================================");
    console.log("📝 后续重要步骤:");
    console.log("========================================\n");
    
    console.log("⚠️  极其重要：锁定流动性!");
    console.log();
    console.log("1️⃣  推荐使用以下平台锁定LP代币:");
    console.log("   • Unicrypt (https://www.unicrypt.network/)");
    console.log("   • Team Finance (https://www.team.finance/)");
    console.log("   • PinkSale Lock (https://www.pinksale.finance/)");
    console.log();
    console.log("2️⃣  锁定参数建议:");
    console.log("   • 锁定时长：至少6个月（推荐1年+）");
    console.log("   • 锁定比例：100%");
    console.log("   • 解锁方式：线性解锁或阶梯解锁");
    console.log();
    console.log("3️⃣  锁定后请:");
    console.log("   • 在项目文档中公开锁定证明");
    console.log("   • 在社交媒体分享锁定链接");
    console.log("   • 将锁定信息添加到网站");
    console.log();
    
    console.log("========================================");
    console.log("✨ 流动性添加完成!");
    console.log("========================================");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ 执行失败:");
        console.error(error);
        process.exit(1);
    });

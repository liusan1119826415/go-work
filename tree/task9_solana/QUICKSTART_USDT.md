# Solana USDT 转账快速开始

## 🚀 快速开始步骤

### 1️⃣ 更新依赖
```powershell
cd d:\project\go-work\tree\task9_solana

# 更新 SDK（确保支持 SPL Token）
go get -u github.com/blocto/solana-go-sdk@latest

# 清理并重新整理依赖
go clean -modcache
go mod tidy
```

### 2️⃣ 配置 transfer_usdt.go

打开 `transfer_usdt.go` 文件，修改以下配置：

#### a) 设置私钥（第 22 行）
```go
privateKeyBase58 := "你的Base58格式私钥"
```

#### b) 选择网络和 USDT Mint 地址（第 28-32 行）

**主网（Mainnet）- 真实 USDT：**
```go
// 1. 修改 RPC（第 18 行）
c := client.NewClient("https://api.mainnet-beta.solana.com")

// 2. 使用主网 USDT Mint
usdtMint := common.PublicKeyFromString("Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB")
```

**测试网（Devnet）- 测试代币：**
```go
// 1. 保持 RPC 不变（第 18 行）
c := client.NewClient("https://api.devnet.solana.com")

// 2. 创建测试代币或使用现有测试代币 Mint
usdtMint := common.PublicKeyFromString("你的测试代币Mint地址")
```

#### c) 设置接收方（第 35 行）
```go
receiverAddress := common.PublicKeyFromString("接收方钱包地址")
```

#### d) 设置转账金额（第 99 行）
```go
// USDT 有 6 位小数
transferAmount := uint64(1_000_000)      // 1 USDT
// transferAmount := uint64(5_500_000)   // 5.5 USDT
// transferAmount := uint64(100_000_000) // 100 USDT
```

### 3️⃣ 运行程序
```powershell
# 清理编译缓存
go clean

# 运行程序
go run .
```

选择选项 **7** - 转账 USDT

## 📝 完整配置示例

### 示例 1：Devnet 测试
```go
// transfer_usdt.go

func TransferUSDT() {
    // RPC - 测试网
    c := client.NewClient("https://api.devnet.solana.com")
    
    // 你的私钥
    privateKeyBase58 := "5JK...你的私钥...xyz"
    
    // 测试代币 Mint（需要先创建）
    usdtMint := common.PublicKeyFromString("Gh9ZwE...测试代币Mint...abc")
    
    // 接收方地址
    receiverAddress := common.PublicKeyFromString("8Ux1qSM...接收方...H4J")
    
    // 转账 1 个测试代币
    transferAmount := uint64(1_000_000)
    
    // ... 其余代码不变
}
```

### 示例 2：Mainnet 真实 USDT
```go
// transfer_usdt.go

func TransferUSDT() {
    // RPC - 主网
    c := client.NewClient("https://api.mainnet-beta.solana.com")
    
    // 你的私钥（⚠️ 确保账户安全！）
    privateKeyBase58 := "5JK...你的私钥...xyz"
    
    // USDT Mainnet Mint
    usdtMint := common.PublicKeyFromString("Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB")
    
    // 接收方地址
    receiverAddress := common.PublicKeyFromString("目标钱包地址")
    
    // 转账 10 USDT
    transferAmount := uint64(10_000_000)
    
    // ... 其余代码不变
}
```

## 🔍 如何创建测试代币（Devnet）

### 方法一：使用 Solana CLI

```bash
# 安装 Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# 设置为 Devnet
solana config set --url https://api.devnet.solana.com

# 创建钱包（如果还没有）
solana-keygen new

# 获取测试 SOL
solana airdrop 2

# 创建 SPL Token（6位小数，类似USDT）
spl-token create-token --decimals 6

# 记录输出的 Mint 地址，例如：
# Creating token Gh9ZwEmdLJ8626syfAwfHcWrQQY78VmXYN5HK8MQhfWN

# 为自己创建 Token 账户
spl-token create-account Gh9ZwEmdLJ8626syfAwfHcWrQQY78VmXYN5HK8MQhfWN

# 铸造 1000 个测试币给自己
spl-token mint Gh9ZwEmdLJ8626syfAwfHcWrQQY78VmXYN5HK8MQhfWN 1000
```

### 方法二：使用在线工具

访问：https://spl-token-ui.vercel.app/
- 连接 Phantom 钱包
- 选择 Devnet
- 创建新代币
- 设置 6 位小数

## ✅ 验证配置

运行程序后应该看到：

```
执行: 转账 USDT (SPL Token)
发送方地址: 3PixJx4woQaYuwpTVX9Trg5tYsZ3njd1McXfj2KKR63D
发送方 USDT 账户: AaB1Cc2Dd...
接收方 USDT 账户: XxY3Zz4Ww...
发送方 USDT 余额: 100.000000

正在发送 USDT 转账交易...
转账金额: 1.000000 USDT

✅ USDT 转账成功！
交易哈希: 5jK3xL...
在浏览器查看: https://explorer.solana.com/tx/5jK3xL...?cluster=devnet
```

## ⚠️ 常见问题

### 问题 1：编译错误 "missing go.sum entry"
```bash
解决：
go get -u github.com/blocto/solana-go-sdk@latest
go mod tidy
```

### 问题 2："insufficient funds"
```
原因：SOL 余额不足支付手续费
解决：确保账户有至少 0.01 SOL
```

### 问题 3："account not found" 或 Token 账户不存在
```
原因：接收方的 USDT Token 账户还未创建
解决：程序会自动创建，确保有足够 SOL（约 0.002 SOL）
```

### 问题 4："insufficient token balance"
```
原因：USDT 余额不足
解决：确保账户有足够的 USDT
```

## 🔐 安全检查清单

- [ ] ✅ 先在 Devnet 测试
- [ ] ✅ 私钥不要硬编码在代码中
- [ ] ✅ 不要将包含私钥的代码上传到 GitHub
- [ ] ✅ 转账金额和接收地址仔细核对
- [ ] ✅ 主网操作前三思而行

## 📚 USDT 金额对照表

| USDT 数量 | 最小单位值 | 代码写法 |
|----------|-----------|---------|
| 0.01 USDT | 10,000 | `uint64(10_000)` |
| 0.1 USDT | 100,000 | `uint64(100_000)` |
| 1 USDT | 1,000,000 | `uint64(1_000_000)` |
| 10 USDT | 10,000,000 | `uint64(10_000_000)` |
| 100 USDT | 100,000,000 | `uint64(100_000_000)` |
| 1000 USDT | 1,000,000,000 | `uint64(1_000_000_000)` |

## 🎯 下一步

配置完成后，就可以：
1. 运行 `go run .`
2. 选择选项 7
3. 查看交易结果
4. 在区块链浏览器验证交易

祝你成功！🎉

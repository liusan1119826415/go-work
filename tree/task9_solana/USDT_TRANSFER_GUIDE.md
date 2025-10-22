# Solana USDT 转账完整指南

## 📚 什么是 SPL Token？

在 Solana 上，USDT 不是原生代币，而是一个 **SPL Token**（Solana Program Library Token）。这类似于以太坊上的 ERC-20 代币。

## 🔑 关键概念

### 1. Mint Address（铸币地址）
每个 SPL Token 都有一个唯一的 Mint 地址，代表这个代币的"合约"。

**USDT Mainnet Mint 地址：**
```
Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB
```

### 2. Associated Token Account (ATA)
- 每个钱包地址需要一个专门的 Token 账户来持有 SPL Token
- ATA 是一个确定性派生的账户地址
- 格式：由钱包地址 + Mint 地址派生而来

### 3. USDT 精度
- USDT 有 **6 位小数**
- 1 USDT = 1,000,000 (最小单位)
- 转账 1.5 USDT = 1,500,000

## 📦 安装依赖

```bash
cd d:\project\go-work\tree\task9_solana

# 更新 SDK 到最新版本
go get -u github.com/blocto/solana-go-sdk

# 整理依赖
go mod tidy
```

## 🚀 使用步骤

### 第一步：修改配置

打开 `transfer_usdt.go`，修改以下内容：

#### 1. 填入你的私钥（第 22 行）
```go
privateKeyBase58 := "你的Base58格式私钥字符串"
```

#### 2. 设置 USDT Mint 地址（第 32 行）

**Mainnet（主网）：**
```go
usdtMint := common.PublicKeyFromString("Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB")
```

**Devnet（测试网）：**
你需要使用测试网的 USDT 或创建自己的测试代币。
```go
// 使用测试代币地址
usdtMint := common.PublicKeyFromString("你的测试代币Mint地址")
```

#### 3. 设置接收方地址（第 35 行）
```go
receiverAddress := common.PublicKeyFromString("接收方的钱包地址")
```

#### 4. 设置转账金额（第 99 行）
```go
// 转账 1 USDT
transferAmount := uint64(1_000_000)

// 转账 10 USDT
transferAmount := uint64(10_000_000)

// 转账 0.5 USDT
transferAmount := uint64(500_000)
```

### 第二步：更新 main.go 菜单

打开 `main.go`，添加 USDT 转账选项：

```go
fmt.Println("7. 转账 USDT (SPL Token)")
```

在 switch 语句中添加：
```go
case "7":
    fmt.Println("\n执行: 转账 USDT")
    TransferUSDT()
```

### 第三步：运行程序

```bash
go run .
```

选择选项 **7** 执行 USDT 转账。

## 📝 程序执行流程

```
1. 从私钥导入账户
   ↓
2. 查找发送方的 USDT Token 账户 (ATA)
   ↓
3. 查找接收方的 USDT Token 账户 (ATA)
   ↓
4. 检查发送方 USDT 余额
   ↓
5. 检查接收方 Token 账户是否存在
   ↓
6. 如果不存在，创建接收方 Token 账户
   ↓
7. 执行转账
   ↓
8. 返回交易哈希
```

## 💰 如何获取测试网 USDT？

### 方案一：使用 SPL Token Faucet
访问：https://spl-token-faucet.com/

### 方案二：创建自己的测试代币

```bash
# 安装 Solana CLI
# 创建测试代币
spl-token create-token --decimals 6

# 创建 Token 账户
spl-token create-account <TOKEN_MINT_ADDRESS>

# 铸造代币
spl-token mint <TOKEN_MINT_ADDRESS> 1000
```

## 🔍 完整示例

### Mainnet 转账示例

```go
// 发送方私钥
privateKeyBase58 := "你的私钥"

// USDT Mainnet Mint
usdtMint := common.PublicKeyFromString("Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB")

// 接收方地址
receiverAddress := common.PublicKeyFromString("目标钱包地址")

// 转账 10 USDT
transferAmount := uint64(10_000_000)
```

### Devnet 测试示例

```go
// 使用测试代币
usdtMint := common.PublicKeyFromString("你创建的测试代币Mint地址")

// 转账 1 个测试代币
transferAmount := uint64(1_000_000)
```

## ⚠️ 常见错误

### 1. "insufficient funds"
- **原因**：SOL 余额不足支付手续费
- **解决**：确保账户有至少 0.01 SOL

### 2. "account not found"
- **原因**：Token 账户不存在
- **解决**：程序会自动创建，确保有足够 SOL 支付创建费用（约 0.002 SOL）

### 3. "insufficient token balance"
- **原因**：USDT 余额不足
- **解决**：确保账户有足够的 USDT

## 🌐 切换到 Mainnet

修改 RPC 端点（第 18 行）：

```go
// Devnet
c := client.NewClient("https://api.devnet.solana.com")

// Mainnet
c := client.NewClient("https://api.mainnet-beta.solana.com")
```

## 📊 查看交易

交易成功后，访问：
```
https://explorer.solana.com/tx/<交易哈希>?cluster=devnet
```

主网：
```
https://explorer.solana.com/tx/<交易哈希>
```

## 🔐 安全提示

1. ⚠️ **永远不要**在代码中硬编码主网私钥
2. ⚠️ **永远不要**将包含私钥的代码上传到 GitHub
3. ✅ 使用环境变量或配置文件存储私钥
4. ✅ 在主网操作前，先在 Devnet 充分测试

## 📚 相关资源

- [SPL Token 文档](https://spl.solana.com/token)
- [Solana Web3.js 指南](https://docs.solana.com/developing/clients/javascript-api)
- [USDT on Solana](https://tether.to/en/transparency/)

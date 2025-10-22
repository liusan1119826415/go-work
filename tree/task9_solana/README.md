# Solana Go SDK 示例项目

这个项目展示了如何使用 Go 语言与 Solana 区块链进行交互，包括创建交易、查询区块信息、账户管理等功能。

## 📁 项目文件

```
task9_solana/
├── README.md                      # 本文件
├── SOLANA_TRANSACTION_GUIDE.md   # 详细交易创建指南
├── go.mod                         # Go 模块配置
├── main.go                        # 主程序入口
├── select_block.go               # 区块查询示例
├── transaction_examples.go       # 交易创建示例
└── create_transaction.go         # 交易创建工具函数
```

## 🚀 快速开始

### 1. 安装依赖

```bash
cd d:\project\go-work\tree\task9_solana
go mod tidy
```

这会自动下载 `github.com/blocto/solana-go-sdk` 包。

### 2. 运行示例

#### 方式 A: 运行主程序（推荐）
```bash
go run main.go select_block.go transaction_examples.go
```

这会启动一个交互式菜单，包含以下选项：
- 查询区块信息
- 简单转账交易
- 创建账户交易
- 批量转账交易
- 查询账户余额

#### 方式 B: 运行单个示例
```bash
# 查询区块信息
go run select_block.go

# 运行交易示例
go run transaction_examples.go
```

## 📚 核心功能

### 1. 创建 Solana 交易的基本步骤

```go
import (
    "github.com/blocto/solana-go-sdk/client"
    "github.com/blocto/solana-go-sdk/types"
    "github.com/blocto/solana-go-sdk/program/system"
)

// 1. 创建客户端
c := client.NewClient("https://api.devnet.solana.com")

// 2. 创建账户
sender := types.NewAccount()
receiver := types.NewAccount()

// 3. 获取最新区块哈希
response, _ := c.GetLatestBlockhash(context.Background())

// 4. 创建转账指令
instruction := system.Transfer(system.TransferParam{
    From:   sender.PublicKey,
    To:     receiver.PublicKey,
    Amount: 1_000_000, // lamports
})

// 5. 构建交易消息
message := types.NewMessage(types.NewMessageParam{
    FeePayer:        sender.PublicKey,
    RecentBlockhash: response.Blockhash,
    Instructions:    []types.Instruction{instruction},
})

// 6. 创建并签名交易
tx, _ := types.NewTransaction(types.NewTransactionParam{
    Message: message,
    Signers: []types.Account{sender},
})

// 7. 发送交易
txHash, _ := c.SendTransaction(context.Background(), tx)
```

### 2. 查询区块信息

```go
// 获取当前区块高度
slot, _ := c.GetSlot(context.Background())

// 获取区块详情
block, _ := c.GetBlock(context.Background(), slot)
```

### 3. 查询账户余额

```go
balance, _ := c.GetBalance(context.Background(), address)
// 余额单位是 lamports (1 SOL = 1,000,000,000 lamports)
```

## 🔧 配置说明

### 网络选择

项目默认使用 **Devnet**（开发网络）：
```go
c := client.NewClient("https://api.devnet.solana.com")
```

你可以切换到其他网络：
```go
// Mainnet (主网)
c := client.NewClient("https://api.mainnet-beta.solana.com")

// Testnet (测试网)
c := client.NewClient("https://api.testnet.solana.com")
```

### 获取测试 SOL

在 Devnet 上，你可以使用空投功能获取测试 SOL：
```go
txHash, err := c.RequestAirdrop(
    context.Background(),
    account.PublicKey.ToBase58(),
    1e9, // 1 SOL = 1,000,000,000 lamports
)
```

## 📖 详细文档

查看 [`SOLANA_TRANSACTION_GUIDE.md`](./SOLANA_TRANSACTION_GUIDE.md) 获取：
- 完整的交易创建流程
- 常用指令参考
- 错误处理指南
- 安全最佳实践
- 调试技巧

## 🎯 示例说明

### SimpleTransfer() - 简单转账
展示最基本的 SOL 转账功能。

### CreateAccountTransaction() - 创建账户
展示如何创建新的 Solana 账户，包括租金豁免计算。

### BatchTransfer() - 批量转账
展示如何在一个交易中包含多个转账指令。

### QueryBlockInfo() - 查询区块
展示如何获取区块高度和区块详细信息。

### QueryAccountBalance() - 查询余额
展示如何查询账户的 SOL 余额。

## ⚠️ 注意事项

1. **私钥安全**
   - 永远不要在代码中硬编码私钥
   - 使用环境变量或安全的密钥管理系统

2. **网络选择**
   - 开发和测试请使用 Devnet 或 Testnet
   - 避免在主网上进行测试

3. **交易费用**
   - 每个交易需要支付少量 SOL 作为手续费
   - 确保账户有足够余额

4. **区块哈希有效期**
   - 区块哈希约在 150 个区块后过期
   - 如果交易未及时发送，需要重新获取

## 🛠️ 故障排查

### 编译错误

**错误**: `missing go.sum entry`
```bash
# 解决方案
go mod tidy
```

**错误**: `cannot find package`
```bash
# 确保安装了正确的包
go get github.com/blocto/solana-go-sdk@latest
```

### 运行时错误

**错误**: `blockhash not found`
- 原因：区块哈希已过期
- 解决：重新获取最新区块哈希

**错误**: `insufficient funds`
- 原因：账户余额不足
- 解决：在 Devnet 使用空投获取测试 SOL

## 📚 参考资源

- [Solana 官方文档](https://docs.solana.com/)
- [Solana Go SDK GitHub](https://github.com/blocto/solana-go-sdk)
- [Solana Explorer (Devnet)](https://explorer.solana.com/?cluster=devnet)
- [Solana Cookbook](https://solanacookbook.com/)

## 🎓 学习路径

1. ✅ **基础** - 创建交易、查询区块
2. 🔄 **进阶** - SPL Token 操作
3. 🚀 **高级** - 程序调用、PDA、跨程序调用

## 💡 下一步

完成基础示例后，可以尝试：
- 创建和管理 SPL Token
- 调用自定义 Solana 程序
- 实现 NFT 铸造
- 构建完整的 DApp 后端

---

**提示**：所有示例都使用 Devnet，可以安全测试，不会花费真实资金。

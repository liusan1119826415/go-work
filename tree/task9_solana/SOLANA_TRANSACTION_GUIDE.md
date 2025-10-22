# Solana Go SDK 交易创建指南

## 📋 目录
- [安装依赖](#安装依赖)
- [基础概念](#基础概念)
- [交易创建流程](#交易创建流程)
- [代码示例](#代码示例)
- [运行示例](#运行示例)

## 🚀 安装依赖

```bash
cd d:\project\go-work\tree\task9_solana
go get github.com/blocto/solana-go-sdk@latest
go mod tidy
```

## 📚 基础概念

### 1. Lamports
- Solana 的最小单位
- 1 SOL = 1,000,000,000 lamports
- 类似于以太坊的 wei

### 2. 交易结构
```
Transaction
├── Message
│   ├── FeePayer (手续费支付者)
│   ├── RecentBlockhash (最新区块哈希)
│   └── Instructions[] (指令列表)
└── Signatures[] (签名列表)
```

### 3. 常用网络
- **Mainnet**: https://api.mainnet-beta.solana.com
- **Devnet**: https://api.devnet.solana.com
- **Testnet**: https://api.testnet.solana.com

## 🔧 交易创建流程

### 步骤 1: 创建客户端
```go
import "github.com/blocto/solana-go-sdk/client"

c := client.NewClient("https://api.devnet.solana.com")
```

### 步骤 2: 创建或加载账户
```go
import "github.com/blocto/solana-go-sdk/types"

// 方式1: 生成新账户
newAccount := types.NewAccount()

// 方式2: 从私钥加载（需要实现）
// account := types.AccountFromBytes(privateKeyBytes)
```

### 步骤 3: 获取最新区块哈希
```go
response, err := c.GetLatestBlockhash(context.Background())
if err != nil {
    log.Fatal(err)
}
blockhash := response.Blockhash
```

### 步骤 4: 创建指令
```go
import "github.com/blocto/solana-go-sdk/program/system"

// 转账指令
instruction := system.Transfer(system.TransferParam{
    From:   sender.PublicKey,
    To:     receiver.PublicKey,
    Amount: 1_000_000, // lamports
})
```

### 步骤 5: 构建交易消息
```go
message := types.NewMessage(types.NewMessageParam{
    FeePayer:        sender.PublicKey,
    RecentBlockhash: blockhash,
    Instructions:    []types.Instruction{instruction},
})
```

### 步骤 6: 创建并签名交易
```go
tx, err := types.NewTransaction(types.NewTransactionParam{
    Message: message,
    Signers: []types.Account{sender}, // 签名者列表
})
```

### 步骤 7: 发送交易
```go
txHash, err := c.SendTransaction(context.Background(), tx)
if err != nil {
    log.Fatal(err)
}
fmt.Printf("交易哈希: %s\n", txHash)
```

## 📝 代码示例

### 示例 1: 简单转账
```go
// 见 transaction_examples.go 中的 SimpleTransfer()
```

### 示例 2: 创建账户
```go
// 见 transaction_examples.go 中的 CreateAccountTransaction()
```

### 示例 3: 批量转账
```go
// 见 transaction_examples.go 中的 BatchTransfer()
```

## ▶️ 运行示例

### 方式 1: 运行单个文件
```bash
# 运行转账示例
go run transaction_examples.go

# 运行区块查询
go run select_block.go
```

### 方式 2: 运行主程序
```bash
go run main.go
```

## 🔑 私钥管理

### 生成新密钥对
```go
account := types.NewAccount()
fmt.Printf("公钥: %s\n", account.PublicKey.ToBase58())
fmt.Printf("私钥: %v\n", account.PrivateKey)
```

### 从私钥恢复账户
```go
// 私钥是 64 字节的数组
privateKey := []byte{...} // 你的私钥字节
account := types.AccountFromBytes(privateKey)
```

### 安全建议
⚠️ **永远不要在代码中硬编码私钥！**

推荐做法:
1. 使用环境变量
2. 使用密钥文件（加密存储）
3. 使用硬件钱包

## 📊 常用 System Program 指令

### 1. Transfer (转账)
```go
system.Transfer(system.TransferParam{
    From:   sender.PublicKey,
    To:     receiver.PublicKey,
    Amount: 1_000_000,
})
```

### 2. CreateAccount (创建账户)
```go
system.CreateAccount(system.CreateAccountParam{
    From:     feePayer.PublicKey,
    New:      newAccount.PublicKey,
    Owner:    common.SystemProgramID,
    Lamports: rentExemption,
    Space:    0,
})
```

### 3. Allocate (分配空间)
```go
system.Allocate(system.AllocateParam{
    Account: account.PublicKey,
    Space:   165, // 字节数
})
```

### 4. Assign (分配所有者)
```go
system.Assign(system.AssignParam{
    Account: account.PublicKey,
    Owner:   programID,
})
```

## 🛠️ 常用工具函数

### 查询账户余额
```go
balance, err := c.GetBalance(context.Background(), account.PublicKey.ToBase58())
if err != nil {
    log.Fatal(err)
}
fmt.Printf("余额: %d lamports (%.9f SOL)\n", balance, float64(balance)/1e9)
```

### 查询交易状态
```go
tx, err := c.GetTransaction(context.Background(), txHash)
if err != nil {
    log.Fatal(err)
}
// 检查 tx.Meta.Err 判断交易是否成功
```

### 空投 SOL (仅限 Devnet/Testnet)
```go
txHash, err := c.RequestAirdrop(
    context.Background(),
    account.PublicKey.ToBase58(),
    1e9, // 1 SOL
)
```

## 🔍 调试技巧

### 1. 查看交易详情
访问浏览器: `https://explorer.solana.com/tx/[交易哈希]?cluster=devnet`

### 2. 模拟交易（不实际发送）
```go
result, err := c.SimulateTransaction(context.Background(), tx)
if err != nil {
    log.Fatal(err)
}
// 检查模拟结果
```

### 3. 获取交易费用
```go
fee, err := c.GetFeeForMessage(context.Background(), message)
if err != nil {
    log.Fatal(err)
}
fmt.Printf("预估手续费: %d lamports\n", fee)
```

## ⚠️ 常见错误

### 1. "blockhash not found"
- 原因: 区块哈希过期（约150个区块后过期）
- 解决: 重新获取最新的区块哈希

### 2. "insufficient funds"
- 原因: 账户余额不足
- 解决: 在 Devnet 使用空投功能获取测试 SOL

### 3. "invalid signature"
- 原因: 签名者不正确或缺少必要的签名
- 解决: 确保所有需要的账户都在 Signers 列表中

## 📖 参考资源

- [Solana 官方文档](https://docs.solana.com/)
- [Solana Go SDK GitHub](https://github.com/blocto/solana-go-sdk)
- [Solana Explorer](https://explorer.solana.com/)
- [Solana Cookbook](https://solanacookbook.com/)

## 🎯 下一步学习

1. **SPL Token 操作**
   - 创建代币
   - 铸造代币
   - 转账代币

2. **程序调用**
   - 调用自定义程序
   - 跨程序调用（CPI）

3. **账户管理**
   - PDA (Program Derived Address)
   - 账户租金机制

4. **高级特性**
   - 交易优先级费用
   - 版本化交易
   - 查找表（Lookup Tables）

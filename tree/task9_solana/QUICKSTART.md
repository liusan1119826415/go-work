# 快速开始指南

## 1. 准备工作

### 1.1 安装 Go
确保已安装 Go 1.18 或更高版本：
```bash
go version
```

### 1.2 克隆项目
```bash
cd task9_solana
```

### 1.3 安装依赖
```bash
go mod tidy
```

## 2. 配置私钥

### 2.1 复制配置模板
```bash
# Windows (PowerShell)
Copy-Item config.yaml.template config.yaml

# Linux/Mac
cp config.yaml.template config.yaml
```

### 2.2 编辑配置文件
打开 `config.yaml`，填入你的私钥：

```yaml
wallet:
  private_key_base58: "yky9Vnk5PZgY3svzVRJFryzUZbP4uDL7835VLZqm7aWFgEDJfzKLTj2zBm9fLwtqcvMia8rdaGhXzUTUJEhEAJF"
```

### 2.3 获取私钥的方法

#### 方法 1: 从 Phantom 钱包导出
1. 打开 Phantom 钱包
2. 点击设置 → 安全与隐私
3. 导出私钥
4. 复制 Base58 格式的私钥

#### 方法 2: 使用 Solana CLI 生成
```bash
# 生成新钱包
solana-keygen new --outfile ~/my-solana-wallet.json

# 查看公钥
solana-keygen pubkey ~/my-solana-wallet.json

# 获取私钥（需要转换为 Base58）
# 或者直接在配置中使用 JSON 文件路径
```

## 3. 获取测试 SOL

### 3.1 使用 Solana Faucet
访问 https://faucet.solana.com 并输入你的地址

### 3.2 使用命令行
```bash
solana airdrop 2 <your-address> --url devnet
```

### 3.3 验证余额
```bash
solana balance <your-address> --url devnet
```

## 4. 运行程序

### 4.1 构建程序
```bash
go build .
```

### 4.2 运行程序
```bash
# Windows
.\solana-interactor.exe

# Linux/Mac
./solana-interactor
```

## 5. 功能演示

### 5.1 查询区块信息（选项 1）
```
请选择操作 (0-8): 1

执行: 查询区块信息
当前区块高度 (Slot): 285698412
区块哈希: 9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin
父区块哈希: 5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj
交易数量: 142
```

### 5.2 简单转账（选项 2）
发送 SOL 到另一个地址

### 5.3 USDT 转账（选项 7）
转账 SPL Token（如 USDT）

### 5.4 事件监听服务（选项 8）★ 新功能
```
请选择操作 (0-8): 8

执行: 事件监听服务演示
=== Solana 事件监听服务演示 ===

📡 开始监听区块槽位更新
📡 开始监听账户: 11111111111111111111111111111111

事件监听服务已启动，按 Ctrl+C 停止...

⛓️  新区块 - Slot: 285698413, Parent: 285698412, Root: 285698381
⛓️  新区块 - Slot: 285698414, Parent: 285698413, Root: 285698382
...
```

## 6. 查看技术报告

### 6.1 交易生命周期流程图
打开 `docs/技术报告.md`，查看详细的 Mermaid 流程图

### 6.2 BPF 加载器工作原理
了解 Solana 虚拟机如何执行智能合约

### 6.3 账户模型对比
深入理解 Solana 与 EVM 的差异

## 7. 智能合约开发

查看 `docs/智能合约开发指南.md`：
- Token Swap 合约完整代码
- Anchor 框架使用
- Go 客户端集成示例

## 8. 常见问题

### Q: 配置文件找不到？
A: 确保在项目根目录运行程序，或使用绝对路径

### Q: WebSocket 连接超时？
A: 检查网络连接，或更换 RPC 节点：
```yaml
network:
  rpc_url: "https://api.mainnet-beta.solana.com"
  ws_url: "wss://api.mainnet-beta.solana.com"
```

### Q: 余额不足？
A: 先领取测试 SOL：
```bash
solana airdrop 2 <your-address> --url devnet
```

## 9. 项目文件说明

```
task9_solana/
├── config.yaml              # 配置文件（包含私钥）⚠️ 不要提交到 Git
├── config.yaml.template     # 配置模板
├── config/
│   └── config.go           # 配置管理器
├── docs/
│   ├── 技术报告.md          # 完整技术报告 ★
│   └── 智能合约开发指南.md   # 合约开发文档 ★
├── event_listener.go        # 事件监听服务 ★ 新增
├── create_transaction.go    # 交易创建（已更新）
├── transfer_usdt.go         # USDT 转账（已更新）
├── main.go                  # 主程序（已更新）
└── README_ASSIGNMENT.md     # 作业完成报告 ★
```

## 10. 下一步

### 学习资源
- [Solana 官方文档](https://docs.solana.com/)
- [Anchor 教程](https://www.anchor-lang.com/docs/intro)
- [Solana Cookbook](https://solanacookbook.com/)

### 实践建议
1. 尝试修改配置，连接到 Mainnet
2. 订阅自己的交易签名
3. 监听特定的 Token 账户
4. 部署自己的智能合约

### 安全提醒
⚠️ **重要**: 
- 不要将包含私钥的 `config.yaml` 提交到 Git
- 不要在公共场合分享你的私钥
- 建议使用测试网进行开发

## 11. 联系与支持

如遇问题：
1. 检查 `docs/技术报告.md` 中的详细说明
2. 查看代码注释
3. 访问 Solana Discord 社区

---

**祝你开发愉快！** 🚀

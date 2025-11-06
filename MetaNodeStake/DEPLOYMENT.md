# 部署指南

## 环境准备

### 后端环境

1. 确保已安装 Node.js (推荐 v16 或更高版本)
2. 安装项目依赖：
```bash
cd d:\project\go-work\MetaNodeStake
npm install
```

3. 安装 Hardhat 工具：
```bash
npm install --save-dev hardhat
```

### 前端环境

1. 安装前端依赖：
```bash
cd d:\project\go-work\MetaNodeStake\frontend
npm install
```

## 网络配置

### Sepolia 测试网配置

1. 在 [Infura](https://infura.io/) 注册账号并创建项目
2. 获取项目 ID
3. 导出私钥（测试用，请勿在主网使用真实私钥）：
```bash
export PRIVATE_KEY=your_private_key_here
```

4. 在 `hardhat.config.js` 中替换 `YOUR_INFURA_PROJECT_ID` 为你的 Infura 项目 ID

## 合约部署

### 1. 编译合约

```bash
npx hardhat compile
```

### 2. 部署到 Sepolia

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

部署成功后会输出类似以下信息：
```
Deploying contracts with the account: 0x...
MetaNodeToken deployed to: 0x...
MetaNodeStake deployed to: 0x...
Native currency pool added
MetaNodeToken pool added
Deployment completed!
```

请记录下 `MetaNodeToken` 和 `MetaNodeStake` 的合约地址。

## 前端配置

### 1. 更新合约地址

编辑 `frontend/src/App.jsx` 文件，更新以下常量：
```javascript
const CONTRACT_ADDRESS = "your_MetaNodeStake_contract_address";
const TOKEN_ADDRESS = "your_MetaNodeToken_contract_address";
```

### 2. 运行前端

```bash
npm run dev
```

默认情况下，前端将在 http://localhost:3000 运行。

## 合约交互

### 管理员操作

1. **添加新的质押池**：
   - 调用 `addPool()` 函数
   - 参数：
     - `_stTokenAddress`: 质押代币地址（address(0) 表示 ETH）
     - `_poolWeight`: 池权重
     - `_minDepositAmount`: 最小质押金额
     - `_unstakeLockedBlocks`: 解质押锁定区块数

2. **更新质押池配置**：
   - 调用 `updatePoolConfig()` 函数
   - 参数：
     - `_pid`: 质押池 ID
     - `_poolWeight`: 新的池权重
     - `_minDepositAmount`: 新的最小质押金额
     - `_unstakeLockedBlocks`: 新的解质押锁定区块数

### 用户操作

1. **质押代币**：
   - 对于 ETH 质押：调用 `deposit()` 并发送相应 ETH
   - 对于 ERC20 质押：先调用代币的 `approve()`，再调用 `deposit()`

2. **请求解质押**：
   - 调用 `requestUnstake()` 函数
   - 参数：
     - `_pid`: 质押池 ID
     - `_amount`: 解质押数量

3. **提取已解锁代币**：
   - 调用 `withdrawUnstaked()` 函数
   - 参数：
     - `_pid`: 质押池 ID

4. **领取奖励**：
   - 调用 `claimReward()` 函数
   - 参数：
     - `_pid`: 质押池 ID

## 测试

### 运行合约测试

```bash
npx hardhat test
```

测试将验证以下功能：
- 合约部署
- 质押池管理
- ETH 质押和解质押
- ERC20 代币质押和解质押
- 奖励计算和领取

## 故障排除

### 常见问题

1. **编译错误**：
   - 确保 Solidity 版本正确（0.8.19）
   - 检查 OpenZeppelin 依赖是否正确安装

2. **部署失败**：
   - 检查网络配置是否正确
   - 确保账户有足够的 ETH 支付 Gas 费用
   - 验证私钥是否正确

3. **前端无法连接**：
   - 确保 Metamask 已安装并连接到 Sepolia 网络
   - 检查合约地址是否正确配置
   - 确保本地开发服务器正在运行

### 日志查看

查看详细日志信息：
```bash
npx hardhat run scripts/deploy.js --network sepolia --verbose
```

## 安全建议

1. **私钥管理**：
   - 永远不要在代码中硬编码私钥
   - 使用环境变量存储敏感信息
   - 在生产环境中使用硬件钱包

2. **合约审核**：
   - 部署前请专业审计公司审核合约
   - 使用 Slither 等工具进行静态分析
   - 进行全面的测试覆盖

3. **权限控制**：
   - 限制管理员权限的使用
   - 定期审查角色分配
   - 实现多重签名机制

## 升级和维护

### 合约升级

当前合约实现为单一合约，如需升级功能，建议：

1. 实现代理合约模式
2. 使用 OpenZeppelin 的 Upgradeable Contracts
3. 部署新的实现合约并更新代理指向

### 监控和维护

1. 定期检查合约余额
2. 监控质押池状态
3. 更新奖励参数以适应市场变化
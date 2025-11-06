# MetaNode 质押系统

这是一个基于区块链的质押系统，支持多种代币的质押，并基于用户质押的代币数量和时间长度分配 MetaNode 代币作为奖励。

## 项目结构

```
MetaNodeStake/
├── contracts/              # 智能合约
│   ├── MetaNodeStake.sol   # 主质押合约
│   └── MetaNodeToken.sol   # 奖励代币合约
├── scripts/                # 部署脚本
│   └── deploy.js           # 合约部署脚本
├── test/                   # 测试文件
│   └── MetaNodeStake.test.js  # 合约测试
├── frontend/               # 前端界面
│   ├── src/                # 前端源代码
│   ├── package.json        # 前端依赖
│   └── vite.config.js      # Vite 配置
├── package.json            # 后端依赖
└── hardhat.config.js       # Hardhat 配置
```

## 功能特性

1. **多质押池支持**：支持 Native Currency (ETH) 和 ERC20 代币质押
2. **权重系统**：不同质押池可设置不同权重影响奖励分配
3. **锁定期机制**：解质押需要等待一定区块数后才能提取
4. **奖励计算**：基于质押数量和时间长度计算奖励
5. **权限控制**：基于角色的访问控制确保安全性
6. **前端界面**：用户友好的 React 界面进行交互

## 合约功能

### 核心功能
- `deposit()`: 质押代币
- `requestUnstake()`: 请求解质押
- `withdrawUnstaked()`: 提取已解锁的代币
- `claimReward()`: 领取奖励
- `emergencyWithdraw()`: 紧急提取（不领取奖励）

### 管理功能
- `addPool()`: 添加新的质押池
- `updatePoolConfig()`: 更新质押池配置
- `setMetaNodePerBlock()`: 设置每区块奖励数量

## 部署说明

### 后端合约部署

1. 安装依赖：
```bash
npm install
```

2. 配置网络：
编辑 `hardhat.config.js` 文件，设置你的 Infura 项目 ID 和私钥

3. 编译合约：
```bash
npx hardhat compile
```

4. 部署到 Sepolia 测试网：
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

### 前端运行

1. 进入前端目录：
```bash
cd frontend
```

2. 安装依赖：
```bash
npm install
```

3. 运行开发服务器：
```bash
npm run dev
```

## 测试

运行合约测试：
```bash
npx hardhat test
```

## 安全特性

- 使用 OpenZeppelin 合约库确保标准安全实践
- 实现重入攻击防护
- 基于角色的访问控制
- 输入验证和边界检查
- 紧急提取功能以防意外情况

## 使用说明

1. 部署合约后，将合约地址配置到前端
2. 用户连接钱包后可以进行质押操作
3. 质押代币后可以领取奖励
4. 解质押需要等待锁定期结束后才能提取
# Deploy to Sepolia

1. 新建 `.env`：

```
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/<YOUR_PROJECT_ID>
PRIVATE_KEY=0x...
CURRENT_CHAIN_ID=11155111
CCIP_ROUTER=0xF9B8...   # Chainlink CCIP Router 地址（Sepolia）
CCIP_FUND=0.05
# 可选：用逗号分隔的ERC20真实地址，给它们设置同价预言机
ERC20S=
```

2. 部署：

```bash
npx hardhat run scripts/deployCrossChainAuction.js --network sepolia
```

输出包含：`Auction impl`、`ProxyAdmin`、`AuctionFactor` 地址。

3. 升级 Auction 实现：

```bash
FACT0R_ADDRESS=<factory_addr> \
NEW_IMPL_NAME=Auction \
npx hardhat run scripts/upgradeAuctionImpl.js --network sepolia
```

4. 跨链：如果要做跨链，需要在两条链上各部署一个 `AuctionFactor`，然后互相 `setRemoteAuctionFactor`，并在两边分别资助少量原生币用于 CCIP 费用。

# 跨链拍卖系统

## 1. 学习指南

### 功能概述
本系统实现了一个支持跨链的NFT拍卖平台，主要功能包括：
- 创建跨链NFT拍卖
- 支持ETH和ERC20代币出价
- 跨链拍卖结算
- NFT跨链转移
- 价格预言机集成

### 核心概念
- **跨链拍卖**：拍卖可在不同区块链网络间同步状态
- **CCIP协议**：使用Chainlink的跨链互操作协议
- **UUPS代理**：可升级的合约架构
- **价格预言机**：集成Chainlink获取实时价格数据

## 2. 快速入门

### 环境准备
- Node.js v16+
- Hardhat
- Git

### 安装依赖
```bash
npm install
```

### 配置网络
在`hardhat.config.js`中配置目标网络：
```javascript
module.exports = {
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/YOUR_PROJECT_ID",
      accounts: [PRIVATE_KEY]
    }
  }
};
```

### 部署合约
```bash
npx hardhat run scripts/deployCrossChainAuction.js --network sepolia
```

### 测试
运行单元测试：
```bash
npx hardhat test
```

## 3. 架构图

### 系统架构
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   NFT 合约      │    │   拍卖工厂      │    │   拍卖合约      │
│  (ERC721)       │◄──►│  (Factory)      │◄──►│   (Auction)     │
│                 │    │                 │    │                 │
│ • 铸造 NFT      │    │ • 创建拍卖      │    │ • ETH 出价      │
│ • 转移 NFT      │    │ • 管理拍卖      │    │ • ERC20 出价    │
│ • 跨链支持       │    │ • 价格预言机    │    │ • 拍卖结算      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CCIP 跨链     │    │  Chainlink      │    │   UUPS 代理     │
│   消息处理      │    │   价格预言机    │    │   升级机制      │
│                 │    │                 │    │                 │
│ • 跨链拍卖      │    │ • ETH/USD 价格  │    │ • 合约升级      │
│ • 消息验证      │    │ • LINK/USD 价格 │    │ • 状态保持      │
│ • 安全机制      │    │ • 价格比较      │    │ • 权限控制      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 交互流程
1. **创建拍卖**：
   - 用户通过拍卖工厂创建跨链拍卖
   - NFT转移到拍卖合约
   - 拍卖信息通过CCIP同步到目标链

2. **参与拍卖**：
   - 用户通过拍卖合约出价
   - 出价信息通过CCIP同步到源链

3. **结算拍卖**：
   - 拍卖结束后结算
   - NFT通过CCIP转移到买家所在链
   - 资金结算给卖家

## 4. 开发者指南

### 合约目录结构
```
contracts/
├── Auction.sol          # 拍卖合约实现
├── AuctionFactor.sol     # 拍卖工厂
├── IAuctionFactor.sol    # 工厂接口
├── ICrossChainAuction.sol # 跨链接口
├── MyNftERC721.sol       # NFT合约
└── AggreagatorV3.sol     # 价格预言机接口
```

### 测试说明
测试覆盖以下场景：
- 跨链拍卖创建
- 跨链出价
- 跨链结算
- 错误条件处理

运行完整测试套件：
```bash
npx hardhat test
```

### 注意事项
1. 部署前确保配置正确的CCIP路由器和链ID
2. 测试网使用需要获取测试代币
3. 生产环境建议添加更多安全措施

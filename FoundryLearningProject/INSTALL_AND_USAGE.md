# Windows环境下Foundry安装与使用指南

## 1. 安装Foundry

### 方法一：使用官方安装脚本（推荐）

1. 打开PowerShell（建议以管理员身份运行）
2. 执行以下命令：
   ```powershell
   irm https://get.foundry.paradigm.xyz | iex
   ```
3. 安装完成后，重启终端并运行：
   ```powershell
   foundryup
   ```

### 方法二：手动下载安装

1. 访问 [Foundry GitHub Releases](https://github.com/foundry-rs/foundry/releases)
2. 下载适用于Windows的二进制文件（通常命名为`foundry_nightly_windows_amd64.zip`）
3. 解压文件并将可执行文件添加到系统PATH环境变量中

### 方法三：使用包管理器

如果您已安装Chocolatey：
```powershell
choco install foundry
```

或者使用Scoop：
```powershell
scoop install foundry
```

## 2. 验证安装

安装完成后，在终端中运行以下命令验证安装：
```powershell
forge --version
cast --version
anvil --version
```

## 3. 项目初始化

进入项目目录：
```powershell
cd FoundryLearningProject
```

## 4. 运行测试

### 基本测试运行
```powershell
forge test
```

### 带详细输出的测试运行
```powershell
forge test -vvv
```

### 生成Gas报告
```powershell
forge test --gas-report
```

### 生成覆盖率报告
```powershell
forge coverage
```

## 5. 项目结构说明

- `src/`: 存放智能合约源代码
- `test/`: 存放测试文件
- `script/`: 存放部署脚本
- `out/`: 编译产物目录
- `cache/`: 缓存文件目录

## 6. 开发流程

1. 编写智能合约代码到`src/`目录
2. 编写对应的测试文件到`test/`目录
3. 运行测试验证功能正确性
4. 使用Gas报告分析和优化合约
5. 重复迭代直到满足性能要求

## 7. 常用命令

- `forge build`: 编译合约
- `forge test`: 运行测试
- `forge snapshot`: 创建Gas快照
- `forge verify-contract`: 验证链上合约
- `cast send`: 发送交易
- `cast call`: 调用只读函数
- `anvil`: 启动本地测试网络
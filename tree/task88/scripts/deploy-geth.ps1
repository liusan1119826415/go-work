# Geth 自动化部署脚本 (Windows PowerShell)
# 用于快速搭建本地以太坊开发环境

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Geth 自动化部署脚本 (Windows)" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# 配置变量
$GETH_DIR = ".\geth-install"
$DATA_DIR = ".\devchain"
$GETH_VERSION = "v1.13.5"

# 检查Go环境
function Check-Go {
    Write-Host "检查Go环境..." -ForegroundColor Yellow
    
    $goVersion = go version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "未检测到Go环境，请先安装Go (https://golang.org/dl/)" -ForegroundColor Red
        exit 1
    }
    Write-Host "Go版本: $goVersion" -ForegroundColor Green
}

# 克隆Geth源码
function Clone-Geth {
    Write-Host "克隆Geth源码..." -ForegroundColor Yellow
    
    if (Test-Path $GETH_DIR) {
        Write-Host "目录已存在，跳过克隆" -ForegroundColor Yellow
        Set-Location $GETH_DIR
    } else {
        git clone https://github.com/ethereum/go-ethereum.git $GETH_DIR
        Set-Location $GETH_DIR
        git checkout $GETH_VERSION
    }
}

# 编译Geth
function Build-Geth {
    Write-Host "编译Geth..." -ForegroundColor Yellow
    
    # Windows下使用go build
    $env:CGO_ENABLED = 1
    go build -o .\build\bin\geth.exe .\cmd\geth
    
    if (Test-Path ".\build\bin\geth.exe") {
        Write-Host "编译成功！" -ForegroundColor Green
        .\build\bin\geth.exe version
    } else {
        Write-Host "编译失败" -ForegroundColor Red
        exit 1
    }
}

# 创建创世配置
function Create-Genesis {
    Write-Host "创建创世配置文件..." -ForegroundColor Yellow
    
    $genesisContent = @"
{
  "config": {
    "chainId": 88888,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "clique": {
      "period": 5,
      "epoch": 30000
    }
  },
  "difficulty": "1",
  "gasLimit": "8000000000",
  "alloc": {
    "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0": {
      "balance": "1000000000000000000000000"
    }
  }
}
"@
    
    Set-Content -Path "genesis.json" -Value $genesisContent
    Write-Host "创世配置文件已创建: genesis.json" -ForegroundColor Green
}

# 初始化区块链
function Initialize-Chain {
    Write-Host "初始化区块链..." -ForegroundColor Yellow
    
    $fullDataDir = Join-Path $PSScriptRoot "..\$DATA_DIR"
    
    if (Test-Path $fullDataDir) {
        $response = Read-Host "数据目录已存在，是否删除并重新初始化？(y/n)"
        if ($response -eq "y" -or $response -eq "Y") {
            Remove-Item -Recurse -Force $fullDataDir
        } else {
            Write-Host "跳过初始化" -ForegroundColor Yellow
            return
        }
    }
    
    .\build\bin\geth.exe --datadir $fullDataDir init genesis.json
    Write-Host "区块链初始化完成" -ForegroundColor Green
}

# 创建启动脚本
function Create-StartScript {
    Write-Host "创建启动脚本..." -ForegroundColor Yellow
    
    $startScript = @"
# Geth启动脚本 (Windows)
`$GETH_DIR = ".\geth-install"
`$DATA_DIR = ".\devchain"

Write-Host "启动Geth开发节点..." -ForegroundColor Cyan

Set-Location `$GETH_DIR

.\build\bin\geth.exe ``
  --datadir "..\`$DATA_DIR" ``
  --networkid 88888 ``
  --http ``
  --http.addr "0.0.0.0" ``
  --http.port 8545 ``
  --http.api "eth,web3,personal,net,debug,txpool,admin" ``
  --http.corsdomain "*" ``
  --ws ``
  --ws.addr "0.0.0.0" ``
  --ws.port 8546 ``
  --ws.api "eth,web3,personal,net" ``
  --ws.origins "*" ``
  --allow-insecure-unlock ``
  --nodiscover ``
  --maxpeers 0 ``
  console
"@
    
    Set-Content -Path "..\start-geth.ps1" -Value $startScript
    Write-Host "启动脚本已创建: start-geth.ps1" -ForegroundColor Green
}

# 创建连接脚本
function Create-AttachScript {
    Write-Host "创建连接脚本..." -ForegroundColor Yellow
    
    $attachScript = @"
# Geth连接脚本 (Windows)
`$GETH_DIR = ".\geth-install"
`$DATA_DIR = ".\devchain"

Write-Host "连接到Geth控制台..." -ForegroundColor Cyan

Set-Location `$GETH_DIR

.\build\bin\geth.exe attach "..\`$DATA_DIR\geth.ipc"
"@
    
    Set-Content -Path "..\attach-geth.ps1" -Value $attachScript
    Write-Host "连接脚本已创建: attach-geth.ps1" -ForegroundColor Green
}

# 主函数
function Main {
    Write-Host "开始部署..." -ForegroundColor Yellow
    
    Check-Go
    Clone-Geth
    Build-Geth
    Create-Genesis
    Initialize-Chain
    Create-StartScript
    Create-AttachScript
    
    Set-Location ..
    
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "部署完成！" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步操作：" -ForegroundColor Yellow
    Write-Host "1. 启动节点: " -NoNewline; Write-Host ".\start-geth.ps1" -ForegroundColor Green
    Write-Host "2. 连接控制台: " -NoNewline; Write-Host ".\attach-geth.ps1" -ForegroundColor Green -NoNewline; Write-Host " (在另一个终端)" -ForegroundColor Yellow
    Write-Host "3. RPC地址: " -NoNewline; Write-Host "http://localhost:8545" -ForegroundColor Green
    Write-Host "4. WebSocket地址: " -NoNewline; Write-Host "ws://localhost:8546" -ForegroundColor Green
    Write-Host ""
    Write-Host "预分配账户:" -ForegroundColor Yellow
    Write-Host "地址: " -NoNewline; Write-Host "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0" -ForegroundColor Green
    Write-Host "余额: " -NoNewline; Write-Host "1000000 ETH" -ForegroundColor Green
    Write-Host ""
}

# 执行主函数
Main

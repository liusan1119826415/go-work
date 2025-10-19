#!/bin/bash

# Geth 自动化部署脚本
# 用于快速搭建本地以太坊开发环境

set -e

echo "================================"
echo "Geth 自动化部署脚本"
echo "================================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 配置变量
GETH_DIR="./geth-install"
DATA_DIR="./devchain"
GETH_VERSION="v1.13.5"

# 检查Go环境
check_go() {
    echo -e "${YELLOW}检查Go环境...${NC}"
    if ! command -v go &> /dev/null; then
        echo -e "${RED}未检测到Go环境，请先安装Go (https://golang.org/dl/)${NC}"
        exit 1
    fi
    echo -e "${GREEN}Go版本: $(go version)${NC}"
}

# 克隆Geth源码
clone_geth() {
    echo -e "${YELLOW}克隆Geth源码...${NC}"
    
    if [ -d "$GETH_DIR" ]; then
        echo -e "${YELLOW}目录已存在，跳过克隆${NC}"
        cd "$GETH_DIR"
    else
        git clone https://github.com/ethereum/go-ethereum.git "$GETH_DIR"
        cd "$GETH_DIR"
        git checkout "$GETH_VERSION"
    fi
}

# 编译Geth
build_geth() {
    echo -e "${YELLOW}编译Geth...${NC}"
    make geth
    
    if [ -f "./build/bin/geth" ]; then
        echo -e "${GREEN}编译成功！${NC}"
        ./build/bin/geth version
    else
        echo -e "${RED}编译失败${NC}"
        exit 1
    fi
}

# 创建创世配置
create_genesis() {
    echo -e "${YELLOW}创建创世配置文件...${NC}"
    
    cat > genesis.json << 'EOF'
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
EOF
    
    echo -e "${GREEN}创世配置文件已创建: genesis.json${NC}"
}

# 初始化区块链
init_chain() {
    echo -e "${YELLOW}初始化区块链...${NC}"
    
    if [ -d "../$DATA_DIR" ]; then
        echo -e "${YELLOW}数据目录已存在，是否删除并重新初始化？(y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "../$DATA_DIR"
        else
            echo -e "${YELLOW}跳过初始化${NC}"
            return
        fi
    fi
    
    ./build/bin/geth --datadir "../$DATA_DIR" init genesis.json
    echo -e "${GREEN}区块链初始化完成${NC}"
}

# 创建启动脚本
create_start_script() {
    echo -e "${YELLOW}创建启动脚本...${NC}"
    
    cat > start-geth.sh << 'EOF'
#!/bin/bash

# Geth启动脚本
GETH_DIR="./geth-install"
DATA_DIR="./devchain"

echo "启动Geth开发节点..."

cd "$GETH_DIR"

./build/bin/geth \
  --datadir "../$DATA_DIR" \
  --networkid 88888 \
  --http \
  --http.addr "0.0.0.0" \
  --http.port 8545 \
  --http.api "eth,web3,personal,net,debug,txpool,admin" \
  --http.corsdomain "*" \
  --ws \
  --ws.addr "0.0.0.0" \
  --ws.port 8546 \
  --ws.api "eth,web3,personal,net" \
  --ws.origins "*" \
  --allow-insecure-unlock \
  --nodiscover \
  --maxpeers 0 \
  console
EOF
    
    chmod +x start-geth.sh
    mv start-geth.sh ..
    echo -e "${GREEN}启动脚本已创建: start-geth.sh${NC}"
}

# 创建连接脚本
create_attach_script() {
    echo -e "${YELLOW}创建连接脚本...${NC}"
    
    cat > attach-geth.sh << 'EOF'
#!/bin/bash

# Geth连接脚本
GETH_DIR="./geth-install"
DATA_DIR="./devchain"

echo "连接到Geth控制台..."

cd "$GETH_DIR"

./build/bin/geth attach "../$DATA_DIR/geth.ipc"
EOF
    
    chmod +x attach-geth.sh
    mv attach-geth.sh ..
    echo -e "${GREEN}连接脚本已创建: attach-geth.sh${NC}"
}

# 主函数
main() {
    echo -e "${YELLOW}开始部署...${NC}"
    
    check_go
    clone_geth
    build_geth
    create_genesis
    init_chain
    create_start_script
    create_attach_script
    
    cd ..
    
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}部署完成！${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${YELLOW}下一步操作：${NC}"
    echo -e "1. 启动节点: ${GREEN}./start-geth.sh${NC}"
    echo -e "2. 连接控制台: ${GREEN}./attach-geth.sh${NC} (在另一个终端)"
    echo -e "3. RPC地址: ${GREEN}http://localhost:8545${NC}"
    echo -e "4. WebSocket地址: ${GREEN}ws://localhost:8546${NC}"
    echo ""
    echo -e "${YELLOW}预分配账户:${NC}"
    echo -e "地址: ${GREEN}0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0${NC}"
    echo -e "余额: ${GREEN}1000000 ETH${NC}"
    echo ""
}

# 执行主函数
main

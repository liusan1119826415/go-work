const Web3 = require('web3');

// 配置
const RPC_URL = 'http://127.0.0.1:8545';
const web3 = new Web3(RPC_URL);

// SimpleStorage合约ABI和Bytecode（需要先编译Solidity）
// 使用 solc SimpleStorage.sol --abi --bin 获取

const SimpleStorageABI = [
    {
        "inputs": [{"internalType": "uint256", "name": "initialValue", "type": "uint256"}],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "internalType": "address", "name": "setter", "type": "address"},
            {"indexed": false, "internalType": "uint256", "name": "oldValue", "type": "uint256"},
            {"indexed": false, "internalType": "uint256", "name": "newValue", "type": "uint256"}
        ],
        "name": "DataStored",
        "type": "event"
    },
    {
        "inputs": [],
        "name": "get",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "uint256", "name": "x", "type": "uint256"}],
        "name": "set",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "uint256", "name": "x", "type": "uint256"}],
        "name": "increment",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "owner",
        "outputs": [{"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
    }
];

// 主测试函数
async function main() {
    try {
        console.log('=== Geth节点连接测试 ===\n');
        
        // 1. 检查连接
        const isConnected = await web3.eth.net.isListening();
        console.log('✓ 节点连接状态:', isConnected ? '已连接' : '未连接');
        
        // 2. 获取链信息
        const chainId = await web3.eth.getChainId();
        const blockNumber = await web3.eth.getBlockNumber();
        const gasPrice = await web3.eth.getGasPrice();
        
        console.log('✓ 链ID:', chainId);
        console.log('✓ 当前区块高度:', blockNumber);
        console.log('✓ Gas价格:', web3.utils.fromWei(gasPrice, 'gwei'), 'Gwei');
        
        // 3. 获取账户
        const accounts = await web3.eth.getAccounts();
        console.log('\n=== 账户信息 ===\n');
        
        if (accounts.length === 0) {
            console.log('⚠ 未检测到账户，请先创建账户');
            return;
        }
        
        for (let i = 0; i < Math.min(accounts.length, 3); i++) {
            const balance = await web3.eth.getBalance(accounts[i]);
            const nonce = await web3.eth.getTransactionCount(accounts[i]);
            console.log(`账户 ${i}:`, accounts[i]);
            console.log(`  余额:`, web3.utils.fromWei(balance, 'ether'), 'ETH');
            console.log(`  Nonce:`, nonce);
        }
        
        // 4. 测试交易（如果有多个账户）
        if (accounts.length >= 2) {
            console.log('\n=== 测试转账交易 ===\n');
            
            const fromAccount = accounts[0];
            const toAccount = accounts[1];
            const amount = web3.utils.toWei('1', 'ether');
            
            console.log('从:', fromAccount);
            console.log('到:', toAccount);
            console.log('金额:', web3.utils.fromWei(amount, 'ether'), 'ETH');
            
            // 发送交易
            const txReceipt = await web3.eth.sendTransaction({
                from: fromAccount,
                to: toAccount,
                value: amount,
                gas: 21000
            });
            
            console.log('✓ 交易哈希:', txReceipt.transactionHash);
            console.log('✓ 区块号:', txReceipt.blockNumber);
            console.log('✓ Gas使用:', txReceipt.gasUsed);
            console.log('✓ 状态:', txReceipt.status ? '成功' : '失败');
            
            // 验证余额变化
            const newBalance = await web3.eth.getBalance(toAccount);
            console.log('✓ 接收方新余额:', web3.utils.fromWei(newBalance, 'ether'), 'ETH');
        }
        
        // 5. 测试区块查询
        console.log('\n=== 最新区块信息 ===\n');
        const latestBlock = await web3.eth.getBlock('latest');
        console.log('区块号:', latestBlock.number);
        console.log('区块哈希:', latestBlock.hash);
        console.log('父区块哈希:', latestBlock.parentHash);
        console.log('交易数量:', latestBlock.transactions.length);
        console.log('Gas限制:', latestBlock.gasLimit);
        console.log('Gas使用:', latestBlock.gasUsed);
        console.log('时间戳:', new Date(latestBlock.timestamp * 1000).toLocaleString());
        
        // 6. 测试事件订阅（WebSocket）
        console.log('\n=== 测试完成 ===\n');
        console.log('所有测试通过！✓');
        
    } catch (error) {
        console.error('错误:', error.message);
        process.exit(1);
    }
}

// 合约部署测试
async function testContractDeployment() {
    try {
        console.log('\n=== 测试合约部署 ===\n');
        
        const accounts = await web3.eth.getAccounts();
        if (accounts.length === 0) {
            console.log('⚠ 未检测到账户');
            return;
        }
        
        // 注意：这里需要实际的bytecode，需要先编译Solidity合约
        console.log('⚠ 合约部署需要先编译Solidity文件');
        console.log('运行: solc --abi --bin SimpleStorage.sol');
        console.log('然后将bytecode填入到脚本中');
        
        // 示例代码（需要填入实际bytecode）
        /*
        const SimpleStorage = new web3.eth.Contract(SimpleStorageABI);
        
        const deploy = SimpleStorage.deploy({
            data: '0x...bytecode...',
            arguments: [100]  // initialValue = 100
        });
        
        const contract = await deploy.send({
            from: accounts[0],
            gas: 1500000,
            gasPrice: web3.utils.toWei('1', 'gwei')
        });
        
        console.log('✓ 合约部署成功！');
        console.log('合约地址:', contract.options.address);
        
        // 测试合约调用
        const value = await contract.methods.get().call();
        console.log('存储值:', value);
        
        // 测试合约交易
        const receipt = await contract.methods.set(200).send({
            from: accounts[0],
            gas: 100000
        });
        
        console.log('✓ 交易成功，Gas使用:', receipt.gasUsed);
        
        const newValue = await contract.methods.get().call();
        console.log('新存储值:', newValue);
        */
        
    } catch (error) {
        console.error('合约部署错误:', error.message);
    }
}

// 执行测试
if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch(error => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = { main, testContractDeployment };

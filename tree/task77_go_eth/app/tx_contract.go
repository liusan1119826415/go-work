package app

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"go-ethereum/config"

	"go-ethereum/count" // 暂时注释，待重新生成绑定文件后启用
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

type ContractApp struct{}

//

func (d *ContractApp) Name() string {
	return "tx_contract"
}

func (d *ContractApp) Run() error {

	client, err := ethclient.Dial("https://ethereum-sepolia-rpc.publicnode.com")
	if err != nil {
		log.Fatal(err)
	}

	configManage := config.NewConfigManager("my_config.json", "liusan123")

	privateHexkey, err := configManage.GetPrivateKey()
	if err != nil {
		log.Fatal(err)
	}

	privateKey, err := crypto.HexToECDSA(privateHexkey)

	if err != nil {
		log.Fatal(err)
	}

	publicKey := privateKey.Public()

	publicKeyECDS, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDS)

	fmt.Println(fromAddress)

	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal(err)
	}

	// 获取当前推荐的 Gas 价格
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		log.Fatal(err)
	}

	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)

	// 增加 Gas Limit 以确保部署成功
	// 合约部署通常需要更多的 gas
	auth.GasLimit = uint64(3000000) // 从 300000 增加到 3000000

	// 可选：提高 Gas Price 以加快确认速度
	// auth.GasPrice = new(big.Int).Mul(gasPrice, big.NewInt(2)) // 2倍 gas price
	auth.GasPrice = gasPrice

	fmt.Printf("部署参数:\n")
	fmt.Printf("  Gas Limit: %d\n", auth.GasLimit)
	fmt.Printf("  Gas Price: %s Gwei\n", new(big.Int).Div(gasPrice, big.NewInt(1e9)).String())
	fmt.Printf("  Nonce: %d\n\n", nonce)

	// 部署合约
	initialCount := big.NewInt(100)
	fmt.Println("正在部署合约...")
	fmt.Println("提示：部署可能需要 15-30 秒，请耐心等待...\n")

	address, tx, instance, err := count.DeployCount(auth, client, initialCount)
	if err != nil {
		log.Fatal("部署合约失败:", err)
	}

	fmt.Printf("✅ 合约部署交易已发送！\n")
	fmt.Printf("合约地址: %s\n", address.Hex())
	fmt.Printf("部署交易哈希: %s\n", tx.Hash().Hex())
	fmt.Printf("初始计数值: %d\n\n", initialCount)

	// 等待交易确认
	fmt.Println("⏳ 等待交易确认...")
	receipt, err := bind.WaitMined(context.Background(), client, tx)
	if err != nil {
		log.Fatal("等待交易确认失败:", err)
	}

	if receipt.Status == 1 {
		fmt.Printf("\n🎉 合约部署成功！\n")
		fmt.Printf("区块号: %d\n", receipt.BlockNumber)
		fmt.Printf("Gas 使用: %d\n", receipt.GasUsed)
		fmt.Printf("实际花费: %s ETH\n", new(big.Int).Div(
			new(big.Int).Mul(big.NewInt(int64(receipt.GasUsed)), gasPrice),
			big.NewInt(1e18),
		).String())
		fmt.Printf("\n📝 请保存此合约地址，用于后续交互:\n")
		fmt.Printf("   %s\n\n", address.Hex())
		fmt.Printf("可以在区块浏览器查看:\n")
		fmt.Printf("https://sepolia.etherscan.io/address/%s\n", address.Hex())
		fmt.Printf("\n下一步: 使用 'go run main.go call_contract' 与合约交互\n")
		fmt.Printf("提示: 需要先在 call_contract.go 中更新合约地址为: %s\n", address.Hex())
	} else {
		fmt.Printf("❌ 合约部署失败！\n")
		fmt.Printf("请在 Etherscan 查看详情: https://sepolia.etherscan.io/tx/%s\n", tx.Hash().Hex())
	}

	// 合约实例可用于后续调用
	_ = instance

	return nil
}

func init() {
	// 在包初始化时自动注册应用
	Register(&ContractApp{})
}

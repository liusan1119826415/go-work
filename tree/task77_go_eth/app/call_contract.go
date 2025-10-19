package app

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"go-ethereum/config"
	"go-ethereum/count"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

type CallContractApp struct{}

//

func (d *CallContractApp) Name() string {
	return "call_contract"
}

func (d *CallContractApp) Run() error {

	client, err := ethclient.Dial("https://ethereum-sepolia-rpc.publicnode.com")
	if err != nil {
		log.Fatal(err)
	}

	contractAddress := "0xAaCB6E3fAA5a155e6Ca33AAD5F246d673276310B"

	// 验证地址上是否有合约代码
	bytecode, err := client.CodeAt(context.Background(), common.HexToAddress(contractAddress), nil)
	if err != nil {
		log.Fatal("检查合约地址失败:", err)
	}
	if len(bytecode) == 0 {
		fmt.Printf("❌ 错误: 地址 %s 上没有部署合约\n\n", contractAddress)
		fmt.Println("可能的原因：")
		fmt.Println("1. 合约地址错误")
		fmt.Println("2. 合约在不同的网络上（当前连接: Sepolia 测试网）")
		fmt.Println("3. 合约尚未部署")
		fmt.Println("\n解决方案：")
		fmt.Println("- 如需部署新合约，请运行: go run main.go tx_contract")
		fmt.Println("- 或修改 call_contract.go 中的 contractAddress 为正确的地址")
		return fmt.Errorf("合约不存在")
	}

	countContract, err := count.NewCount(common.HexToAddress(contractAddress), client)
	if err != nil {
		log.Fatal("连接合约失败:", err)
	}

	fmt.Printf("✅ 已连接到合约地址: %s\n\n", contractAddress)

	// 获取配置管理器
	configManage := config.NewConfigManager("my_config.json", "liusan123")
	privateKeyHex, err := configManage.GetPrivateKey()
	if err != nil {
		log.Fatal("获取私钥失败:", err)
	}

	privateKey, err := crypto.HexToECDSA(privateKeyHex)
	if err != nil {
		log.Fatal("解析私钥失败:", err)
	}

	// 获取公钥地址
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("无法转换公钥类型")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	fmt.Printf("发送者地址: %s\n\n", fromAddress.Hex())

	// 查询合约所有者
	callOpt := &bind.CallOpts{Context: context.Background()}
	owner, err := countContract.Owner(callOpt)
	if err != nil {
		log.Fatal("查询合约所有者失败:", err)
	}
	fmt.Printf("合约所有者: %s\n", owner.Hex())

	// 准备交易选项
	opt, err := bind.NewKeyedTransactorWithChainID(privateKey, big.NewInt(11155111))
	if err != nil {
		log.Fatal("创建交易器失败:", err)
	}

	// 调用 Increment 函数（注意大写）
	incrementValue := big.NewInt(3)
	fmt.Printf("\n正在调用 Increment 函数，增加值: %d\n", incrementValue)

	tx, err := countContract.Increment(opt, incrementValue)
	if err != nil {
		log.Fatal("调用 Increment 失败:", err)
	}

	fmt.Printf("✅ 交易已发送！\n")
	fmt.Printf("交易哈希: %s\n", tx.Hash().Hex())
	fmt.Printf("\n⏳ 等待交易确认...\n")

	// 等待交易被打包
	receipt, err := bind.WaitMined(context.Background(), client, tx)
	if err != nil {
		log.Fatal("等待交易确认失败:", err)
	}

	if receipt.Status == 1 {
		fmt.Printf("✅ 交易确认成功！\n")
		fmt.Printf("区块号: %d\n", receipt.BlockNumber)
		fmt.Printf("Gas 使用: %d\n\n", receipt.GasUsed)

		// 解析事件日志获取新的计数值
		for _, vLog := range receipt.Logs {
			event, err := countContract.ParseCountIncremented(*vLog)
			if err == nil {
				fmt.Printf("🎉 计数值已更新！\n")
				fmt.Printf("新的计数值: %s\n", event.NewCount.String())
				fmt.Printf("操作者: %s\n", event.By.Hex())
				fmt.Printf("时间戳: %s\n", event.Timestamp.String())
				break
			}
		}
	} else {
		fmt.Printf("❌ 交易执行失败\n")
	}

	fmt.Printf("\n可以在区块浏览器查看: https://sepolia.etherscan.io/tx/%s\n", tx.Hash().Hex())

	//计数减少
	decrementValue := big.NewInt(2)

	tx, err = countContract.Decrement(opt, decrementValue)
	if err != nil {
		log.Fatal("调用 Decrement 失败:", err)
	}

	fmt.Printf("\n正在调用 Decrement 函数，减少的值: %d\n", decrementValue)

	receipt, err = bind.WaitMined(context.Background(), client, tx)
	if err != nil {
		log.Fatal("等待交易确认失败:", err)
	}

	if receipt.Status == 1 {
		fmt.Printf("✅ 交易确认成功！\n")

		for _, vLog := range receipt.Logs {
			event, err := countContract.ParseCountDecremented(*vLog)
			if err == nil {
				fmt.Println("🎉 计数值已减少！")
				fmt.Printf("新的计数值", event.NewCount.String())
				fmt.Printf("操作者", event.By.Hex())
				fmt.Println("时间戳", event.Timestamp.String())
			}
		}
	}

	return nil
}

func init() {
	// 在包初始化时自动注册应用
	Register(&CallContractApp{})
}

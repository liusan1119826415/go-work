package app

import (
	"context"
	"fmt"
	"go-ethereum/count"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

type QueryCountApp struct{}

func (d *QueryCountApp) Name() string {
	return "query_count"
}

func (d *QueryCountApp) Run() error {

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
		fmt.Println("- 或修改 query_count.go 中的 contractAddress 为正确的地址")
		return fmt.Errorf("合约不存在")
	}

	countContract, err := count.NewCount(common.HexToAddress(contractAddress), client)
	if err != nil {
		log.Fatal("连接合约失败:", err)
	}

	fmt.Printf("📊 查询合约: %s\n\n", contractAddress)

	// 获取合约所有者
	callOpt := &bind.CallOpts{Context: context.Background()}
	owner, err := countContract.Owner(callOpt)
	if err != nil {
		log.Fatal("查询合约所有者失败:", err)
	}
	fmt.Printf("合约所有者: %s\n\n", owner.Hex())

	// 查询历史 Increment 事件
	fmt.Println("🔍 查询最近的 Increment 事件...")

	// 获取当前区块号
	currentBlock, err := client.BlockNumber(context.Background())
	if err != nil {
		log.Fatal("获取当前区块号失败:", err)
	}

	// 查询最近 10000 个区块的事件
	fromBlock := currentBlock - 10000
	if fromBlock < 0 {
		fromBlock = 0
	}

	filterOpts := &bind.FilterOpts{
		Start:   fromBlock,
		End:     &currentBlock,
		Context: context.Background(),
	}

	iter, err := countContract.FilterCountIncremented(filterOpts, nil)
	if err != nil {
		log.Fatal("查询事件失败:", err)
	}
	defer iter.Close()

	eventCount := 0
	var latestCount *big.Int

	for iter.Next() {
		eventCount++
		event := iter.Event
		latestCount = event.NewCount

		fmt.Printf("\n事件 #%d:\n", eventCount)
		fmt.Printf("  新计数值: %s\n", event.NewCount.String())
		fmt.Printf("  操作者: %s\n", event.By.Hex())
		fmt.Printf("  时间戳: %s\n", event.Timestamp.String())
		fmt.Printf("  区块号: %d\n", event.Raw.BlockNumber)
		fmt.Printf("  交易哈希: %s\n", event.Raw.TxHash.Hex())
	}

	if err := iter.Error(); err != nil {
		log.Fatal("遍历事件出错:", err)
	}

	if eventCount == 0 {
		fmt.Println("\n⚠️  未找到 Increment 事件")
		fmt.Println("提示：可能合约还没有被调用过，或者事件在更早的区块中")
	} else {
		fmt.Printf("\n✅ 共找到 %d 个 Increment 事件\n", eventCount)
		if latestCount != nil {
			fmt.Printf("🎯 最新的计数值: %s\n", latestCount.String())
		}
	}

	// 查询 Decrement 事件
	fmt.Println("\n🔍 查询最近的 Decrement 事件...")

	decrementIter, err := countContract.FilterCountDecremented(filterOpts, nil)
	if err != nil {
		log.Fatal("查询 Decrement 事件失败:", err)
	}
	defer decrementIter.Close()

	decrementCount := 0
	for decrementIter.Next() {
		decrementCount++
		event := decrementIter.Event

		fmt.Printf("\n事件 #%d:\n", decrementCount)
		fmt.Printf("  新计数值: %s\n", event.NewCount.String())
		fmt.Printf("  操作者: %s\n", event.By.Hex())
		fmt.Printf("  时间戳: %s\n", event.Timestamp.String())
		fmt.Printf("  区块号: %d\n", event.Raw.BlockNumber)
		fmt.Printf("  交易哈希: %s\n", event.Raw.TxHash.Hex())
	}

	if decrementCount == 0 {
		fmt.Println("\n⚠️  未找到 Decrement 事件")
	} else {
		fmt.Printf("\n✅ 共找到 %d 个 Decrement 事件\n", decrementCount)
	}

	return nil
}

func init() {
	// 在包初始化时自动注册应用
	Register(&QueryCountApp{})
}

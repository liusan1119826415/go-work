package app

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Demo1App 示例应用1
type Demo1App struct{}

func (d *Demo1App) Name() string {
	return "blockNumber"
}

func (d *Demo1App) Run() error {
	client, err := ethclient.Dial("https://ethereum-sepolia-rpc.publicnode.com")

	if err != nil {
		return err
	}

	//查询指定区块区块号信息
	blockNumber := big.NewInt(5671748)

	fmt.Println("Current block number:", blockNumber)

	block, err := client.BlockByNumber(context.Background(), blockNumber)
	if err != nil {
		return err
	}

	for _, tx := range block.Transactions() {
		fmt.Println("Transaction:", tx.Hash().Hex())

		fmt.Println("value", tx.Value().String())
		fmt.Println("block_timestamp", tx.Time())
		fmt.Println("gas", tx.Gas())
		//获取交易者
		sender, err := types.Sender(types.NewEIP155Signer(big.NewInt(11155111)), tx)
		if err != nil {
			return err
		}

		fmt.Println("sender", sender.Hex())

		//获取交易回执
		receipt, err := client.TransactionReceipt(context.Background(), tx.Hash())
		if err != nil {
			return err
		}

		fmt.Println(receipt.Status)
		fmt.Println(receipt.Logs)
		break
	}

	//获取区块哈希
	block_hash := common.HexToHash("0xae713dea1419ac72b928ebe6ba9915cd4fc1ef125a606f90f5e783c47cb1a4b5")

	count, err := client.TransactionCount(context.Background(), block_hash)
	if err != nil {
		return err
	}

	fmt.Println("transaction count:", count)

	for idx := uint(0); idx < count; idx++ {
		tx, err := client.TransactionInBlock(context.Background(), block_hash, idx)

		if err != nil {
			return err
		}

		fmt.Println("transaction:", tx.Hash().Hex())

		//获取交易
		tx, isPending, err := client.TransactionByHash(context.Background(), tx.Hash())
		if err != nil {
			return err
		}

		fmt.Println("isPending:", isPending)

		break

	}

	return nil
}

func init() {
	// 在包初始化时自动注册应用
	Register(&Demo1App{})
}

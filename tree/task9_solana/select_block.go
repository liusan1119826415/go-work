package main

import (
	"context"
	"fmt"
	"log"

	"github.com/blocto/solana-go-sdk/client"
	"github.com/blocto/solana-go-sdk/types"
)

// QueryBlockInfo 查询区块信息
func QueryBlockInfo() {
	// 创建 RPC 客户端
	c := client.NewClient("https://api.devnet.solana.com")

	// 获取最新区块高度
	slot, err := c.GetSlot(context.Background())
	if err != nil {
		log.Printf("获取区块高度失败: %v", err)
		return
	}

	fmt.Printf("当前区块高度 (Slot): %d\n", slot)

	// 获取区块信息
	block, err := c.GetBlock(context.Background(), slot)
	if err != nil {
		log.Printf("获取区块信息失败: %v", err)
		return
	}

	fmt.Printf("区块哈希: %s\n", block.Blockhash)
	fmt.Printf("父区块哈希: %s\n", block.PreviousBlockhash)
	fmt.Printf("交易数量: %d\n", len(block.Transactions))
}

// QueryAccountBalance 查询账户余额
func QueryAccountBalance() {
	c := client.NewClient("https://api.devnet.solana.com")

	// 创建一个示例账户
	account := types.NewAccount()
	fmt.Printf("查询账户: %s\n", account.PublicKey.ToBase58())

	// 查询余额
	balance, err := c.GetBalance(context.Background(), account.PublicKey.ToBase58())
	if err != nil {
		log.Printf("查询余额失败: %v", err)
		return
	}

	fmt.Printf("余额: %d lamports (%.9f SOL)\n", balance, float64(balance)/1e9)
}

package main

import (
	"context"
	"fmt"
	"log"

	"github.com/blocto/solana-go-sdk/client"
	"github.com/blocto/solana-go-sdk/common"
	"github.com/blocto/solana-go-sdk/program/system"
	"github.com/blocto/solana-go-sdk/types"
)

// 示例1：简单的 SOL 转账交易
func SimpleTransfer() {
	// 创建客户端
	c := client.NewClient("https://api.devnet.solana.com")

	// 创建发送方和接收方账户
	sender := types.NewAccount()
	receiver := types.NewAccount()

	fmt.Printf("发送方地址: %s\n", sender.PublicKey.ToBase58())
	fmt.Printf("接收方地址: %s\n", receiver.PublicKey.ToBase58())

	// 获取最新区块哈希
	response, err := c.GetLatestBlockhash(context.Background())
	if err != nil {
		log.Fatalf("获取区块哈希失败: %v", err)
	}

	// 创建转账指令
	instruction := system.Transfer(system.TransferParam{
		From:   sender.PublicKey,
		To:     receiver.PublicKey,
		Amount: 1_000_000, // 0.001 SOL (1 SOL = 1,000,000,000 lamports)
	})

	// 构建交易消息
	message := types.NewMessage(types.NewMessageParam{
		FeePayer:        sender.PublicKey,
		RecentBlockhash: response.Blockhash,
		Instructions:    []types.Instruction{instruction},
	})

	// 创建交易并签名
	tx, err := types.NewTransaction(types.NewTransactionParam{
		Message: message,
		Signers: []types.Account{sender},
	})
	if err != nil {
		log.Fatalf("创建交易失败: %v", err)
	}

	// 发送交易
	txHash, err := c.SendTransaction(context.Background(), tx)
	if err != nil {
		log.Fatalf("发送交易失败: %v", err)
	}

	fmt.Printf("交易已发送! 交易哈希: %s\n", txHash)
	fmt.Printf("在浏览器查看: https://explorer.solana.com/tx/%s?cluster=devnet\n", txHash)
}

// 示例2：创建账户交易
func CreateAccountTransaction() {
	c := client.NewClient("https://api.devnet.solana.com")

	// 创建支付者账户
	feePayer := types.NewAccount()

	// 创建新账户
	newAccount := types.NewAccount()

	fmt.Printf("新账户地址: %s\n", newAccount.PublicKey.ToBase58())

	// 获取最低租金豁免余额
	rentExemption, err := c.GetMinimumBalanceForRentExemption(context.Background(), 0)
	if err != nil {
		log.Fatalf("获取租金豁免金额失败: %v", err)
	}

	// 获取最新区块哈希
	response, err := c.GetLatestBlockhash(context.Background())
	if err != nil {
		log.Fatalf("获取区块哈希失败: %v", err)
	}

	// 创建账户指令
	instruction := system.CreateAccount(system.CreateAccountParam{
		From:     feePayer.PublicKey,
		New:      newAccount.PublicKey,
		Owner:    common.SystemProgramID,
		Lamports: rentExemption,
		Space:    0,
	})

	// 构建交易
	message := types.NewMessage(types.NewMessageParam{
		FeePayer:        feePayer.PublicKey,
		RecentBlockhash: response.Blockhash,
		Instructions:    []types.Instruction{instruction},
	})

	tx, err := types.NewTransaction(types.NewTransactionParam{
		Message: message,
		Signers: []types.Account{feePayer, newAccount}, // 需要两个签名
	})
	if err != nil {
		log.Fatalf("创建交易失败: %v", err)
	}

	// 发送交易
	txHash, err := c.SendTransaction(context.Background(), tx)
	if err != nil {
		log.Fatalf("发送交易失败: %v", err)
	}

	fmt.Printf("账户创建交易已发送! 交易哈希: %s\n", txHash)
}

// 示例3：批量转账（一个交易包含多个指令）
func BatchTransfer() {
	c := client.NewClient("https://api.devnet.solana.com")

	sender := types.NewAccount()
	receiver1 := types.NewAccount()
	receiver2 := types.NewAccount()
	receiver3 := types.NewAccount()

	fmt.Printf("发送方: %s\n", sender.PublicKey.ToBase58())

	// 获取最新区块哈希
	response, err := c.GetLatestBlockhash(context.Background())
	if err != nil {
		log.Fatalf("获取区块哈希失败: %v", err)
	}

	// 创建多个转账指令
	instructions := []types.Instruction{
		system.Transfer(system.TransferParam{
			From:   sender.PublicKey,
			To:     receiver1.PublicKey,
			Amount: 1_000_000,
		}),
		system.Transfer(system.TransferParam{
			From:   sender.PublicKey,
			To:     receiver2.PublicKey,
			Amount: 2_000_000,
		}),
		system.Transfer(system.TransferParam{
			From:   sender.PublicKey,
			To:     receiver3.PublicKey,
			Amount: 3_000_000,
		}),
	}

	// 构建交易
	message := types.NewMessage(types.NewMessageParam{
		FeePayer:        sender.PublicKey,
		RecentBlockhash: response.Blockhash,
		Instructions:    instructions, // 多个指令
	})

	tx, err := types.NewTransaction(types.NewTransactionParam{
		Message: message,
		Signers: []types.Account{sender},
	})
	if err != nil {
		log.Fatalf("创建交易失败: %v", err)
	}

	txHash, err := c.SendTransaction(context.Background(), tx)
	if err != nil {
		log.Fatalf("发送交易失败: %v", err)
	}

	fmt.Printf("批量转账交易已发送! 交易哈希: %s\n", txHash)
}

// RunTransactionExamples 运行所有交易示例
func RunTransactionExamples() {
	fmt.Println("=== Solana 交易创建示例 ===\n")

	fmt.Println("1. 简单转账")
	SimpleTransfer()

	// 取消注释以运行其他示例
	// fmt.Println("\n2. 创建账户")
	// CreateAccountTransaction()

	// fmt.Println("\n3. 批量转账")
	// BatchTransfer()
}

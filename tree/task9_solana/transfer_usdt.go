package main

import (
	"context"
	"fmt"
	"log"

	"solana-interactor/config"

	"github.com/blocto/solana-go-sdk/client"
	"github.com/blocto/solana-go-sdk/common"
	"github.com/blocto/solana-go-sdk/program/associated_token_account"
	"github.com/blocto/solana-go-sdk/program/token"
	"github.com/blocto/solana-go-sdk/types"
)

// TransferUSDT 转账 USDT (SPL Token)
func TransferUSDT() {
	// 加载配置
	cfg, err := config.LoadConfig("config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 1. 创建 RPC 客户端（从配置文件读取）
	c := client.NewClient(cfg.Network.RPCURL)

	// 2. 从配置文件读取私钥并导入账户
	privateKeyBase58 := cfg.Wallet.PrivateKeyBase58

	sender, err := types.AccountFromBase58(privateKeyBase58)
	if err != nil {
		log.Fatalf("从私钥导入账户失败: %v", err)
	}

	fmt.Printf("发送方地址: %s\n", sender.PublicKey.ToBase58())
	fmt.Printf("✅ 从配置文件加载私钥成功\n")

	// 3. 从配置文件读取 USDT Mint 地址
	usdtMint := common.PublicKeyFromString(cfg.Tokens.USDTMint)

	// 4. 接收方地址
	receiverAddress := common.PublicKeyFromString("8Ux1qSM9tgjwARjXcasmbtDJYsT5HVKchQTC9nZPBH4J")

	// 5. 查找或创建 Associated Token Account (ATA)
	// 发送方的 USDT Token 账户
	senderTokenAccount, _, err := common.FindAssociatedTokenAddress(
		sender.PublicKey,
		usdtMint,
	)
	if err != nil {
		log.Fatalf("查找发送方 Token 账户失败: %v", err)
	}
	fmt.Printf("发送方 USDT 账户: %s\n", senderTokenAccount.ToBase58())

	// 接收方的 USDT Token 账户
	receiverTokenAccount, _, err := common.FindAssociatedTokenAddress(
		receiverAddress,
		usdtMint,
	)
	if err != nil {
		log.Fatalf("查找接收方 Token 账户失败: %v", err)
	}
	fmt.Printf("接收方 USDT 账户: %s\n", receiverTokenAccount.ToBase58())

	// 6. 检查发送方 Token 账户余额
	tokenBalance, err := c.GetTokenAccountBalance(context.Background(), senderTokenAccount.ToBase58())
	if err != nil {
		log.Printf("获取 Token 余额失败: %v\n", err)
		log.Println("可能是账户不存在，需要先获取 USDT")
	} else {
		fmt.Printf("发送方 USDT 余额: %s\n", tokenBalance.UIAmountString)
	}

	// 7. 检查接收方 Token 账户是否存在
	receiverAccountInfo, err := c.GetAccountInfo(context.Background(), receiverTokenAccount.ToBase58())
	receiverAccountExists := err == nil && receiverAccountInfo.Owner.ToBase58() != ""

	// 8. 获取最新区块哈希
	recentBlockhash, err := c.GetLatestBlockhash(context.Background())
	if err != nil {
		log.Fatalf("获取最新区块哈希失败: %v", err)
	}

	// 9. 构建交易指令
	var instructions []types.Instruction

	// 如果接收方的 Token 账户不存在，需要先创建
	if !receiverAccountExists {
		fmt.Println("接收方 USDT 账户不存在，将自动创建...")
		createATAInstruction := associated_token_account.Create(
			associated_token_account.CreateParam{
				Funder:                 sender.PublicKey,
				Owner:                  receiverAddress,
				Mint:                   usdtMint,
				AssociatedTokenAccount: receiverTokenAccount,
			},
		)
		instructions = append(instructions, createATAInstruction)
	}

	// 转账指令
	// USDT 有 6 位小数，所以 1 USDT = 1,000,000 (最小单位)
	transferAmount := uint64(1_000_000) // 转账 1 USDT

	transferInstruction := token.Transfer(
		token.TransferParam{
			From:   senderTokenAccount,   // 发送方 Token 账户
			To:     receiverTokenAccount, // 接收方 Token 账户
			Auth:   sender.PublicKey,     // 授权者（发送方）
			Amount: transferAmount,       // 转账金额
		},
	)
	instructions = append(instructions, transferInstruction)

	// 10. 创建并签名交易
	tx, err := types.NewTransaction(types.NewTransactionParam{
		Signers: []types.Account{sender},
		Message: types.NewMessage(types.NewMessageParam{
			FeePayer:        sender.PublicKey,
			RecentBlockhash: recentBlockhash.Blockhash,
			Instructions:    instructions,
		}),
	})
	if err != nil {
		log.Fatalf("创建交易失败: %v", err)
	}

	// 11. 发送交易
	fmt.Printf("\n正在发送 USDT 转账交易...\n")
	fmt.Printf("转账金额: %.6f USDT\n", float64(transferAmount)/1e6)

	txHash, err := c.SendTransaction(context.Background(), tx)
	if err != nil {
		log.Fatalf("发送交易失败: %v", err)
	}

	fmt.Printf("\n✅ USDT 转账成功！\n")
	fmt.Printf("交易哈希: %s\n", txHash)
	fmt.Printf("在浏览器查看: https://explorer.solana.com/tx/%s?cluster=%s\n", txHash, cfg.Network.Cluster)

	// 12. 等待交易确认（可选）
	fmt.Println("\n等待交易确认...")
	// 可以通过 GetTransaction 轮询交易状态
}

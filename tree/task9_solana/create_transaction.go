package main

import (
	"context"
	"fmt"
	"log"

	"solana-interactor/config"

	"github.com/blocto/solana-go-sdk/client"
	"github.com/blocto/solana-go-sdk/common"
	"github.com/blocto/solana-go-sdk/program/system"
	"github.com/blocto/solana-go-sdk/types"
)

func CreateAndSendTransaction() {
	// 加载配置
	cfg, err := config.LoadConfig("config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 1. 创建 RPC 客户端（从配置文件读取）
	c := client.NewClient(cfg.Network.RPCURL)

	// 2. 从配置文件读取私钥并导入账户
	privateKeyBase58 := cfg.Wallet.PrivateKeyBase58

	// 从 Base58 私钥导入账户
	feePayer, err := types.AccountFromBase58(privateKeyBase58)
	if err != nil {
		log.Fatalf("从私钥导入账户失败: %v", err)
	}

	fmt.Printf("✅ 从配置文件加载私钥成功\n")
	fmt.Printf("发送方地址: %s\n", feePayer.PublicKey.ToBase58())

	// 检查账户余额
	balance, err := c.GetBalance(context.Background(), feePayer.PublicKey.ToBase58())
	if err != nil {
		log.Fatalf("获取余额失败: %v", err)
	}
	fmt.Printf("当前余额: %d lamports (%.9f SOL)\n", balance, float64(balance)/1e9)

	// 如果余额为0，提示用户领取测试代币
	if balance == 0 {
		fmt.Println("\n⚠️  账户余额为0，需要先获取测试SOL！")
		fmt.Println("请执行以下步骤：")
		fmt.Printf("1. 访问 Solana Devnet 水龙头: https://faucet.solana.com\n")
		fmt.Printf("2. 输入你的地址: %s\n", feePayer.PublicKey.ToBase58())
		fmt.Println("3. 领取测试 SOL 后再运行此程序")
		fmt.Println("\n或者使用命令行:")
		fmt.Printf("   solana airdrop 1 %s --url devnet\n", feePayer.PublicKey.ToBase58())
		log.Fatal("\n程序终止：需要先获取测试代币")
	}

	// 检查余额是否足够支付交易费用（约5000 lamports）和转账金额
	requiredAmount := uint64(1000000 + 5000) // 转账金额 + 预估手续费
	if balance < requiredAmount {
		fmt.Printf("\n⚠️  余额不足！当前: %d lamports, 需要: %d lamports\n", balance, requiredAmount)
		log.Fatal("请先获取足够的测试SOL")
	}

	// 3. 创建接收方地址
	receiver := common.PublicKeyFromString("8Ux1qSM9tgjwARjXcasmbtDJYsT5HVKchQTC9nZPBH4J") // 替换为实际接收地址

	// 4. 获取最新的区块哈希（交易需要）
	recentBlockhash, err := c.GetLatestBlockhash(context.Background())
	if err != nil {
		log.Fatalf("获取最新区块哈希失败: %v", err)
	}
	fmt.Printf("最新区块哈希: %s\n", recentBlockhash.Blockhash)

	// 5. 构建转账指令
	transferInstruction := system.Transfer(system.TransferParam{
		From:   feePayer.PublicKey, // 发送方
		To:     receiver,           // 接收方
		Amount: 1000000,            // 转账金额（lamports，1 SOL = 1,000,000,000 lamports）
	})

	// 6. 创建交易
	tx, err := types.NewTransaction(types.NewTransactionParam{
		Signers: []types.Account{feePayer}, // 签名者列表
		Message: types.NewMessage(types.NewMessageParam{
			FeePayer:        feePayer.PublicKey,                       // 手续费支付者
			RecentBlockhash: recentBlockhash.Blockhash,                // 最新区块哈希
			Instructions:    []types.Instruction{transferInstruction}, // 指令列表
		}),
	})
	if err != nil {
		log.Fatalf("创建交易失败: %v", err)
	}

	// 7. 发送交易
	txHash, err := c.SendTransaction(context.Background(), tx)
	if err != nil {
		log.Fatalf("发送交易失败: %v", err)
	}

	fmt.Printf("交易已发送，交易哈希: %s\n", txHash)

	// 8. 等待交易确认（可选）
	fmt.Println("等待交易确认...")
	fmt.Printf("在浏览器查看: https://explorer.solana.com/tx/%s?cluster=%s\n", txHash, cfg.Network.Cluster)
	// 可以通过 GetTransaction 轮询交易状态
}

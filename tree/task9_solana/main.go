package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	reader := bufio.NewReader(os.Stdin)

	for {
		fmt.Println("\n=== Solana Go SDK 示例程序 ===")
		fmt.Println("1. 查询区块信息")
		fmt.Println("2. 简单转账交易")
		fmt.Println("3. 创建账户交易")
		fmt.Println("4. 批量转账交易")
		fmt.Println("5. 查询账户余额")
		fmt.Println("6. 从助记词导入并发送交易 (新)")
		fmt.Println("7. 转账 USDT (SPL Token) (新)")
		fmt.Println("8. 事件监听服务演示 (新)")
		fmt.Println("0. 退出")
		fmt.Print("\n请选择操作 (0-8): ")

		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)

		switch input {
		case "1":
			fmt.Println("\n执行: 查询区块信息")
			QueryBlockInfo()
		case "2":
			fmt.Println("\n执行: 简单转账交易")
			CreateAndSendTransaction()
		case "3":
			fmt.Println("\n执行: 创建账户交易")
			CreateAccountTransaction()
		case "4":
			fmt.Println("\n执行: 批量转账交易")
			BatchTransfer()
		case "5":
			fmt.Println("\n执行: 查询账户余额")
			QueryAccountBalance()
		case "6":
			fmt.Println("\n执行: 从助记词导入并发送交易")
			CreateAndSendTransaction()
		case "7":
			fmt.Println("\n执行: 转账 USDT (SPL Token)")
			TransferUSDT()
		case "8":
			fmt.Println("\n执行: 事件监听服务演示")
			RunEventListenerDemo()
		case "0":
			fmt.Println("退出程序")
			return
		default:
			fmt.Println("无效选择，请重新输入")
		}
	}
}

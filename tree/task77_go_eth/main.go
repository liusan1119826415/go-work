package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"go-ethereum/app"
)

func main() {
	// 定义命令行参数
	appName := flag.String("app", "", "指定要运行的应用名称(多个应用用逗号分隔)")
	listApps := flag.Bool("list", false, "列出所有可用的应用")
	runAll := flag.Bool("all", false, "运行所有应用")
	flag.Parse()

	// 列出所有应用
	if *listApps {
		fmt.Println("可用的应用列表:")
		for _, name := range app.ListApps() {
			fmt.Printf("  - %s\n", name)
		}
		return
	}

	// 运行所有应用
	if *runAll {
		fmt.Println("开始运行所有应用...")
		if err := app.RunAll(); err != nil {
			log.Fatalf("运行应用失败: %v", err)
		}
		fmt.Println("\n所有应用运行完成!")
		return
	}

	// 运行指定的应用
	if *appName != "" {
		// 支持多个应用用逗号分隔
		appNames := strings.Split(*appName, ",")
		for _, name := range appNames {
			name = strings.TrimSpace(name)
			application, exists := app.GetApp(name)
			if !exists {
				log.Fatalf("应用 '%s' 不存在,使用 -list 查看可用应用", name)
			}
			fmt.Printf("\n正在运行应用: %s\n", name)
			if err := application.Run(); err != nil {
				log.Fatalf("运行应用 '%s' 失败: %v", name, err)
			}
		}
		fmt.Println("\n应用运行完成!")
		return
	}

	// 默认行为：显示帮助信息
	fmt.Println("Go-Ethereum 应用启动器")
	fmt.Println("\n使用方法:")
	fmt.Println("  go run main.go -list              # 列出所有可用应用")
	fmt.Println("  go run main.go -all               # 运行所有应用")
	fmt.Println("  go run main.go -app=demo1         # 运行指定应用")
	fmt.Println("  go run main.go -app=demo1,demo2   # 运行多个应用")
	fmt.Println("\n可用参数:")
	flag.PrintDefaults()
	fmt.Println("\n提示: 使用 -list 查看所有可用应用")
	os.Exit(0)
}

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"solana-interactor/config"

	"github.com/gagliardetto/solana-go"
	"github.com/gagliardetto/solana-go/rpc"
	"github.com/gagliardetto/solana-go/rpc/ws"
)

// EventListener Solana 事件监听服务
type EventListener struct {
	rpcClient *rpc.Client
	wsClient  *ws.Client
	config    *config.Config
	ctx       context.Context
	cancel    context.CancelFunc
}

// NewEventListener 创建事件监听器
func NewEventListener(cfg *config.Config) (*EventListener, error) {
	// 创建 RPC 客户端
	rpcClient := rpc.New(cfg.Network.RPCURL)

	ctx, cancel := context.WithCancel(context.Background())

	return &EventListener{
		rpcClient: rpcClient,
		config:    cfg,
		ctx:       ctx,
		cancel:    cancel,
	}, nil
}

// connectWebSocket 连接 WebSocket
func (el *EventListener) connectWebSocket() error {
	wsClient, err := ws.Connect(el.ctx, el.config.Network.WSURL)
	if err != nil {
		return fmt.Errorf("连接 WebSocket 失败: %w", err)
	}
	el.wsClient = wsClient
	return nil
}

// SubscribeSignature 订阅特定交易签名的状态变化
func (el *EventListener) SubscribeSignature(signature solana.Signature) error {
	if el.wsClient == nil {
		if err := el.connectWebSocket(); err != nil {
			return err
		}
	}

	fmt.Printf("📡 开始监听交易签名: %s\n", signature)

	sub, err := el.wsClient.SignatureSubscribe(
		signature,
		rpc.CommitmentFinalized,
	)
	if err != nil {
		return fmt.Errorf("订阅签名失败: %w", err)
	}

	// 在后台处理订阅事件
	go func() {
		defer sub.Unsubscribe()

		for {
			select {
			case <-el.ctx.Done():
				fmt.Println("停止监听交易签名")
				return
			default:
				got, err := sub.Recv(el.ctx)
				if err != nil {
					log.Printf("接收事件失败: %v\n", err)
					if el.config.EventListener.AutoReconnect {
						time.Sleep(time.Duration(el.config.EventListener.ReconnectInterval) * time.Second)
						continue
					}
					return
				}

				if got == nil {
					continue
				}

				fmt.Printf("\n🔔 交易状态更新\n")
				fmt.Printf("签名: %s\n", signature)

				// 处理错误
				if got.Value.Err != nil {
					fmt.Printf("❌ 交易失败: %v\n", got.Value.Err)
				} else {
					fmt.Printf("✅ 交易确认成功\n")
				}

				fmt.Printf("时间: %s\n", time.Now().Format("2006-01-02 15:04:05"))
				fmt.Printf("================================\n")
			}
		}
	}()

	return nil
}

// SubscribeAccount 订阅账户变化
func (el *EventListener) SubscribeAccount(accountPubkey solana.PublicKey) error {
	if el.wsClient == nil {
		if err := el.connectWebSocket(); err != nil {
			return err
		}
	}

	fmt.Printf("📡 开始监听账户: %s\n", accountPubkey)

	sub, err := el.wsClient.AccountSubscribe(
		accountPubkey,
		rpc.CommitmentFinalized,
	)
	if err != nil {
		return fmt.Errorf("订阅账户失败: %w", err)
	}

	go func() {
		defer sub.Unsubscribe()

		for {
			select {
			case <-el.ctx.Done():
				fmt.Println("停止监听账户")
				return
			default:
				got, err := sub.Recv(el.ctx)
				if err != nil {
					log.Printf("接收账户事件失败: %v\n", err)
					if el.config.EventListener.AutoReconnect {
						time.Sleep(time.Duration(el.config.EventListener.ReconnectInterval) * time.Second)
						continue
					}
					return
				}

				if got == nil {
					continue
				}

				fmt.Printf("\n🔔 账户状态更新\n")
				fmt.Printf("账户: %s\n", accountPubkey)
				fmt.Printf("余额: %d lamports\n", got.Value.Lamports)
				fmt.Printf("所有者: %s\n", got.Value.Owner)
				fmt.Printf("时间: %s\n", time.Now().Format("2006-01-02 15:04:05"))
				fmt.Printf("================================\n")
			}
		}
	}()

	return nil
}

// SubscribeLogs 订阅程序日志
func (el *EventListener) SubscribeLogs(programID solana.PublicKey) error {
	if el.wsClient == nil {
		if err := el.connectWebSocket(); err != nil {
			return err
		}
	}

	fmt.Printf("📡 开始监听程序日志: %s\n", programID)

	sub, err := el.wsClient.LogsSubscribeMentions(
		programID,
		rpc.CommitmentFinalized,
	)
	if err != nil {
		return fmt.Errorf("订阅日志失败: %w", err)
	}

	go func() {
		defer sub.Unsubscribe()

		for {
			select {
			case <-el.ctx.Done():
				fmt.Println("停止监听程序日志")
				return
			default:
				got, err := sub.Recv(el.ctx)
				if err != nil {
					log.Printf("接收日志事件失败: %v\n", err)
					if el.config.EventListener.AutoReconnect {
						time.Sleep(time.Duration(el.config.EventListener.ReconnectInterval) * time.Second)
						continue
					}
					return
				}

				if got == nil {
					continue
				}

				fmt.Printf("\n📝 程序日志\n")
				fmt.Printf("签名: %s\n", got.Value.Signature)
				fmt.Printf("日志内容:\n")
				for _, log := range got.Value.Logs {
					fmt.Printf("  %s\n", log)
				}
				if got.Value.Err != nil {
					fmt.Printf("❌ 错误: %v\n", got.Value.Err)
				}
				fmt.Printf("时间: %s\n", time.Now().Format("2006-01-02 15:04:05"))
				fmt.Printf("================================\n")
			}
		}
	}()

	return nil
}

// SubscribeSlot 订阅区块槽位更新
func (el *EventListener) SubscribeSlot() error {
	if el.wsClient == nil {
		if err := el.connectWebSocket(); err != nil {
			return err
		}
	}

	fmt.Printf("📡 开始监听区块槽位更新\n")

	sub, err := el.wsClient.SlotSubscribe()
	if err != nil {
		return fmt.Errorf("订阅槽位失败: %w", err)
	}

	go func() {
		defer sub.Unsubscribe()

		for {
			select {
			case <-el.ctx.Done():
				fmt.Println("停止监听槽位")
				return
			default:
				got, err := sub.Recv(el.ctx)
				if err != nil {
					log.Printf("接收槽位事件失败: %v\n", err)
					if el.config.EventListener.AutoReconnect {
						time.Sleep(time.Duration(el.config.EventListener.ReconnectInterval) * time.Second)
						continue
					}
					return
				}

				if got == nil {
					continue
				}

				fmt.Printf("⛓️  新区块 - Slot: %d, Parent: %d, Root: %d\n",
					got.Slot, got.Parent, got.Root)
			}
		}
	}()

	return nil
}

// Stop 停止事件监听
func (el *EventListener) Stop() {
	fmt.Println("\n正在停止事件监听服务...")
	el.cancel()
	if el.wsClient != nil {
		el.wsClient.Close()
	}
}

// RunEventListenerDemo 运行事件监听演示
func RunEventListenerDemo() {
	fmt.Println("=== Solana 事件监听服务演示 ===\n")

	// 加载配置
	cfg, err := config.LoadConfig("config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 创建事件监听器
	listener, err := NewEventListener(cfg)
	if err != nil {
		log.Fatalf("创建事件监听器失败: %v", err)
	}

	// 订阅区块槽位更新
	err = listener.SubscribeSlot()
	if err != nil {
		log.Fatalf("订阅槽位失败: %v", err)
	}

	// 示例：订阅特定账户（替换为实际账户地址）
	// 这里使用 System Program 作为示例
	systemProgram := solana.MustPublicKeyFromBase58("8Ux1qSM9tgjwARjXcasmbtDJYsT5HVKchQTC9nZPBH4J")
	err = listener.SubscribeAccount(systemProgram)
	if err != nil {
		log.Printf("订阅账户失败: %v", err)
	}

	// 示例：订阅特定交易签名（需要替换为实际的交易签名）
	// exampleSignature := solana.MustSignatureFromBase58("your_transaction_signature_here")
	// err = listener.SubscribeSignature(exampleSignature)
	// if err != nil {
	// 	log.Printf("订阅签名失败: %v", err)
	// }

	// 等待中断信号
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	fmt.Println("\n事件监听服务已启动，按 Ctrl+C 停止...\n")

	<-sigChan
	listener.Stop()
	fmt.Println("事件监听服务已停止")
}

package utils

import (
	"context"
	"fmt"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

func WaitForTransactionReceiptV2(client *ethclient.Client, txHash common.Hash) (*types.Receipt, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)

	defer cancel()

	for {

		select {
		case <-ctx.Done():
			return nil, fmt.Errorf("等待交易确认超时")
		default:
			receipt, err := client.TransactionReceipt(context.Background(), txHash)

			if err != nil {
				time.Sleep(2 * time.Second)

				continue
			}
			return receipt, nil

		}
	}
}

package app

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"

	"go-ethereum/config"
	"go-ethereum/utils"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Demo2App 示例应用2
type Demo2App struct{}

//

func (d *Demo2App) Name() string {
	return "tx_eth"
}

func (d *Demo2App) Run() error {

	fmt.Println("tx_eth is running")
	client, err := ethclient.Dial("https://ethereum-sepolia-rpc.publicnode.com")
	if err != nil {
		log.Fatal(err)
	}

	configManager := config.NewConfigManager("my_config.json", "liusan123")
	privateKey, err := configManager.GetPrivateKey()
	if err != nil {
		log.Fatal(err)
	}

	privateKeyHex, err := crypto.HexToECDSA(privateKey)

	if err != nil {
		log.Fatal(err)
	}

	publicKey := privateKeyHex.Public()

	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)

	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)

	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal(err)
	}

	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	toAddress := common.HexToAddress("0x083eDF0e0F6F0FA579f21631E877DF34CE568783")
	value := big.NewInt(10000000000000000)
	gasLimit := uint64(300000)
	var data []byte
	tx := types.NewTransaction(nonce, toAddress, value, gasLimit, gasPrice, data)

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKeyHex)

	if err != nil {
		log.Fatal(err)
	}

	err = client.SendTransaction(context.Background(), signedTx)

	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("tx sent: ", signedTx.Hash().Hex())

	fmt.Println("等待交易确认...")
	receipt, err := utils.WaitForTransactionReceiptV2(client, signedTx.Hash())

	if err != nil {
		log.Fatal("交易确认失败:", err)
	}

	fmt.Println("交易成功:", receipt.Status)

	return nil
}

func init() {
	// 在包初始化时自动注册应用
	Register(&Demo2App{})
}

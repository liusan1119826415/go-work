package app

import (
	"context"
	"crypto/ecdsa"
	"fmt"

	"golang.org/x/crypto/sha3"

	"go-ethereum/config"
	"go-ethereum/utils"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"

	"github.com/ethereum/go-ethereum/crypto"

	"github.com/ethereum/go-ethereum/ethclient"
)

// Demo1App 示例应用1
type Demo3App struct{}

func (d *Demo3App) Name() string {
	return "tx_usdc"
}

func (d *Demo3App) Run() error {

	client, err := ethclient.Dial("https://ethereum-sepolia-rpc.publicnode.com")
	if err != nil {
		log.Fatal(err)
	}

	cofigManger := config.NewConfigManager("my_config.json", "liusan123")

	privateKey, err := cofigManger.GetPrivateKey()
	if err != nil {
		log.Fatal(err)
	}
	privateKeyECDSA, err := crypto.HexToECDSA(privateKey)
	if err != nil {
		log.Fatal(err)
	}
	publicKey := privateKeyECDSA.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("public key type assertion failed")
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

	// 增加 Gas 价格以确保交易被快速处理
	gasPrice = new(big.Int).Mul(gasPrice, big.NewInt(110))
	gasPrice = new(big.Int).Div(gasPrice, big.NewInt(100))

	to := common.HexToAddress("0x083eDF0e0F6F0FA579f21631E877DF34CE568783")

	contractAddress := common.HexToAddress("0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238")

	transferFnSignature := []byte("transfer(address,uint256)")

	hash := sha3.NewLegacyKeccak256()

	// 将函数签名写入哈希计算器
	hash.Write(transferFnSignature)

	// MethodID
	methodID := hash.Sum(nil)[:4]

	pasddedAddress := common.LeftPadBytes(to.Bytes(), 32)

	amount := new(big.Int)

	amount.SetString("10000000", 10)

	paddedAmount := common.LeftPadBytes(amount.Bytes(), 32)

	var data []byte

	data = append(data, methodID...)
	data = append(data, pasddedAddress...)
	data = append(data, paddedAmount...)

	gasLimit, err := client.EstimateGas(context.Background(), ethereum.CallMsg{
		From: fromAddress,
		To:   &contractAddress,
		Data: data,
	})

	if err != nil {
		log.Fatal(err)
	}

	gasLimit = gasLimit * 120 / 100

	//检查账户余额和代币余额
	usdcBlance, err := getTokenBalance(client, fromAddress, contractAddress)
	if err != nil {
		log.Fatal(err)
	}

	usdtActual := new(big.Float).SetInt(usdcBlance)

	usdtActual.Quo(usdtActual, big.NewFloat(1000000))
	fmt.Printf("USDT 余额: %s (实际: %s USDT)\n", usdcBlance.String(), usdtActual.Text('f', 6))

	// 检查余额是否足够
	if usdcBlance.Cmp(amount) < 0 {
		log.Fatal("USDC 余额不足")
	}

	// ERC-20 转账时 value 必须为 0，转账金额在 data 中编码
	tx := types.NewTransaction(nonce, contractAddress, big.NewInt(0), gasLimit, gasPrice, data)
	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKeyECDSA)
	if err != nil {
		log.Fatal(err)
	}

	err = client.SendTransaction(context.Background(), signedTx)

	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("交易已发送: %s\n", signedTx.Hash().Hex())

	fmt.Println("等待交易确认...")

	receipt, err := utils.WaitForTransactionReceiptV2(client, signedTx.Hash())
	if err != nil {
		log.Fatal("交易确认失败:", err)
	}
	fmt.Println("交易成功:", receipt.Status)

	return nil
}

func getTokenBalance(client *ethclient.Client, adress, contractAddress common.Address) (*big.Int, error) {
	balanceOfSignature := []byte("balanceOf(address)")
	hash := sha3.NewLegacyKeccak256()

	hash.Write(balanceOfSignature)
	methodID := hash.Sum(nil)[:4]

	//编码地址参数
	paddedAddress := common.LeftPadBytes(adress.Bytes(), 32)
	var data []byte

	data = append(data, methodID...)
	data = append(data, paddedAddress...)

	result, err := client.CallContract(context.Background(), ethereum.CallMsg{
		To:   &contractAddress,
		Data: data,
	}, nil)
	if err != nil {
		return nil, err
	}

	return new(big.Int).SetBytes(result), nil

}

func init() {
	// 在包初始化时自动注册应用
	Register(&Demo3App{})
}

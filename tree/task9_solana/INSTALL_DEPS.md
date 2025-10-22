# 安装依赖说明

## 问题说明

你的 Phantom 钱包地址是 `3PixJx4woQaYuwpTVX9Trg5tYsZ3njd1McXfj2KKR63D`，但程序生成的地址不同。

这是因为助记词可以派生出多个地址，钱包使用的是 **BIP44 标准派生路径**：`m/44'/501'/0'/0'`

## 需要安装的依赖

```bash
cd d:\project\go-work\tree\task9_solana

# 安装 BIP39（助记词）库
go get github.com/luxfi/go-bip39

# 安装 BIP32（密钥派生）库
go get github.com/luxfi/go-bip32

# 整理依赖
go mod tidy
```

## 安装步骤

1. 打开 PowerShell 或命令提示符
2. 切换到项目目录：
   ```powershell
   cd d:\project\go-work\tree\task9_solana
   ```

3. 执行安装命令：
   ```powershell
   go get github.com/luxfi/go-bip39
   go get github.com/luxfi/go-bip32
   go mod tidy
   ```

4. 等待安装完成后，修改 `create_transaction.go` 第21行，填入你的24个助记词

5. 运行程序：
   ```powershell
   go run main.go create_transaction.go select_block.go transaction_examples.go
   ```

## BIP44 派生路径说明

- `m/44'` - BIP44 标准
- `501'` - Solana 的币种编号
- `0'` - 账户索引（第一个账户）
- `0'` - 地址索引（第一个地址）

使用正确的派生路径后，生成的地址将与 Phantom 钱包显示的地址一致。

## 验证

安装完成后，程序会显示：
- 发送方地址应该是：`3PixJx4woQaYuwpTVX9Trg5tYsZ3njd1McXfj2KKR63D`
- 账户余额
- 如果余额为0，会提示如何获取测试 SOL

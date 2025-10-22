# 如何从 Phantom 钱包导出私钥

## ⚠️ 安全警告
- **私钥非常重要**，拥有私钥就拥有账户的完全控制权
- **永远不要**将私钥分享给他人
- **不要**将私钥上传到公共代码库
- 仅在测试环境使用

## 从 Phantom 钱包导出私钥

### 步骤 1：打开 Phantom 钱包
1. 点击浏览器中的 Phantom 扩展图标
2. 解锁钱包（输入密码）

### 步骤 2：访问设置
1. 点击左下角的 **齿轮图标**（设置）
2. 在设置菜单中找到你的钱包账户

### 步骤 3：导出私钥
1. 点击你想导出私钥的账户
2. 找到 **"Export Private Key"**（导出私钥）选项
3. 输入你的钱包密码确认
4. **复制显示的私钥字符串**

私钥格式类似：
```
5Jxxx...xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
这是一个 Base58 编码的字符串，长度约为 87-88 个字符。

## 使用私钥

### 修改代码
打开 `create_transaction.go`，找到第 21 行：

```go
privateKeyBase58 := "你的Base58格式私钥字符串"
```

将你从 Phantom 导出的私钥粘贴到这里：

```go
privateKeyBase58 := "5Jxxx...你的完整私钥字符串...xxxxx"
```

### 修改接收地址
找到第 54 行：

```go
receiver := common.PublicKeyFromString("8Ux1qSM9tgjwARjXcasmbtDJYsT5HVKchQTC9nZPBH4J")
```

替换为你想要发送 SOL 的目标地址。

## 运行程序

```powershell
cd d:\project\go-work\tree\task9_solana
go run .
```

选择菜单选项 **6**：从私钥导入并发送交易

## 程序会做什么

1. ✓ 从私钥导入账户
2. ✓ 显示你的钱包地址（应该是 `3PixJx4woQaYuwpTVX9Trg5tYsZ3njd1McXfj2KKR63D`）
3. ✓ 检查账户余额
4. ✓ 如果余额不足，提示如何获取测试 SOL
5. ✓ 发送交易并显示交易哈希

## 如果余额为 0

访问 Solana Devnet 水龙头：
- 网址：https://faucet.solana.com
- 输入地址：`3PixJx4woQaYuwpTVX9Trg5tYsZ3njd1McXfj2KKR63D`
- 点击领取测试 SOL

## 字节数组格式（备选方案）

如果你有字节数组格式的私钥（64字节），可以使用备选方法：

在 `create_transaction.go` 中取消注释第 28-35 行的代码：

```go
privateKeyBytes := []byte{
    // 填入你的 64 字节私钥
    123, 45, 67, 89, ... // 共 64 个数字
}
feePayer, err := types.AccountFromBytes(privateKeyBytes)
if err != nil {
    log.Fatalf("从私钥字节导入账户失败: %v", err)
}
```

并注释掉第 24-26 行的 Base58 导入代码。

## 检查地址是否正确

运行程序后，检查显示的地址：
```
发送方地址: 3PixJx4woQaYuwpTVX9Trg5tYsZ3njd1McXfj2KKR63D
```

如果地址匹配，说明私钥导入成功！✅

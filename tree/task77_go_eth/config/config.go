package config

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"os"

	"golang.org/x/crypto/pbkdf2"
)

// Config 配置结构体
type Config struct {
	// 网络配置
	Network struct {
		RPCURL       string `json:"rpc_url"`  // RPC 节点地址
		WebSocketURL string `json:"ws_url"`   // WebSocket 节点地址
		ChainID      int64  `json:"chain_id"` // 链 ID
	} `json:"network"`

	// 账户配置
	Account struct {
		EncryptedPrivateKey string `json:"encrypted_private_key"` // 加密的私钥
		Address             string `json:"address"`               // 账户地址
		Salt                string `json:"salt"`                  // 加密盐值
	} `json:"account"`

	// 合约配置
	Contracts struct {
		USDC string `json:"usdc"` // USDC 合约地址
		USDT string `json:"usdt"` // USDT 合约地址
	} `json:"contracts"`
}

// ConfigManager 配置管理器
type ConfigManager struct {
	configPath string
	password   string
}

// NewConfigManager 创建配置管理器
func NewConfigManager(configPath, password string) *ConfigManager {
	return &ConfigManager{
		configPath: configPath,
		password:   password,
	}
}

// 生成随机盐值
func generateSalt() ([]byte, error) {
	salt := make([]byte, 32)
	_, err := rand.Read(salt)
	return salt, err
}

// 从密码和盐值生成密钥
func deriveKey(password string, salt []byte) []byte {
	return pbkdf2.Key([]byte(password), salt, 10000, 32, sha256.New)
}

// 加密数据
func encrypt(data []byte, password string) ([]byte, []byte, error) {
	// 生成随机盐值
	salt, err := generateSalt()
	if err != nil {
		return nil, nil, err
	}

	// 从密码和盐值生成密钥
	key := deriveKey(password, salt)

	// 创建 AES 加密器
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, nil, err
	}

	// 创建 GCM 模式
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, nil, err
	}

	// 生成随机 nonce
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, nil, err
	}

	// 加密数据
	ciphertext := gcm.Seal(nonce, nonce, data, nil)

	return ciphertext, salt, nil
}

// 解密数据
func decrypt(encryptedData []byte, password string, salt []byte) ([]byte, error) {
	// 从密码和盐值生成密钥
	key := deriveKey(password, salt)

	// 创建 AES 解密器
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}

	// 创建 GCM 模式
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	// 提取 nonce
	nonceSize := gcm.NonceSize()
	if len(encryptedData) < nonceSize {
		return nil, fmt.Errorf("加密数据太短")
	}

	nonce, ciphertext := encryptedData[:nonceSize], encryptedData[nonceSize:]

	// 解密数据
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return nil, err
	}

	return plaintext, nil
}

// LoadConfig 加载配置文件
func (cm *ConfigManager) LoadConfig() (*Config, error) {
	// 检查配置文件是否存在
	if _, err := os.Stat(cm.configPath); os.IsNotExist(err) {
		// 如果配置文件不存在，创建默认配置
		return cm.createDefaultConfig()
	}

	// 读取配置文件
	data, err := os.ReadFile(cm.configPath)
	if err != nil {
		return nil, fmt.Errorf("读取配置文件失败: %v", err)
	}

	// 解析 JSON
	var config Config
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("解析配置文件失败: %v", err)
	}

	return &config, nil
}

// SaveConfig 保存配置文件
func (cm *ConfigManager) SaveConfig(config *Config) error {
	// 将配置转换为 JSON
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return fmt.Errorf("序列化配置失败: %v", err)
	}

	// 写入文件
	if err := os.WriteFile(cm.configPath, data, 0600); err != nil {
		return fmt.Errorf("写入配置文件失败: %v", err)
	}

	return nil
}

// SetPrivateKey 设置私钥（加密存储）
func (cm *ConfigManager) SetPrivateKey(privateKey string) error {
	config, err := cm.LoadConfig()
	if err != nil {
		return err
	}

	// 加密私钥
	encryptedKey, salt, err := encrypt([]byte(privateKey), cm.password)
	if err != nil {
		return fmt.Errorf("加密私钥失败: %v", err)
	}

	// 更新配置
	config.Account.EncryptedPrivateKey = base64.StdEncoding.EncodeToString(encryptedKey)
	config.Account.Salt = base64.StdEncoding.EncodeToString(salt)

	// 保存配置
	return cm.SaveConfig(config)
}

// GetPrivateKey 获取私钥（解密）
func (cm *ConfigManager) GetPrivateKey() (string, error) {
	config, err := cm.LoadConfig()
	if err != nil {
		return "", err
	}

	// 检查是否有加密的私钥
	if config.Account.EncryptedPrivateKey == "" {
		return "", fmt.Errorf("未找到加密的私钥")
	}

	// 解码加密的私钥和盐值
	encryptedData, err := base64.StdEncoding.DecodeString(config.Account.EncryptedPrivateKey)
	if err != nil {
		return "", fmt.Errorf("解码加密私钥失败: %v", err)
	}

	salt, err := base64.StdEncoding.DecodeString(config.Account.Salt)
	if err != nil {
		return "", fmt.Errorf("解码盐值失败: %v", err)
	}

	// 解密私钥
	decryptedKey, err := decrypt(encryptedData, cm.password, salt)
	if err != nil {
		return "", fmt.Errorf("解密私钥失败: %v", err)
	}

	return string(decryptedKey), nil
}

// createDefaultConfig 创建默认配置
func (cm *ConfigManager) createDefaultConfig() (*Config, error) {
	config := &Config{
		Network: struct {
			RPCURL       string `json:"rpc_url"`
			WebSocketURL string `json:"ws_url"`
			ChainID      int64  `json:"chain_id"`
		}{
			RPCURL:       "https://rpc.ankr.com/eth_sepolia/",
			WebSocketURL: "wss://rpc.ankr.com/eth_sepolia/ws/",
			ChainID:      11155111, // Sepolia 测试网链 ID
		},
		Account: struct {
			EncryptedPrivateKey string `json:"encrypted_private_key"`
			Address             string `json:"address"`
			Salt                string `json:"salt"`
		}{},
		Contracts: struct {
			USDC string `json:"usdc"`
			USDT string `json:"usdt"`
		}{
			USDC: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
			USDT: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
		},
	}

	// 保存默认配置
	if err := cm.SaveConfig(config); err != nil {
		return nil, err
	}

	return config, nil
}

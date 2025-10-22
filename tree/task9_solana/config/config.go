package config

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// Config 应用配置结构
type Config struct {
	Network       NetworkConfig       `yaml:"network"`
	Wallet        WalletConfig        `yaml:"wallet"`
	Tokens        TokensConfig        `yaml:"tokens"`
	EventListener EventListenerConfig `yaml:"event_listener"`
}

// NetworkConfig 网络配置
type NetworkConfig struct {
	RPCURL  string `yaml:"rpc_url"`
	WSURL   string `yaml:"ws_url"`
	Cluster string `yaml:"cluster"`
}

// WalletConfig 钱包配置
type WalletConfig struct {
	PrivateKeyBase58 string `yaml:"private_key_base58"`
}

// TokensConfig 代币配置
type TokensConfig struct {
	USDTMint string `yaml:"usdt_mint"`
}

// EventListenerConfig 事件监听配置
type EventListenerConfig struct {
	AutoReconnect     bool     `yaml:"auto_reconnect"`
	ReconnectInterval int      `yaml:"reconnect_interval"`
	Signatures        []string `yaml:"signatures"`
}

var globalConfig *Config

// LoadConfig 从文件加载配置
func LoadConfig(configPath string) (*Config, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("读取配置文件失败: %w", err)
	}

	var config Config
	err = yaml.Unmarshal(data, &config)
	if err != nil {
		return nil, fmt.Errorf("解析配置文件失败: %w", err)
	}

	globalConfig = &config
	return &config, nil
}

// GetConfig 获取全局配置
func GetConfig() *Config {
	if globalConfig == nil {
		// 尝试加载默认配置文件
		config, err := LoadConfig("config.yaml")
		if err != nil {
			panic(fmt.Sprintf("加载配置失败: %v", err))
		}
		return config
	}
	return globalConfig
}

// GetPrivateKey 获取私钥
func GetPrivateKey() string {
	return GetConfig().Wallet.PrivateKeyBase58
}

// GetRPCURL 获取 RPC URL
func GetRPCURL() string {
	return GetConfig().Network.RPCURL
}

// GetWSURL 获取 WebSocket URL
func GetWSURL() string {
	return GetConfig().Network.WSURL
}

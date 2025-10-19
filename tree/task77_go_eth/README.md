# Go-Ethereum 应用启动器

这是一个灵活的应用入口文件，可以方便地运行 `app` 目录下的所有程序。

## 项目结构

```
task77_go_eth/
├── main.go          # 入口文件
├── app/             # 应用目录
│   ├── app.go       # 应用接口和注册管理
│   ├── demo1.go     # 示例应用1
│   └── demo2.go     # 示例应用2
├── go.mod
└── README.md
```

## 使用方法

### 1. 列出所有可用应用
```bash
go run main.go -list
```

### 2. 运行所有应用
```bash
go run main.go -all
```

### 3. 运行指定应用
```bash
go run main.go -app=demo1
```

### 4. 运行多个应用（用逗号分隔）
```bash
go run main.go -app=demo1,demo2
```

### 5. 显示帮助信息
```bash
go run main.go
```

## 如何添加新应用

在 `app` 目录下创建新的 Go 文件，实现 `App` 接口：

```go
package app

import "fmt"

// MyNewApp 你的新应用
type MyNewApp struct{}

func (m *MyNewApp) Name() string {
	return "mynewapp"  // 应用名称
}

func (m *MyNewApp) Run() error {
	fmt.Println("你的应用逻辑...")
	// 在这里实现你的应用逻辑
	return nil
}

func init() {
	// 在包初始化时自动注册应用
	Register(&MyNewApp{})
}
```

保存文件后，新应用会自动注册，无需修改 `main.go`。

## 核心特性

1. **自动注册机制**：通过 `init()` 函数，所有应用在导入时自动注册
2. **灵活运行**：支持运行单个、多个或全部应用
3. **统一接口**：所有应用实现相同的 `App` 接口
4. **易于扩展**：添加新应用只需在 `app` 目录创建新文件

## 示例输出

```
$ go run main.go -list
可用的应用列表:
  - demo1
  - demo2

$ go run main.go -all
开始运行所有应用...
正在运行应用: demo1
===== Demo1 应用开始运行 =====
这是第一个示例应用
当前时间: 2025-10-16 20:51:14
===== Demo1 应用运行完成 =====
正在运行应用: demo2
===== Demo2 应用开始运行 =====
这是第二个示例应用
1到10的和: 55
===== Demo2 应用运行完成 =====

所有应用运行完成!
```

## 技术实现

- **接口设计**：定义统一的 `App` 接口，包含 `Name()` 和 `Run()` 方法
- **注册表模式**：使用全局 `Registry` 管理所有应用
- **命令行参数**：使用 `flag` 包处理命令行参数
- **包初始化**：利用 Go 的 `init()` 函数实现自动注册

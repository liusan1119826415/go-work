package app

import (
	"fmt"
)

// App 定义应用接口
type App interface {
	// Name 返回应用名称
	Name() string
	// Run 运行应用
	Run() error
}

// Registry 应用注册表
var Registry = make(map[string]App)

// Register 注册应用
func Register(app App) {
	Registry[app.Name()] = app
}

// GetApp 获取应用
func GetApp(name string) (App, bool) {
	app, exists := Registry[name]
	return app, exists
}

// ListApps 列出所有应用
func ListApps() []string {
	apps := make([]string, 0, len(Registry))
	for name := range Registry {
		apps = append(apps, name)
	}
	return apps
}

// RunAll 运行所有应用
func RunAll() error {
	for name, app := range Registry {
		fmt.Printf("正在运行应用: %s\n", name)
		if err := app.Run(); err != nil {
			return fmt.Errorf("应用 %s 运行失败: %v", name, err)
		}
	}
	return nil
}

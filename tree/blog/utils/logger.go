package utils

import (
	"os"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var (
	logger     *zap.Logger
	once       sync.Once
	loggerInit bool
)

// InitLogger 初始化日志记录器
func InitLogger() {
	once.Do(func() {
		config := zap.NewProductionConfig()

		// 设置日志级别
		config.Level = zap.NewAtomicLevelAt(zap.InfoLevel)

		// 设置时间格式
		config.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder

		// 创建日志目录
		if err := os.MkdirAll("logs", 0755); err != nil {
			// 如果创建目录失败，只输出到控制台
			config.OutputPaths = []string{"stdout"}
			config.ErrorOutputPaths = []string{"stderr"}
		} else {
			// 设置日志输出
			config.OutputPaths = []string{
				"logs/app.log",
				"stdout",
			}
			config.ErrorOutputPaths = []string{
				"logs/error.log",
				"stderr",
			}
		}

		var err error
		logger, err = config.Build()
		if err != nil {
			// 如果zap初始化失败，使用一个简单的备用logger
			logger = zap.NewExample()
			logger.Error("Failed to initialize zap logger, using example logger", zap.Error(err))
		}

		loggerInit = true
	})
}

// GetLogger 获取日志记录器
func GetLogger() *zap.Logger {
	if !loggerInit {
		InitLogger()
	}
	return logger
}

// LogRequest 记录请求日志
func LogRequest(c *gin.Context, status int, latency time.Duration) {
	logger := GetLogger()

	if logger == nil {
		// 如果logger仍然为nil，直接返回避免panic
		return
	}

	logger.Info("HTTP Request",
		zap.String("method", c.Request.Method),
		zap.String("path", c.Request.URL.Path),
		zap.Int("status", status),
		zap.String("ip", c.ClientIP()),
		zap.Duration("latency", latency),
		zap.String("user_agent", c.Request.UserAgent()),
	)
}

// LogError 记录错误日志
func LogError(message string, err error, fields ...zap.Field) {
	logger := GetLogger()

	if logger == nil {
		return
	}

	allFields := append([]zap.Field{
		zap.String("error", err.Error()),
	}, fields...)

	logger.Error(message, allFields...)
}

// LogInfo 记录信息日志
func LogInfo(message string, fields ...zap.Field) {
	logger := GetLogger()
	if logger == nil {
		return
	}
	logger.Info(message, fields...)
}

// LogWarn 记录警告日志
func LogWarn(message string, fields ...zap.Field) {
	logger := GetLogger()
	if logger == nil {
		return
	}
	logger.Warn(message, fields...)
}

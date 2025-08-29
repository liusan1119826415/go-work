package middlewares

import (
	"time"

	"blog/utils"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// ErrorHandlerMiddleware 全局错误处理中间件
func ErrorHandlerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 确保日志器已初始化
		utils.GetLogger()

		start := time.Now()

		// 处理请求
		c.Next()

		// 记录请求日志
		utils.LogRequest(c, c.Writer.Status(), time.Since(start))

		// 如果有错误，记录错误日志
		if len(c.Errors) > 0 {
			for _, err := range c.Errors {
				utils.LogError("Request error", err.Err,
					zap.String("path", c.Request.URL.Path),
					zap.String("method", c.Request.Method),
				)
			}
		}
	}
}

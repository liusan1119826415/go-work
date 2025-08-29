package middlewares

import (
	"blog/types"
	"blog/utils"
	"fmt"
	"net/http"
	"runtime"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// 全局异常捕获中间件
func RecoveryMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				// 获取堆栈信息
				stack := make([]byte, 4096)
				length := runtime.Stack(stack, true)
				stackInfo := string(stack[:length])

				// 记录错误日志
				utils.LogError("panic recovered", fmt.Errorf("%v", err),
					zap.String("stack", stackInfo),
				)

				// 返回500错误
				c.JSON(http.StatusInternalServerError, types.ErrorResponse(fmt.Errorf("internal server error")))

				// 终止请求链
				c.Abort()
			}
		}()

		c.Next()
	}
}

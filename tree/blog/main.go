package main

import (
	"blog/config"
	"blog/controllers"
	"blog/middlewares"
	"blog/models"
	"blog/utils"
	"fmt"
	"net/http"
	"os"

	"crypto/rand"
	"encoding/base64"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func GenerateSecret() string {
	b := make([]byte, 32)
	rand.Read(b)
	return base64.StdEncoding.EncodeToString(b)
}
func main() {

	config.ConnectDB()
	utils.InitLogger()
	logger := utils.GetLogger()

	defer func() {
		if logger != nil {
			logger.Sync()
		}
	}()

	db := config.GetDB()

	os.Setenv("JWT_SECRET", "2dTDGB968OzNmMEBcOv4c1ag4K/wsksG7RCgVhYUTkE=")

	err := db.AutoMigrate(&models.User{}, &models.Post{})

	if err != nil {
		if logger != nil {
			logger.Fatal("Database migration failed", zap.Error(err))
		} else {
			panic("Database migration failed: " + err.Error())
		}
	}
	fmt.Println("数据库迁移成功")

	r := gin.Default()

	r.Use(middlewares.RecoveryMiddleware())

	r.Use(middlewares.ErrorHandlerMiddleware())

	authController := controllers.NewAuthController()

	r.POST("/signup", authController.SignUp)

	r.POST("/login", authController.Login)

	protected := r.Group("/api")

	protected.Use(middlewares.JwtAuthMiddleware())
	{
		protected.GET("/profile", func(ctx *gin.Context) {
			userID := ctx.MustGet("userID").(uint)

			ctx.JSON(http.StatusOK, gin.H{"user_id": userID})
		})

		protected.POST("/createposts", controllers.NewPostsController().CreatePosts)

		protected.GET("/getpostslist", controllers.NewPostsController().GetPostsList)

		protected.GET("/getPostDetail", controllers.NewPostsController().GetPostsDetail)

		protected.POST("/updatePosts", controllers.NewPostsController().EditPost)

		protected.POST("/deletePosts", controllers.NewPostsController().DeletePost)

		protected.POST("/createComment", controllers.NewCommentController().CreateComment)

		protected.GET("/getCommentByPost", controllers.NewCommentController().GetCommentByPost)

	}

	if err := r.Run(":8080"); err != nil {
		logger.Fatal("http 服务启动失败", zap.Error(err))
	}
}

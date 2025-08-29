package controllers

import (
	"blog/config"
	"blog/middlewares"
	"blog/models"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type PostsController struct {
	DB *gorm.DB
}

func NewPostsController() *PostsController {
	return &PostsController{
		config.GetDB(),
	}
}

type PostsInput struct {
	Title   string `json:"title" binding:"required,min=1,max=255"`
	Content string `json:"content" binding:"required,min=1"`
	UserID  uint64
}

type UpdatePostsInput struct {
	ID      uint64 `json:"id" binding:"required"`
	Title   string `json:"title" binding:"required,min=1,max=255"`
	Content string `json:"content" binding:"required,min=1"`
}

type DeletePostsID struct {
	ID uint64 `json:"id" binding:"required"`
}

func (po *PostsController) CreatePosts(c *gin.Context) {
	var postsInput PostsInput

	if err := c.ShouldBind(&postsInput); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := c.MustGet("userID").(uint)
	posts := models.Post{
		UserID:  userID,
		Title:   postsInput.Title,
		Content: postsInput.Content,
	}

	if err := po.DB.Create(&posts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "文章发布失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "文章发布成功"})

}

func (po *PostsController) GetPostsList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize := 10

	if page < 1 {
		page = 1
	}

	offset := (page - 1) * pageSize

	var total int64

	var postsList []models.Post
	if err := po.DB.Model(&models.Post{}).Count(&total).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取文章总数失败"})
		return
	}
	if err := po.DB.Offset(offset).Limit(pageSize).Find(&postsList).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取文章失败"})
		return
	}

	//计算总页数

	totalPages := int(total) / pageSize

	if int(total)%pageSize != 0 {
		totalPages++
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "获取成功",
		"data": gin.H{
			"list":        postsList,
			"total":       total,
			"page":        page,
			"page_size":   pageSize,
			"total_pages": totalPages,
		}})

}

func (po *PostsController) GetPostsDetail(c *gin.Context) {
	var postsDetail models.Post
	id := c.Query("id")

	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID不能为空"})
		return
	}

	PostID, _ := strconv.ParseUint(id, 10, 32)

	if err := po.DB.Where("id = ?", PostID).First(&postsDetail).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "文章不存在"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "获取成功",
		"data":    postsDetail,
	})

}

func (po *PostsController) EditPost(c *gin.Context) {
	var Post models.Post
	var updateInput UpdatePostsInput
	if err := c.ShouldBind(&updateInput); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数错误" + err.Error()})
		return
	}

	if err := po.DB.Where("id = ?", updateInput.ID).First(&Post).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "文章不存在"})
		return
	}

	//只要文章作者才能修改

	if middlewares.GetCurrentUserId(c) != Post.UserID {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权修改此文章"})
		return
	}

	Post.Title = updateInput.Title
	Post.Content = updateInput.Content

	po.DB.Save(&Post)
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "修改成功",
	})

}

func (po *PostsController) DeletePost(c *gin.Context) {
	var post models.Post
	var deleteIDInput DeletePostsID
	if err := c.ShouldBind(&deleteIDInput); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数错误"})
		return
	}

	PostID := deleteIDInput.ID

	if err := po.DB.Where("id = ?", PostID).First(&post).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "文章不存在"})
		return
	}

	if middlewares.GetCurrentUserId(c) != post.UserID {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权删除此文章"})
		return
	}

	if err := po.DB.Where("id = ? and user_id = ?", PostID, middlewares.GetCurrentUserId(c)).Delete(&models.Post{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "文章删除失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "文章删除成功",
	})

}

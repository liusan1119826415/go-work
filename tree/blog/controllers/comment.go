package controllers

import (
	"blog/config"
	"blog/middlewares"
	"blog/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type CommentSearch struct {
	Page     uint   `form:"page"`      // 添加form标签用于查询参数
	PageSize uint   `form:"page_size"` // 添加form标签
	PostID   uint32 `form:"post_id" binding:"required"`
}

type CommentInput struct {
	PostID  uint64 `json:"post_id" binding:"required"`
	Content string `json:"content" binding:"required,min=1"`
}

type CommentController struct {
	DB *gorm.DB
}

func NewCommentController() *CommentController {
	return &CommentController{
		config.GetDB(),
	}
}

func (co *CommentController) CreateComment(c *gin.Context) {
	var commentInput CommentInput

	if err := c.ShouldBind(&commentInput); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数错误" + err.Error()})
	}

	UserID := middlewares.GetCurrentUserId(c)

	comment := models.Comment{
		UserID:  UserID,
		Content: commentInput.Content,
		PostID:  uint(commentInput.PostID),
	}

	var postDetail models.Post

	if err := co.DB.Where("id = ?", commentInput.PostID).First(&postDetail).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "文章不存在"})
		return
	}

	if err := co.DB.Create(&comment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "评论发布失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"code": 200, "message": "评论发布成功"})

}

func (co *CommentController) GetCommentByPost(c *gin.Context) {

	var commentSearch CommentSearch

	if err := c.ShouldBind(&commentSearch); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数错误" + err.Error()})
		return
	}

	var comments []models.Comment

	if commentSearch.Page == 0 {
		commentSearch.Page = 1
	}

	if commentSearch.PageSize == 0 {
		commentSearch.PageSize = 10
	}

	if commentSearch.PageSize > 100 {
		commentSearch.PageSize = 100
	}

	var total int64

	if err := co.DB.Model(&models.Comment{}).Where("post_id = ?", commentSearch.PostID).Count(&total).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取评论总数失败"})
		return
	}

	offset := int((commentSearch.Page - 1) * commentSearch.PageSize)

	if err := co.DB.Where("post_id = ?", commentSearch.PostID).Offset(offset).Limit(int(commentSearch.PageSize)).Find(&comments).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取评论列表失败"})
		return
	}

	totalPage := int(total) / int(commentSearch.PageSize)

	if int(total)%int(commentSearch.PageSize) != 0 {
		totalPage++
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "获取成功",
		"data": gin.H{
			"list":        comments,
			"total":       total,
			"page":        commentSearch.Page,
			"page_size":   commentSearch.PageSize,
			"total_pages": totalPage,
		}})

}

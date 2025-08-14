package main

import (
	"fmt"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type User struct {
	ID    uint   `gorm:"primaryKey"`
	Name  string `gorm:"size:50;not null"`
	Email string `gorm:"uniqueIndex;size:50;not null"`
	Count uint   `gorm:"default:0;not null"`
	//一对多：一个用户多篇文章
	Posts []Post `gorm:"foreignKey:UserID"`
}

type Post struct {
	ID      uint   `gorm:"primaryKey"`
	Title   string `gorm:"size:200;not null"`
	Content string `gorm:"type:text"`
	Count   uint   `gorm:"default:0;not null"`
	Status  int8   `gorm:"type:tinyint(1);default:0;not null;comment:'0=未评论,1=已评论'"`
	UserID  uint   //外键

	User User

	//一对多评论

	Comments []Comment `gorm:"foreignKey:PostID"`
}

type Comment struct {
	ID uint `gorm:"primaryKey"`

	Content string `gorm:"type:text;not null"`

	PostID uint

	Post Post
}

func main() {

	dns := "root:phpcj@tcp(localhost:3306)/test?charset=utf8mb4&parseTime=true"

	db, err := gorm.Open(mysql.Open(dns), &gorm.Config{})

	if err != nil {
		log.Fatal("数据库连接失败", err)
	}

	err = db.AutoMigrate(&User{}, &Post{}, &Comment{})

	if err != nil {
		log.Fatal("数据库迁移失败", err)
	}

	fmt.Println("数据库表迁移成功")

	//getUserPostsWithComment(db, 1)

	//getPostWithMostComments(db)

	// post := Post{Title: "goods文章", Content: "文章内容", UserID: 1}

	// result := db.Create(&post)
	// fmt.Println()
	// fmt.Println("===", result.RowsAffected)
	var comment Comment
	db.First(&comment, 2)
	db.Delete(&comment)

}

func getUserPostsWithComment(db *gorm.DB, userID uint) {
	var user User

	//先查询用户再预加载文档和评论
	err := db.Preload("Posts.Comments").First(&user, userID).Error

	if err != nil {
		log.Fatal("查询数据失败", err)
	}
	fmt.Printf("用户：%s\n", user.Name)

	for _, post := range user.Posts {
		fmt.Printf("文章===%s\n", post.Title)

		for _, comment := range post.Comments {
			fmt.Printf("评论:%s\n", comment.Content)
		}
	}

}

func getPostWithMostComments(db *gorm.DB) {
	var post Post

	err := db.Model(&Post{}).Select("posts.*,count(comments.id) as comment_num").
		Joins("left join comments on posts.id=comments.post_id").
		Group("posts.id").
		Order("comment_num desc").
		Limit(1).
		Scan(&post).Error

	if err != nil {
		log.Fatal("查询失败", err)
	}

	fmt.Printf("评论最多的文章:%s", post.Title)

}

func (p *Post) AfterCreate(tx *gorm.DB) (err error) {

	// var user User
	// tx.First(&user, p.UserID)
	// user.Count = user.Count + 1
	// tx.Save(&user)
	// return nil

	return tx.Model(&User{}).Where("id = ?", p.UserID).UpdateColumn("count", gorm.Expr("count - ?", 1)).Error
}

func (c *Comment) AfterDelete(tx *gorm.DB) (err error) {

	var count int64

	tx.Model(&Comment{}).Where("post_id= ?", c.PostID).Count(&count)

	var post Post
	if err := tx.First(&post, c.PostID).Error; err != nil {
		return err
	}

	if count == 0 {
		post.Status = 0
	} else {
		post.Status = 1
	}

	post.Count = uint(count)

	return tx.Save(&post).Error

}

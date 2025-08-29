package models

import (
	"time"

	"gorm.io/gorm"
)

type Comment struct {
	gorm.Model
	ID uint `gorm:"primaryKey"`

	UserID     uint
	User       User
	PostID     uint
	Post       Post
	Content    string    `gorm:"type:text"`
	Created_at time.Time `gorm:"autoCreateTime"`
	Updated_at time.Time `gorm:"autoCreateTime"`
}

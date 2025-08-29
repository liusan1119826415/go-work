package models

import (
	"time"

	"gorm.io/gorm"
)

type Post struct {
	gorm.Model
	ID         uint `gorm:"primaryKey"`
	UserID     uint
	User       User
	Title      string    `gorm:"not null"`
	Content    string    `gorm:"type:text"`
	Created_at time.Time `gorm:"autoCreateTime"`
	Updated_at time.Time `gorm:"autoCreateTime"`
	Comments   []Comment `gorm:"foreignKey:PostID"`
}

package models

import (
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	ID          uint      `gorm:"primaryKey"`
	Username    string    `gorm:"size:100;unique;not null"`
	Password    string    `gorm:"size:255;not null"`
	Email       string    `gorm:"size:50;unique;not null"`
	LastLoginAt time.Time `gorm:"column:last_login_at" json:"last_login_at"` // 改为指针类型
	LastLoginIP string    `gorm:"size:50;column:last_login_ip" json:"last_login_ip"`
	Created_at  time.Time `gorm:"autoCreateTime"`
	Updated_at  time.Time `gorm:"autoCreateTime"`
	Posts       []Post    `gorm:"foreignKey:UserID"`
	Comments    []Comment `gorm:"foreignKey:UserID"`
}

func (user *User) HashPassword(password string) error {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)

	if err != nil {
		return err
	}

	user.Password = string(bytes)
	return nil
}

func (user *User) CheckPassword(providedPassword string) error {
	err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(providedPassword))
	if err != nil {
		return err
	}
	return nil
}

package config

import (
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
)

var DB *gorm.DB

func ConnectDB() {

	dsn := "root:phpcj@tcp(localhost:3306)/blog?charset=utf8&parseTime=true"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		NamingStrategy: schema.NamingStrategy{
			TablePrefix: "blog_",
		},
	})
	if err != nil {
		log.Fatal("数据库连接失败")
	}

	DB = db
}

func GetDB() *gorm.DB {

	return DB
}

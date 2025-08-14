package main

import (
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"
)

type Book struct {
	Id     int     `db:"id"`
	Title  string  `db:"title"`
	Author string  `db:"author"`
	Price  float64 `db:"price"`
}

func main() {

	dns := "root:phpcj@tcp(localhost:3306)/test?charset=utf8mb4&parseTime=true&loc=Local"

	db, err := sqlx.Open("mysql", dns)

	if err != nil {
		log.Fatal("数据库连接失败")
	}

	defer db.Close()

	if err = db.Ping(); err != nil {
		log.Fatal("数据库无法连接", err)
	}

	bookData := getBook(db, 50)

	for _, v := range bookData {
		fmt.Printf("id=%d==书名==%s==作者==%s==价格==%.2f\n", v.Id, v.Title, v.Author, v.Price)
	}

}

func getBook(db *sqlx.DB, price float64) []Book {

	var book []Book

	err := db.Select(&book, "select id,title,author,price from books where price > ? ", price)
	if err != nil {
		log.Fatal("查询数据失败", err)
	}

	return book
}

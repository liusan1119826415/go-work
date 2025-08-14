package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

func main() {

	dsn := "root:phpcj@tcp(localhost:3306)/test?charset=utf8mb4&parseTime=True&loc=Local"

	db, err := sql.Open("mysql", dsn)

	if err != nil {
		log.Fatal("连接数据库失败", err)
	}

	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatal("数据库无法连接", err)
	}

	fmt.Println("数据库连接成功")

	err = Transfer(db, 1, 2, 100)
	if err != nil {
		log.Fatal("转账失败", err)
	}

	fmt.Println("转账成功")

}

func Transfer(db *sql.DB, from_id int, to_id int, amount float64) error {

	tx, err := db.Begin()

	if err != nil {
		log.Fatal("事物错误", err)
	}

	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		} else if err != nil {
			tx.Rollback()
		} else {
			err = tx.Commit()
		}
	}()

	var balance float64

	err = tx.QueryRow("select balance from accounts where id = ? for update", from_id).Scan(&balance)
	fmt.Println(balance)
	if err != nil {
		return fmt.Errorf("查询余额失败", err)
	}

	if balance < amount {
		return fmt.Errorf("账户余额不足,无法转账")
	}

	//扣除转账的金额

	_, err = tx.Exec("update accounts set balance = balance-? where id = ?", amount, from_id)

	if err != nil {
		return fmt.Errorf("转账失败，扣除金额失败", err)
	}
	//增加账户余额
	_, err = tx.Exec("update accounts set balance = balance + ? where id = ?", amount, to_id)

	if err != nil {
		return fmt.Errorf("增加余额失败", err)
	}

	_, err = tx.Exec(" insert into transactions (from_account_id, to_account_id, amount) values (?,?,?)", from_id, to_id, amount)

	if err != nil {
		return fmt.Errorf("记录交易失败", err)
	}

	return nil
}

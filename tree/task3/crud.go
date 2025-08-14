package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

type Person struct {
	Name  string
	Age   int
	Grade string
}

func main() {
	//建立连接数据库
	dsn := "root:phpcj@tcp(localhost:3306)/test?charset=utf8mb4&parseTime=True&loc=Local"

	db, err := sql.Open("mysql", dsn)

	if err != nil {
		log.Fatal("连接数据库失败:", err)
	}

	defer db.Close()

	//测试连接

	if err := db.Ping(); err != nil {
		log.Fatal("数据库无法连接:", err)
	}

	fmt.Println("数据库连接成功")

	p1 := Person{Name: "张三", Age: 30, Grade: "三年级"}

	if err := insrerStudent(db, p1); err != nil {
		log.Fatal("插入失败:", err)
	}

	fmt.Println("插入成功")

	if err := updateStudent(db, "张三", "四年级"); err != nil {
		log.Fatal("更新失败", err)
	}

	fmt.Println("更新成功")

	students, err := selectStudent(db, 18)

	fmt.Println("查询结果：")
	for _, s := range students {
		fmt.Printf("姓名: %s, 年龄: %d, 年级: %s\n", s.Name, s.Age, s.Grade)
	}

	if err := deleteStudent(db, 15); err != nil {
		log.Fatal("删除失败", err)
	}

	fmt.Println("删除成功")

}

func insrerStudent(db *sql.DB, p Person) error {
	query := `insert into students (name, age, grade ) values (?,?,?)`

	_, err := db.Exec(query, p.Name, p.Age, p.Grade)

	return err

}

func updateStudent(db *sql.DB, name string, grade string) error {

	swl := `update  students set grade = ? where name = ?`

	_, err := db.Exec(swl, grade, name)

	return err

}

func selectStudent(db *sql.DB, age int) ([]Person, error) {
	swl := `select name,age,grade from students where age>?`

	row, err := db.Query(swl, age)

	if err != nil {
		return nil, err
	}

	defer row.Close()

	var students []Person
	for row.Next() {
		var p Person

		if err := row.Scan(&p.Name, &p.Age, &p.Grade); err != nil {
			return nil, err
		}

		students = append(students, p)

	}

	return students, nil

}

func deleteStudent(db *sql.DB, age int) error {

	swl := "delete from students where age < ?"

	_, err := db.Exec(swl, age)

	return err

}

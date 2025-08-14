package main

import (
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"
)

type Employee struct {
	Id         int
	Name       string
	Department string
	Salary     float64
}

func main() {

	dsn := "root:phpcj@tcp(localhost:3306)/test?charset=utf8mb4&parseTime=true&loc=Local"

	db, err := sqlx.Open("mysql", dsn)

	if err != nil {
		log.Fatal("数据库连接失败", err)
	}

	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatal("数据库无法连接", err)
	}

	employeeData := selectEmployee(db, "技术部")

	for _, r := range employeeData {
		fmt.Printf("员工姓名:%s 部门:%s 工资:%.2f\n", r.Name, r.Department, r.Salary)
	}

	salaryData := getMaxSalary(db)

	fmt.Printf("员工最高工资====姓名:%s 部门:%s 工资:%.2f\n", salaryData.Name, salaryData.Department, salaryData.Salary)

}

func selectEmployee(db *sqlx.DB, name string) []Employee {

	var employee []Employee

	err := db.Select(&employee, "select id,name,department, salary from employees where department=?", name)

	if err != nil {
		log.Fatal("查询失败", err)
	}

	return employee

}

func getMaxSalary(db *sqlx.DB) Employee {
	var employee Employee
	err := db.Get(&employee, "select id,name,department, salary from employees order by salary desc limit 1")
	if err != nil {
		log.Fatal("查询数据失败", err)
	}
	return employee
}

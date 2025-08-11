package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

type Employee struct {
	*Person
	EmployeeID int
}

func (e *Employee) PrintInfo() {
	fmt.Println("===员工姓名%s===年龄%d", e.Name, e.Age)
}

func main() {

	Employee := &Employee{Person: &Person{Name: "山姆", Age: 20}, EmployeeID: 112}

	Employee.PrintInfo()

}

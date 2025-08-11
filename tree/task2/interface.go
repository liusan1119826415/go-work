package main

import "fmt"

type Shape interface {
	Area()
	Perimeter()
}

type Rectangle struct {
	name string
}

type Circle struct {
	name string
}

func (r *Rectangle) Area() {
	fmt.Println(r.name)
}

func (r *Rectangle) Perimeter() {
	fmt.Println("ArePerimetera")
}

func (c *Circle) Area() {
	fmt.Println("CircleArea")
}

func (c *Circle) Perimeter() {
	fmt.Println("Circle==Perimeter")
}

func main() {

	obj := &Rectangle{name: "shanmu"}

	obj.Area()
}

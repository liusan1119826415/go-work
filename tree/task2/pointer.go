package main

import (
	"fmt"
)

func main() {
	num := 5
	//题目1
	fmt.Println(edit(&num))

	//题目2
	Slices := []int{1, 2, 3, 4, 5, 6}

	count(&Slices)

}

func edit(nums *int) int {
	return *nums + 10
}

func count(Slices *[]int) {

	for i := range *Slices {
		(*Slices)[i] *= 2

	}

	fmt.Println(*Slices)
}

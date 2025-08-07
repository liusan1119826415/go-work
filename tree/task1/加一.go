package main

import "fmt"

func main() {

	arr5 := [][]int{{1, 2, 3, 4, 5}, {1, 2}, {9, 9, 9}, {9}, {0}}
	for _, v := range arr5 {
		arr1 := one(v)

		fmt.Print(arr1)
	}

}

func one(arr []int) []int {

	n := len(arr)

	for i := n - 1; i >= 0; i-- {
		arr[i]++

		if arr[i] < 10 {
			return arr
		}

		arr[i] = 0
	}

	return append([]int{1}, arr...)
}

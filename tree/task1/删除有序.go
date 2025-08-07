package main

import "fmt"

func main() {

	arr := [][]int{
		{1, 2, 2, 3, 4, 5, 6, 6, 7},
		{2, 3, 3, 4, 4, 5, 7, 8},
	}

	for _, v := range arr {

		len1 := deleteNum(v)

		fmt.Println("长度===", len1)
	}
}

func deleteNum(nums []int) int {

	n := len(nums)

	if n == 0 {
		return 0
	}

	i := 0

	for j := 1; j < len(nums); j++ {
		if nums[j] != nums[i] {
			i++
			nums[i] = nums[j]
		}

	}
	return i + 1
}

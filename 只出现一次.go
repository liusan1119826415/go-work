package main

import "fmt"

func singleNumber(nums []int) int {

	countMap := make(map[int]int)
	for _, num := range nums {
		countMap[num]++
	}

	for num, count := range countMap {
		if count == 1 {
			return num
		}
	}
	return -1
}

func main() {
	nums := []int{4, 1, 2, 1, 2}
	//TODO只出现一次
	fmt.Println("只出现一次的数字是:", singleNumber(nums))

}

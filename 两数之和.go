package main

import "fmt"

func main() {

	nums := []int{1, 2, 3, 4, 5, 6, 7, 8}

	target := 7

	numsMap := make(map[int]int)
	// for i := 0; i < len(nums); i++ {
	// 	com := target - nums[i]

	// 	if _, ok := numsMap[com]; ok {

	// 		fmt.Println(nums[i])
	// 	}

	// 	numsMap[nums[i]] = com
	// }

	for _, v := range nums {
		com := target - v
		fmt.Println("=======", com)
		if _, ok := numsMap[com]; ok {
			fmt.Printf("找到两个数: %d 和 %d\n",
				com, v)
		}

		numsMap[v] = com
		println("+++++++++", v)
	}

}

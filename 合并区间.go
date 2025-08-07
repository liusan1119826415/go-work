package main

import (
	"fmt"
	"sort"
)

func main() {

	arrtest := [][][]int{
		{{1, 3}, {2, 6}, {8, 10}, {15, 18}},
		{{1, 4}, {4, 5}},
		{{1, 4}, {0, 4}},
		{{1, 4}, {2, 3}},
		{},
		{{1, 3}},
	}

	for _, v := range arrtest {

		fmt.Println(merge(v))
	}

}
func merge(arr [][]int) [][]int {

	if len(arr) <= 1 {
		return arr
	}

	sort.Slice(arr, func(i, j int) bool {
		return arr[i][0] < arr[j][0]
	})

	merged := [][]int{arr[0]}
	fmt.Print("====merged", merged)
	for i := 1; i < len(arr); i++ {
		fmt.Println("len====", len(merged)-1)
		last := merged[len(merged)-1]
		fmt.Println("=====", last)
		currents := arr[i]

		if currents[0] <= last[1] {
			if currents[1] > last[1] {
				last[1] = currents[1]
			}
		} else {
			merged = append(merged, currents)
		}
	}

	return merged

}

package main

import "fmt"

func longString(strs []string) string {

	if len(strs) == 0 {
		return ""
	}

	prefix := strs[0]

	for i := 1; i < len(strs); i++ {
		j := 0

		for ; j < len(prefix) && j < len(strs[i]); j++ {
			if prefix[j] != strs[i][j] {
				break
			}
		}
		prefix = prefix[:j]

		if prefix == "" {
			return ""
		}

	}
	return prefix
}

func main() {

	testCases := [][]string{
		{"flower", "flow", "flight"},
		{"dog", "racecar", "car"},
		{"", "abc", "def"},
		{"abc", "abc", "abc"},
		{"a"},
		{},
	}

	for _, v := range testCases {
		fmt.Printf("输入：%v\n", v)

		fmt.Printf("输出: %s \n", longString(v))
	}
}

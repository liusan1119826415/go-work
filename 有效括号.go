package main

import "fmt"

func isValid(s string) bool {
	pairs := map[rune]rune{
		'(': ')',
		'[': ']',
		'{': '}',
	}

	stack := []rune{}

	for _, char := range s {

		if _, ok := pairs[char]; ok {
			stack = append(stack, char)
		} else {
			if len(stack) == 0 {
				return false
			}
			top := stack[len(stack)-1]
			fmt.Println("===", char, pairs[top])
			if pairs[top] != char {

				return false
			}
			stack = stack[:len(stack)-1]
		}
	}

	return len(stack) == 0

}

func main() {

	teststring := []string{"()", "()}", "{})", "[]{}"}

	for _, v := range teststring {
		boolval := isValid(v)
		fmt.Println("是否为正常括号===", boolval)
	}
}

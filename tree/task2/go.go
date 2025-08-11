package main

import (
	"fmt"
	"sync"
)

func main() {

	//题目1
	var wg sync.WaitGroup
	wg.Add(2)
	go func() {
		defer wg.Done()
		for i := 1; i < 10; i += 2 {
			fmt.Println("奇数%d", i)
		}
	}()

	go func() {

		defer wg.Done()
		for i := 2; i < 10; i += 2 {
			fmt.Println("偶数%d", i)
		}

	}()

	wg.Wait()
	fmt.Println("打印完成")

	//题目2

}

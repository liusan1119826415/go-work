package main

import (
	"fmt"
	"sync"
)

func acceptNum(ch chan<- int, wg *sync.WaitGroup) {
	defer wg.Done()

	for i := 1; i <= 10; i++ {
		ch <- i
	}

	close(ch)
}

func PrintNum(ch <-chan int, wg *sync.WaitGroup) {
	defer wg.Done()

	for num := range ch {
		fmt.Println("===num===", num)
	}

}

func main() {

	ch := make(chan int)

	var wg sync.WaitGroup
	wg.Add(2)

	go acceptNum(ch, &wg)

	go PrintNum(ch, &wg)

	wg.Wait()

	fmt.Println("程序结束")

	//另外版本

	chan_num := make(chan int)
	go func() {
		for i := 1; i <= 10; i++ {
			chan_num <- i
		}
		close(chan_num)
	}()

	for v := range chan_num {
		fmt.Println(v)
	}

	chh := make(chan int)
	go func() {
		chh <- 78
	}()

	fmt.Println(<-chh)

}

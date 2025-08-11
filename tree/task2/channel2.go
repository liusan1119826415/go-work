package main

import (
	"fmt"
	"sync"
)

func product(ch chan<- int, wg *sync.WaitGroup) {
	defer wg.Done()
	for i := 1; i <= 100; i++ {
		ch <- i
	}

	close(ch)
}

func consumer(ch <-chan int, wg *sync.WaitGroup) {
	defer wg.Done()

	for v := range ch {
		fmt.Println("接收参数===%d", v)
	}
}

func main() {

	ch := make(chan int, 20)

	var wg sync.WaitGroup

	wg.Add(2)

	go product(ch, &wg)

	consumer(ch, &wg)

	wg.Wait()

	fmt.Println("带缓冲接收完成")

}

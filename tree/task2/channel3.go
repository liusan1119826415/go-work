package main

import "fmt"

func Product(ch chan<- int) {

	for i := 1; i <= 10; i++ {
		ch <- i
	}
	close(ch)
}

func Consumer(ch <-chan int) {

	for v := range ch {
		fmt.Println(v)
	}
}

func main() {

	ch := make(chan int)

	go Product(ch)

	Consumer(ch)
}

package main

import (
	"fmt"
	"sync"
)

type Counter struct {
	value int
	mutex sync.Mutex
}

func (c *Counter) add() {
	c.mutex.Lock()
	defer c.mutex.Unlock()
	c.value++

}

func main() {

	var wg sync.WaitGroup

	counter := Counter{}

	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := 0; i < 1000; i++ {
				counter.add()
			}
		}()

	}

	wg.Wait()
	fmt.Printf("====统计值===%d", counter.value)
}

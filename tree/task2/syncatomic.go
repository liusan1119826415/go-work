package main

import (
	"fmt"
	"sync"
	"sync/atomic"
)

type CountData struct {
	value int32
	mutex sync.Mutex
}

func (c *CountData) add2() {

	atomic.AddInt32(&c.value, 1)

}

func main() {

	var wg sync.WaitGroup

	countData := CountData{}

	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()

			for i := 0; i < 1000; i++ {
				countData.add2()
			}
		}()
	}
	wg.Wait()
	fmt.Printf("====统计值===%d", countData.value)
}

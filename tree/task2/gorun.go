package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

type Task func() error

type TaskScheduler struct {
	taskQueue      chan Task
	workerCount    int
	wg             sync.WaitGroup
	totalTasks     int32
	completedTasks int32     // 已完成任务数(原子操作)
	startTime      time.Time // 开始时间
}

func NewScheduler(workerCount, queueSize int) *TaskScheduler {
	return &TaskScheduler{
		taskQueue:   make(chan Task, queueSize),
		workerCount: workerCount,
	}
}

func (s *TaskScheduler) AddTask(task Task) {
	atomic.AddInt32(&s.totalTasks, 1)
	s.taskQueue <- task
}

func (s *TaskScheduler) worker(id int) {
	defer s.wg.Done()

	for task := range s.taskQueue {
		start := time.Now()

		err := task()

		duration := time.Since(start)

		atomic.AddInt32(&s.completedTasks, 1)

		if err != nil {
			fmt.Printf("Worker %d: 任务执行失败, 耗时 %v, 错误: %v\n", id, duration, err)
		} else {
			fmt.Printf("Worker %d: 任务执行成功, 耗时 %v\n", id, duration)
		}

	}
}

func (s *TaskScheduler) Stop() {
	close(s.taskQueue)
	s.wg.Wait()

	totalTime := time.Since(s.startTime)
	fmt.Printf("\n任务统计: 共 %d/%d 完成, 总耗时 %v\n",
		atomic.LoadInt32(&s.completedTasks),
		atomic.LoadInt32(&s.totalTasks),
		totalTime)
}

// 启动工作协程
func (s *TaskScheduler) Start() {
	s.startTime = time.Now()
	for i := 0; i < s.workerCount; i++ {
		s.wg.Add(1)
		go s.worker(i + 1)
	}
}

func main() {
	// 创建调度器，3个工作协程，任务队列缓冲10
	scheduler := NewScheduler(3, 10)
	scheduler.Start()

	// 添加10个示例任务
	for i := 0; i < 10; i++ {
		taskID := i + 1
		scheduler.AddTask(func() error {
			// 模拟任务执行时间
			duration := time.Duration(100+(taskID*50)) * time.Millisecond
			time.Sleep(duration)

			// 模拟部分任务失败
			if taskID%4 == 0 {
				return fmt.Errorf("任务 %d 模拟错误", taskID)
			}
			return nil
		})
	}

	// 等待所有任务完成
	scheduler.Stop()
}

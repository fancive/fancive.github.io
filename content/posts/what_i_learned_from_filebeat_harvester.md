---
title: "我从filebeat-harvester中学到什么"
date: 2022-11-28T14:13:14+08:00
featured_image: ""

categories:
- Go

tags:
- filebeat
---


### 总体流程

filebeat 对每个path都会创建一个 `harvester`,  `harvester` 负责逐行读取文件内容。它的上游是 `input` , `input` 负责管理`harvester`, 它的下游是 `output`, `output` 负责消费每一行消息。

通过阅读harvester代码，我学习到了如何管理多个相互依赖的协程的生命周期，具体可以拆分为4个问题

1. 为主协程添加超时控制协程
2. 主协程结束如何关闭超时控制协程和其他协程(`monitorFileSize`)
3. 关闭协程时如何控制不同job间的先后执行顺序
4. 如何从外部关闭任务，并等待清理完成

### 超时控制协程

`(h *Harvester)Run()` 方法里，会创建超时控制协程，在此协程中会消费2个事件

1. 超时事件 `closeTimeout`
2. 主任务结束标志 `h.done`

一旦接收到其中一个事件，那么会调用 `stop` 并关闭 `reader`

```go
// Closes reader after timeout or when done channel is closed
	// This routine is also responsible to properly stop the reader
go func(source string) {
    closeTimeout := make(<-chan time.Time)
    // starts close_timeout timer
    if h.config.CloseTimeout > 0 {
        closeTimeout = time.After(h.config.CloseTimeout)
    }

    select {
    // Applies when timeout is reached
    case <-closeTimeout:
        logger.Infof("Closing harvester because close_timeout was reached: %s", source)
    // Required when reader loop returns and reader finished
    case <-h.done:
    }

    h.stop()
    err := h.reader.Close()
    if err != nil {
        logger.Errorf("Failed to stop harvester for file: %v", err)
    }
}(h.state.Source)
```

### 主协程关闭其他附属功能协程

一句话，主要是通过调用 `stop` (在defer里)， `stop` 里会 `close(h.done)`

```go
select {
	case <-h.done:
		h.stopWg.Done()
		return nil
	default:
	}

defer func() {
	// Channel to stop internal harvester routines
	h.stop()

	// Makes sure file is properly closed when the harvester is stopped
	h.cleanup()

	harvesterRunning.Add(-1)

	// Marks harvester stopping completed
	h.stopWg.Done()
}()
```

其他协程会消费 `h.done`

1. Run 函数开头, 用于立刻停止
2. 超时控制协程，这里select 消费了2个chan (其中一个是h.done)

```go
select{
    // Applies when timeout is reached
    case<-closeTimeout:
        logger.Infof("Closing harvester because close_timeout was reached: %s", source)
    // Required when reader loop returns and reader finished
    case<-h.done:
}
```

1. Run函数的for-loop，这里是主要的逻辑实现地方

```go
for{
    select{
            case<-h.done:
            return nil
                default:
    }
    // 读文件
    ...
}
```

1. `monitorFileSize`监控文件大小协程，需要和主协程一起结束
1.  `Run` 方法开始的地方，创建其他子协程之前
1. 逐行读文件的 `for-loop` 里


### `doneWg` waitGroup

用来在主协程(*`Run`*)发送结束信号*`close*(h.done)`时等 `monitorFileSize`协程关闭

2个问题，这个wg用来等什么协程，在哪等

1. 用来等的是`monitorFileSize`监控文件大小协程

```go
h.doneWg.Add(1)
go func() {
   h.monitorFileSize()
   h.doneWg.Done()
}()
```

1. 在 `stop` 函数里等(小写stop)

```go
//stop is intended for internal use and closed thedone channel tostop execution
func(h *Harvester) stop() {
	  h.stopOnce.Do(func() {
				close(h.done)
				// Wait for goroutines monitoring h.done to terminate before closing source.
				h.doneWg.Wait()
	      filesMetrics.Remove(h.id.String())
   })
}

```

那么 `stop` 函数在哪被调用呢？

1. *`Run` 函数的的defer操作里*
2. 超时控制的协程里
3. 外部调用 `Stop` 时

这里有个疑问，为什么在 `stop` 里面要`h.doneWg.Wait()`, 看上去 `monitorFileSize` 即使不wait也能正常退出，后来再读后面代码发现是为了先执行 `monitorFileSize` 后执行 `cleanup` 关闭句柄并改变关闭状态

这里可以看出，当主协程因为某种原因结束时，我们希望先等 `monitorFileSize` 协程先退出后再执行后续操作 `cleanup` ，这里的顺序是

1. `h.stop()`
2. `h.monitorFileSize` 协程退出
3. `h.cleanup()`

### `stopWg` waitGroup, 结束完成

2个问题，这个wg用来等什么协程，在哪等

1. 用来等待*`Run`函数的defer也完成后再退出 (*`cleanup`函数, 改变`Harvester`状态为关闭,并关闭句柄*)*

```go
defer func() {
    // Channel to stop internal harvester routines
    h.stop()
    
    // Makes sure file is properly closed when the harvester is stopped
    h.cleanup()
    
    harvesterRunning.Add(-1)
    
    // Marks harvester stopping completed
    h.stopWg.Done()
}()

```

1. 在 *`Stop` 函数里等(大写)*

```go
//Stop stops harvester and waits for completion
func(h *Harvester)Stop() {
   h.stop()
// Prevent stopWg.Wait() to be called at the same time as stopWg.Add(1)
h.stopLock.Lock()
   h.stopWg.Wait()
   h.stopLock.Unlock()
}
```

可以看出，这个wg的用途是当外部关闭该任务时，保证 `stop` 和 `cleanup` 被执行完成

### 参考

filebeat/input/log/harvester.go
```go
// Harvester contains all harvester related data
type Harvester struct {
	logger *logp.Logger

	id     uuid.UUID
	config config
	source harvester.Source // the source being watched

	// shutdown handling
	done     chan struct{}
	doneWg   *sync.WaitGroup
	stopOnce sync.Once
	stopWg   *sync.WaitGroup
	stopLock sync.Mutex

	// internal harvester state
	state  file.State
	states *file.States
	log    *Log

	// file reader pipeline
	reader          reader.Reader
	encodingFactory encoding.EncodingFactory
	encoding        encoding.Encoding

	// event/state publishing
	outletFactory OutletFactory
	publishState  func(file.State) bool

	metrics *harvesterProgressMetrics

	onTerminate func()
}
```
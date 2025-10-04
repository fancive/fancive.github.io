---
title: "我从filebeat-harvester中学到什么"
date: 2022-11-28T14:13:14+08:00
cover: "/images/illustrations/harvester.jpg"
description: "通过分析 Filebeat Harvester 模块的实现，学习文件采集、状态管理和并发控制的最佳实践。"
categories:
  - Go语言
tags:
  - filebeat
---

## 引言

在学习优秀开源项目的源码时，我们不仅能学到具体的技术实现，更能领悟到工程实践中的设计智慧。Filebeat 作为 Elastic Stack 中的日志采集器，其 Harvester 模块的设计就是一个典范。本文通过深入分析 Harvester 的协程管理机制，总结了四个核心问题的解决方案，这些经验可以直接应用到我们日常的 Go 项目开发中。

**核心问题**：
- 如何为主协程添加超时控制？
- 主协程结束时如何优雅关闭其他协程？
- 如何控制多个协程的关闭顺序？
- 如何从外部安全地关闭任务并等待清理完成？

<!--more-->

## 总体流程

Filebeat 对每个 path 都会创建一个 `harvester`，`harvester` 负责逐行读取文件内容。它的上游是 `input`，`input` 负责管理 `harvester`，它的下游是 `output`，`output` 负责消费每一行消息。

通过阅读 harvester 代码，我学习到了如何管理多个相互依赖的协程的生命周期，具体可以拆分为 4 个问题：

1. 为主协程添加超时控制协程
2. 主协程结束如何关闭超时控制协程和其他协程 (`monitorFileSize`)
3. 关闭协程时如何控制不同 job 间的先后执行顺序
4. 如何从外部关闭任务，并等待清理完成

## 超时控制协程

`(h *Harvester)Run()` 方法里，会创建超时控制协程，在此协程中会消费 2 个事件：

1. 超时事件 `closeTimeout`
2. 主任务结束标志 `h.done`

一旦接收到其中一个事件，那么会调用 `stop` 并关闭 `reader`：

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

## 主协程关闭其他附属功能协程

一句话，主要是通过调用 `stop` (在 defer 里)，`stop` 里会 `close(h.done)`：

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

其他协程会消费 `h.done`：

1. Run 函数开头，用于立刻停止
2. 超时控制协程，这里 select 消费了 2 个 chan (其中一个是 h.done)

```go
select{
    // Applies when timeout is reached
    case<-closeTimeout:
        logger.Infof("Closing harvester because close_timeout was reached: %s", source)
    // Required when reader loop returns and reader finished
    case<-h.done:
}
```

3. Run 函数的 for-loop，这里是主要的逻辑实现地方

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

4. `monitorFileSize` 监控文件大小协程，需要和主协程一起结束
5. `Run` 方法开始的地方，创建其他子协程之前
6. 逐行读文件的 `for-loop` 里

## `doneWg` waitGroup

用来在主协程 (`Run`) 发送结束信号 `close(h.done)` 时等 `monitorFileSize` 协程关闭。

2 个问题，这个 wg 用来等什么协程，在哪等：

1. 用来等的是 `monitorFileSize` 监控文件大小协程

```go
h.doneWg.Add(1)
go func() {
   h.monitorFileSize()
   h.doneWg.Done()
}()
```

2. 在 `stop` 函数里等 (小写 stop)

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

1. `Run` 函数的 defer 操作里
2. 超时控制的协程里
3. 外部调用 `Stop` 时

这里有个疑问，为什么在 `stop` 里面要 `h.doneWg.Wait()`，看上去 `monitorFileSize` 即使不 wait 也能正常退出，后来再读后面代码发现是为了先执行 `monitorFileSize` 后执行 `cleanup` 关闭句柄并改变关闭状态。

这里可以看出，当主协程因为某种原因结束时，我们希望先等 `monitorFileSize` 协程先退出后再执行后续操作 `cleanup`，这里的顺序是：

1. `h.stop()`
2. `h.monitorFileSize` 协程退出
3. `h.cleanup()`

## `stopWg` waitGroup - 结束完成

2 个问题，这个 wg 用来等什么协程，在哪等：

1. 用来等待 `Run` 函数的 defer 也完成后再退出 (`cleanup` 函数，改变 `Harvester` 状态为关闭，并关闭句柄)

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

2. 在 `Stop` 函数里等 (大写)

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

可以看出，这个 wg 的用途是当外部关闭该任务时，保证 `stop` 和 `cleanup` 被执行完成。

## 总结

### 核心设计模式

通过对 Filebeat Harvester 的分析，我们学习到了优雅的协程生命周期管理模式：

1. **双 WaitGroup 模式**
   - `doneWg`：用于等待内部协程（如 `monitorFileSize`）完成
   - `stopWg`：用于外部调用者等待整个任务完全清理
   - 这种设计实现了分层的关闭控制

2. **Channel + WaitGroup 组合**
   - `done channel`：作为广播信号，通知所有协程停止
   - `sync.Once`：保证关闭操作只执行一次
   - WaitGroup：确保关闭顺序可控

3. **优雅关闭的顺序控制**
   ```
   主协程结束 → close(h.done) → 等待 monitorFileSize → cleanup → stopWg.Done()
   ```

### 关键技术要点

| 技术点 | 作用 | 使用场景 |
|--------|------|----------|
| `done channel` | 广播停止信号 | 通知多个协程同时停止 |
| `doneWg` | 等待内部协程 | 保证清理前内部任务完成 |
| `stopWg` | 等待清理完成 | 外部调用者等待资源释放 |
| `sync.Once` | 防止重复关闭 | 多个协程可能触发关闭 |
| `stopLock` | 防止竞态 | 保护 stopWg 的并发访问 |

### 实践建议

1. **设计长生命周期协程时**
   - 提供明确的停止信号机制（如 `done channel`）
   - 为主协程设计超时控制，避免无限等待
   - 使用 defer 确保清理代码一定执行

2. **管理多个协程时**
   - 使用 WaitGroup 控制关闭顺序
   - 区分内部协程等待和外部调用等待
   - 使用 `sync.Once` 保证关闭操作幂等性

3. **资源清理时**
   - 先停止业务逻辑（close channel）
   - 再等待子任务完成（doneWg.Wait）
   - 最后清理资源（cleanup）
   - 通知外部调用者（stopWg.Done）

### 可复用的代码模式

```go
type Worker struct {
    done     chan struct{}
    doneWg   *sync.WaitGroup  // 等待内部协程
    stopOnce sync.Once
    stopWg   *sync.WaitGroup  // 等待清理完成
    stopLock sync.Mutex
}

func (w *Worker) Run() error {
    w.stopWg.Add(1)
    defer func() {
        w.stop()
        w.cleanup()
        w.stopWg.Done()
    }()

    // 启动监控协程
    w.doneWg.Add(1)
    go func() {
        w.monitor()
        w.doneWg.Done()
    }()

    // 主逻辑
    for {
        select {
        case <-w.done:
            return nil
        default:
            // 业务处理
        }
    }
}

func (w *Worker) stop() {
    w.stopOnce.Do(func() {
        close(w.done)
        w.doneWg.Wait()  // 等待内部协程
    })
}

func (w *Worker) Stop() {
    w.stop()
    w.stopLock.Lock()
    w.stopWg.Wait()  // 等待清理完成
    w.stopLock.Unlock()
}
```

### 扩展思考

这种协程管理模式不仅适用于文件采集场景，也可以应用于：
- 网络连接池管理
- 定时任务调度
- 消息队列消费者
- 长连接服务（WebSocket、gRPC）

关键是理解**分层关闭**和**顺序控制**的设计思想。

## 参考

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
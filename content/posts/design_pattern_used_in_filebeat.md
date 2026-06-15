---
title: "Filebeat 中使用的设计模式"
date: 2020-09-16T22:15:59+08:00
cover:
  image: "/images/illustrations/patterns.jpg"
description: "分析 Filebeat 源码中使用的设计模式，包括 Registry 模式、Observer 模式、Strategy 模式和 Object Pool 模式等优秀的工程实践。"
categories:
  - Go语言
tags:
  - filebeat
  - 设计模式
---

Filebeat 是 Elastic Stack 里那个轻量级的日志采集器。最近读它的源码，发现几处设计模式用得很顺手，记一下：Registry + LazyInit、Observer、Strategy 和 Object Pool 这四个，正好对应插件化、解耦、可配置和性能优化几个常见诉求。

<!--more-->

## Registry + LazyInit

Filebeat 支持 log、stdin、redis、kafka 等多种 input 类型，要做到加一种类型不动核心代码，靠的就是注册表：每个 input 类型把自己的工厂函数登记进去，运行时再按配置里的 `type` 查出来用。延迟初始化的部分在于——只有配置里真正用到的 input 才会被实例化。

在 `filebeat/input.New` 中，通过 Registry 获取对应类型的工厂函数：

```go
f, err = GetFactory(input.config.Type)
```

**Registry 查找逻辑**

```go
func GetFactory(name string) (Factory, error) {
    if _, exists := registry[name]; !exists {
        return nil, fmt.Errorf("Error creating input. No such input type exist: '%v'", name)
    }
    return registry[name], nil
}
```

**组件注册**

各个 input 类型在初始化时自动注册到 registry：

```go
func init() {
    err := input.Register("log", NewInput)
    if err != nil {
        panic(err)
    }
}
```

这样配置和实现就彻底分开了——加一种新的 input 类型只要在 `init` 里 `Register` 一下，核心的 `New` 逻辑一行都不用改。

## Observer：事件总线

Filebeat 内部组件之间不直接互相调用，而是走一条事件总线（Event Bus）：谁关心什么事件就订阅，谁产生了事件就发布出去，中间用 channel 传递。典型的观察者模式。

发布事件时遍历所有订阅者，只把它感兴趣的事件投进它的 channel：

```go
func (b *bus) Publish(e Event) {
    b.RLock()
    defer b.RUnlock()
    logp.Debug("bus", "%s: %+v", b.name, e)

    // 遍历所有订阅者，发送感兴趣的事件
    for _, listener := range b.listeners {
        if listener.interested(e) {
            listener.channel <- e
        }
    }
}
```

订阅时创建一个带缓冲的 channel，并把 filter 一起记下来，这样发布端就能做选择性投递：

```go
func (b *bus) Subscribe(filter ...string) Listener {
    listener := &listener{
        filter:  filter,
        bus:     b,
        channel: make(chan Event, 100), // 带缓冲的 channel
    }

    b.Lock()
    defer b.Unlock()
    b.listeners = append(b.listeners, listener)
    return listener
}
```

发布者和订阅者互不知道对方存在，靠 channel 异步传递，再加上 filter 做选择性订阅——这套组合让模块之间的耦合降到很低。

## Strategy：Kafka 分区策略

Filebeat 往 Kafka 写数据时支持 random、round_robin、hash 几种分区方式。与其在写入逻辑里塞一堆 `if-else`，它把每种策略做成一个独立的构造函数，用一张 map 注册起来，按配置取用：

```go
// 定义策略映射表
var partitioners = map[string]partitionBuilder{
    "random":      cfgRandomPartitioner,
    "round_robin": cfgRoundRobinPartitioner,
    "hash":        cfgHashPartitioner,
}

func initPartitionStrategy(config *Config) (Partitioner, error) {
    name := config.Partition

    // 根据配置选择策略
    mk := partitioners[name]
    if mk == nil {
        return nil, fmt.Errorf("unknown kafka partition mode %v", name)
    }

    // 构造具体的分区器
    partitioner, err := mk(config)
    // ...
}
```

加一种新的分区策略，往这张 map 里添一行就行，写入主流程完全不用动。

## Object Pool：复用 ackChan

Filebeat 在确认（ACK）链路上会高频创建、丢弃 `ackChan` 这种短命对象，频繁分配会给 GC 带来压力。它的做法是用 `sync.Pool` 把这些对象池化复用。

定义对象池，`New` 负责在池空时兜底造一个新的：

```go
var ackChanPool = sync.Pool{
    New: func() interface{} {
        return &ackChan{
            ch: make(chan batchAckMsg, 1),
        }
    },
}
```

从池里取出来后，把每个字段重新赋值，相当于"重置"成一个干净对象再用：

```go
func newACKChan(seq uint, start, count int, states []clientState) *ackChan {
    ch := ackChanPool.Get().(*ackChan)
    ch.next = nil
    ch.seq = seq
    ch.start = start
    ch.count = count
    ch.states = states
    return ch
}
```

归还时把 `next` 置空再 `Put` 回去——这一步很关键，不清掉引用的话被池子持有的对象会顺带把它指向的东西也留住，造成内存泄漏：

```go
func releaseACKChan(c *ackChan) {
    c.next = nil  // 清理引用，防止内存泄漏
    ackChanPool.Put(c)
}
```

`sync.Pool` 在这种高频创建销毁的短命对象上收益最明显，省下的是反复分配内存和触发 GC 的开销。

## 参考资源

- [Filebeat 官方文档](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
- [Filebeat GitHub 仓库](https://github.com/elastic/beats)

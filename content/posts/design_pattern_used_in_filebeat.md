---
title: "Design pattern used in filebeat"
date: 2020-09-16T22:15:59+08:00
---

## registry 与 lazyinit 结合
filebeat/input.New

```go
f, err = GetFactory(input.config.Type)
```

GetFactory

```go
func GetFactory(name string) (Factory, error) {
    if _, exists := registry[name]; !exists {
        return nil, fmt.Errorf("Error creating input. No such input type exist: '%v'", name)
    }
    return registry[name], nil
}
```
注册
```go
func init() {
    err := input.Register("log", NewInput)
    if err != nil {
        panic(err)
    }
}
```
## observer

publish
```go
func (b *bus) Publish(e Event) {
    b.RLock()
    defer b.RUnlock()
    logp.Debug("bus", "%s: %+v", b.name, e)
    for _, listener := range b.listeners {
        if listener.interested(e) {
            listener.channel <- e
        }
    }
}
```
Subscribe
```go
func (b *bus) Subscribe(filter ...string) Listener {
    listener := &listener{
        filter:  filter,
        bus:     b,
        channel: make(chan Event, 100),
    }

    b.Lock()
    defer b.Unlock()
    b.listeners = append(b.listeners, listener)
    return listener
}
```

## strategy
libbeat/outputs/kafka.makePartitioner()
```go

var partitioners = map[string]partitionBuilder{
    "random":      cfgRandomPartitioner,
    "round_robin": cfgRoundRobinPartitioner,
    "hash":        cfgHashPartitioner,
}

func initPartitionStrategy(
    ...
    *// instantiate partitioner strategy*
    mk := partitioners[name]
    if mk == nil {
        return nil, false, fmt.Errorf("unknown kafka partition mode %v", name)
    }

    constr, err := mk(config)
    ...
}
```

## object pool
libbeat/queue/memqueue.broker.go

```go
var ackChanPool = sync.Pool{
    New: func() interface{} {
        return &ackChan{
            ch: make(chan batchAckMsg, 1),
        }
    },
}

func newACKChan(seq uint, start, count int, states []clientState) *ackChan {
    ch := ackChanPool.Get().(*ackChan)
    ch.next = nil
    ch.seq = seq
    ch.start = start
    ch.count = count
    ch.states = states
    return ch

}

func releaseACKChan(c *ackChan) {
    c.next = nil
    ackChanPool.Put(c)

}
```
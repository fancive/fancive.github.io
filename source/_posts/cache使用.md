---
title: cache使用
date: 2018-01-28 19:13:37
tags: 技术经验
---

# cache使用

> 来自毛老师的分享总结

## 一. 选型

### Redis

- 数据类型丰富，支持增量修改
- 可以做数据索引
- 没有内存池，有内存碎片(jmalloc)

### Mc

- kv存储,value不超过1M
- 可作为大文本或者简单kv结构使用
- slab内存管理，优化ratio, slab_automove开启动态slab
- 防止热点slab

### 具体选型

- redis单线程，mc多线程，redis遭遇大数据返回时qps会抖动
- 建议纯kv都走mc
- 可以使用mc帮redis挡一层(hgetall)
- 不建议使用持久化，会导致无状态变为有状态
- 不建议使用redis作为队列，因为可能因为拥堵而导致oom(先落磁盘后投递)


## 二. 策略

### Cache-Aside

- 读写缓存，miss则读数据库

#### 问题

##### 一致性

- delete失败怎么办？
- a 删除缓存还没回写，b更新了数据并回写，这时候a回写缓存，脏数据？

方案: 订阅db的binlog

##### 命中率

- 热点key频繁过期

方案: 被删除不会真正过期，只是打个状态（改源码或者基础库支持）

##### 穿透

1. slb对key做一致性Hash, 使某个key一定落在某个节点，节点内使用互斥锁(无法解决批量查询问题)
2. 分布式锁， 抢到锁才可以执行回源操作，其他候选者轮训cache这个lock，不存在读缓存，miss了继续抢锁
3. 队列，cache miss交由队列聚合key，来load回写数据(适合回源加载数据重的任务)
4. lease机制，64bit token, 与key绑定

## 三. 技巧

### mc

- flag: comperess,encoding, large value
- gets: pipeline
- 二进制协议， pipeline delete, udp读，tcp写
- 优化Incast Congestion
- 微服务泳道，多套缓存集群

### redis

- 增量更新先expire判断是否存在
- bitset: 为了避免单个BITSET过大或者热点，需要使用Region Sharding
- List: Stack PUSH/POP
- Sortedset: 杜绝zrange 或者 zrevrange
- Hashs: 过小的时候会使用压缩列表、过大的情况容易导致rehash内存浪费，也杜绝返回hgetall
- String：SETNX可以用于分布式锁、SETEX聚合了SET + EXPIRE
- 避免超大Value；

## 四. 超时

- 使用连接池
- 全链路超时 slb (1s) -> serviceA (0.98s) -> serviceB (0.95s)

## 五. 集群


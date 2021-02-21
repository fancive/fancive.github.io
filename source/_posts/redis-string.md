---
title: redis_string
date: 2018-08-04 00:05:45
tags:
- redis
- tech
---

> redis 版本: v1.3.12

# redis_string(sds)

结构声明

```c
struct sdshdr {
    long len;
    long free;
    char buf[];
};
```

struct sdshdr是redis的字符串容器，比较与常规字符串，有几个特点

- 支持O(1) 时间内获取字符串长度 sdslen
- 不会因为长度溢出导致缓冲区溢出(buffer overflow)  strcat <-->sdscat
- 支持空间预分配与惰性释放
- 二进制安全

## 为什么这么设计

redis作为一个频繁更新的kv存储，每次更新都需要重新判断字符串长度防止 buffer overflow , 因此需要支持以下特性

*  支持O(1) 时间内获取字符串长度
*  支持空间预分配
*  惰性释放

用户不会只在 redis中存储字符串，可能有其他数据类型，因此可能会有 EOF,  所以存储类型必须是二进制安全的，否则造成截断。

## 横向比较

nginx中的字符串容器设计

```c
typedef struct {
    size_t      len;
    u_char     *data;
} ngx_str_t;
```
比较与reids, nginx 中的字符串容器没有free 属性，因此获取字符串长度时间复杂度也为O(1),  但是获取字符串容器总长度的事件复杂度为 O(n)




## ref

[redisbook](http://redisbook.com/index.html)



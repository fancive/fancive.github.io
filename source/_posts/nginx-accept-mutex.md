---
title: nginx源码_work负载均衡--accept_mutex
date: 2018-03-22 22:55:04
categories:
- 中间件
tags: 
- nginx
- tech
---

# nginx源码_work负载均衡--accept_mutex

> nginx -v 1.9

## 0x01 引言

accept_mutex是nginx各worker接收请求的负载均衡策略的实现的核心  

## ngx_accept_disabled

ngx_accept_disabled = 进程当前连接数/8 - 空闲连接数 ， 可见当前进程的连接数越多，ngx_accept_disabled越大

```c
ngx_accept_disabled = ngx_cycle->connection_n / 8 - ngx_cycle->free_connection_n;                              
```

## 负载均衡逻辑


```c
 if (ngx_use_accept_mutex) {
        if (ngx_accept_disabled > 0) {
            ngx_accept_disabled--;
        } else {
            if (ngx_trylock_accept_mutex(cycle) == NGX_ERROR) {
                return;
            }

            if (ngx_accept_mutex_held) {
                flags |= NGX_POST_EVENTS;
            } else {
                if (timer == NGX_TIMER_INFINITE
                    || timer > ngx_accept_mutex_delay)
                {
                    timer = ngx_accept_mutex_delay;
                }
            }
        }
    }
```


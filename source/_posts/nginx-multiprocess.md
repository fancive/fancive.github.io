---
title: nginx源码_多进程启动
date: 2018-04-21 10:48:55
tags:
- nginx
- tech
---

# 多进程启动

## `ngx_master_process_cycle`


```c
ngx_master_process_cycle(ngx_cycle_t *cycle)
```
信号初始化


```c
    sigemptyset(&set);
    sigaddset(&set, SIGCHLD);
    ...
```




## 函数

### `sigaddset`


```c
sigaddset
```



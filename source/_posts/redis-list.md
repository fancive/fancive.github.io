---
title: redis_list
date: 2018-08-04 14:52:57
tags:
- redis
- tech
---

> redis 版本: v1.3.12

## redis_list

```c
typedef struct listNode {
    // 前置节点
    struct listNode *prev;
    // 后置节点
    struct listNode *next;
    // 节点的值
    void *value;
} listNode;
```

redis 的链表节点是最简单的双向链表节点，表头和表尾都是NULL，没有环式链表。

```c
typedef struct list {
    listNode *head;
    listNode *tail;
    void *(*dup)(void *ptr);
    void (*free)(void *ptr);
    int (*match)(void *ptr, void *key);
    unsigned int len;
} list;```
链表容器中保存了表头和表尾，以及节点数量len，以及复制函数指针 `void *(*dup)(void *ptr);` 以及释放函数指针 ` void (*free)(void *ptr)` 和值比较函数 ` int (*match)(void *ptr, void *key)`

### 为什么这么设计

* 使用`void *value`保存链表节点的值是为了存储多种数据类型
* 链表容器中存储了 head 和 tail 是为了 O(1) 复杂度访问头尾节点
* 存储len是为了在O(1)复杂度内获取链表长度
* 三个函数指针是为了实现多态链表

### 横向比较

nginx 中有两个链表，单链表 `ngx_list_t` 和双向链表 `ngx_queue_t` 

####  ngx_list_t
ngx_list_t 中的每个链表节点都是一个数组，数组元素数量上限存储在链表容器 nalloc 中，数组每个元素大小存储在链表容器 size 中，链表节点中只保存已有的元素数量 nelts ， 以及存放元素的开始地址 elts， 以及下一个链表节点指针 next

```c
struct ngx_list_part_s {
    void             *elts;
    ngx_uint_t        nelts;
    ngx_list_part_t  *next;
};
typedef struct {
    ngx_list_part_t  *last;
    ngx_list_part_t   part;
    size_t            size;
    ngx_uint_t        nalloc;
    ngx_pool_t       *pool;
} ngx_list_t;
```

#### `ngx_queue_t`

普通的双向链表

```c
struct ngx_queue_s {
    ngx_queue_t  *prev;
    ngx_queue_t  *next;
};
```

## ref

[redisbook](http://redisbook.com/index.html)


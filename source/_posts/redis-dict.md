---
title: redis_dict
date: 2018-08-08 19:37:17
tags:
- redis
- tech
---

> redis 版本: v1.3.12

## redis_dict

```c

typedef struct dictEntry {
    void *key;
    void *val;
    struct dictEntry *next;
} dictEntry;

// 哈希表容器
typedef struct dict {
    dictEntry **table; // 指向dictEntry
    dictType *type;
    unsigned long size;
    unsigned long sizemask;
    unsigned long used;
    void *privdata;
} dict;

// 多态字典
typedef struct dictType {
    unsigned int (*hashFunction)(const void *key);
    void *(*keyDup)(void *privdata, const void *key);
    void *(*valDup)(void *privdata, const void *obj);
    int (*keyCompare)(void *privdata, const void *key1, const void *key2);
    void (*keyDestructor)(void *privdata, void *key);
    void (*valDestructor)(void *privdata, void *obj);
} dictType;
```

`dict`是哈希表容器, table是指针数组(指向dictEntry), size是哈希表容量(table数组长度), used是已使用容量, sizemask = size -1 , sizemask主要用来确认一个value在table上的位置。

`dictEntry`是哈希表节点，next指针是为了防止碰撞。

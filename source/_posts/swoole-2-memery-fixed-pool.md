---
title: swoole_2_memery_fixed_pool
date: 2018-05-30 20:17:18
categories: 
- 中间件
tags: 
- swoole
- tech
---


# swoole 内存模型 - fiexdPool

## synopsis

- swFixedPool_slice 内存池元素
- swFixedPool 内存池。

### 文件

* FixedPool.c
* swool.h

## 声明

### swFixedPool_slice
swFixedPool 是双向链表

```c
typedef struct _swFixedPool_slice
{
    uint8_t lock; // 是否空闲
    struct _swFixedPool_slice *next;
    struct _swFixedPool_slice *pre;
    char data[0]; // 

} swFixedPool_slice;
```
swFixedPool
```c
typedef struct _swFixedPool
{
    void *memory;
    size_t size;

    swFixedPool_slice *head;
    swFixedPool_slice *tail;

    /**
     * total memory size
     */
    uint32_t slice_num;

    /**
     * memory usage
     */
    uint32_t slice_use;

    /**
     * Fixed slice size, not include the memory used by swFixedPool_slice
     */
    uint32_t slice_size;

    /**
     * use shared memory
     */
    uint8_t shared;

} swFixedPool;
```


## 初始化


```c
swMemoryPool* swFixedPool_new(uint32_t slice_num, uint32_t slice_size, uint8_t shared)
{
    size_t size = slice_size * slice_num + slice_num * sizeof(swFixedPool_slice);
    //slice大小*slice数量+MemoryPool头部大小+FixedPool头部大小
    size_t alloc_size = size + sizeof(swFixedPool) + sizeof(swMemoryPool);
    void *memory = (shared == 1) ? sw_shm_malloc(alloc_size) : sw_malloc(alloc_size);

    swFixedPool *object = memory;
    memory += sizeof(swFixedPool);
    bzero(object, sizeof(swFixedPool));

    object->shared = shared;
    object->slice_num = slice_num;
    object->slice_size = slice_size;
    object->size = size;

    swMemoryPool *pool = memory;
    memory += sizeof(swMemoryPool);
    pool->object = object;
    pool->alloc = swFixedPool_alloc;
    pool->free = swFixedPool_free;
    pool->destroy = swFixedPool_destroy;

    object->memory = memory;

    /**
     * init linked list
     */
    swFixedPool_init(object);

    return pool;
}
```


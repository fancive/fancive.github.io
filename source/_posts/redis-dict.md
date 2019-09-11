---
title: redis_dict
date: 2018-08-08 19:37:17
categories: 
- 中间件
tags:
- redis
---

> redis 版本: v1.3.12

# redis_dict

## declaration

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

#### `dict`

`dict` 是哈希表容器, 

- table是指针数组(指向dictEntry), 
- size是哈希表容量(table数组长度), 
- used是已使用容量, 
- sizemask = size -1 , sizemask主要用来确认一个value在table上的位置代码如下

```c
    h = dictHashKey(ht, key) & ht->sizemask;
```

#### `dictEntry`

是哈希表节点，next指针是为了防止碰撞。

## functions

### **dictAdd**

计算hash，并将新节点添加到链表头

```
/* Add an element to the target hash table */
static int dictAdd(dict *ht, void *key, void *val)
{
    int index;
    dictEntry *entry;

    /* Get the index of the new element, or -1 if
     * the element already exists. */
    if ((index = _dictKeyIndex(ht, key)) == -1)
        return DICT_ERR;

    /* Allocates the memory and stores key */
    entry = malloc(sizeof(*entry));
    entry->next = ht->table[index];
    ht->table[index] = entry;

    /* Set the hash entry fields. */
    dictSetHashKey(ht, entry, key);
    dictSetHashVal(ht, entry, val);
    ht->used++;
    return DICT_OK;
}
```

#### **_dictKeyIndex**

```c
static int _dictKeyIndex(dict *ht, const void *key)
{
    unsigned int h;
    dictEntry *he;

    /* Expand the hashtable if needed */
    if (_dictExpandIfNeeded(ht) == DICT_ERR)
        return -1;
    /* Compute the key hash value */
    h = dictHashKey(ht, key) & ht->sizemask;
    /* Search if this slot does not already contain the given key */
    he = ht->table[h];
    while (he)
    {
        if (dictCompareHashKeys(ht, key, he->key))
            return -1;
        he = he->next;
    }
    return h;
}
```



##### **_dictExpandIfNeeded**

```c
static int _dictExpandIfNeeded(dict *ht)
{
    /* If the hash table is empty expand it to the initial size,
     * if the table is "full" dobule its size. */
    if (ht->size == 0)
        return dictExpand(ht, DICT_HT_INITIAL_SIZE);
    if (ht->used == ht->size)
        return dictExpand(ht, ht->size * 2);
    return DICT_OK;
}
```



###### **dictExpand**

dict的rehash操作，将旧的hashtable(ht) 中的每个节点(指针)放到新的hashable(n)，

没有看到渐进式hash的逻辑

```c
/* Expand or create the hashtable */
static int dictExpand(dict *ht, unsigned long size)
{
    dict n; /* the new hashtable */
    unsigned long realsize = _dictNextPower(size), i;

    /* the size is invalid if it is smaller than the number of
     * elements already inside the hashtable */
    if (ht->used > size)
        return DICT_ERR;

    _dictInit(&n, ht->type, ht->privdata);
    n.size = realsize;
    n.sizemask = realsize - 1;
    n.table = calloc(realsize, sizeof(dictEntry *));

    /* Copy all the elements from the old to the new table:
     * note that if the old hash table is empty ht->size is zero,
     * so dictExpand just creates an hash table. */
    n.used = ht->used;
    for (i = 0; i < ht->size && ht->used > 0; i++)
    {
        dictEntry *he, *nextHe;

        if (ht->table[i] == NULL)
            continue;

        /* For each hash entry on this slot... */
        he = ht->table[i];
        while (he)
        {
            unsigned int h;

            nextHe = he->next;
            /* Get the new element index */
            h = dictHashKey(ht, he->key) & n.sizemask;
            he->next = n.table[h];
            n.table[h] = he;
            ht->used--;
            /* Pass to the next element */
            he = nextHe;
        }
    }
    assert(ht->used == 0);
    free(ht->table);

    /* Remap the new hashtable in the old */
    *ht = n;
    return DICT_OK;
}
```

##### **dictCompareHashKeys**

多态比较函数，可以是自动以的compare函数，也可以直接比较key1和key2的值

```c
#define dictCompareHashKeys(ht, key1, key2) \
    (((ht)->type->keyCompare) ? \
        (ht)->type->keyCompare((ht)->privdata, key1, key2) : \
        (key1) == (key2))

```


---
title: swoole_reactor
date: 2018-06-26 14:04:43
tags:
- swoole
categories: 
- 中间件
---

# reactor

reactor的线程结构

```c
struct _swReactor
{
    // reactor的事件循环, 根据参数和内核选择事件模型比如swReactorEpoll
    void *object;m
    
    // swServer 
    void *ptr;  //reserve

    /**
     * last signal number
     */
    int singal_no;
    
    // epoll上挂的事件数量
    uint32_t event_num;
    // 对应epoll_wait 中的maxevents
    uint32_t max_event_num;
    
    // ??
    uint32_t check_timer :1;
    
    // swReactor_create() 中置1 reactor是否create
    uint32_t running :1;
    
    // swReactorEpoll_wait() 中置1 reactor开始工作
    uint32_t start :1;

    /**
     * disable accept new connection
     */
    uint32_t disable_accept :1;

    uint32_t check_signalfd :1;

    /**
     * multi-thread reactor, cannot realloc sockets.
     */
    uint32_t thread :1;

	/**
	 * reactor->wait timeout (millisecond) or -1
	 */
	int32_t timeout_msec;

	uint16_t id; //Reactor ID
	uint16_t flag; //flag

    uint32_t max_socket;

#ifdef SW_USE_MALLOC_TRIM
    time_t last_malloc_trim_time;
#endif

#ifdef SW_USE_TIMEWHEEL
    swTimeWheel *timewheel;
    uint16_t heartbeat_interval;
    time_t last_heartbeat_time;
#endif

    /**
     * for thread
     */
    swConnection *socket_list;

    /**
     * for process
     */
    swArray *socket_array;

    swReactor_handle handle[SW_MAX_FDTYPE];        //默认事件
    swReactor_handle write_handle[SW_MAX_FDTYPE];  //扩展事件1(一般为写事件)
    swReactor_handle error_handle[SW_MAX_FDTYPE];  //扩展事件2(一般为错误事件,如socket关闭)

    int (*add)(swReactor *, int fd, int fdtype);
    int (*set)(swReactor *, int fd, int fdtype);
    int (*del)(swReactor *, int fd);
    int (*wait)(swReactor *, struct timeval *);
    void (*free)(swReactor *);

    int (*setHandle)(swReactor *, int fdtype, swReactor_handle);
    swDefer_callback *defer_callback_list;
    swDefer_callback idle_task;

    void (*onTimeout)(swReactor *);
    void (*onFinish)(swReactor *);

    void (*enable_accept)(swReactor *);

    int (*write)(swReactor *, int, void *, int);
    int (*close)(swReactor *, int);
    int (*defer)(swReactor *, swCallback, void *);
};
```


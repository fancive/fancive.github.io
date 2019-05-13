---
title: nginx_listening
date: 2018-06-13 13:42:24
tags:
- nginx
- tech

---

# ngx_listening_t

## 定义

```c
typedef struct ngx_listening_s  ngx_listening_t;

struct ngx_listening_s {
    ngx_socket_t        fd;

    struct sockaddr    *sockaddr;
    socklen_t           socklen;    /* size of sockaddr */
    size_t              addr_text_max_len;
    ngx_str_t           addr_text;

    int                 type; //套接字类型

    int                 backlog;
    int                 rcvbuf; //内核接收缓冲区大小
    int                 sndbuf; //内核发送缓冲区大小

    /* handler of accepted connection */
    ngx_connection_handler_pt   handler; //tcp连接建立成功后执行方法

    void               *servers;  /* array of ngx_http_in_addr_t, for example */

    ngx_log_t           log;
    ngx_log_t          *logp;

    size_t              pool_size;
    /* should be here because of the AcceptEx() preread */
    size_t              post_accept_buffer_size;
    /* should be here because of the deferred accept */
    ngx_msec_t          post_accept_timeout;

    ngx_listening_t    *previous; //ngx_listening_t 构成的单链表
    ngx_connection_t   *connection; //当前监听fd对应的 ngx_connection_t

    unsigned            open:1; //当前监听fd是否有效
    unsigned            remain:1; // 是否使用已有的ngx_cycle_t初始化
    unsigned            ignore:1;
    unsigned            bound:1;       /* already bound */
    unsigned            inherited:1;   //当前监听fd是否来自前一个进程
    unsigned            nonblocking_accept:1;
    unsigned            listen:1; // 为1表示当前结构体对应的套接字已经监听
    unsigned            nonblocking:1;
    unsigned            shared:1;    /* shared between threads or processes */
    unsigned            addr_ntop:1;

    unsigned            keepalive:2;
};
```


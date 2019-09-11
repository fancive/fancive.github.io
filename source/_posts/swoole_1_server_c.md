---
title: swoole_1_server.c
categories: 
- 中间件
tags:
- swoole
- tech
---

# swoole-server-1


## main()

* swServer_init() 初始化
* swServer_create() 根据 factory_mode 创建reactor线程
* swServer_add_port() 还没看
* swServer_start() 启动Server
```c
int main(int argc, char **argv)
{
	int ret;

	swServer serv;
	swServer_init(&serv); //初始化

	//config
	serv.reactor_num = 2; //reactor线程数量
	serv.worker_num = 4;      //worker进程数量

	serv.factory_mode = SW_MODE_PROCESS; //SW_MODE_PROCESS SW_MODE_THREAD SW_MODE_BASE
	serv.max_connection = 100000;
	//serv.open_cpu_affinity = 1;
	//serv.open_tcp_nodelay = 1;
	//serv.daemonize = 1;
	//serv.open_eof_check = 1;

	//create Server
	ret = swServer_create(&serv);
	if (ret < 0)
	{
		swTrace("create server fail[error=%d].\n", ret);
		exit(0);
	}

	//swServer_addListen(&serv, SW_SOCK_UDP, "127.0.0.1", 9500);
	swListenPort *port = swServer_add_port(&serv, SW_SOCK_TCP, "127.0.0.1", 9501);
	//swServer_addListen(&serv, SW_SOCK_UDP, "127.0.0.1", 9502);
	//swServer_addListen(&serv, SW_SOCK_UDP, "127.0.0.1", 8888);
	port->backlog = 128;

	serv.onStart = my_onStart;
	serv.onShutdown = my_onShutdown;
	serv.onConnect = my_onConnect;
	serv.onReceive = my_onReceive;
	serv.onClose = my_onClose;
	serv.onWorkerStart = my_onWorkerStart;
	serv.onWorkerStop = my_onWorkerStop;

	ret = swServer_start(&serv);
	if (ret < 0)
	{
		swTrace("start server fail[error=%d].\n", ret);
		exit(0);
	}
	return 0;
}
```


```c
void swServer_init(swServer *serv);

```

## swServer_init() 

就是初始化结构体成员, 调用 swoole_init()

```c
/**
 * initializing server config, set default
 */
void swServer_init(swServer *serv)
{
    swoole_init();
    bzero(serv, sizeof(swServer));

    serv->factory_mode = SW_MODE_BASE;

    serv->reactor_num = SW_REACTOR_NUM > SW_REACTOR_MAX_THREAD ? SW_REACTOR_MAX_THREAD : SW_REACTOR_NUM;

    serv->dispatch_mode = SW_DISPATCH_FDMOD;

    serv->worker_num = SW_CPU_NUM;
    serv->max_connection = SwooleG.max_sockets < SW_SESSION_LIST_SIZE ? SwooleG.max_sockets : SW_SESSION_LIST_SIZE;

    serv->max_request = 0;
    serv->max_wait_time = SW_WORKER_MAX_WAIT_TIME;

    //http server
    serv->http_parse_post = 1;
    serv->upload_tmp_dir = sw_strdup("/tmp");

    //heartbeat check
    serv->heartbeat_idle_time = SW_HEARTBEAT_IDLE;
    serv->heartbeat_check_interval = SW_HEARTBEAT_CHECK;

    serv->buffer_input_size = SW_BUFFER_INPUT_SIZE;
    serv->buffer_output_size = SW_BUFFER_OUTPUT_SIZE;

    SwooleG.serv = serv;
}
```

##  swServer_add_port

这里是socket, bind 
```c

swListenPort* swServer_add_port(swServer *serv, int type, char *host, int port)
{
    if (serv->listen_port_num >= SW_MAX_LISTEN_PORT)
    {
        swoole_error_log(SW_LOG_ERROR, SW_ERROR_SERVER_TOO_MANY_LISTEN_PORT, "allows up to %d ports to listen", SW_MAX_LISTEN_PORT);
        return NULL;
    }
    if (!(type == SW_SOCK_UNIX_DGRAM || type == SW_SOCK_UNIX_STREAM) && (port < 0 || port > 65535))
    {
        swoole_error_log(SW_LOG_ERROR, SW_ERROR_SERVER_INVALID_LISTEN_PORT, "invalid port [%d]", port);
        return NULL;
    }
    if (strlen(host) + 1  > SW_HOST_MAXSIZE)
    {
        swoole_error_log(SW_LOG_ERROR, SW_ERROR_NAME_TOO_LONG, "address '%s' exceeds %d characters limit", host, SW_HOST_MAXSIZE - 1);
        return NULL;
    }

    swListenPort *ls = SwooleG.memory_pool->alloc(SwooleG.memory_pool, sizeof(swListenPort));
    if (ls == NULL)
    {
        swError("alloc failed");
        return NULL;
    }

    swPort_init(ls);
    ls->type = type;
    ls->port = port;
    strncpy(ls->host, host, strlen(host) + 1);

    if (type & SW_SOCK_SSL)
    {
        type = type & (~SW_SOCK_SSL);
        if (swSocket_is_stream(type))
        {
            ls->type = type;
            ls->ssl = 1;
#ifdef SW_USE_OPENSSL
            ls->ssl_config.prefer_server_ciphers = 1;
            ls->ssl_config.session_tickets = 0;
            ls->ssl_config.stapling = 1;
            ls->ssl_config.stapling_verify = 1;
            ls->ssl_config.ciphers = sw_strdup(SW_SSL_CIPHER_LIST);
            ls->ssl_config.ecdh_curve = sw_strdup(SW_SSL_ECDH_CURVE);
#endif
        }
    }

    //create server socket
    int sock = swSocket_create(ls->type);
    if (sock < 0)
    {
        swSysError("create socket failed.");
        return NULL;
    }
    //bind address and port
    if (swSocket_bind(sock, ls->type, ls->host, &ls->port) < 0)
    {
        close(sock);
        return NULL;
    }
    //dgram socket, setting socket buffer size
    if (swSocket_is_dgram(ls->type))
    {
        setsockopt(sock, SOL_SOCKET, SO_SNDBUF, &ls->socket_buffer_size, sizeof(int));
        setsockopt(sock, SOL_SOCKET, SO_RCVBUF, &ls->socket_buffer_size, sizeof(int));
    }
    //O_NONBLOCK & O_CLOEXEC
    swoole_fcntl_set_option(sock, 1, 1);
    ls->sock = sock;

    if (swSocket_is_dgram(ls->type))
    {
        serv->have_udp_sock = 1;
        serv->dgram_port_num++;
        if (ls->type == SW_SOCK_UDP)
        {
            serv->udp_socket_ipv4 = sock;
        }
        else if (ls->type == SW_SOCK_UDP6)
        {
            serv->udp_socket_ipv6 = sock;
        }
    }
    else
    {
        serv->have_tcp_sock = 1;
    }

    LL_APPEND(serv->listen_list, ls);
    serv->listen_port_num++;
    return ls;
}
```
## listen swServer_start_proxy

注册swServer_master_onAccept事件

```c
/**
 * proxy模式
 * 在单独的n个线程中接受维持TCP连接
 */
static int swServer_start_proxy(swServer *serv)
{
    int ret;
    swReactor *main_reactor = SwooleG.memory_pool->alloc(SwooleG.memory_pool, sizeof(swReactor));

    ret = swReactor_create(main_reactor, SW_REACTOR_MAXEVENTS);
    if (ret < 0)
    {
        swWarn("Reactor create failed");
        return SW_ERR;
    }

    main_reactor->thread = 1;
    main_reactor->socket_list = serv->connection_list;
    main_reactor->disable_accept = 0;
    main_reactor->enable_accept = swServer_enable_accept;

#ifdef HAVE_SIGNALFD
    if (SwooleG.use_signalfd)
    {
        swSignalfd_setup(main_reactor);
    }
#endif

    //set listen socket options
    swListenPort *ls;
    LL_FOREACH(serv->listen_list, ls)
    {
        if (swSocket_is_dgram(ls->type))
        {
            continue;
        }
        if (swPort_listen(ls) < 0)
        {
            return SW_ERR;
        }
    }

    /**
     * create reactor thread
     */
    ret = swReactorThread_start(serv, main_reactor);
    if (ret < 0)
    {
        swWarn("ReactorThread start failed");
        return SW_ERR;
    }

#ifndef SW_USE_TIMEWHEEL
    /**
     * heartbeat thread
     */
    if (serv->heartbeat_check_interval >= 1 && serv->heartbeat_check_interval <= serv->heartbeat_idle_time)
    {
        swTrace("hb timer start, time: %d live time:%d", serv->heartbeat_check_interval, serv->heartbeat_idle_time);
        swHeartbeatThread_start(serv);
    }
#endif

    /**
     * master thread loop
     */
    SwooleTG.type = SW_THREAD_MASTER;
    SwooleTG.factory_target_worker = -1;
    SwooleTG.factory_lock_target = 0;
    SwooleTG.id = serv->reactor_num;
    SwooleTG.update_time = 1;

    SwooleG.main_reactor = main_reactor;
    SwooleG.pid = getpid();
    SwooleG.process_type = SW_PROCESS_MASTER;

    /**
     * set a special id
     */
    main_reactor->id = serv->reactor_num;
    main_reactor->ptr = serv;
    main_reactor->setHandle(main_reactor, SW_FD_LISTEN, swServer_master_onAccept);

    if (serv->onStart != NULL)
    {
        serv->onStart(serv);
    }

    struct timeval tmo;
    tmo.tv_sec = 1; //for seconds timer
    tmo.tv_usec = 0;
    return main_reactor->wait(main_reactor, &tmo);
}

```



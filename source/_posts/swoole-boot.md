---
title: swoole_boot
date: 2018-06-22 23:02:24
categories: 
- 中间件
tags: 
- swoole
- tech
---

# swoole 启动

## 流程

* minit
* swoole_server->start()

  

## MINIT && RINIT

swoole作为php扩展在minit阶段启动，实现 PHP_MINIT_FUNCTION 宏和 PHP_RINIT_FUNCTION 宏


```c

/* {{{ PHP_MINIT_FUNCTION
 */
PHP_MINIT_FUNCTION(swoole)
{
    ZEND_INIT_MODULE_GLOBALS(swoole, php_swoole_init_globals, NULL);
    REGISTER_INI_ENTRIES();

    ...
    // 常量
    REGISTER_STRINGL_CONSTANT("SWOOLE_VERSION", PHP_SWOOLE_VERSION, sizeof(PHP_SWOOLE_VERSION) - 1, CONST_CS | CONST_PERSISTENT);

    // 类, swoole_server_methods数组包含start方法
    SWOOLE_INIT_CLASS_ENTRY(swoole_server_ce, "swoole_server", "Swoole\\Server", swoole_server_methods);

    //类属性
    zend_declare_property_null(swoole_server_class_entry_ptr, ZEND_STRL("onConnect"), ZEND_ACC_PUBLIC TSRMLS_CC);

    //swoole init
    swoole_init();
    ...
    return SUCCESS;
}

PHP_RINIT_FUNCTION(swoole)
{
    //running
    SwooleG.running = 1;
    ...
    return SUCCESS;
}
```

## swoole_server.c 

swoole_server ->start


```c
PHP_METHOD(swoole_server, start)
{
    zval *zobject = getThis();
    int ret;

    if (SwooleGS->start > 0)
    {
        swoole_php_fatal_error(E_WARNING, "server is running. unable to execute swoole_server->start.");
        RETURN_FALSE;
    }

    swServer *serv = swoole_get_object(zobject);
    php_swoole_register_callback(serv);

    if (php_sw_server_callbacks[SW_SERVER_CB_onReceive] == NULL && php_sw_server_callbacks[SW_SERVER_CB_onPacket] == NULL)
    {
        swoole_php_fatal_error(E_ERROR, "require onReceive/onPacket callback");
        RETURN_FALSE;
    }
    //-------------------------------------------------------------
    serv->onReceive = php_swoole_onReceive;
    serv->ptr2 = zobject;

    sw_zval_add_ref(&zobject);
    php_swoole_server_before_start(serv, zobject TSRMLS_CC);

    ret = swServer_start(serv);
    if (ret < 0)
    {
        swoole_php_fatal_error(E_ERROR, "failed to start server. Error: %s", sw_error);
        RETURN_LONG(ret);
    }
    RETURN_TRUE;
}
```

## swServer_start()


```c

int swServer_start(swServer *serv)
{
    swFactory *factory = &serv->factory;
    
    ...
        
    //run as daemon
    if (serv->daemonize > 0)
    {    
        ...
    }

    ...

    serv->send = swServer_tcp_send;
    serv->sendwait = swServer_tcp_sendwait;
    serv->sendfile = swServer_tcp_sendfile;
    serv->close = swServer_tcp_close;
    
    // worker内存
    serv->workers = SwooleG.memory_pool->alloc(SwooleG.memory_pool, serv->worker_num * sizeof(swWorker));

    ...
    
    //factory start 下面会讨论
    if (factory->start(factory) < 0)
    {
        return SW_ERR;
    }
    //signal Init
    swServer_signal_init(serv);

    if (serv->factory_mode == SW_MODE_SINGLE)
    {
        ret = swReactorProcess_start(serv);
    }
    else
    {
        ret = swServer_start_proxy(serv); //base && process
    }
    
    ...    
    return SW_OK;
}
```

## factory->start()

swoole_server.c

```c

PHP_METHOD(swoole_server, __construct)
{
    ...
    
    long serv_mode = SW_MODE_PROCESS;

    ...
    
    swServer_init(serv);

#ifdef __CYGWIN__
    serv_mode = SW_MODE_SINGLE;
#elif !defined(SW_USE_THREAD)
    if (serv_mode == SW_MODE_THREAD || serv_mode == SW_MODE_BASE)
    {
        serv_mode = SW_MODE_SINGLE;
        swoole_php_fatal_error(E_WARNING, "can't use multi-threading in PHP. reset server mode to be SWOOLE_MODE_BASE");
    }
#endif
    serv->factory_mode = serv_mode;
    
    ...
}
```

回到 swoole_server ->start -> php_swoole_server_before_start() ->swServer_create()


## swServer_create()


```c
int swServer_create(swServer *serv)
{
    ...

    if (serv->factory_mode == SW_MODE_SINGLE)
    {
        return swReactorProcess_create(serv);
    }
    else
    {
        return swReactorThread_create(serv);
    }
}
```

swReactorProcess_create()->swFactory_create()->swFactory_start() 什么都没做

```c
int swFactory_start(swFactory *factory)
{
    SwooleWG.run_always = 1;
    return SW_OK;
}
```

## swReactorThread_create()


```c

int swReactorThread_create(swServer *serv)
{
    ...
    
    if (serv->factory_mode == SW_MODE_THREAD)
    {
        if (serv->worker_num < 1)
        {
            swError("Fatal Error: serv->worker_num < 1");
            return SW_ERR;
        }
        ret = swFactoryThread_create(&(serv->factory), serv->worker_num);
    }
    else if (serv->factory_mode == SW_MODE_PROCESS)
    {
        if (serv->worker_num < 1)
        {
            swError("Fatal Error: serv->worker_num < 1");
            return SW_ERR;
        }
        ret = swFactoryProcess_create(&(serv->factory), serv->worker_num);
    }
    else
    {
        ret = swFactory_create(&(serv->factory));
    }
}
```
swFactoryProcess_create()->swFactoryProcess_create()


```c
int swFactoryProcess_create(swFactory *factory, int worker_num)
{
    ...    
    factory->start = swFactoryProcess_start;
    ...
}
```

## swFactoryProcess_start()


```c
static int swFactoryProcess_start(swFactory *factory)
{
    int i;
    swServer *serv = factory->ptr;
    swWorker *worker;

    for (i = 0; i < serv->worker_num; i++)
    {
        worker = swServer_get_worker(serv, i);
        if (swWorker_create(worker) < 0)
        {
            return SW_ERR;
        }
    }

    serv->reactor_pipe_num = serv->worker_num / serv->reactor_num;

    //必须先启动manager进程组，否则会带线程fork
    if (swManager_start(factory) < 0)
    {
        swWarn("swFactoryProcess_manager_start failed.");
        return SW_ERR;
    }
    //主进程需要设置为直写模式
    factory->finish = swFactory_finish;
    return SW_OK;
}
```


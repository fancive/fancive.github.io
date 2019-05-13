---
title: nginx_boot
date: 2018-06-13 15:49:56
categories:
- 中间件
tags:
- nginx
---

# main

## 流程

* ngx_get_options() 获取参数
* init_cycle
* ngx_process_options() 
* ngx_add_inherited_sockets() 平滑重启
* ngx_init_cycle()
    1. cycle->listening.elts = ngx_pcalloc(pool, n * sizeof(ngx_listening_t));
    1. ngx_modules[i]->ctx->create_conf(cycle)
    1. ngx_conf_param() 
    1. ngx_conf_parse()
    1. ngx_modules[i]->ctx->init_conf(cycle, cycle->conf_ctx[ngx_modules[i]->index])
    1. ngx_open_listening_sockets() 
    1. ngx_open_listening_sockets()
    1. ngx_modules[i]->init_module(cycle)
* ngx_master_process_cycle()
* ngx_start_worker_processes()
* ngx_start_cache_manager_processes()
* 


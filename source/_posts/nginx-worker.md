---
title: nginx_worker
date: 2018-06-14 15:41:08
tags:
---


# worker

## ngx_start_worker_processes 

- ngx_spawn_process()
    - ngx_worker_process_cycle()
        - ngx_worker_process_init()
        - ngx_process_events_and_timers()
- ngx_pass_open_channel()



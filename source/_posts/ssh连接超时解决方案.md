---
title: ssh连接超时解决方案
author: Bill Zong
tags:
  - bash
  - ssh
categories:
  - Shell
abbrlink: 4c3910cf
date: 2021-04-25 22:04:00
---
## 修改Server端

```
# etc/ssh/sshd_config

ClientAliveInterval 60 ＃server每隔60秒发送一次请求给client，然后client响应，从而保持连接
ClientAliveCountMax 3 ＃server发出请求后，客户端没有响应得次数达到3，就自动断开连接，正常情况下，client不会不响应
```

## 修改Client端

在没有权限改server配置的情形下

```
# etc/ssh/ssh_config

ServerAliveInterval 60 ＃client每隔60秒发送一次请求给server，然后server响应，从而保持连接
ServerAliveCountMax 3  ＃client发出请求后，服务器端没有响应得次数达到3，就自动断开连接，正常情况下，server不会不响应
```

## 连接时增加响应

* 不修改配置文件

* 在命令参数里 `ssh -o ServerAliveInterval=60` 
    * 只在需要的连接中保持持久连接。 毕竟不是所有连接都要保持持久的
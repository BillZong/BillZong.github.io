---
title: SSH禁止密码登录，修改SSH配置文件
author: Bill Zong
tags:
  - ssh
  - bash
categories:
  - Shell
abbrlink: 56b134ed
date: 2021-04-13 22:00:00
---
`/etc/ssh/sshd_config`

关闭root用户使用密码登陆

```
#禁用密码验证
PasswordAuthentication no  //修改为no 
打开下面3个的注释。43行
#启用密钥验证
RSAAuthentication yes
PubkeyAuthentication yes
#指定公钥数据库文件
AuthorizedKeysFile  .ssh/authorized_keys
```
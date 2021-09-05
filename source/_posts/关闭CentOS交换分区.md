---
title: 关闭CentOS交换分区
author: Bill Zong
tags:
  - swap
categories:
  - Linux
abbrlink: e9025282
date: 2021-04-25 22:11:00
---
```
swapoff -a
sed -i '/^\/dev\/mapper\/centos-swap*/d' /etc/fstab
```
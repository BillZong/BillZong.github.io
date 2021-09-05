---
title: awk结合kubeadm删除无效token的脚本
author: Bill Zong
tags:
  - awk
  - kubeadm
  - bash
categories:
  - Shell
abbrlink: 756e1ce4
date: 2021-04-13 22:02:00
---
```
# 删除所有token
kubeadm token list | awk 'NR == 1 {next} {print $1}' |
while read s
do
  kubeadm token delete $s
done

# 删除无效token
kubeadm token list | awk 'NR == 1 {next} $2=="<invalid>" {print $1}' |
while read s
do
  kubeadm token delete $s
done
```
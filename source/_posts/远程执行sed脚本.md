---
title: 远程执行sed脚本
author: Bill Zong
tags:
  - bash
  - ssh
  - sed
categories:
  - Shell
abbrlink: 6fcc8439
date: 2021-04-25 22:04:00
---
```
for ((i=1;i<=9;i++)); do
	ssh "sz-bg-13$i" 'sed -i "s/#StrictModes yes/StrictModes no/g" /etc/ssh/sshd_config'
done
```
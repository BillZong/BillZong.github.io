---
title: CentOS7升级内核全流程
author: Bill Zong
tags:
  - kernel
  - upgrade
categories:
  - Linux
abbrlink: 2a353e7b
date: 2021-04-25 22:09:00
---
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

# 安装Redhat内核仓库

#rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm

# 或者如上指定版本，目前版本为7.0-5

# yum install https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm -y

yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm -y

# 查看内核仓库元信息

yum --disablerepo=\* --enablerepo=elrepo-kernel repolist

# 查看内容仓库所有版本

yum --disablerepo=\* --enablerepo=elrepo-kernel list kernel*

# 安装最新的 LT 版本

yum --disablerepo=\* --enablerepo=elrepo-kernel install  kernel-lt.x86_64  -y

# 也可以安装最新的主线分支版本

# yum --disablerepo=\* --enablerepo=elrepo-kernel install  kernel-ml.x86_64  -y

# 删除旧版本工具包

yum remove kernel-tools-libs.x86_64 kernel-tools.x86_64  -y

# 安装新版本工具包

yum --disablerepo=\* --enablerepo=elrepo-kernel install kernel-lt-tools.x86_64  -y

# 查看内核插入顺序

awk -F \' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg

# 或者使用下面的命令查看

grep "^menuentry" /boot/grub2/grub.cfg | cut -d "'" -f2

# 查看当前实际启动顺序

grub2-editenv list

# 设置默认启动，记得修改版本为当前的版本

grep "^menuentry" /boot/grub2/grub.cfg | cut -d "'" -f2 | grep -v 'tool' | awk 'NR==1{print}' | while read kernal; do grub2-set-default "$kernal"; done

# 目前版本信息也是一样的

# grub2-set-default 'CentOS Linux (5.10.9-1.el7.elrepo.x86_64) 7 (Core)'

# 或者直接设置默认启动内核系统下标

# grub2-set-default 0 # 自测无效

# 重启并检查

reboot

# 查看系统中全部的内核rpm包

rpm -qa |grep kernel

# 如果不考虑使用老内核，也可以将其清除掉

# 删除旧内核的rpm包

yum remove kernel-3.10.0-957.el7.x86_64
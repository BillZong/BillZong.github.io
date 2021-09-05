---
title: CentOS部署和配置NTP服务器
author: Bill Zong
tags:
  - CentOS 7
  - ntp
  - deploy
categories:
  - Linux
abbrlink: c9a962b3
date: 2021-04-25 22:10:00
---
## ntp服务端

```
# 将所有节点设置为中国时区
echo "Asia/shanghai" > /etc/timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

```
# 设置系统时间
date -s '2021-01-11 15:20:00'
# 写入硬件时间
hwclock -w
```

```
# 安装chrony
yum install chrony -y

# 对于用作ntp server的服务器，需要修改server本身的时钟源:
sed -e 's!centos.pool.ntp.org!cn.pool.ntp.org!g' -i /etc/chrony.conf
# 也可以考虑不再同步外部NTP服务
sed -i '/^server*/d' /etc/chrony.conf

# 设置可以访问服务的IP网段
sed -e '/^#allow*/a\allow 172.20.0.0/16 \nallow 172.16.0.0/16 \nallow 10.0.0.0/8' -i /etc/chrony.conf

# 设置开机自启并启动服务
systemctl enable chronyd && systemctl restart chronyd
```

## ntp客户端

```
# 将所有节点设置为中国时区
echo "Asia/shanghai" > /etc/timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 安装chrony
yum install chrony -y

# 其它需要时钟同步的节点，设置从上述服务器同步时钟
sed -i '/^server*/d' /etc/chrony.conf
sed -i -e '/^# Please consider*/a\server 218.204.171.130 minpoll 4 maxpoll 10 iburst' /etc/chrony.conf
systemctl enable chronyd && systemctl restart chronyd

# 非常关键的一步，将时间同步更新到date控件
timedatectl set-ntp yes

# 同步时间后，把当前时间写入硬件时间
hwclock -w
```
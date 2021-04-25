---
title: 一次OpenSSH升级记录
author: Bill Zong
tags:
  - OpenSSH
  - upgrade
categories:
  - Linux
abbrlink: 87c46404
date: 2021-04-25 22:08:00
---
```
ssh -V


# 安装telnet 防止无法登陆。完成后记得关闭telnet服务
apt-get install openbsd-inetd telnetd telnet -y
/etc/init.d/openbsd-inetd restart


# 修改配置以使root用户可以登录。完成后记得恢复
## 修改 /etc/inetd.conf文件，只需取消下面一行注释掉即可。
#telnet          stream  tcp     nowait  telnetd /usr/sbin/tcpd  /usr/sbin/in.telnetd
## 允许root用户telnet登录。记得恢复
### 有两种方法：
### (1)输入命令：mv /etc/securetty /etc/securetty.bak
### (2)修改/etc/pam.d/login这个文件。只需将下面一行注释一下即可。 
#auth required lib/security/pam_securetty.so 
mv /etc/securetty /etc/securetty.bak


# 从其它机器进行telnet登陆
telnet 10.1.1.10

mkdir -p /root/workspace


# 安装 gcc, make 等工具
apt install gcc make -y


# 更新（安装）zlib
cd /root/workspace
wget http://zlib.net/zlib-1.2.11.tar.gz
tar xvf zlib-1.2.11.tar.gz
cd /root/workspace/zlib-1.2.11
./configure --shared
make -j 8
make install

# 后面安装openssl错误时，需要回来执行这个，所以先进行执行
make clean
./configure --shared
make test
make install
cp zutil.h /usr/local/include
cp zutil.c /usr/local/include


# 更新（安装）openssl
cd /root/workspace
wget https://www.openssl.org/source/openssl-1.1.1h.tar.gz
tar zxvf openssl-1.1.1h.tar.gz
cd /root/workspace/openssl-1.1.1h
./config shared zlib
make -j 8
make install


# 备份原来的openssl,创建软链接到系统位置
mv /usr/bin/openssl /usr/bin/openssl.bak 
mv /usr/include/openssl /usr/include/openssl.bak 
ln -s /usr/local/bin/openssl /usr/bin/openssl
ln -s /usr/local/include/openssl /usr/include/openssl


# 将openssl 的lib 库添加到系统，并使用
echo "/usr/local/lib" > /etc/ld.so.conf.d/openssl.conf
ldconfig  


# 查看 openssl 版本
openssl version -a


# 更新 openssh
# 备份原openssh文件,卸载原openssh
mv /etc/init.d/ssh /etc/init.d/ssh.old
cp -r /etc/ssh /etc/ssh.old
apt-get remove openssh-server openssh-client -y


# 安装新版本
apt-get install libpam0g-dev -y
cd /root/workspace
wget --no-check-certificate https://fastly.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.4p1.tar.gz
tar zxvf openssh-8.4p1.tar.gz
cd openssh-8.4p1

./configure --prefix=/usr \
--sysconfdir=/etc/ssh \
--with-md5-passwords \
--with-pam --with-zlib \
--with-ssl-dir=/usr/local \
--with-privsep-path=/var/lib/sshd #需要指定openssl的安装路径 

make -j 8
make install 


# 查看安装更新效果
ssh -V


# 还原配置文件
cd /etc/ssh
mv sshd_config sshd_config.default
cp ../ssh.old/sshd_config ./
systemctl unmask sshd
systemctl restart sshd


# 使用ssh重新登陆设备，并进行其它恢复
sed -i '/^.*GSSAPIAuthentication/d' /etc/ssh/ssh_config
systemctl stop openbsd-inetd
systemctl disable openbsd-inetd
mv /etc/securetty.bak /etc/securetty
apt-get remove openbsd-inetd -y

```

以上脚本为Ubuntu使用，后面的脚本为CentOS7使用：

```
# 安装telnet服务器
yum install xinetd telnet-server telnet -y

# 添加root用户访问权限
cat <<EOT >>/etc/securetty
pts/0
pts/1
pts/2
pts/3
EOT

# 启动telnet服务
systemctl start telnet.socket
systemctl start xinetd




# 使用telnet连接并升级OpenSSH
telnet 10.1.1.10

# 升级安装工具
yum install  -y gcc gcc-c++ glibc make autoconf pcre-devel

# 安装pam
yum install pam* -y


# 更新（安装）zlib
cd /root/workspace
wget http://zlib.net/zlib-1.2.11.tar.gz
tar xvf zlib-1.2.11.tar.gz
cd /root/workspace/zlib-1.2.11
./configure --prefix=/usr/local/zlib --shared
make -j 8
make install

# 后面安装openssl错误时，需要回来执行这个，所以先进行执行
make clean
./configure --shared
make test
make install
cp zutil.h /usr/local/include
cp zutil.c /usr/local/include


# 更新（安装）openssl
cd /root/workspace
wget https://www.openssl.org/source/openssl-1.1.1h.tar.gz
tar zxvf openssl-1.1.1h.tar.gz
cd /root/workspace/openssl-1.1.1h
./config -fPIC enable-shared
make -j 8
make install


# 备份原来的openssl,创建软链接到系统位置
mv /usr/bin/openssl /usr/bin/openssl.bak 
mv /usr/include/openssl /usr/include/openssl.bak 
ln -s /usr/local/bin/openssl /usr/bin/openssl
ln -s /usr/local/include/openssl /usr/include/openssl


# 将openssl 的lib 库添加到系统，并使用
echo "/usr/local/lib" > /etc/ld.so.conf.d/openssl.conf
ldconfig  


# 查看 openssl 版本
openssl version -a


# 更新 openssh
# 备份原openssh文件,卸载原openssh
cp -r /etc/ssh /etc/ssh.old
# 不应该删除sshd服务，否则会导致无法使用
#yum remove openssh-server -y


# 安装新版本
cd /root/workspace
wget --no-check-certificate https://fastly.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.4p1.tar.gz
tar zxvf openssh-8.4p1.tar.gz
cd /root/workspace/openssh-8.4p1
./configure --prefix=/usr \
--sysconfdir=/etc/ssh \
--with-md5-passwords \
--with-pam --with-zlib \
--with-ssl-dir=/usr/local \
--with-privsep-path=/var/lib/sshd
make -j 8
make install 

# 查看安装更新效果
ssh -V


# 还原配置文件
cd /etc/ssh
mv sshd_config sshd_config.default
cp ../ssh.old/sshd_config ./
systemctl unmask sshd
systemctl restart sshd



# 使用ssh登陆目标设备并恢复环境
systemctl stop telnet.socket
systemctl stop xinetd
sed -i '/^pts\/.*/d' /etc/securetty
yum remove telnet-server xinetd -y
```



## 参考资料

* [Ubuntu设置telnet 远程登录(root权限)](https://www.cnblogs.com/appear001/p/13293703.html)
* [CentOS-升级openSSH，修复安全漏洞](https://cloud.tencent.com/developer/news/378034)
* [error： zlib.h:no such file or directory](https://blog.51cto.com/53cto/1768007)
* [UBUNTU 18.04 升级OPENSSH 8.4P1](https://zalenet.cn/archives/ubuntu1804%E5%8D%87%E7%BA%A7openssh84p1)
* [centos7 升级openssh到openssh-8.0p1版本](https://www.cnblogs.com/nmap/p/10779658.html)
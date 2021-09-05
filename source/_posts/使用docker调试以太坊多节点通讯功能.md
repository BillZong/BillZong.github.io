---
title: 使用docker调试以太坊多节点通讯功能
author: Bill Zong
tags:
  - ethereum
  - docker
  - p2p
categories:
  - 区块链
abbrlink: 48c09b8d
date: 2021-04-12 22:21:00
---
## 内容提要
本文将介绍如何使用docker来启动多个以太坊应用实例，并且使用IDE连接这些实例进行调试。
本文仅做基础性介绍，不涉及docker原理、docker容器编排(多机部署)等内容

## 本文目的

1. 使用docker缓解多节点部署带来的困难

	* p2p网络需要>=2两个节点来验证
	* 使用多台物理机非常困难，需要依赖同事配合
	* 在一台机器上运行多个节点
		* 需要调整端口、数据文件夹
			* 但是代码是共享的，修改比较麻烦
			* 不过也可以通过指定参数来缓解

2. 使用docker来隔离运行环境

	* 不再因为每个人运行环境不一样而导致问题
	* 不再需要调整端口、数据文件夹
		* 因为都是隔离的运行环境，可以认为就是一台虚拟机
	* 可以互相通讯
	* 可以比较方便的控制启动、停止等

3. 远端调试go程序

	* 节点通过docker运行后就需要使用远端调试技术

4. 在docker中使用本地文件夹（挂载）

5. 一些简单的docker命令



##正文1 docker的简单介绍
* www.docker.com
![图片](https://lexiangla.com/assets/f5782f54d34b11e8bab4525400e884b1 "图片")

* 什么是docker
	* 一项虚拟化技术
	* 开箱即用
	* Container Engine

* 与传统虚拟化技术的比较
![图片](https://lexiangla.com/assets/3f538d5cd34d11e88376525400ac2e73 "图片")

* 名词解释
	* image 可以认为和安装操作系统时用到的镜像是一个概念
		* image是一个不可修改的可运行的系统的模板
		* 通过层的概念，可以非常方便的创建、复用

	* container 可以认为就是一个正在运行的虚拟机
		* 拥有自己的网络等配置
		* 可以很方便的启动、停止、重启
		* 我们也称container为image的一个实例(instance)

	* registries 用于存储image的地方
		* 可公有或者私有

	* docker engine
		* 可以认为就是docker的运行时环境
		* 在linux上体现为dockerd服务

	* docker命令行
		* docker是cs架构
		* 通过命令行docker与docker engine交互
		* 具体命令都发送给docker engine去执行
		* 下文中docker的具体含义请根据上下文去理解是指docker运行时还是指docker命令

* 架构
![图片](https://lexiangla.com/assets/d23aeb92d34d11e8aebd5254004f9daa "图片")

* 下载
	* 使用 community edition即可

##正文2 docker实操(命令介绍)

***此处仅介绍若干命令的基本用法，不是完整而完全正确的解释***

* docker pull
	* 用于获取镜像
	* 默认从 https://hub.docker.com/ 获取image
	```
	docker pull ${image_name}:${tag_name}
	# eg: 
	dcoker pull kirklandatdocker/godev
	```
	* tag用于控制版本，可以省略，默认为latest

* docker images
	* 用于列出本地的所有镜像
	```
	docker images
	```
	* 示例输出
	![图片](https://lexiangla.com/assets/a793fc3cd36411e88a73525400a20cd4 "图片")

	* 可以看到image的名字(REPOSITYORY的部分) 、TAG 和 ID
	* 可以使用 名字或者ID + TAG 来唯一表示一个image

* docker run
	* 用于运行一个新的容器
	```
	docker run ${options} ${image_name} ${comamnd} ${command_args}
	# eg:
	docker run -p 2349:2349 --security-opt=seccomp:unconfined --name "p2pserver_debug" -it -v /Users/you/go/src:/root/go/src kirklandatdocker/godev
	```
	* 重要的options
		* --name=${name} 表示container的名字，后续可以使用这个名字来操作此container
		* -it 其实是 -i -t 的简写，用于表示我们需要一个终端(tty)并且要进行交互操作
		* -v 表示将本地目录挂载到contianer
			* eg中的例子表示将 /Users/you/go/src 目录挂载到 container的/root/go/src位置
			* 这样在container中/root/go/src下的内容就是/Users/you/go/src下的文件内容
		* --security-opt=seccomp:unconfined 解除Secure computing mode限制，是我们能自由地使用全部系统调用
			* 如果我们想对container的进程进行debug，那么这个选项就是必须的
		* -p ${host_port}:${container_port} 表示将container上的${cotainer_port} 映射为host的${host_port}
			* 例子中所有经过主机上2349端口上的流量将被全部映射到container的2349端口上
	*问题： run的是什么命令呢？

* docker ps
	* 用于列出系统中所有的container
	```
	docker ps -a
	```
	* 示例输出
	![图片](https://lexiangla.com/assets/a6c2f4a4d36211e8a0ce5254009b631d "图片")
	
	* 可以看到cotainer的id和name，他们都可以用于标识一个container
	* 可以看到container使用的image
	* 可以看到cotainer的状态
		* Up 运行中
		* Exited 已经退出，但是可以被重启

* docker start
	* 可以用于重启一个已经停止(Exited)的container
	```
	docker start ${options} ${container_identifier}
	# eg
	docker start -ai p2pserver_test
	```
	* 重要的options
		* -a 表示将标准输入输出attach到container上
		* -i 表示需要进行交互操作
	*问题： run的是什么命令呢？

* docker rm
	* 表示彻底删除一个container
	```
	docker rm ${options} ${container_identifier}
	# eg
	docker rm -f p2pserver_test
	```
	* 重要的options 
		* -f 强制删除，即使container还在运行中

## OK，掌握了上面的命令之后，你就可以使用docker来搭建、调试相关程序了

* 还有一个疑问，docker run, docker start启动了一个container，但是container里面运行了什么进程？
	* docker run后面可以接command参数，表示启动container后要运行这个进程
	* 或者将使用 dockerfile 中指定的命令 CMD / ENTRYPOINT，这个不详细介绍了
	* docker start之后，container将执行run时候指定的命令

##正文3 使用部署、启动以太坊节点

1. 先获取image

```
docker pull kirklandatdocker/godev
```

* 将获取我打包好的一个image，里面包含了go的开发环境、git命令等
* 但是不包含任何go、以太坊等源代码

2. 启动一个container
	```
	docker run --security-opt=seccomp:unconfined --name "p2pserver_debug" -it -v /Users/you/workspace/go/src:/root/go/src kirklandatdocker/godev
	```
	* 如命令，我们启动一个名为p2pserver_debug的container
	* container的/root/go/src目录就是主机上的/Users/you/workspace/go目录
		* 注意请将 /Users/you/workspace/go 替换为你自己机器上的go目录
	* 启动后我们应该进入了一个linux shell中，表明目前我们在contianer内
	* 通过ifconfig获取此container的ip地址
	* 示例输出
	![图片](https://lexiangla.com/assets/ace97c80d36811e8b8f15254004f9daa "图片")

	* 执行相关命令，编译程序并进行运行
	```
	cd /root/go/src/bitbucket.org/oudmondev/go-blockcloud-transaction-chain
	make && ./build/bin/gbloc --verbosity=10
	```
	* 示例输出
	![图片](https://lexiangla.com/assets/611813fcd36811e8983c5254004f9daa "图片")
	* 请注意保留 self="enode://..." 的输出，后续我们需要通过这个标识来连接到这个gbloc节点

3. 启动另一个container
	```
	docker run -p 2349:2349 --security-opt=seccomp:unconfined --name "p2pclient1_debug" -it -v /Users/you/workspace/go/src:/root/go/src kirklandatdocker/godev
	```
	* 启动了一个名为 p2pclient1_debug 的container，并且暴露了端口2349，这个端口将用于远程debug
	* 需要进行dubug，我们首先要安装dlv程序(请先自行下载好相关源代码)
	```
	cd /root/go/src/github.com/derekparker/delve
	make install
	```
	* 执行debug命令，启动debug服务端
	```
	cd /root/go/src/bitbucket.org/oudmondev/go-blockcloud-transaction-chain/cmd/gbloc
	dlv debug --headless --listen=:2349 --log -- --bootnodes "enode://...@${p2p_server_ip}:30303" --verbosity=10
	# 请注意，如果ide需要dlv version 2的支持，那么需要添加一个执行参数 dlv debug --api-version=2 ...
	```
	* enode参数和p2p_server_ip都是上一步骤上获取到的相关参数，请进行相关替换
	* --listen=:2349 表示dlv debugger会监听2349端口，远端的程序可以发送debug命令道这个端口，然后被debugger接收并执行

4. 打开ide，设置好相关断点，配置好远端调试命令，然后就可以执行debug了
	* 以下为vscode的一个远程调试的配置
	```
	    {
            "name": "remote debug",
            "type": "go",
            "request": "launch",
            "mode": "remote",
            "remotePath": "/root/go/src/bitbucket.org/oudmondev/go-blockcloud-transaction-chain/cmd/gbloc/main.go",
            "port": 2350,
            "host": "127.0.0.1",
            "program": "${workspaceRoot}/cmd/gbloc/main.go",
            "env": {}
        }
	```
	* 配置完毕后就可以在vscode中像调试本地程序一样调试container中的程序了

## 全文完
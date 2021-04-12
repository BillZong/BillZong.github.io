---
title: go111module编译实践说明
author: Bill Zong
tags:
  - golang
  - module
categories:
  - Golang
abbrlink: cb3e5607
date: 2021-04-12 22:27:00
---
# 概要

本文只关注`go 1.11`版本新添加的`modules`编译方式，说明本次[PR]()合入后项目依赖管理和编译方式的变化，以及其中具体的一些坑。

以下操作仅提供相对简便的方式，更复杂、专业的操作内容，请参考相关文档和指令说明。

# 背景

`go 1.11`版本发布了大量改动，其中就包括我们关注的`modules`。

官方放出的[Release Note](https://golang.org/doc/go1.11#modules)中，将`moduels`描述为包版本管理、依赖管理。

从此代码不必再放到`GOPATH`路径下，`go get`也不再是以前那种无版本管理的挫样了。

# 详细说明

## 编译依赖

分为两种情况，一种是路径在`GOPATH	`路径中，另外一种是不在此路径中。我们优先讨论本地仓库路径不在`GOPATH`中的情况。后续描述以此为参考。

所有脚本执行都是在仓库根目录下。

1. 创建`module`

    > go mod init [module] # 创建go.mod，并生成vendor目录

2. 新增某个第三方库

    * `github.com/author/repo_name`在此被称为**module**，还可以使用`go get module@none`拉取该`module`当前最新的版本
    * 将代码拉到本地缓存，解决依赖问题并更新go.mod。同时，还会做代码编译，生成`.a`文件

    > go get github.com/author/repo_name@v1.0.0

    * 将本地下载缓存的代码更新vendor（**可不执行，甚至可以完全不依赖此文件夹，但不使用vendor意味着每次缓存失效后都要从网络重新下载**）

    > go mod vendor

3. 更新其他童鞋新增的第三方库

    * 下载模块信息

    > go mod download

    * 执行更新。

    > go mod tidy

4. 修正某个第三方库版本

    * 直接拉取指定版本的代码

    > go get github.com/author/repo_name@v1.1.0

    * 执行更新动作。**注意！**该操作除了更新未下载的`module`，将`go.mod`的版本信息更新到`go.sum`，还会删除`go.mod`中未被引用的`module`。

    > go mod tidy

    * 将本地下载缓存的代码更新vendor（**可不执行**，甚至可以完全不依赖此文件夹，但不使用vendor意味着每次缓存失效后都要从网络重新下载）

    > go mod vendor

5. 移除某个第三方库版本

    * 编辑`go.mod`。如果你确保项目里边已经不存在这个`module`的引用，**可不执行此步骤**

    > go mod edit -droprequire [module]

    * 执行更新动作。

    > go mod tidy

6. 声明为什么引入第三方库

    * 个人认为这非常重要。如果不声明则引入，建议`Decline`。如果引入了第三方库，但说明填入`Commit`的描述，会随着时间过去而难以被确认。

    > go mod why [-m] [-vendor] packages...

    * 例如查找一个未被引用的`module`，结果如下:

    > $ go mod why github.com/signintech/gopdf

    > github.com/signintech/gopdf
    > (main module does not need package github.com/signintech/gopdf)

7. 查看当前项目所有的`module`，包括自身的

    > go mod graph

## 编译

极度简单，在仓库根目录下执行`make`即可。

但考虑到大伙没有把代码放到`GOPATH`环境，可以再执行`make install`将编译出来的`gbloc`拷贝到`$GOPATH/bin/`这个可执行路径下。

## 仓库在`GOPATH`环境下怎么玩

其实也不难，一个办法是在所有`go mod`指令前面添加上`GO111MODULE=on`，如下所示：

> GO111MODULE=on go mod tidy

但这个操作毕竟不太方便。如果长期使用，可以考虑添加别名，减少输入。

在当前使用的`shell`环境变量配置脚本的最后一行，添加一行内容：
`alias go111="GO111MODULE=on go"`。

重新加载终端配置，从此就可以使用`go111 mod ***`来进行操作了。而其它常规的操作，则使用`go ***`来完成。

因为目前`go`命令行没有提供便捷的配置操作，暂时只能这么处理。

# 参考资料

1. [Command go](https://golang.org/cmd/go)
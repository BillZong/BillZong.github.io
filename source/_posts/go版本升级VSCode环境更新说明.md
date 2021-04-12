---
title: go版本升级VSCode环境更新说明
author: Bill Zong
tags:
  - golang
  - VSCode
  - debug
categories:
  - Golang
abbrlink: 1ec527c6
date: 2021-04-12 22:28:00
---
# 推荐

使用`Homebrew`

* 版本管理方便
* 依赖管理简单

# 流程

> brew install go # 安装最新版本
>
> brew switch go 1.11.1 # 指定切换版本, 如版本不同, 请自己修改

# 问题

更新后原来的`VS Code`上安装的各种开发/调试工具无法正常使用

# 解决办法

> cd ~/go/bin # 系统的GOPATH, 如有修改, 自己切换
>
> rm * # 如果有装其它go二进制文件, 建议备份一下名称, 自己去更新代码/二进制文件, 重新安装

执行以下脚本

```sh
go get -u -v github.com/ramya-rao-a/go-outline
go get -u -v github.com/acroca/go-symbols
go get -u -v github.com/mdempsky/gocode
go get -u -v github.com/rogpeppe/godef
go get -u -v golang.org/x/tools/cmd/godoc
go get -u -v github.com/zmb3/gogetdoc
go get -u -v github.com/golang/lint/golint
go get -u -v github.com/fatih/gomodifytags
go get -u -v golang.org/x/tools/cmd/gorename
go get -u -v sourcegraph.com/sqs/goreturns
go get -u -v golang.org/x/tools/cmd/goimports
go get -u -v github.com/cweill/gotests/...
go get -u -v golang.org/x/tools/cmd/guru
go get -u -v github.com/josharian/impl
go get -u -v github.com/haya14busa/goplay/cmd/goplay
go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs
go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct
go get -u -v github.com/alecthomas/gometalinter
gometalinter --install
go get -u -v golang.org/x/lint/golint
```

```sh
go get -u -v github.com/derekparker/delve
cd $GOPATH/src/github.com/derekparker/delve
make install
```

重新启动`VS Code`项目或程序

# 其它

因为go版本变化, 导致原来编译的二进制文件不可用. 所以不只是`VS Code`的相关依赖的Go环境吗, 还有其它的工具, 需要根据具体环境来进行处理.
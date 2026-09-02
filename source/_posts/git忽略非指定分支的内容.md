---
title: git 忽略非指定分支的内容
tags:
  - git
  - fetch
  - refspec
  - 分支管理
categories:
  - 工具
abbrlink: 9471d398
date: 2026-09-02 23:36:54
---

## 需求

在阅读处理开源项目，特别是热门的项目时，经常会发现几十、几百，甚至在AI时代出现了几千个远端分支的情况。这篇文章就是探讨屏蔽这些内容的干扰的问题。

## 核心

* 只获取你想要的分支，其它分支一律忽略。
* 正确使用正则。

### 步骤

* 在你本地仓库的工作路径下，进入 git 配置编辑页面。建议在处理你的终端命令前，先修改 bashrc 或其它 shell rc 文件，使用 vim 作为编辑器（Linux、MacOS 默认是Nano）。

> #// ~/.bashrc
> export EDITOR=vim
> export VISUAL=vim

* 编辑仓库内的 .git/config 文件。
  * 两种方案：终端编辑；可视化文本工具直接编辑。

> git config -e # 终端编辑

* 编辑内容如下：

```toml
[remote "origin"]
        url = https://github.com/fake-organization-name/fake-repo-name
        fetch = +refs/heads/main:refs/remotes/origin/main
        fetch = +refs/heads/main:dev/remotes/origin/dev
        fetch = +refs/heads/main:release-*/remotes/origin/release-*
        fetch = -refs/heads/*:refs/remotes/origin/*
```

### 验证

再执行一遍 `git fetch --prune origin`，神奇的事情就此发生，一会几十几百个远端仓库分支就会从本地 .git 目录中移除。

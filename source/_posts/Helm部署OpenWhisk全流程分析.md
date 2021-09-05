title: Helm部署OpenWhisk全流程分析
author: Bill Zong
abbrlink: 605dd585
tags:
  - OpenWhisk
  - helm
  - deploy
categories:
  - Serverless
date: 2021-04-11 16:32:00
---
## 主流程

* 拷贝[incubator-openwhisk](https://github.com/apache/incubator-openwhisk)仓库
    * 删除默认的授权配置文件
* 执行`installRouteMgmt.sh`脚本
    * 进入目录`$OPENWHISK_HOME/ansible/roles/routemgmt/file`
* `installRouteMgmt.sh`脚本主要内容
    * 分别进入目录`$OPENWHISK_HOME/core/routemgmt/getApi`，`$OPENWHISK_HOME/core/routemgmt/createApi`，`$OPENWHISK_HOME/core/routemgmt/deleteApi`，执行`npm install`和`zip -r`任务。
    * 将打包好`zip`文件作为`Action`安装到`system`这个名称空间中。
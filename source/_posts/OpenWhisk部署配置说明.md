title: OpenWhisk部署配置说明
author: Bill Zong
abbrlink: b854b9de
tags:
  - OpenWhisk
  - deploy
categories:
  - Serverless
date: 2021-04-11 16:34:00
---
## 概述

本文主要描述当前OpenWhisk部署项目的代码修改、配置修改及生产环境下的配置说明。

### 版本说明

部署仓库[初始版本](https://github.com/apache/incubator-openwhisk-deploy-kube)。`master`分支，节点`89f1787ed58228063ae813ff85acfa9824ea045b`，缩减描述为`89f1787`。
其对应的[代码仓库](https://github.com/apache/incubator-openwhisk)，`master`分支，节点`5a2bf810dc5fda2f0d184c022e5931ac65de9721`，缩减描述为`5a2bf810`。

---

## 代码修改

* 将 Node.js runtime 的预热容器数量提升，以便后面进行性能测试。

```json
// helm/openwhisk/runtimes.json line 19-20
"count": 8,
"memory": "128 MB"
```

* 将 OpenWhisk 初始化 CouchDB 的超时时间延长，避免网络超时导致失败。

```yaml
// helm/openwhisk/templates/couchdb-init-job.yaml line 13
activeDeadlineSeconds: 6000 # 原值为 600
```

* 将 OpenWhisk 安装 package 的超时时间延长，避免网络超时导致失败。

```yaml
.. helm/openwhisk/templates/install-packages-job.yaml line 12
activeDeadlineSeconds: 9000 # 原值为 900
```

---

## 配置修改

这部分内容通过自测，可以直接使用在网聚和阿里云服务器上。

```yaml
# openwhisk 自定义部署配置文件，yaml格式
k8s:
  persistence:
    enabled: true # 必须持久化
    explicitStorageClass: nfs-storage # 使用已初始化完成的局域网nfs存储
    hasDefaultStorageClass: false # 不设置默认存储类
providers:
  alarm:
    enabled: false # 不做预警提示，生产环境需要修正
whisk:
  containerPool:
    userMemory: 2048m # 一般节点内存池在8G左右，所以预留2G给内存池没什么问题
  ingress:
    apiHostName: 47.106.26.103 # OpenWhisk API服务暴露的公网IP
  limits:
    actions:
      memory:
        min: 128m # 主要配合whisk.containerPool.userMemory，用于控制Invoker容器slots数量
        std: 384m # 主要是给人脸检测这种Docker Action使用，其计算内存存在波动
    actionsInvokesConcurrent: 999999 # 每个名称空间并发容器上限
    actionsInvokesPerminute: 999999 # 每个名称空间并发容器每分钟上限
    actionsSequenceMaxlength: 999999 # 每个名称空间容器队列最大长度
    triggersFiresPerminute: 999999 # 每个名称空间触发器每分钟触发上限
  loadbalancer:
    blackboxFraction: 90% # 多分配主要是考虑到后续集群业务主要集中在视频分析这类Docker Action上
```

---

## 生产环境配置

配置都在`helm/openwhisk/values.yaml`文件，可直接在外部提供文件覆盖这些配置。

### 备份数量

默认情况下，所有的 OpenWhisk 控制平面的微服务，其部署的备份数量都为 1。我们可以修改其冗余备份数量，即修改其`replicaCount`即可。

部分组件不支持这种配置设置。

* `apigateway`和`redis`。
    * 因为其不太可能成为瓶颈。
* `couchdb`
    * 建议使用外部`CouchDB`集群，提高其稳定性和性能。
* 事件提供者，如`alarmprovider`，`cloudantprovider`，`kafkaprovider`
    * 相对灵活，方便管理。
    * 的`providers`项。

---

## 参考文档

[configurationChoices](https://github.com/apache/incubator-openwhisk-deploy-kube/blob/master/docs/configurationChoices.md)
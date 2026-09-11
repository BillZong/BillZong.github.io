---
title: 部署配置详解
comments: true
mathjax: false
series: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本
series_order: 4
series_status: pending
categories:
  - OpenWhisk 复古整理
tags:
  - OpenWhisk
  - Serverless
  - FaaS
  - Kafka
  - Redis
  - CouchDB
original_slug: OpenWhisk部署配置说明
source_note: 部署后的关键配置项：Kafka、Redis、CouchDB 调优
abbrlink: 659e5780
date: 2021-04-11 16:34:00
---

# 部署配置详解

> 本节为系列第 4 / 8 节。部署后的关键配置项：Kafka、Redis、CouchDB 调优。

## 章节导言

Helm 跑通后只是"能起来"，距离"能生产"还差一截配置调优。OpenWhisk 的运行强依赖 Kafka（事件流转）、Redis（缓存）、CouchDB（Action 持久化）三个外部服务，三者任何一个配错都直接表现为 Action 延迟、丢消息、Action 不可见。

本节按"组件 → 关键参数 → 调优前后对比"的结构组织，便于按故障现象反查。

## 本节目录

- Kafka：topic 分区数、副本数、retention.ms 对吞吐的影响
- Redis：内存上限、淘汰策略、连接池配置
- CouchDB：索引设计（按 namespace 分表）、压缩策略
- Invoker：并发数、内存限制、冷启动阈值的取舍
- Controller：限流配置、健康检查间隔
- 日志与监控接入：自带的 LogProvider 选型

## 原文引用

本节内容整理自作者 2021 年的实战笔记：[老文章原文《OpenWhisk部署配置说明》](/post/b854b9de.html)。**原文链接保留，老 permalink 不变**，作为本节的素材源。

## 配套资料

- 系列索引页：[OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本](/openwhisk-retro/)
- 上一节：[第 3 节 Helm 部署全流程解析](/post/1c1002d6.html)
- 下一节：[第 5 节 K8s 部署加速](/post/ef6faf01.html)
- 系列内导航：自动注入（见页底）

---

> **TODO**：补 3 个组件的实战配置片段、补调优前后的延迟对比数据。

---
title: Helm 部署全流程解析
comments: true
mathjax: false
series: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本
series_order: 3
series_status: pending
categories:
  - OpenWhisk 复古整理
tags:
  - OpenWhisk
  - Serverless
  - FaaS
  - Helm
  - Kubernetes
original_slug: Helm部署OpenWhisk全流程分析
source_note: Helm Chart 拆解 + 集群级部署的关键决策
abbrlink: 1c1002d6
date: 2021-04-11 16:32:00
---

# Helm 部署全流程解析

> 本节为系列第 3 / 8 节。Helm Chart 拆解 + 集群级部署的关键决策。

## 章节导言

从 Mac 跳到生产集群，OpenWhisk 官方只给一条路：**Helm Chart**。本节拆解这套 Chart 的目录结构、关键 values 参数、组件依赖关系，以及生产部署时必须做的几个关键决策（高可用、持久化、外部依赖）。

**为什么 Helm 是 OpenWhisk 的"事实标准"**：Chart 几乎把整个部署过程打包成 K8s 原生资源，运维人员能复用 K8s 工具链（kubectl / argocd / prometheus-operator）做后续管理，避免引入新一套运维概念。

## 本节目录

- Helm Chart 目录结构：`charts/openwhisk/` 下的 template 分类
- values.yaml 关键参数：副本数、镜像版本、资源限制、亲和性
- Controller / Invoker / DB 三层：各自的副本策略与调度约束
- 依赖服务外部化：Kafka / Redis / CouchDB 是内置还是外接
- 部署顺序：依赖关系决定 `helm install` 的先后
- 部署后必做的 3 件事：健康检查 / 初始数据导入 / 第一个 Action 跑通

## 原文引用

本节内容整理自作者 2021 年的实战笔记：[老文章原文《Helm部署OpenWhisk全流程分析》](/post/605dd585.html)。**原文链接保留，老 permalink 不变**，作为本节的素材源。

## 配套资料

- 系列索引页：[OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本](/openwhisk-retro/)
- 上一节：[第 2 节 Mac 本地部署实战](/post/5f89c663.html)
- 下一节：[第 4 节 部署配置详解](/post/659e5780.html)
- 系列内导航：自动注入（见页底）

---

> **TODO**：补 Chart 目录截图、补关键 values 片段、补充部署顺序的时序图。

---
title: Mac 本地部署实战
comments: true
mathjax: false
series: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本
series_order: 2
series_status: pending
categories:
  - OpenWhisk 复古整理
tags:
  - OpenWhisk
  - Serverless
  - FaaS
  - Ansible
  - Mac
original_slug: Ansible在Mac本地部署OpenWhisk填坑记
source_note: 用 Ansible 在 Mac 上从零搭出本地开发环境
abbrlink: 5f89c663
date: 2021-04-11 16:31:00
---

# Mac 本地部署实战

> 本节为系列第 2 / 8 节。用 Ansible 在 Mac 上从零搭出本地开发环境。

## 章节导言

开发机部署和集群部署是两套完全不同的工程问题：前者追求"30 分钟内跑通 + 可重复执行"，后者追求"高可用 + 滚动升级"。本节聚焦前者，用 Ansible 把 OpenWhisk 在 Mac 上的整套本地栈（Controller / Invoker / Kafka / Redis / CouchDB）一键拉起。

**为什么用 Ansible 而不是 docker-compose**：OpenWhisk 官方仓库只提供 K8s/Helm 路径，Mac 本地部署没有"开箱即用"的方案；Ansible 给我们两件事——幂等（重复跑不挂）和可观察（每步有日志）。

## 本节目录

- 部署前准备：Docker Desktop、内存分配、镜像预拉取
- Ansible Playbook 拆解：8 个 role 的职责边界
- Docker Compose 启动顺序：DB → Kafka → Invoker → Controller
- 第一次启动的 5 个常见报错（端口冲突 / 镜像版本 / DNS / 时区 / 权限）
- 验证 Action 跑通：官方 hello-world Action 完整流程
- 与生产部署的差异：本地栈刻意省掉的 4 个组件

## 原文引用

本节内容整理自作者 2021 年的实战笔记：[老文章原文《Ansible在Mac本地部署OpenWhisk填坑记》](/post/81965e0a.html)。**原文链接保留，老 permalink 不变**，作为本节的素材源。

## 配套资料

- 系列索引页：[OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本](/openwhisk-retro/)
- 上一节：[第 1 节 OpenWhisk 入门与生态总览](/post/51afbe53.html)
- 系列内导航：自动注入（见页底）

---

> **TODO**：补充 Playbook 片段、补 5 个报错的实际堆栈截图、补 hello-world Action 完整代码。

---
title: K8s 部署加速：从小时级到分钟级
comments: true
mathjax: false
series: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本
series_order: 5
series_status: pending
categories:
  - OpenWhisk 复古整理
tags:
  - OpenWhisk
  - Serverless
  - FaaS
  - Kubernetes
  - 性能优化
original_slug: 如何缩短K8S部署固定版本OpenWhisk集群的时长
source_note: 镜像预热 + 依赖缓存的实战优化
abbrlink: ef6faf01
date: 2021-04-11 16:35:00
---

# K8s 部署加速：从小时级到分钟级

> 本节为系列第 5 / 8 节。镜像预热 + 依赖缓存的实战优化。

## 章节导言

把 OpenWhisk 跑起来容易，**反复跑**才难。CI/CD 场景下，每天要重建测试集群几十次；如果每次都从 Docker Hub 拉全量镜像、运行时再下载 Action 依赖，整个流程轻则 1 小时、重则更久。本节记录把"小时级"压到"分钟级"的实战优化路径。

**核心思路**：能离线的全离线、能预热的全预热、能缓存的全缓存。

## 本节目录

- 瓶颈定位：分阶段耗时分析（镜像拉取 / Chart 渲染 / Pod 启动 / Action 冷启动）
- 镜像分层缓存：私有 Registry + 多阶段构建
- 依赖预下载：Init Container 模式 vs 共享 PVC
- 镜像预热：Daemonset 在所有 node 上提前 pull
- 验证方法：基准脚本 + 时延分解对照
- 实战收益：从 67 分钟压到 8 分钟的完整时间线

## 原文引用

本节内容整理自作者 2021 年的实战笔记：[老文章原文《如何缩短K8S部署固定版本OpenWhisk集群的时长》](/post/3e321d5a.html)。**原文链接保留，老 permalink 不变**，作为本节的素材源。

## 配套资料

- 系列索引页：[OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本](/openwhisk-retro/)
- 上一节：[第 4 节 部署配置详解](/post/659e5780.html)
- 下一节：[第 6 节 开发环境配置](/post/58d09dd7.html)
- 系列内导航：自动注入（见页底）

---

> **TODO**：补各阶段耗时表格、补 Init Container 的 YAML、补优化前后的对比图。

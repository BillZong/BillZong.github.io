---
title: 开发环境配置
comments: true
mathjax: false
series: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本
series_order: 6
series_status: pending
categories:
  - OpenWhisk 复古整理
tags:
  - OpenWhisk
  - Serverless
  - FaaS
  - CLI
  - 开发工具
original_slug: OpenWhisk开发环境配置说明
source_note: 从 CLI 到本地 Action 调试的完整链路
abbrlink: 58d09dd7
date: 2021-04-11 16:33:00
---

# 开发环境配置

> 本节为系列第 6 / 8 节。从 CLI 到本地 Action 调试的完整链路。

## 章节导言

部署完集群只是"基础设施 ready"，开发者真正要面对的是"怎么写 Action、怎么调试、怎么在本地快速验证"。本节聚焦开发者侧的配置——wsk CLI、Action 打包、依赖管理、与 IDE 集成。

**关键认知**：OpenWhisk 的 Action 是 zip 包 + 运行时约定，调试体验和 Lambda 一样属于"半黑盒"。把本地调试的反馈循环压到秒级是本节目标。

## 本节目录

- wsk CLI 安装与认证：api host / auth key 配置
- Action 编写：单文件、zip 包、Docker 三种模式选型
- 依赖打包：npm/pip 项目如何打进 Action zip
- 本地 invoke 调试：参数传递、结果查看、激活日志
- 与 IDE 集成：VSCode 任务配置 + wsk 输出查看
- 常见开发痛点：超时、内存限制、依赖过大

## 原文引用

本节内容整理自作者 2021 年的实战笔记：[老文章原文《OpenWhisk开发环境配置说明》](/post/73ccc9b4.html)。**原文链接保留，老 permalink 不变**，作为本节的素材源。

## 配套资料

- 系列索引页：[OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本](/openwhisk-retro/)
- 上一节：[第 5 节 K8s 部署加速](/post/ef6faf01.html)
- 下一节：[第 7 节 监控指标体系](/post/4e670e66.html)
- 系列内导航：自动注入（见页底）

---

> **TODO**：补 VSCode 任务配置 JSON、补 Action zip 打包脚本、补调试流程截图。

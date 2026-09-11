---
title: 性能基准：阿里云 vs 腾讯云
comments: true
mathjax: false
series: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本
series_order: 8
series_status: pending
categories:
  - OpenWhisk 复古整理
tags:
  - OpenWhisk
  - Serverless
  - FaaS
  - 性能测试
  - 阿里云
  - 腾讯云
original_slug: 阿里云腾讯云OpenWhisk性能测试方案
source_note: 同代码基线下的双云性能对比
abbrlink: 85d1e09b
date: 2021-04-11 16:38:00
---

# 性能基准：阿里云 vs 腾讯云

> 本节为系列第 8 / 8 节。同代码基线下的双云性能对比。

## 章节导言

作为系列收尾，本节用一份**同代码基线的双云对比**，回答一个最朴素的问题：在阿里云函数计算和腾讯云 SCF 上跑同一份 OpenWhisk 兼容代码，谁更快、更便宜？

**注意时效**：本节数据来自 2021 年 4 月，**两家云的产品形态在 2026 年已大幅变化**。结论的"对比方法论"仍有参考价值，绝对数字请按当下产品文档重新校准。

## 本节目录

- 测试方法论：3 个负载场景 × 2 个云厂商 × 3 个区域
- 冷启动延迟：JavaScript / Python / Java 三种 runtime 对比
- 吞吐：并发 100 / 1000 下的 QPS 极限
- 成本：相同调用量下的账单差异
- 选型建议：什么场景选哪家
- 时效性说明：5 年后再看这份数据的局限性

## 原文引用

本节内容整理自作者 2021 年的实战笔记：[老文章原文《阿里云腾讯云OpenWhisk性能测试方案》](/post/d13f2d70.html)。**原文链接保留，老 permalink 不变**，作为本节的素材源。

## 配套资料

- 系列索引页：[OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本](/openwhisk-retro/)
- 上一节：[第 7 节 监控指标体系](/post/4e670e66.html)
- 系列内导航：自动注入（见页底）

---

> **TODO**：补 3 个负载场景的测试脚本、补冷启动延迟对比图、补充 2026 年的成本对比说明（如果还能找到数据）。

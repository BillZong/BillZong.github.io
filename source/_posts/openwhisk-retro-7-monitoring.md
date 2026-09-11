---
title: 监控指标体系
comments: true
mathjax: false
series: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本
series_order: 7
series_status: pending
categories:
  - OpenWhisk 复古整理
tags:
  - OpenWhisk
  - Serverless
  - FaaS
  - 监控
  - Prometheus
  - Grafana
original_slug: OpenWhisk当前监控指标详细说明
source_note: OpenWhisk 自带指标 + Prometheus 接入
abbrlink: 4e670e66
date: 2021-04-09 23:30:00
---

# 监控指标体系

> 本节为系列第 7 / 8 节。OpenWhisk 自带指标 + Prometheus 接入。

## 章节导言

生产化必备的一环是"能看见系统在做什么"。OpenWhisk 自带一个相对完整的指标体系：Controller、Invoker、各 DB 组件都暴露 Prometheus 格式的端点。本节梳理：(1) 哪些指标最关键；(2) 怎么接到 Prometheus；(3) Grafana 看板怎么设计。

**核心问题**：FaaS 平台的"调用"是一次性的异步事件，传统的主机 CPU/内存指标意义有限；**真正关键的是激活延迟、并发、错误率、限流触发**等业务级指标。

## 本节目录

- OpenWhisk 内置指标全景：4 类指标（Controller / Invoker / Kafka / 自定义）
- 关键指标解读：activation latency、cold start、memory usage
- Prometheus 抓取配置：ServiceMonitor + endpoints
- Grafana 看板设计：4 张分图（延迟 / 吞吐 / 错误 / 资源）
- 告警规则建议：哪些阈值值得在生产设告警
- 与老一代 zabbix 方案的对比：Prometheus 体系的优劣

## 原文引用

本节内容整理自作者 2021 年的实战笔记：[老文章原文《OpenWhisk当前监控指标详细说明》](/post/b265443c.html)。**原文链接保留，老 permalink 不变**，作为本节的素材源。

## 配套资料

- 系列索引页：[OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本](/openwhisk-retro/)
- 上一节：[第 6 节 开发环境配置](/post/58d09dd7.html)
- 下一节：[第 8 节 性能基准：阿里云 vs 腾讯云](/post/85d1e09b.html)
- 系列内导航：自动注入（见页底）

---

> **TODO**：补 Prometheus 抓取配置 YAML、补 4 张 Grafana 看板截图、补告警规则 PromQL。

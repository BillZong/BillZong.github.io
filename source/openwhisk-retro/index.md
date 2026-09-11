---
title: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本
date: 2026-09-10 15:50:00
comments: true
type: page
layout: page
description: 8 篇系列文章索引页，从 2021 年实战笔记回看 Serverless 平台架构演进
---

# OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本

> **系列背景**：本系列基于 2021 年 4 月对 Apache OpenWhisk（IBM Cloud Functions 原型）的 8 篇实战笔记重新整理。OpenWhisk 本身在 2023 年由 IBM 移交 Adobe、改名 Adobe I/O Runtime，已淡出主流视野，但**作为一个完整 FaaS 平台的设计样本**，其部署/开发/监控/性能四维度的实战数据仍有参考价值。本系列按"从入门到生产"的递进逻辑重排，**保留原文链接**以备查阅。

## 系列目录

> 注：链接使用绝对 permalink（基于 hexo-abbrlink），不再因文件改名而失效。

1. ⏳ pending — [OpenWhisk 入门与生态总览](/post/51afbe53.html) · 入门/概览
2. ⏳ pending — [Mac 本地部署实战](/post/5f89c663.html) · 部署
3. ⏳ pending — [Helm 部署全流程解析](/post/1c1002d6.html) · 部署
4. ⏳ pending — [部署配置详解](/post/659e5780.html) · 部署
5. ⏳ pending — [K8s 部署加速：从小时级到分钟级](/post/ef6faf01.html) · 部署优化
6. ⏳ pending — [开发环境配置](/post/58d09dd7.html) · 开发
7. ⏳ pending — [监控指标体系](/post/4e670e66.html) · 运维
8. ⏳ pending — [性能基准：阿里云 vs 腾讯云](/post/85d1e09b.html) · 性能

## 主题递进逻辑

本系列按"**从入门到生产化**"的顺序组织，8 节形成一条连贯的能力链：

```
入门概览(1) → 本地部署(2) → 集群部署(3,4) → 部署优化(5) → 开发链路(6) → 生产运维(7,8)
```

- **第 1 节**是全系列锚点，回答"OpenWhisk 是什么 / 为什么值得研究"
- **第 2-5 节**聚焦**部署链**：从开发机到生产集群的全流程
- **第 6 节**切换视角到**开发体验**
- **第 7-8 节**是**生产化关键**：监控可见性 + 性能基线

## 元数据约定

每篇新文章 front-matter 必须包含：

- `series: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本` —— 全系列 8 篇保持一致
- `series_order: N` —— 1~8 的整数
- `series_status: pending | drafting | published` —— 写作状态
- `categories: [OpenWhisk 复古整理]` —— 一级分类，自动归档
- `original_slug:` —— 对应老文章的源文件名（不含 .md），用于交叉链接
- `source_note:` —— ≤60 字说明本节角色

## 配套脚本

- `scripts/series-nav.js` —— 文章底部自动注入"系列内导航"（无需手动维护）
- `scripts/migrate-openwhisk.js` —— 给 8 篇老文章追加迁移声明段落

## 写作流程

```bash
# 1. 用本系列专用模板建文章
hexo new openwhisk-retro "第 N 节：xxx"

# 2. 编辑生成的文件，填正文 + series_order + original_slug

# 3. 同步本索引页对应行的链接和状态

# 4. 写完改 series_status: published，本页状态改为 ✅
```

## 相关归档

- 分类归档：[OpenWhisk 复古整理](/categories/openwhisk-复古整理/)
- 老原文：每篇新文章底部"原文"段保留源链接，老 permalink 不变
- 全文订阅：[RSS](/rss2.xml) / [Atom](/atom.xml)

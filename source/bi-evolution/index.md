---
title: BI 系统的发展进程：数据建模、计算引擎与语义交互的架构演进
date: 2026-09-11 12:22:00
comments: true
type: page
layout: page
description: 系列索引页 · 引言 + 6 篇正文 + 结论 = 8 个章节
---

# BI 系统的发展进程：数据建模、计算引擎与语义交互的架构演进

> **本系列结构**：1 篇引言章前置 + 6 篇正文 + 1 篇结论，共 8 个章节。围绕"数据建模、计算引擎与语义交互"三条主线，回看 BI 系统过去三十年的抽象层上移过程。

## 系列目录

| # | 标题 | 状态 |
|---|------|------|
| 1 | 引言章前置：系统架构的四层抽象与解耦总纲 | ⏳ pending |
| 2 | 第一篇：企业数据仓库与经典 OLAP 时代（集中式语义的奠基） | ✅ published |
| 3 | 第二篇：分布式计算与云原生数仓时代（计算与存储的解耦） | ✅ published |
| 4 | 第三篇：现代数据栈与语义层（Semantic Layer）的重新崛起 | ⏳ pending |
| 5 | 第四篇：大模型重构时代（确定性语义层与概率模型的融合） | ⏳ pending |
| 6 | 第五篇：业务对象图时代（从 System of Insight 到 System of Action） | ⏳ pending |
| 7 | 第六篇：下一阶段演进：AI-Native 现代分析系统的底层重构 | ⏳ pending |
| 8 | 结论：BI 真正演进的不是 UI，而是抽象层 | ⏳ pending |

> 永久链接将在每篇发布后填入。

## 主题递进逻辑

全系列按"抽象层上移"主线组织：

```
1. 引言       建立四层架构模型 (Data Platform / Query Engine / Semantic / Interaction)
2. EDW 时代   数据源/平台层 + 查询计算层起步，语义层被硬编码在 Cube
3. 分布式     查询计算层突破单机死局，存算分离
4. 语义层     语义层独立化、服务化 (Headless BI)
5. 大模型     交互层从 Dashboard → NL → Semantic IR
6. 业务对象   语义层向 Ontology 跨越，开启 System of Action
7. AI-Native  治理面 + MCP + 模型路由 + TEE 的工程化整合
8. 结论       抽象层上移的总结与展望
```

## 元数据约定

每篇 front-matter 必须包含：

- `series: BI系统的发展进程：数据建模、计算引擎与语义交互的架构演进` —— 8 篇保持一致
- `series_order: N` —— 1~8
- `series_status: pending | drafting | published`
- `categories: [bi-evolution]` —— 一级分类，自动归档

## 配套脚本

- `scripts/series-nav.js` —— 文章底部自动注入"系列内导航"（length < 2 不显示）
- 脚注渲染：当前用 `hexo-renderer-marked`，**不支持** Pandoc 风格 `[^N]`，需要装插件（待定）

## 写作流程

```bash
hexo new post "第 X 部分：xxx"        # 标准模板
# 手动复制 scaffolds/bi-evolution.md 的 front-matter 字段
# 填 series / series_order / source_note / categories
```

## 相关归档

- 分类归档：[BI 系统的发展进程](/categories/bi-evolution/)（自动生成）
- 全文订阅：[RSS](/rss2.xml) / [Atom](/atom.xml)

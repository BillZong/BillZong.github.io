---
title: BI 系统的发展进程：数据建模、计算引擎与语义交互的架构演进
date: 2026-09-09 12:42:00
comments: true
type: page
layout: page
description: 8 篇系列文章索引页
---

# BI 系统的发展进程：数据建模、计算引擎与语义交互的架构演进

> 本系列共 8 篇文章，按发布顺序排列。点击进入对应章节。

| # | 标题 | 状态 | 发布时间 |
|---|------|------|----------|
| 1 | _待补充：第 1 部分标题_ | ⏳ pending | — |
| 2 | _待补充：第 2 部分标题_ | ⏳ pending | — |
| 3 | _待补充：第 3 部分标题_ | ⏳ pending | — |
| 4 | _待补充：第 4 部分标题_ | ⏳ pending | — |
| 5 | _待补充：第 5 部分标题_ | ⏳ pending | — |
| 6 | _待补充：第 6 部分标题_ | ⏳ pending | — |
| 7 | _待补充：第 7 部分标题_ | ⏳ pending | — |
| 8 | _待补充：第 8 部分标题_ | ⏳ pending | — |

## 系列元数据约定

每篇文章的 front-matter 需要包含以下字段，便于后续自动化处理（聚合、统计、归档）：

- `series: BI 系统的发展进程` — 系列名，全系列 8 篇保持一致
- `series_order: N` — 系列内序号（1~8）
- `series_status: pending | drafting | published` — 写作状态
- `categories: [BI 系统的发展进程]` — 用作一级分类，自动生成归档页 `/categories/bi-系统的发展进程/`
- `abbrlink:` — 稳定链接（hexo-abbrlink 自动生成，**不要手动指定**，避免重命名后链断）

## 写作流程

```bash
# 1. 用系列专用模板新建文章
hexo new bi-evolution "第 N 部分：xxx"

# 2. 编辑 source/_posts/ 下生成的文件，填写 series_order 和正文

# 3. 同步更新本索引页（source/bi-evolution/index.md）的对应行

# 4. 完成后把 series_status 改为 published，本页状态改为 ✅
```

## 相关归档

- 按分类归档：[BI 系统的发展进程](/categories/bi-系统的发展进程/)
- 按标签归档：待 tags 确定后补链接
- 全文订阅：[RSS](/rss2.xml) / [Atom](/atom.xml)

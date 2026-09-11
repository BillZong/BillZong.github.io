---
title: OpenWhisk 入门与生态总览
comments: true
mathjax: false
series: OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本
series_order: 1
series_status: drafting
categories:
  - OpenWhisk 复古整理
tags:
  - OpenWhisk
  - Serverless
  - FaaS
original_slug: 搭建OpenWhisk
source_note: 系列锚点：建立对 OpenWhisk 架构与生态的全景认知
abbrlink: 51afbe53
date: 2021-04-11 16:36:00
---

# OpenWhisk 入门与生态总览

> 本节为系列第 1 / 8 节。系列锚点：建立对 OpenWhisk 架构与生态的全景认知。

## 章节导言

Apache OpenWhisk 起源于 IBM 2016 年开源的事件驱动 FaaS 平台，是 AWS Lambda 之外**第二早成熟的开源 Serverless 方案**。与 Lambda 走"托管即唯一入口"路线不同，OpenWhisk 选择"完全自托管 + 深度可定制"，因此成为企业内部落地 Serverless 的主流候选。

本节作为系列开篇，先建立三件事：(1) 清楚 OpenWhisk 的核心编程模型（Action / Trigger / Rule / Package）；(2) 理解它与 Lambda/Knative 的设计差异；(3) 形成对后续 7 节"部署 → 开发 → 运维"递进逻辑的整体地图。

## 1. OpenWhisk 起源：从 IBM Bluemix 到 Apache 顶级项目

OpenWhisk 的代码最早可追溯到 2014 年 IBM 内部代号 "BlueWhisk" 的 Serverless 实验项目。2016 年 2 月，IBM 把它以 Apache 2.0 协议开源，命名 **OpenWhisk**；同年 12 月进入 Apache 孵化器，2017 年 10 月毕业成为 Apache 顶级项目（TLP）。

与同期开源方案相比，OpenWhisk 的两个差异点决定了它的产品定位：

- **一开始就面向"多语言 + 多触发源"**：原生支持 Node.js / Python / Java / Go / Swift / .NET / Ruby / PHP 8+ 种 runtime，且把 Kafka、CouchDB、Cloudant、Slack、GitHub 等几十种事件源做成一等公民的 "Package" 抽象。这与 Lambda 当年只支持 4 种 runtime 形成强烈对比。
- **从 Day 1 就强调自托管**：IBM 的策略是"把 OpenWhisk 当成一个**完整平台**开源，让任何人都能跑出与 IBM Cloud Functions 同源的运行时"，而不是开源一个"轻量 SDK 让你接到我们托管平台"。这个定位直接影响后续 Apache 社区的演进方向。

## 2. 核心架构：Controller / Invoker / CouchDB / Kafka 四大组件

OpenWhisk 的运行时由四个独立可扩展的组件构成，每个都有清晰职责：

| 组件 | 角色 | 关键资源 |
|---|---|---|
| **Controller** | API 网关 + 调度中心，接收所有 REST 请求、鉴权、写入 activation 记录、分配 Invoker | 无状态，可水平扩 |
| **Invoker** | 真正执行 Action 的容器池（基于 Docker），跑用户的代码 | 无状态，按 Action 隔离 |
| **CouchDB** | Action 定义、activation 历史、命名空间等元数据存储 | 单点依赖，但可换 Cloudant |
| **Kafka** | Controller → Invoker、Trigger 事件流转的异步消息总线 | 强依赖，所有事件流都走它 |

四个组件之间通过 REST + Kafka 协作：**Controller 收到 API 请求后，把"要执行哪个 Action" 写到 Kafka；Invoker 消费 Kafka，拉起 Docker 容器跑 Action，结果回写 CouchDB**。这种"Controller 只管调度、Invoker 只管执行"的解耦让两端都能独立扩容。

## 3. 编程模型：Action / Trigger / Rule / Package 关系图

OpenWhisk 的编程模型由 4 个核心概念组成，**事件驱动是底层哲学**：

- **Action**：一段可调用的函数代码。可以是 inline 文本、zip 包、或者 Docker 镜像。
- **Trigger**：一类事件源（如 Kafka topic 消息、GitHub push、定时器）。事件到达 Trigger 不会自动触发任何东西——它只是一个"事件通道"。
- **Rule**：把 Trigger 绑定到 Action 的关联规则。一个 Trigger 可以挂多个 Rule，一个 Rule 只能对应一个 Action。这是"事件 → 函数"的真正连接点。
- **Package**：一组 Action + 共享配置 + 外部服务凭证的集合。比如 `github` Package 包含 `webhook` Action + 访问 GitHub API 所需的 token 配置。

**典型流程**：外部事件源 → Trigger → Rule → Action → CouchDB 记录 activation。整套模型完全声明式，所有元素都通过 `wsk` CLI 或 REST API 创建、查询、删除。

## 4. 与 Lambda / Knative 的关键差异

把 OpenWhisk 和同期两个主流方案横向对比，能看清它的取舍：

| 维度 | OpenWhisk | AWS Lambda | Knative Serving |
|---|---|---|---|
| **部署模型** | 完全自托管（Helm / Ansible） | 黑盒托管 | 基于 K8s CRD |
| **事件源丰富度** | 几十种内置 Package | EventBridge / 第三方 | 依赖 K8s Eventing 生态 |
| **多语言** | 8+ runtime 原生 | 15+ runtime | 任意容器 |
| **冷启动** | 数百毫秒（Invoker 池预热） | 几十到数百毫秒 | 可配置（0 到秒级） |
| **可观测性** | 自带 activation 日志 + Prometheus | CloudWatch | K8s 原生（Prometheus + Jaeger） |
| **生态活跃度** | 2021 后下降 | 极活跃 | 活跃（K8s 周边） |

**核心取舍**：OpenWhisk 押注"完全自托管 + 事件源丰富"——企业内部落地能避开厂商锁定，但运维负担比 Lambda 高一个量级；Knative 走"K8s 原生"路线，运维融入 K8s 工具链，但事件能力依赖周边生态。Lambda 不参与"自托管"赛道。

## 5. 兴衰时间线：2023 IBM 移交 Adobe

OpenWhisk 的兴衰是一段典型的"开源项目与企业战略同进退"故事：

- **2014-2017（黄金期）**：IBM 全力投入，OpenWhisk 是 Bluemix（后改名 IBM Cloud）的核心 Serverless 产品
- **2018-2020（分化期）**：IBM 把 OpenWhisk 改名 "IBM Cloud Functions"，云产品持续运营，但 Apache 社区贡献者增长放缓
- **2020-2022（被超越期）**：Knative、OpenFaaS 等 K8s 原生方案崛起，OpenWhisk 在云原生生态的声量被稀释
- **2023（移交期）**：IBM 决定退出 Cloud Functions 业务，**把 OpenWhisk 的商标和代码维护权移交给 Adobe**，Apache 项目继续存在但转为"维护模式"
- **2024 至今（转生期）**：OpenWhisk 在 Adobe 内部继续作为 **Adobe I/O Runtime** 跑（面向 Adobe API 生态），Apache 仓库偶有 issue 但无大动作

**对企业选型的启示**：技术选型除了看"现在能不能跑"，还要看"3-5 年后会不会有人接盘"。OpenWhisk 的兴衰是最直观的样本。

## 6. 系列后续地图

本系列后续 7 节按"部署 → 开发 → 运维"三段递进：

- **第 2 节 Mac 本地部署实战**：Ansible 把整套栈在 Mac 上拉起来
- **第 3 节 Helm 部署全流程解析**：生产集群的 Chart 拆解
- **第 4 节 部署配置详解**：Kafka / Redis / CouchDB 调优
- **第 5 节 K8s 部署加速**：把 1 小时压到 10 分钟的实战优化
- **第 6 节 开发环境配置**：wsk CLI 到本地调试完整链路
- **第 7 节 监控指标体系**：自带指标 + Prometheus 接入
- **第 8 节 性能基准：阿里云 vs 腾讯云**：同代码基线下的双云对比（数据来自 2021，方法论仍可参考）

## 原文引用

本节内容整理自作者 2021 年的实战笔记：[老文章原文《搭建OpenWhisk》](/post/d6ffd7c3.html)。**原文链接保留，老 permalink 不变**，作为本节的素材源。

## 配套资料

- 系列索引页：[OpenWhisk 复古整理：一个 Serverless 平台的兴衰样本](/openwhisk-retro/)
- 下一节：[第 2 节 Mac 本地部署实战](/post/5f89c663.html)
- 系列内导航：自动注入（见页底）

---

> **TODO（待你补充）**：
> 1. **第 1 节起源**：补 1-2 张 IBM 2016 公告截图 / 邮件列表存档链接
> 2. **第 2 节核心架构**：补 4 组件拓扑图（建议方向：Controller 居中，Invoker / CouchDB / Kafka 在外围，REST/Kafka 标箭头）
> 3. **第 4 节对比**：补你自己用 Lambda / Knative 时的体感差异（这部分是基于公开资料的客观对比，没你的主观经验）
> 4. **第 5 节兴衰时间线**：你 2021 年选型 OpenWhisk 的背景、当时为什么没选 Knative / Lambda——这部分是"个人选型叙事"，是系列最有价值的部分

title: CNCF组织架构及准入说明
comments: true
abbrlink: 888b8b30
categories:
  - 开源组织
tags:
  - opensource
  - CNCF
date: 2021-04-08 00:10:00
---
## 组织介绍

### 背景

* CNCF，全称Cloud Native Computing Foundation（云原生计算基金会），成立于 2015 年7月21日
* 最初的口号是坚持和整合开源技术来让编排容器作为微服务架构的一部分。
* 致力于云原生应用推广和普及的一支重要力量。

### Cloud Native 全景图

![landscape-cncf.png](/images/pasted-0.png)

### CNCF的使命

* 容器化包装。
* 通过中心编排系统的动态资源管理。
* 面向微服务。

### CNCF组织组成部分

* 会员
    * 白金、金牌、银牌、最终用户、学术和非赢利成员
    * 不同级别的会员在治理委员会中的投票权不同。
* 理事会
    * 负责事务管理
* TOC（技术监督委员会）
    * 技术管理
        * 定义和维护技术视野
        * 审批新项目加入组织，为项目设定概念架构
        * 接受最终用户的反馈并映射到项目中
        * 调整组件间的访问接口，协调组件之间兼容性
* 最终用户社区
    * 推动CNCF技术的采纳并选举最终用户技术咨询委员会
* 最终用户技术咨询委员会
    * 为最终用户会议或向理事会提供咨询
* 营销委员会
    * 市场推广

## 如何提交CNCF项目

### 项目提交流程

* 在TOC项目中提交个[issue](https://github.com/cncf/toc/issues)
* TOC可能会要求 CNCF Sigs 以切入该项目。
* 项目方必须在 TOC 会议上展示其加入CNCF的提议。
* 项目提议通过了超过 2/3 TOC 成员的投票。

### 项目提议需求

* 必须提交到Github。

以下项目为尽可能完成项：

* CNCF内项目名称唯一。
* 项目介绍。
* 与CNCF Charpter使命一致的声明。
* TOC导师。
* 更成熟的项目级别。
* 软件许可证。
* 代码管理。
* 外部依赖声明。
* 初始提交者。
* 基础设施要求。
    * CI 或 CNCF 集群。
* 沟通渠道。
    * slack，irc，邮件列表等
* 问题跟进渠道。
    * 默认为GitHub。
* 网页。
    * 将当前版本网页内容迁移到 project.cncf.io。
* 版本Release技术方法论。
* 媒体公布账户。
* 社区规模及赞助方名单。
* 项目使用用户及使用规模。
* 项目Logo（SVG格式）。

### 项目原则

* 追求项目高进展速度。
* 开放。
    * 项目全开源，且尊重社区价值观。
* 公正。
    * 避免“付费玩家”决策。
* 强技术身份。
    * 基金会将获得并保持在项目中共享的高度的技术认同。
* 清晰的边界。
    * 明确的项目目标。
* 可伸缩性。
    * 项目必须支持各种伸缩尺度的部署。
* 平台普适性。
    * 各种体系和操作平台均可运行。

### 项目成熟度分级

* sandbox（初级）
* incubating（孵化中）
* graduated（毕业）

### 项目毕业条件

是否可以成为CNCF项目需要通过Technical Oversight Committee (技术监督委员会）简称TOC，投票采取fallback策略，即回退策略，先从最高级别（graduated）开始，如果2/3多数投票通过的话则确认为该级别，如果没通过的话，则进行下一低级别的投票，如果一直到inception级别都没得到2/3多数投票通过的话，则拒绝其进入CNCF项目。

![15784095112292.jpg](/images/pasted-1.png)

## 参考资料

* [CNCF Cloud Native Interactive Landscape](https://landscape.cncf.io/)
* [Cloud Native Computing Foundation (“CNCF”) Charter](https://github.com/cncf/foundation/blob/master/charter.md)
* [CNCF - 云原生计算基金会简介](https://jimmysong.io/kubernetes-handbook/cloud-native/cncf.html)
* [CNCF Technical Oversight Committee (TOC)](https://github.com/cncf/toc)
* [Contributing to the TOC](https://github.com/cncf/toc/blob/master/CONTRIBUTING.md)
* [CNCF Project Proposal Process v1.2](https://github.com/cncf/toc/blob/master/process/project_proposals.adoc)
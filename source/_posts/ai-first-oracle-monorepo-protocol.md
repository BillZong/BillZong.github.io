---
title: AI 开发者协议 (AI-First Oracle Monorepo Protocol)
tags:
  - AI
  - 预言机
  - Oracle
  - UMA
  - Chainlink
  - Agent
  - 协议
categories:
  - 区块链
abbrlink: 30f5e2fa
date: 2026-04-16 14:14:00
---

## 🎯 核心目标 (Context & Purpose)

本仓库旨在构建高可用、防篡改的事件预言机系统，集成 **UMA v3（乐观/争议机制）** 与 **Chainlink（确定性/推送机制）**。

作为 AI Agent，你的首要目标是：**保持合约接口的绝对严谨，后端服务的并发安全（Golang），以及 100% 的关键状态测试覆盖率。**

## 🚦 强制执行法则 (Hard Operating Directives)

1. **测试驱动 (TDD First):** 在编写或修改任何 `contracts/` 或 `backend/` 逻辑前，**必须**先编写/更新对应的单元测试或 Fork 测试。
2. **拒绝盲目假设:** 如果跨模块接口 `packages/` 或 `contracts/interfaces/`) 发生改变，必须先更新 `docs/` 和接口定义，请求人类确认后，再进行实现。
3. **收敛技术栈:** 后端与 Indexer 逻辑默认使用 Golang，合约使用 Solidity (Foundry)。严禁引入任何未经许可的第三方框架或运行时。
4. **上下文组装:** 在编辑核心模块前，使用工具读取对应的 `docs/architecture/` 和上游接口文件。不要基于历史训练数据猜测内部业务逻辑。

## 🛡️ 预言机特定安全基线 (Oracle Security Baseline)

*无论任务是什么，涉及相关逻辑时必须默认遵守：*

- **UMA v3 适配:** 必须处理 `assertionId` 生命周期，强制实现并验证 `dispute`（争议）和 `settle`（结算）的回调与延迟逻辑。
- **Chainlink 适配:** 必须检查 `answeredInRound`，处理 stale data（陈旧数据），并具备在 Chainlink 节点宕机时的 fallback（降级）或熔断机制。
- **重入与并发:** - 合约层面：所有涉及外部调用的状态修改必须使用 `ReentrancyGuard` 并遵循 CEI (Checks-Effects-Interactions) 模式。
  - 后端层面 (Golang)：所有并发 worker 必须通过 context 管理取消信号，避免 Goroutine 泄漏；操作数据库或缓存必须考虑分布式锁或原子操作。
- **机密管理:** 绝对禁止在代码、测试脚手架或 CI 配置中硬编码私钥、RPC URL 或 API Token。使用环境变量注入。

## 🏗️ 架构与模块职责 (Architecture & Module Contracts)

- `docs/`: 架构决议 (ADR)、协议规范和 Runbooks。（**修改代码前，优先检索此目录**）
- `contracts/`:
  - 核心要求：将 UMA 和 Chainlink 封装在统一的 `IOracleAdapter` 接口下。
  - 测试要求：必须包含针对主网状态的 Foundry Fork 测试。
- `backend/`: 预言机链下服务（监听器、数据聚合、喂价 Worker）。要求高并发、防抖和重试机制设计。
- `packages/`: 前后端与合约共享的类型定义 (Types) 和 ABI 生成文件。
- `scripts/ops/`: 自动化部署与监控告警（Grafana/Prometheus 配置）。

## 📝 提交与文档规范 (Output Expectations)

- **PR/Commit 结构:** 每次输出代码时，必须简明扼要地解释“为什么”做这个改动，而不是仅仅描述代码本身。文档应以中文编写，代码注释、Commit Message 和 CLI 输出保持英文。
- **Bootstrap 检查:** 引入新功能时，必须自动核对并更新 `docs/PRD.md` 和对应的 `interfaces`。

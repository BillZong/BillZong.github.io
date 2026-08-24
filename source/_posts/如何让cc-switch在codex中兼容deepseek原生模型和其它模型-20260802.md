---
title: 如何让 cc-switch 在 Codex 中兼容 DeepSeek 原生模型和其它模型
tags:
  - cc-switch
  - Codex
  - DeepSeek
  - AI
  - CLI
categories:
  - AI
abbrlink: 2a4db7bf
date: 2026-08-02 12:00:00
---

## 如何让cc-switch在codex中兼容deepseek原生模型和其它模型

### 原理

要实现“既保留 DeepSeek 官方最佳模型实践（Tool Calls 格式、推理档位、Context Window、System Prompt 等），又能通过 `cc-switch` 无缝无感切换多源（官方直连/第三方中转）”**，核心在于**将能力定义（模型层）与路由鉴权（供应商层）进行解耦。

这个思路最低适配版本为： `codex-cli 0.144.0`。

### 一、 核心解耦架构

Codex 的配置由两个文件共同作用：

1. **`~/.codex/models.json`（能力定义层 - 静态保留）**
   - **作用**：向 Codex 声明 `deepseek-v4-flash` 的元数据（1M 上下文、`apply_patch` 补丁工具格式、`instructions_template`、`supported_reasoning_levels` 推理深度等）。
   - **策略**：**保持一次性写入后不动**。无论 `cc-switch` 怎么切换源，只要 `slug` 叫 `deepseek-v4-flash`，Codex 就能自动应用 DeepSeek 最佳实践。
2. **`~/.codex/config.toml`（路由与鉴权层 - 动态切换）**
   - **作用**：控制当前激活的 `model`，以及对应 Provider 的 `base_url` 和 `api_key`。
   - **策略**：**交由 `cc-switch` 全权托管**。

### 二、 具体配置步骤

#### 1. 静态注入 DeepSeek 官方模型元数据

先运行一次官方脚本（或手动创建）生成 `~/.codex/models.json`，确保 Codex 拿到官方模型定义：

Bash

```
# 执行官方初始化脚本（仅用于生成/更新 models.json）
bash <(curl -fsSL https://cdn.deepseek.com/api-docs/codex-deepseek-setup.sh)
```

> **注意**：脚本会在 `~/.codex/models.json` 中写入 `slug: "deepseek-v4-flash"` 及配套的工具调用与 Agent 提示词配置。只要此文件存在，Codex 内部就能识别该模型的最佳生态行为。

#### 2. 在 `cc-switch` 中配置 DeepSeek 源与中转源

打开 `cc-switch` (v3.19.1+)，添加或修改 Codex 相关的源配置（Profile）。

##### 方案 A：DeepSeek 官方源配置

- **Provider/Key**: `deepseek`
- **Base URL**: `[https://api.deepseek.com/v1](https://api.deepseek.com/v1)` (或 `[https://api.deepseek.com](https://api.deepseek.com)`)
- **Default Model**: `deepseek-v4-flash`
- **API Key**: `sk-xxx`

##### 方案 B：第三方/中转代理源配置

若要切换到第三方中转源，在 `cc-switch` 添加新节点：

- **Base URL**: `[https://your-proxy-domain.com/v1](https://your-proxy-domain.com/v1)`
- **Default Model**: `deepseek-v4-flash` *(关键：Model 必须映射/保持为 `deepseek-v4-flash`)*
- **API Key**: `sk-your-proxy-key`

### 三、 最终切换效果与生效机制

当你通过 `cc-switch` 切换源时，`cc-switch` 会自动将 `~/.codex/config.toml` 写入类似如下的动态配置：

Ini, TOML

```
model = "deepseek-v4-flash"
model_provider = "deepseek"

[model_providers.deepseek]
base_url = "https://api.deepseek.com/v1" # 或中转站 URL
api_key = "sk-xxx"                        # 当前切换源的 API Key
```

**运行逻辑：**

1. Codex 启动时读取 `config.toml`，得知当前使用的模型是 `deepseek-v4-flash`，Provider 地址为 `cc-switch` 写入的 `base_url`。
2. Codex 在 `models.json` 中比对到 `slug == "deepseek-v4-flash"`，自动加载官方优化过的 `multi_agent_version = "v2"`、`instructions_template` 以及 `apply_patch` 命令行工具集。
3. 实现了 **源路由由 `cc-switch` 操控**，而 **Agent 交互与推理质量由 DeepSeek 官方规范兜底**。

### 四、 关键注意点

1. **Model Slug 命名绑定**

   在 `cc-switch` 配置各源的模型名称时，必须填 **`deepseek-v4-flash`**（与 `models.json` 保持严格一致）。若填成 `deepseek-chat` 或其他别名，Codex 会因匹配不到 `models.json` 中的元数据而退回到通用 OpenAI 行为，丢掉官方的 Agent 指令与 Patch 工具支持。

2. **中转源模型映射**

   如果第三方中转站上模型的实际 Slug 不叫 `deepseek-v4-flash`（例如叫 `deepseek-v4`），请在中转网关侧做 Model Mapping；或者在 `models.json` 中复制一份配置块并修改 `slug` 为中转站的名字。

3. **配置文件冲突保护**

   运行 DeepSeek 官方脚本后，若后续使用 `cc-switch` 切换其他非 DeepSeek 源（如 Anthropic/OpenAI），`models.json` 的配置不会被覆盖，随时切回 `deepseek-v4-flash` 仍可直接生效。
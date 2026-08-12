---
title: Pi Agent Harness 系统架构总览
tags:
  - Pi
  - Agent
  - 架构
  - Monorepo
  - TypeScript
  - AI
categories:
  - AI
abbrlink: 7c745b16
date: 2026-08-13 00:00:00
---

# Pi Agent Harness — 系统架构总览

> 仓库根目录：`/Users/bill/go/src/github.com/earendil-works/pi`
> 文档版本：v1（基于 `main @ cd6852a12`）
> 文档目的：给后续阅读源码、做修改、Review PR 的人一个统一的地图

---

## 1. 项目定位

Pi 是一个**可扩展的终端 Coding Agent 框架**，核心卖点：

- **极简内核**：不内置 sub-agent / plan-mode / 权限弹窗；这些能力通过 [Extensions](#74-extensions--skills--prompt-templates--pi-packages) 按需加载。
- **Provider-agnostic**：内置 30+ LLM 提供商（Anthropic / OpenAI / Google / Bedrock / 国产模型 等）。
- **多运行模式**：同一份核心支持 Interactive TUI、Print、JSON Lines、RPC、SDK 五种入口。
- **远程化可选**：通过 `pi-server` + 长度前缀 CBOR 协议将会话放到远端，本地用 `pi-client` 接入。
- **可观测性**：与厂商无关的 `pi-telemetry` 适配器接口，能挂 OpenTelemetry / Sentry。

---

## 2. Monorepo 总览

### 2.1 Workspace 布局

`package.json` 的 `workspaces` 字段声明如下分组：

| 路径 | 角色 |
|------|------|
| `packages/*` | 11 个核心包（详见 §2.2） |
| `packages/session-backends/*` | 会话持久化后端（目前只有 `sqlite-node`） |
| `packages/coding-agent/examples/extensions/*` | 示例扩展（with-deps、custom-provider-anthropic、gitlab-duo、sandbox、gondolin） |

构建顺序由 `scripts.build` 显式串联（**强依赖，不可乱序**）：

```
tui → telemetry → ai → agent → session-backends/sqlite-node
     → protocol → client → server → coding-agent
```

### 2.2 11 个核心包

| 包 | 作用 | 关键导出 |
|----|------|---------|
| `@earendil-works/pi-tui` | 终端 UI 原语（差分渲染、组件库、键位） | `TUI`、`Editor`、`Box`、`SelectList`、`ScrollView` |
| `@earendil-works/pi-telemetry` | 厂商无关 telemetry 契约 + 参考实现 + 类型化 schema | `TelemetryContext`、`NOOP_TELEMETRY_CONTEXT`、`InMemoryTelemetryContext`、`defineTelemetrySchema` |
| `@earendil-works/pi-ai` | 统一多 Provider LLM API（流式 + 一次性 + 图像生成） | `createModels`、`builtinModels`、`createProvider`、`Context`、`Tool`、`fauxProvider` |
| `@earendil-works/pi-agent-core` | Agent 运行时（状态机 + 事件流 + 工具调度） | `Agent`、`agentLoop`、`agentLoopContinue`、`streamProxy` |
| `@earendil-works/pi-session-backend-sqlite-node` | 基于 `node:sqlite` 的会话后端（repository + 物化视图 + FTS） | `SqliteSessionRepository`、`createSqliteSessionSearch` |
| `@earendil-works/pi-protocol` | 远程会话的 CBOR 消息协议 + 字节流分帧 | `PROTOCOL_VERSION`、`encodeClientMessage`、`ServerMessageDecoder` |
| `@earendil-works/pi-client` | 远程会话客户端（transport-neutral，Node 独立 subpath 提供 unix socket） | `PiClient`、`SessionLease`、`createUnixTransportFactory` |
| `@earendil-works/pi-server` | 远程会话服务端（依赖 Pi 应用提供 `PiServerService` 实现） | `PiServer`、`createUnixServer`、`toProtocol*` 桥接器 |
| `@earendil-works/pi-coding-agent` | 终端 Agent 完整实现：CLI、TUI、Print、JSON、RPC、SDK | `createAgentSession`、`AgentSession`、`InteractiveMode`、`runPrintMode`、`runRpcMode` |
| `@earendil-works/pi-evals` | 行为级评估（适配 vitest-evals，运行真实 `AgentSession`） | `createPiCodingAgentHarness`、`evalHarnessTable` |

补充说明：

- `pi-ai` 的兼容入口 `@earendil-works/pi-ai/compat` 保留旧版全局 API（`getModel` / `complete` / `streamAnthropic` ...），仅用于平滑迁移。
- `pi-protocol` 的协议版本字段叫 `PROTOCOL_VERSION`，目前为 `1`；语义是 experimental，不保证兼容。
- `pi-server` 在 README 顶部标注 "Experimental. May change or be removed without notice."

---

## 3. 模块分层图

### 3.1 自顶向下的依赖关系

```text
┌────────────────────────────────────────────────────────────────────┐
│                        应用/嵌入式入口                               │
│   pi-coding-agent (CLI/TUI/Print/JSON/RPC/SDK)                      │
│   examples/extensions/* (扩展开发示例)                              │
└────────────────────────────────┬───────────────────────────────────┘
                                 │ 依赖
┌────────────────────────────────▼───────────────────────────────────┐
│             远程会话 / 协议层                                       │
│   pi-server ──┐                                                    │
│   pi-client ──┴── pi-protocol (CBOR + 分帧)                       │
└────────────────────────────────┬───────────────────────────────────┘
                                 │
┌────────────────────────────────▼───────────────────────────────────┐
│                      Agent 运行时层                                 │
│   pi-agent-core (Agent 类 + agentLoop + tools 协议 + 事件流)       │
│   ├─ harness/session  (JSONL session 持久化)                       │
│   ├─ harness/compaction (上下文压缩 / 分支摘要)                    │
│   └─ harness/tools (read/write/edit/bash 内置工具集)               │
└──────┬──────────────────────────────────────────────┬──────────────┘
       │                                              │
┌──────▼────────────────────┐         ┌───────────────▼──────────────┐
│   Provider/LLM 层          │         │   可观测性 & 持久化层        │
│   pi-ai                    │         │   pi-telemetry              │
│   ├─ api/* (9 个 API 实现)  │         │   session-backends/sqlite   │
│   ├─ providers/* (30+ 厂商)│         └──────────────────────────────┘
│   ├─ auth (API key + OAuth)│
│   └─ compat (旧全局 API)   │
└────────────────────────────┘
                                 ▲
                                 │ 渲染
┌────────────────────────────────┴───────────────────────────────────┐
│                          UI 渲染层                                  │
│   pi-tui (差分渲染、组件库、键位、原义)                             │
│   + pi-coding-agent/modes/interactive (TUI 模式专用组件)            │
└────────────────────────────────────────────────────────────────────┘
```

### 3.2 单包内部模块分层（以 `pi-coding-agent` 为例）

```text
pi-coding-agent
├── cli/                      # 参数解析、auth 命令、子命令实现
├── core/
│   ├── agent-session.ts      # AgentSession：跨模式共享的核心抽象
│   ├── agent-session-runtime.ts / -services.ts  # 高级 SDK 工厂
│   ├── agent-session-services.ts                # 服务容器化注入
│   ├── model-registry.ts / model-resolver.ts    # 模型解析
│   ├── model-runtime.ts                          # Model 工厂（catalog + auth）
│   ├── session-manager.ts                        # JSONL 会话持久化
│   ├── settings-manager.ts                       # 全局/项目设置
│   ├── extensions/{loader,runner,types,wrapper}  # 扩展加载与执行
│   ├── compaction/{compaction,branch-summarization,utils}.ts
│   ├── tools/{read,write,edit,bash,grep,find,ls,...}.ts
│   ├── auth-storage.ts / auth-guidance.ts
│   ├── bash-executor.ts                          # BashExecutionMessage 处理
│   ├── http-dispatcher.ts                        # 全局 HTTP 代理/路由
│   ├── output-guard.ts / output-accumulator.ts
│   └── telemetry.ts
├── modes/
│   ├── interactive/                           # TUI 模式
│   │   ├── interactive-mode.ts
│   │   ├── components/ (44 个 TUI 组件)
│   │   └── theme/ (theme schema + dark/light)
│   ├── print-mode.ts                          # -p 单次输出
│   ├── json-event.ts                          # --mode json
│   └── rpc/                                   # --mode rpc (LF-delimited JSONL)
│       ├── rpc-mode.ts / rpc-client.ts
│       └── rpc-types.ts
├── extensions/{index,llama}/                  # 内置扩展（llama.cpp 管理器）
├── server/create-harness.ts                   # 嵌入式 PiServer 入口
├── client/{index,remote-session,transcript}.ts
├── core/export-html/                          # 会话导出为 HTML
├── core/extensions                            # 扩展机制（与上层同 path）
├── cli/experimental/                          # 实验 CLI（auth 子命令、运输地址）
├── bun/{cli,register-bedrock,restore-sandbox-env}.ts
├── utils/                                     # 杂项工具（child-process、git、图像、HTML...）
└── main.ts / cli.ts / rpc-entry.ts / sdk.ts    # 入口分流
```

### 3.3 依赖规则（总结）

- 底层包**不依赖**上层包（单向 DAG），build 顺序即编译顺序。
- `pi-agent-core` 不直接 import `pi-ai/compat`（这是显式约定，见 `core/sdk.ts:33-36` 注释）；通过 `streamFn` 参数注入。
- `pi-ai` 是唯一一个含 Provider SDK 的包；它的体积取决于注册的 providers（可树摇）。
- 跨包共享类型用 `^workspace:*` version range（npm workspace）。

---

## 4. 数据流程图

### 4.1 一次交互式 turn 的全链路

```text
┌──────────────────────────┐
│ 用户在 TUI 编辑器输入 Enter │
└──────────────┬───────────┘
               │ AgentSession.steer() / prompt()
               ▼
┌──────────────────────────────────────────────────────┐
│ AgentSession (coding-agent/core/agent-session.ts)    │
│ ── 1. 写入 SessionManager JSONL（持久化）             │
│ ── 2. 触发 Agent 运行时                                │
└──────────────┬───────────────────────────────────────┘
               │ agent.prompt(msg)
               ▼
┌──────────────────────────────────────────────────────┐
│ Agent (agent-core/agent.ts)                           │
│ ── 状态机：pending → streaming → tool-running → …     │
│ ── 事件总线：agent_start/turn_start/message_*          │
│   /tool_execution_*/turn_end/agent_end               │
└──────────────┬───────────────────────────────────────┘
               │ agentLoop(prompts, context, config, …)
               ▼
┌──────────────────────────────────────────────────────┐
│ AgentLoop (agent-core/agent-loop.ts)                  │
│  ┌─────────────────────────────────────────────────┐ │
│  │ 1) transformContext  (可选)：裁剪/压缩旧消息      │ │
│  │ 2) convertToLlm      (必需)：AgentMessage→Message│ │
│  │ 3) streamFn(model, context, opts)  ← pi-ai      │ │
│  └─────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────┐ │
│  │ 4) 解析流事件（text/thinking/toolcall）           │ │
│  │ 5) beforeToolCall 钩子（可拦截）                 │ │
│  │ 6) 执行工具：parallel / sequential               │ │
│  │ 7) afterToolCall 钩子（可改写）                  │ │
│  │ 8) 产出 toolResult 消息                          │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────┬───────────────────────────────────────┘
               │ Models.stream / complete
               ▼
┌──────────────────────────────────────────────────────┐
│ pi-ai (Models 集合)                                    │
│ ── 1. 解析 auth（存储凭据 → env var → OAuth）          │
│ ── 2. transformHeaders（最终头部合并）                │
│ ── 3. 派发到 Provider.streamSimple                    │
└──────────────┬───────────────────────────────────────┘
               │ Provider 持有 API 实现（anthropic-messages /
               │ openai-responses / google-generative-ai / ...）
               ▼
┌──────────────────────────────────────────────────────┐
│ HTTP → 厂商 API → SSE/Stream → 反向解析为 EventStream │
│   事件：start/text_delta/toolcall_delta/done/error    │
└──────────────┬───────────────────────────────────────┘
               │ 事件回流到 AgentLoop
               ▼
┌──────────────────────────────────────────────────────┐
│ Agent 处理 toolCall → 调用内置工具 / 扩展工具          │
│   bash-executor → 子进程                              │
│   read/write/edit/grep/find/ls → 文件系统              │
│   扩展工具 → ExtensionRunner.invoke()                 │
└──────────────┬───────────────────────────────────────┘
               │ 工具结果回写到 context.messages
               ▼
┌──────────────────────────────────────────────────────┐
│ 回到 AgentSession → 触发 compaction（必要时）            │
│   → SessionManager 持久化新条目 → 触发下一轮          │
└──────────────────────────────────────────────────────┘
```

### 4.2 RPC 模式的数据流

```text
外部进程
   │ JSONL（每条 LF 分隔，禁 readline）
   ▼
pi-coding-agent/modes/rpc/rpc-mode.ts
   │ RpcClient.parseCommand(stdin)
   ▼
AgentSession（共享核心）
   │ 与交互模式完全相同
   ▼
JSONL 输出（RpcResponse / RpcEventListener）
   │ 通过 stdout 回写
   ▼
外部进程
```

### 4.3 远程模式的数据流（实验性）

```text
Pi 客户端进程
   │
   ├─ PiClient (transport-neutral)
   │     └─ 字节流：Unix socket / WebSocket / 自定义
   ▼
encodeClientMessage() → [uint32-be 长度][CBOR 负载]
   │
   ▼
Pi 服务端进程
   │ decode → ServerMessageDecoder.push(chunk)
   ▼
PiServer.handle() → PiServerService 实现（由应用注入）
   │
   ▼
AgentSession 集群（多个独立 lease）
   │
   ▼
ServerMessage 回包（含 SessionSnapshot authoritative 状态）
```

> 协议规则要点（来自 `pi-protocol/README.md`）：
> - 协议版本 1；wire layout = 4 字节大端长度 + 一个 definite-length CBOR item。
> - 客户端首条必须是 `hello`。
> - 服务器 snapshot 是 authoritative；progress event 是瞬时提示，不得被客户端乐观地合并到 snapshot。
> - 所有 transport 视为 untrusted；配 frame limit；socket 走文件系统权限、网络走握手期鉴权。

### 4.4 持久化数据流（SessionManager）

```text
AgentSession.subscribe(event)
   │
   ▼
EventBus → SessionManager.append(SessionEntry)
   │
   ├─ JSONL 文件：~/.pi/agent/sessions/<cwd-hash>/<sessionId>.jsonl
   │     每条 Entry = { id, parentId, role, ... }，支持树形 / 分支 / fork
   │
   └─ 可选 SQLite 后端（pi-session-backend-sqlite-node）
         ├─ SqliteSessionRepository：ACID
         └─ createSqliteSessionSearch：FTS 投影
```

每个 entry 通过 `id` + `parentId` 链接，**单文件即支持 in-place branching**，不需要单独建文件。

### 4.5 Telemetry 数据流（可观测）

```text
Agent / Tools / Provider
   │ 显式传 TelemetryContext 参数（无 AsyncLocalStorage）
   ▼
TelemetryContext.startSpan({ name, attributes }, cb)
   │
   ├─ NOOP_TELEMETRY_CONTEXT（默认）
   ├─ InMemoryTelemetryContext（参考实现、测试用）
   └─ 应用注入的适配器（OpenTelemetry / Sentry / 自定义）
         │
         ▼
         后端 exporter
```

Schema 维度：pi 自有 `pi.ai.*`、`pi.harness.*`、`pi.session.*` 命名空间；schema 元数据用于类型化 span starter；属性值限定为 scalar / scalar[]，并标记 `sensitive` / `cardinality`。

---

## 5. 关键抽象与数据契约

### 5.1 AgentMessage / Message（双层消息模型）

```ts
// 顶层 AgentMessage：可携带 UI 专用类型
type AgentMessage =
  | UserMessage
  | AssistantMessage
  | ToolResultMessage
  | (自定义声明合并类型，例 BashExecutionMessage、SkillInvocationMessage...)

// LLM 边界：只接受 user / assistant / toolResult
type Message = UserMessage | AssistantMessage | ToolResultMessage;
```

转换路径：`AgentMessage[] → transformContext() → AgentMessage[] → convertToLlm() → Message[] → LLM`

`transformContext` 可选（用于上下文压缩、`/compact`），`convertToLlm` 必选（即使只是 filter 默认类型）。

### 5.2 AgentState

```ts
interface AgentState {
  systemPrompt: string;
  model: Model<any>;
  thinkingLevel: ThinkingLevel;       // 'off' | 'minimal' | 'low' | 'medium' | 'high' | 'xhigh' | 'max'
  tools: AgentTool<any>[];
  messages: AgentMessage[];
  readonly isStreaming: boolean;
  readonly streamingMessage?: AgentMessage;
  readonly pendingToolCalls: ReadonlySet<string>;
  readonly errorMessage?: string;
}
```

`Agent.state.tools = [...]` 与 `Agent.state.messages = [...]` 在 setter 中 `slice()` 复制顶层数组（防引用泄漏），但**内部数组仍可变**。

### 5.3 事件类型（AgentEvent）

```text
agent_start
turn_start
message_start | message_update | message_end    // message_update 仅 assistant
tool_execution_start | tool_execution_update | tool_execution_end
turn_end
agent_end
```

`agent_end` 是 barrier：`agent.waitForIdle()` 与 `agent.prompt()` 等到所有订阅者的 `agent_end` handler 完成后才 settle。

### 5.4 工具执行模式

- `parallel`（默认）：同批次工具并发执行；事件按完成顺序发出，**持久化顺序**仍按 assistant 源码顺序。
- `sequential`：整批串行。
- 单个工具可设 `executionMode: "sequential"`，**只要批次里有一个即整批降级为 sequential**。
- `beforeToolCall` / `afterToolCall` 可返回 `terminate: true` 阻止后续 LLM 调用（仅当整批都 terminate 时生效）。
- `shouldStopAfterTurn`：在 `turn_end` 之后、轮询 steering/follow-up 队列之前调用，可用于触发 compaction。

### 5.5 Provider / Auth / Models 集合

```ts
// Provider 是运行时单元（catalog + auth + API 实现）
const anthropic = anthropicProvider();   // 工厂：仅导入该厂商目录 + lazy API 包装
const models = createModels();           // 集合
models.setProvider(anthropic);           // 注册
models.setProvider(openai);              // 可多个

// Auth 解析优先级（在 Provider 内部）
1) 显式 options.apiKey / options.headers
2) ProviderAuth.apiKey.resolve() → env var / stored credential
3) ProviderAuth.oauth.refresh() → 自动刷新过期 OAuth
4) Ambient（AWS profile、gcloud ADC、Azure 资源名 ...）
```

工具调用一致性：所有厂商在 `models.stream*()` 暴露**相同的 EventStream 形状**（`text_*` / `thinking_*` / `toolcall_*` / `done` / `error`）；`toolcall_delta` 携带 partial JSON，可渐进式 UI 更新。

跨 Provider 切换：`Context` 是可 JSON 序列化的；从 Anthropic 切到 OpenAI 时，对方的 `thinking` block 自动转换为 `<thinking>` 标签文本。

### 5.6 协议层（pi-protocol）契约

| 字段 | 值 |
|------|-----|
| 协议版本 | `PROTOCOL_VERSION = 1` |
| wire layout | `[uint32-be 长度][CBOR]` |
| 默认限制 | 单帧 ≤ 16 MiB、数组 ≤ 1,000,000 项、嵌套 ≤ 64 层 |
| 客户端首条 | `hello`（携带版本号） |
| 鉴权 | transport 层完成后再交换协议字节 |
| 服务器 snapshot | authoritative |
| progress event | 非 authoritative（不可被乐观合并） |

### 5.7 pi-telemetry Schema 维度

| Schema | Span 名空间 | 拥有者 |
|--------|-------------|--------|
| `AI_TELEMETRY_SCHEMA` | `pi.ai.*` | `pi-agent-core`（按 telemetry 章节划分） |
| `HARNESS_TELEMETRY_SCHEMA` | `pi.harness.*` | `pi-agent-core` |
| Session 相关 | `pi.session.*` | `pi-agent-core` |

`createTypedSpanStarter(ctx, [...schemas])` 暴露**强类型**的 `startSpan('pi.ai.stream', { 'pi.ai.provider': 'openai' }, cb)`，回调里的 `span.setAttributes` 仅接受当前 span 的 end-attribute schema。

---

## 6. 运行模式切换矩阵

`pi-coding-agent/src/main.ts` 中通过 `resolveAppMode(parsed, stdinIsTTY, stdoutIsTTY)` 分流：

| 触发 | 模式 | 入口模块 | 输出 |
|------|------|---------|------|
| 默认（无参数、TTY） | Interactive | `modes/interactive/interactive-mode.ts` | TUI 渲染 |
| `-p` / `--print` | Print | `modes/print-mode.ts` | stdout 一次性回复 |
| `--mode json` | JSON Event | `modes/json-event.ts` + AgentSession | stdout JSON Lines |
| `--mode rpc` | RPC | `modes/rpc/rpc-mode.ts` | stdin/stdout JSONL（LF-only） |
| 嵌入式（`createAgentSession`） | SDK | `core/sdk.ts` → `AgentSession` | 由调用方处理事件 |

> **关键不变量**：所有模式共用同一个 `AgentSession`（`coding-agent/src/core/agent-session.ts`），仅 I/O 层不同。改 Agent 行为只需改一处。

---

## 7. 代码阅读重点

按"投入产出比"排序，**先看**这些文件能让你建立 80% 的认知：

### 7.1 一级必读（建立心智模型）

| 路径 | 行数(估) | 重点 |
|------|---------|------|
| `packages/agent/README.md` | 510 | 事件流、tool 协议、steering/follow-up、terminate 语义 |
| `packages/ai/README.md` | 1670 | Provider 工厂、Models 集合、Auth 解析、Tool 流式事件、跨 Provider handoff |
| `packages/agent/src/agent.ts` | ~700 | `Agent` 类：状态机、订阅、steer/followUp、`toolExecution` 模式 |
| `packages/agent/src/agent-loop.ts` | ~500 | `agentLoop` / `agentLoopContinue` 底层循环实现 |
| `packages/agent/src/harness/agent-harness.ts` | ~300 | `RunOutcome` / 错误类型 / LaneBusy 等核心错误模型 |
| `packages/coding-agent/src/core/agent-session.ts` | ~1500+ | 跨模式共享核心：事件订阅 + 自动保存 + 模型/思维管理 + 分支 |
| `packages/coding-agent/src/main.ts` | ~400 | CLI 参数 → `createAgentSession` 的翻译层、模式选择 |
| `packages/coding-agent/src/core/sdk.ts` | ~300 | 公开 SDK：`createAgentSession` 工厂签名与默认值 |

### 7.2 二级推荐（深入子系统）

| 路径 | 关注点 |
|------|--------|
| `packages/ai/src/index.ts` & `compat.ts` | 新旧 API 边界 |
| `packages/ai/src/providers/*.ts` | 任选一家（如 `anthropic.ts`、`openai.ts`），看清工厂注册流程 |
| `packages/ai/src/api/anthropic-messages.ts` | 一个 API 实现的样例：消息转换、thinking 字段、prompt cache |
| `packages/agent/src/harness/session/jsonl.ts` | JSONL 文件格式；与 `types.ts` 配合看 entry 类型 |
| `packages/agent/src/harness/compaction/compaction.ts` | 上下文压缩策略、`findCutPoint`、`shouldCompact` |
| `packages/agent/src/harness/session/search.ts` | 会话搜索接口 |
| `packages/coding-agent/src/core/extensions/{loader,runner,types}.ts` | 扩展加载与执行模型 |
| `packages/coding-agent/src/core/tools/{read,write,edit,bash}.ts` | 内置工具的实现套路（用 `AgentTool` 而非 `Tool`） |
| `packages/coding-agent/src/modes/rpc/rpc-mode.ts` | LF-delimited JSONL framing（与 `docs/rpc.md` 对照） |
| `packages/coding-agent/src/modes/interactive/interactive-mode.ts` | TUI 启动序列、组件挂载 |

### 7.3 三级（专题）

| 主题 | 入口 |
|------|------|
| 加新 Provider | `packages/ai/README.md` "Adding a New Provider" 章节（8 步 checklist） |
| 加新内置工具 | 参考 `core/tools/read.ts`，套用 `AgentTool` + `tools/tool-definition-wrapper.ts` |
| 加新远程协议消息 | `packages/protocol/src/schemas.ts`（CBOR 严格子集） |
| 加新 telemetry span | `packages/agent/src/harness/telemetry.ts`（扩展 `AGENT_TELEMETRY_SCHEMAS`） |
| 加新 Extension 钩子 | `packages/coding-agent/src/core/extensions/types.ts` 中的 `ExtensionAPI` 形状 |
| 自定义 Session Backend | 实现 `packages/agent/src/harness/session/index.ts` 中导出的 `SessionBackend` 接口 |

### 7.4 文档侧必读

| 文档 | 用途 |
|------|------|
| `packages/agent/README.md` | 事件时序图（`prompt()` / `continue()` / With Tool Calls） |
| `packages/ai/README.md` | Provider 表 + Auth 解析表 + Tool 事件参考 |
| `packages/coding-agent/README.md` | Interactive 模式 UI、slash 命令、键盘快捷键、消息队列 |
| `packages/coding-agent/docs/sdk.md` | 嵌入式调用范式 |
| `packages/coding-agent/docs/extensions.md` | Extension API 全量钩子 |
| `packages/coding-agent/docs/sessions.md` & `session-format.md` | 会话持久化格式 |
| `packages/coding-agent/docs/compaction.md` | 自动/手动压缩算法 |
| `packages/coding-agent/docs/rpc.md` | RPC 协议消息列表 |
| `packages/coding-agent/docs/containerization.md` | Gondolin / Docker / OpenShell 三种沙箱方案 |
| `packages/coding-agent/docs/security.md` | 已知威胁与隔离建议 |
| `packages/evals/README.md` | 评估 harness 适配与对比矩阵 |
| `AGENTS.md` | 仓库协作规则（提交格式、并发会话、tmux 测试流程） |
| `tui-plan.md` | TUI 历史决策与未来演进方向（背景知识，非实现细节） |

---

## 8. 常见陷阱 & 设计约束

阅读源码时务必注意以下几点，否则容易被坑：

1. **单向构建顺序**：`npm run build` 中 `cd packages/<x> && npm run build` 的顺序是硬约束，修改包后必须从底层开始重建。
2. **`pi-agent-core` 不依赖 `pi-ai/compat`**：`Agent` 类需要外部注入 `streamFn`；`core/sdk.ts` 通过 `setDefaultStreamFn(streamSimple)` 提供全局兜底。
3. **锁步版本（lockstep versioning）**：所有 11 个包共享同一版本号；`patch`/`minor` 二选一，无 `major`。改动跨包 API 必须同步 `CHANGELOG.md` 的 `[Unreleased]`。
4. **Erasable TypeScript only**：`packages/*/src`、`test`、`coding-agent/examples` 禁用 `enum` / `namespace` / `parameter properties` / `import =` 等需要 JS emit 的构造（Node strip-only）。
6. **直接编辑 `packages/ai/src/models.generated.ts` 被禁止**：必须改 `packages/ai/scripts/generate-models.ts` 后重新生成；生成差异即使混入无关上游 metadata 也可提交。
7. **不允许 inline imports**（`await import()`、`import("pkg").Type`）：只用顶层 `import`。
8. **任何 `npm install` 都带 `--ignore-scripts`**：`.npmrc` 设 `min-release-age=2` 防同日新依赖；CI 用 `npm ci --ignore-scripts`。
9. **pi-protocol 是 experimental**：无兼容承诺，新增字段需同时改 `schemas.ts` 与 `pi-server` 的 `toProtocol*` 桥接。
10. **TUI 启动测试用 tmux**：`AGENTS.md` 给出了 `tmux new-session / send-keys / capture-pane` 的标准流程。
11. **OAuth 是 Provider-owned**：Anthropic / OpenAI Codex / GitHub Copilot / OpenRouter 自带 OAuth；其他厂商走 `envApiKeyAuth`。
12. **`fauxProvider` 仅用于单测**：并发流需要多个独立 `fauxProvider`（不同 provider id）。
13. **`/compact` 与自动 compaction 是有损操作**：完整历史仍在 JSONL，可用 `/tree` 找回。
14. **steering / follow-up 模式（`one-at-a-time` vs `all`）** 在 settings.json 中可配，影响队列消费行为。
15. **`transformHeaders` 由 `Models` 而非 `Provider` 处理**：providers 不感知这个钩子；调用前 `Models` 实现负责消费并删除该字段再下发。

---

## 9. 进一步阅读索引（按场景）

| 你想做的事 | 看哪里 |
|-----------|--------|
| 加新 LLM Provider | `packages/ai/README.md` "Adding a New Provider" |
| 写自定义 Extension | `packages/coding-agent/docs/extensions.md` + `packages/coding-agent/examples/extensions/` |
| 接入 MCP（社区做法） | `packages/coding-agent/docs/extensions.md`（无官方实现，社区用 Extension 桥接） |
| 把 Pi 嵌入自己应用 | `packages/coding-agent/docs/sdk.md` + `core/sdk.ts` |
| 远程化 Pi session | `packages/server/README.md` + `packages/client/README.md` + `packages/protocol/README.md` |
| 跑模型评估 | `packages/evals/README.md` |
| 把 Pi 沙箱化 | `packages/coding-agent/docs/containerization.md`（Gondolin / Docker / OpenShell） |
| 让模型跨 Provider 接力 | `packages/ai/README.md` "Cross-Provider Handoffs" |
| 自定义 telemetry 后端 | `packages/telemetry/README.md` "Adapter Contract" |
| 优化 TUI 性能 | `packages/tui/README.md` + `tui-plan.md` + `scripts/profile-coding-agent-node.mjs --mode tui` |
| 调 RPC 性能 | `scripts/profile-coding-agent-node.mjs --mode rpc` |
| 发版流程 | `AGENTS.md` "Releasing" 章节 + `scripts/release.mjs` |

---

## 10. 文档维护

- 文档位置：`/Users/bill/Library/Mobile Documents/com~apple~CloudDocs/DebugRecords/agents/pi/`
- 配套文件建议：
  - `architecture-overview.md`（本文）
  - `data-flow-pi-coding-agent.md`（聚焦 `AgentSession` 事件流的更详细时序图，可在后续 review 时补充）
  - `extension-author-guide.md`（如团队要做扩展开发，可把钩子清单搬到独立文档）
  - `release-checklist.md`（从 `AGENTS.md` 提炼的发版 SOP）
- 建议在以下时机更新本文档：
  1. 新增 / 移除包（修改 §2.2）；
  2. 新增 / 重命名运行模式（修改 §6）；
  3. 升级 `PROTOCOL_VERSION`（修改 §5.6）；
  4. 变更 telemetry schema 命名空间（修改 §5.7）；
  5. 变更构建顺序脚本（修改 §2.1）。
---
title: iris框架概览
comments: true
abbrlink: 12d311d1
date: 2021-04-08 22:55:08
categories: 网络
tags: 网络
---

## 背景

Web 框架的基本诉求：接收 HTTP 请求 -> 处理 HTTP 各项参数 -> 路由 -> 自定义控制器 ->   获取返回结果 -> 返回 HTTP 响应。如下图所示：
![img](https://pic1.zhimg.com/80/v2-988e45bb7c2676d2cd6d00ab620743cd_hd.jpg)

同时，因为业务场景多变，需要框架能支持复杂的配置。例如：端口、传输文件大小、日志、本地化/国际化。

另外，服务端层面需要较高的单机性能，以提供可行的经济效益。

## iris框架

### 核心组件

#### Application

应用程序，负责管理应用程序的状态，包含并处理了创建快速Web服务器的所有必要部分。

其管理的基本组件如下：路由、上下文管理池、配置、日志库等。

```go
type Application struct {
	*router.APIBuilder                    // 路由构建器
	*router.Router                        // 路由
	ContextPool             *context.Pool // 上下文管理池
	config *Configuration
	logger *golog.Logger
	...
}
```

#### Router

路由功能。将指定的 `path` 和 `handler` 进行绑定。当请求过来时，则完成“转发”。

动态路由功能实现原理：在创建新的路由时，iris 会根据设置的模板(`macro.Template`)规则（最常见为 `{name(:type)}` ）对路径进行（正则表达式）解析，并把其路径参数（包括 path 和 query）都存储到上下文中。

路由的路径规则使用了 `router.trieNode` 进行存储。顾名思义，其子路径会递归嵌套，直至叶子节点。同一个子域的路径规则会生成一颗树 `router.trie`，并最终汇总到 `router.routerHandler.trees`。

默认的 `macro.Template` 共15种，如果都没匹配，且正则合法，则存入了该 `subdomain` 下的 `handlers` 中。解析时从叶子节点到根节点匹配，叶子节点的优先级更高。

例如: `http://example.com:8080/**`，其中 `/**` 作为根路径的正则表达式，会在具体路径无匹配时，跳转并使用全局的 `handlers`，并找到路由注册时绑定的 `handleFunc`。

至此，路由规则分析完成。

```go
type Router struct {
	mu sync.Mutex // 服务降级时使用
	mainHandler    http.HandlerFunc // init-accessible
	cPool          *context.Pool // used on RefreshRouter
	routesProvider RoutesProvider
	closestPaths map[string]*closestmatch.ClosestMatch
}
```

iris 的中间件(`middleware`)其实也被注册为 `handlers` 并存入相应的树形结构内，所以中间件跟其它 `handlers` 一样也有其作用域。

`iris` 注册中间件后是存在执行顺序的，如果中间件间存在依赖关系，一定要注意这一点。

其执行顺序为： `router.ApiBuilder.Use(first) -> router.ApiBuild.Use(second) -> router.ApiHandler.MainHandler(business) -> router.ApiHandler.Done()`。

#### Context

上下文管理，存储了输入请求的“对象”。每次新请求连接过来时，`Application` 会从 `context.Pool` 中获取一个新的 `Context` 对象。

这里 Pool 使用的类是 golang 的 `sync.Pool`，其底层实现机制是将 pool 内的实例对象的 `goroutine` 直接绑定(pin)到P（Processor，处理器）上，并实现了线程安全的管理。

这是 `iris` 在高并发下的性能瓶颈之一。`Context` 存储了太多的信息，当处于高并发时，`sync.Pool`会在堆中创建大量的内存，可能导致 GC 频繁启动回收。关于 `sync.Pool` 的讨论可以查看[这个链接](https://github.com/golang/go/issues/23199)。

```go
type Context interface {
  GetCurrentRoute() RouteReadOnly // 路由
  Next() // 中间件流转
  StopWithStatus(statusCode int) // 停止处理请求，并返回状态码
  Params() *RequestParams // 参数
  Method() string // HTTP 方法
  Path() String // 路径
  StatusCode(statusCode int) // 返回状态码
  JSON(v interface{}, options ...JSON) (int, error) // 写入并返回JSON对象
  ...
}
```

### Supervisor

伺服监管。应用程序 `Application` 可以同时伺服多个不同协议的多个 host，但底层实现是使用 `net/http` 的 `http.ListenAndServer()`，所以其会监听阻塞其调用 `goroutine`。这也是为什么我们必须执行 `go app.Run()` 的根本原因。

每个 host 都被抽象为 `TaskHost`，并在启动时执行 `go http.Serve(listener)`，由底层 `net/http` 完成端口监听分发， `Accept()`, `go c.serve(connCtx)` 实现请求伺服。

所以其核心实现的并发响应能力不可能超越标准库自身，目前必然是全面落后于使用 `fasthttp` 实现的网络框架。

### 流程图

#### 启动

![启动.png](https://i.loli.net/2020/06/19/pgh6w3I1cirA7Nv.png)

#### 路由

![路由.png](https://i.loli.net/2020/06/19/o16cGjRUYXif3A7.png)

## SWOT

### 优势

* 大而全的重量级 Web 框架。
  * 基本实现了 Web 框架的所有基础功能，包括但不限于：直接处理 HTTP 请求和响应、将请求路由到相关的handler中、完整的数据编解码方法、ORM支持、上下文管理、session维护等。
* 完善的中间件生态系统。
  * iris 大包大揽的添加了各种中间件，这意味着其在丰富的业务场景中都有对应的功能插件，随时可以使用，且符合当前框架的开发范式和编程习惯。
  * 这也意味着开发和验证功能特性更便捷。
* 完备支持MVC。
  * 暂时没用到。
* 强大的路由功能，路由支持正则表达式过滤动态路径。
  * 使用的是 `macros` 抽象，结合静态路由和动态路由，并确保它们不冲突。
  * 目前我们在 CDN 路由时使用了。
* Websocket、HTTP2支持。
  * iris 在 gorilla/websocket 的基础上，封装了适用于及时通信的一套框架。
  * 暂时没用到。

### 问题

* iris 号称自己是 golang 领域最快的几个开源框架之一。然而业界并不认可，在[权威的开源测试WebFrameworkBenchmarks](https://www.techempower.com/benchmarks)中完全没有其身影。其性能在部分线下测试中，仅是其它 golang 同行的 85% 左右。
* 高并发下，上下文管理池可能阻塞的问题还未解决。
* 据称，iris 摘录（拷贝）了不少开源代码，编辑代码的提交历史，并且删除了第三方许可证书，导致国外众多开源界人士对其极度反感。从2018年以后，整个项目活跃度下降了很多，只有作者和其他一两个贡献者在维护，新特性的可靠性和稳定性可能未得到充分测试验证。

## 参考资料

* [超全的Go Http路由框架性能比较](https://colobu.com/2016/03/23/Go-HTTP-request-router-and-web-framework-benchmark/)
* [awesome-go把iris从推荐名单移除并永久禁止该作者的仓库](https://github.com/avelino/awesome-go/pull/1730#issuecomment-352275025)
* [Go: Understand the Design of Sync.Pool](https://medium.com/a-journey-with-go/go-understand-the-design-of-sync-pool-2dde3024e277)
* [Iris 路由设置动态路由参数后，会导致跨域问题](https://learnku.com/go/t/45758)
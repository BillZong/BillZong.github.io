title: go-ethereum日志库调研
author: Bill Zong
tags:
  - ethereum
  - source
categories:
  - 区块链
abbrlink: 410d6a4b
date: 2021-04-12 22:15:00
---
# log15
```import "github.com/inconshreveable/log15"```

## 特性
- KV对方式的结构化日志
- 通过继承+自定义上下文的方式达成定制化
- 允许懒加载(日志内容可不提前分配内存和运算, 但仅限于```value```, ```key```上使用```Lazy```无效)
- 处理接口配置简单自定义
- (不同等级)终端输出颜色支持
- 文件日志/流日志/系统日志/网络日志内建支持
- 日志多分流输出(方便同时输出到流/文件等)
- 日志缓存输出(减少过量IO)
- 写入日志失败退出处理(避免丢失日志的概率)

## 常用接口
```go
func Debug(msg string, ctx ...interface{})
type Ctx map[string]interface{} // 输入键值对的方式, 便于人类阅读
// 允许你推迟运算
type Lazy struct {
    Fn interface{}
}
// 格式化设置
type Format interface {
    Format(r *Record) []byte
}
func FormatFunc(f func(*Record) []byte) Format // 动态格式化设置
// 处理接口, 后续一堆实现了该接口的内容, 可用于自定义处理方式
type Handler interface {
    Log(r *Record) error
}
```

## 示例
```go
// all loggers can have key/value context
srvlog := log.New("module", "app/server")

// all log messages can have key/value context
srvlog.Warn("abnormal conn rate", "rate", curRate, "low", lowRate, "high", highRate)

// child loggers with inherited context
connlog := srvlog.New("raddr", c.RemoteAddr())
connlog.Info("connection open")

// lazy evaluation
connlog.Debug("ping remote", "latency", log.Lazy{pingRemote})

// flexible configuration
srvlog.SetHandler(log.MultiHandler(
    log.StreamHandler(os.Stderr, log.LogfmtFormat()),
    log.LvlFilterHandler(
        log.LvlError,
        log.Must.FileHandler("errors.json", log.JsonFormat()))))
```
上面的输出结果如下:
```sh
WARN[06-17|21:58:10] abnormal conn rate                       module=app/server rate=0.500 low=0.100 high=0.800
INFO[06-17|21:58:10] connection open                          module=app/server raddr=10.0.0.1
```

## 问题
- 主分支会一直修正, 如果需要使用稳定的版本, 应使用vendor进行管理
- 目前版本```v2.14```依然不支持```rotate```
- 堆栈信息输出有限(目前为2层), 且无法调整(可能是内存方面的考虑)

# go-ethreum修改
## 特性
- 新增`trace`日志等级
- `critical`日志等级输出后, 退出程序

## 问题
- 依然不支持```rotate```, 有移动端开发社区的童鞋就这个问题进行了修改, 把文件日志使用[lumberjack](https://github.com/natefinch/lumberjack)进行了代替. 具体替换改动见[此链接](https://github.com/PombeirP/status-go/commit/49b0e0747ce6074abee71dbf130342a69acfb4ea)
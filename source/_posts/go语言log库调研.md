---
title: go语言log库调研
author: Bill Zong
tags:
  - golang
  - log
categories:
  - Golang
abbrlink: 6d4a1154
date: 2021-04-12 22:30:00
---
# 系统日志库

```import "log"```

## 基本配置

这些配置可以使日志内容输出时配置相应的内容头

```go
Ldate  // 当前时区日期
Ltime // 当前时区时间
Lmicroseconds // 显示微秒, 要求设置有Ltime
Llongfile // 长文件名:行号
Lshortfile // 短文件名:行号, 会覆盖Llongfile设置
LUTC // 使用UTC时间, 要求设置有Ldate或Ltime
LstdFlags = Ldate | Ltime // 标准日志初始化配置
```

## 基本调用方法

```go
func New(out io.Writer, prefix string, flag int) *Logger
func Printf(format string, v ...interface{})
func (l *Logger) Fatalf(format string, v ...interface{})
func (l *Logger) Panicf(format string, v ...interface{})
```

## 示例

```go
//os.Stdout可以修改为os.Stderr, 或者文件/buff等io.Writer
debugLogger := log.New(os.Stdout, "--Debug-- ", log.LstdFlags|log.Lshortfile)
debugLogger.Println("debug")
errorLogger := log.New(os.Stderr, "--Error-- ", log.LstdFlags|log.Lshortfile)
errorLogger.Println("error")
```

输出效果为:

>--Debug-- 2018/09/12 17:06:21 main.go:10: debug
>
>--Error-- 2018/09/12 17:06:21 main.go:11: error

## 问题点

- 没有日志分级, 需要自己另外做一层级别控制封装
- 输出流控制需要较多的自定义

# 第三方日志库

```import "github.com/op/go-logging"```

- 目前star较多, issure较少的第三方日志库. 基于系统日志库开发, 但有3年左右未更新代码.
- 支持内存日志(日志仅保存到内存)
- 支持系统日志
- 支持标准输出/标准错误输出
- 支持文件日志
- 支持多模块多级别日志

## 基本配置

```go
%{id}        // 日志条数
%{pid}       // 进程ID
%{time}      // 时间戳
%{level}     // 日志级别
%{module}    // 模块名称
%{program}   // 进程名称
%{message}   // 日志内容
%{longfile}  // 长文件名:行号
%{shortfile} // 短文件名:行号
%{callpath}  // 调用路径, 会截断
%{color}     // ANSI颜色
```

## 基本调用方法

```go
func NewLogBackend(out io.Writer, prefix string, flag int) *LogBackend // 创建日志输出后台/通道(io.Writer)
func SetLevel(level Level, module string) // 指定某个(或所有)模块的日志输出限制等级
func (l *Logger) SetBackend(backend LeveledBackend) // 将输出流设置到日志库中
func (l *Logger) Debugf(format string, args ...interface{}) // Debug级别
```

## 示例

```go
package main

import (
	"os"

	logging "gopkg.in/op/go-logging.v1"
)

var log = logging.MustGetLogger("example")

var format = logging.MustStringFormatter(
	`%{color}%{time:15:04:05.000} %{shortfunc} ▶ %{level:.4s} %{id:03x}%{color:reset} %{message}`,
)

// Password is just an example type implementing the Redactor interface. Any
// time this is logged, the Redacted() function will be called.
type Password string

func (p Password) Redacted() interface{} {
	return logging.Redact(string(p))
}

func main() {
	backend1 := logging.NewLogBackend(os.Stderr, "", 0)
	backend2 := logging.NewLogBackend(os.Stderr, "", 0)

	backend2Formatter := logging.NewBackendFormatter(backend2, format)

	// Only errors and more severe messages should be sent to backend1
	backend1Leveled := logging.AddModuleLevel(backend1)
	backend1Leveled.SetLevel(logging.ERROR, "")

	// Set the backends to be used.
	logging.SetBackend(backend1Leveled, backend2Formatter)

	log.Debugf("debug %s", Password("secret"))
	log.Info("info")
	log.Notice("notice")
	log.Warning("warning")
	log.Error("err")
	log.Critical("crit")
}
```

输出结果如图:
![输出效果图](https://lexiangla.com/assets/d726ec36b69311e88616525400a20cd4 "输出效果图")

## 问题点

- 单例需要自行封装
- 文件输出无法使用```append```模式
- 文件输出无法```rotate```
- 线程安全性有待考验, 已知```SetLevel()```是线程不安全的

# 结论

在当前开发调试阶段, 可采用这些目前有瑕疵的第三方库进行封装, 然后直接调用.

后续测试网上线时, 再将日志输出迁移成类似于```go-ethereum```中专门为链的KV值设计的日志库, 并添加上```metrics```进行实时性能监测
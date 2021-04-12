---
title: golang项目编码规范
author: Bill Zong
tags:
  - golang
  - guide
categories:
  - Golang
abbrlink: 107a8b74
date: 2021-04-12 22:33:00
---
## 背景

* 标准化的编码规范指导文档，希望整体编码风格能够趋近统一，便于项目维护、提高代码审核效率。

* 本文档主要内容是翻译（拼接、修改、裁剪）了 `golang` 官方及 `Uber` 的编码规范。

* 基本指导原则为：SOLID（单一功能、开闭原则、里氏替换、接口隔离以及依赖反转）。

* 建议把 `go lint` 和 `go vet` 在开发阶段都使用起来，目前已经有特别多低级错误的校验特性，已被验证为最佳实践之一。

* 另外，强烈推荐你阅读最后的参考资料，以确保你真正理解了这些规定的根本原因。

---

## 格式化

* 不用纠结缩进，直接使用 `gofmt` 统一风格即可。
* （在保存时自动）使用 `goimports` 组织包引用关系。
    * 自动分组为系统、第三方（包括当前项目），也会去除不使用的包引用。
* 列长度限制。

    * 个人自由。考虑到各 IDE 差异性，建议 `120` 字符为换行标准。
* 少用括号。

## 注释

* 公共包及核心功能必须提供注释。
    * 必须注释的内容包括：`package`, 公开的 `interface` | `enum` | `struct` | `func` 等。
    * 符合 `godoc` 注释标准。
    * 接口可使用 `swagger`  注释标准。
    * 方便团队其它童鞋阅读及使用。

```
// Compile parses a regular expression and returns, if successful,
// a Regexp that can be used to match against text.
func Compile(str string) (*Regexp, error) {
```

---

## 名称

### Package

* 纯小写、无特殊符号；简短、符合OOP语意。
* 建议：使用源文件的目录名。例如 目录为 `src/encoding/base64`， 包名建议为 `encoding` 和 `base64`。
* 包内内容语意上已包含了包名本身，所以不需要重复。例如： `bufio.BufReader` 建议修改为 `bufio.Reader`。
* 明确不导出的方法、类型、字段一律使用小写开头。

### Getter

* 没必要使用 `GetXxx()`，使用 `Xxx()`。

### Interface

* 建议使用 `-er` 结尾，例如 `type Reader interface{}`, `type CloseNotifier interface{}`。
* 接口内容明确，如果存在多种行为，可以 考虑使用 `embed` 到一块。如`io.ReadWriter`, `io.ReadCloser`。
* 使用 `String()` 而不是 `ToString()`。其它转换方法同理。

### 驼峰式命名

* 默认标准。

---

## 分号

* 能不用则不用，能换行就不要使用分号将语句拼到一块。

* `if i < f() {` 花括号与表达式在同一行。`gofmt` 会检查它们。

## 控制结构

### if

* 尽快返回，避免过度嵌套。
* 尽可能在判断条件中创建变量，以减少其作用范围。

```go
f, err := os.Open(name)
if err != nil {
    return err
}
d, err := f.Stat()
if err != nil {
    f.Close()
    return err
}
codeUsing(f, d)
```

### 重新声明/分配变量

* 变量覆盖前，要进行处理。`go vet` 会检查该项目。

```go
f, err := os.Open(name)
handle(err)
d, err := f.Stat()
handle(err)
```

### for

* 注意 `for range` 使用的元素是（浅）拷贝而不是原对象。
    * 所以如果对象为切片、数组时，复杂的元素应尽量使用指针：考虑性能（减少拷贝）、有可能在循环中修改元素。
    * 如果在循环中进行了数据拷贝，需要注意深浅拷贝问题。
* 多重循环或 `for switch` 嵌套流程，使用 `label` 来跳出整个大循环。

### switch

* 尽量少使用 `switch`，更不要提超长的 `if ... else  if ... else`  控制流程。
* 如果 `switch` 表达式中包含复杂的逻辑，说明代码结构需要重新设计了。

### type switch

* 类型判断时已生成对应的 `downcasting` 对象，可直接在表达式使用。

```go
switch t := t.(type) {
case bool:
    fmt.Printf("boolean %t\n", t)             // t has type bool
case *bool:
    fmt.Printf("pointer to boolean %t\n", *t) // t has type *bool
}
```

---

## Function

### 多返回值

* 少用 `naked return`。
    * API 描述上啰嗦，直接 `return` 很突兀，特别是存在不同组合的返回结果时难以确认正确结果。
    * 如果返回结果很多，说明需要重新设计，而不是往上继续累变量名来打补丁。

不好的示例：

```go
func (n *Node) Parent1() (node *Node) {}
func (n *Node) Parent2() (node *Node, err error) {}
```

良好的示例：

```go
func (n *Node) Parent1() *Node {}
func (n *Node) Parent2() (*Node, error) {}
```

### defer

* 成功初始化后，应立刻使用 `defer` 释放资源。

---

### 数据

### new() 分配

* new() 不做初始化，不做初始化，不做初始化。

### 构造函数与Composite Literals

* 基本语法：`&StructName {Name1: val1}`。
    * 简洁明确，最常使用。
    * 跟 new() 一样，不设置的 `filed` 为’零值‘。

### make()

* 如果明确切片、数组的大小及初始化内容，可直接设置 capacity，以减少重复分配空间。
    * `s := make([]int, 100)`，再使用 `for i :=0; i < len(s); i++ {}` 来完成设置。
    * `s := make([]int, 0, 100)` 使用’零值‘，这种用法也是可以接受的。
* 使用 `map` 时尽量指明 `capacity`，以减少重复分配空间。
    * `m := make(map[string]string, 10)`。
    * 如果不确定初始大小，则应写成：`m := make([string]string)`，而不是 ``m := make([string]string, 0)`。

### 数组

* 数组是值类型，是值类型，是值类型。
* 数组的长度也是类型的一部分，所以 `[2]int` 不能赋值给 `[3]int`。
* 较少使用，一般使用 `alias` 标识为具体类型，例如：`md5`, `hash`。

### 切片

* 传递切片时传的是值，传的是值，传的是值。
    * 如果需要变更入参的切片，使用其指针。

### Map

* 使用  `, ok` 语法判断 key 对象是否存在，不要直接使用未确认的内容。
* 移除对象建议使用 `delete(map, key)` 方法。

---

## 初始化

### 常数

* 枚举从 1 开始，除非’零值‘有明确的意义。
* 全局相关的常量建议组织到一块，同理也适用于变量。

---

## Method

### 指针 VS. 值

接收者(receiver)到底应该使用指针还是值，有一些基本的指导原则：

* 如果 receiver 是 map，function  或 chan，不要使用指向它们的指针。如果接收方是 slice，并且该方法未重新切片或重新分配切片，不要使用指向该切片的指针（以免让使用者误解）。
* 如果该方法需要更改 receiver，则 receiver 必须是指针。
* 如果 receiver 是包含 `sync.Mutex` 或者类似的 同步字段 的结构，则 receiver 必须是一个指针以避免复制。
* 如果 receiver 是大型结构或数组（>=5个字段|元素），则指针接收器效率更高。
* 如果 receiver 是 struct，array 或 slice，并且其任何元素都是指向可能正在变异的对象的指针，则最好使用指针，因为它将使读者更加清楚意图。
* 如果 receiver 是一个很小的数组或结构，没有可变字段且没有指针，或者只是一个简单的基本类型（如int或string），建议使用值 receiver，可以减少可以生成的垃圾数量（栈分配 vs. 堆分配）。
* **如果不想了解以上复杂的规则，那么就使用指针接收器。**

---

## interfaces与其他类型

### 类型转换

* 类型转换时，应尽量避免拷贝。

```go
type Sequence []int

// Method for printing - sorts the elements before printing
func (s Sequence) String() string {
  s = s.Copy() // 必须拷贝，否则会更改原来的切片内容
  sort.IntSlice(s).Sort() // 类型转换，必要性不大
	return fmt.Sprint([]int(s)) // 类型转换，减少拷贝
}
```

### interface与方法

一个简易HTTP（GET）服务器的各种写法：

```go
import "net/http"
...
ctr := new(Counter)
http.Handle("/counter", ctr)

// 访问次数计数
type Counter struct {
    n int
}

func (ctr *Counter) ServeHTTP(w http.ResponseWriter, req *http.Request) {
    ctr.n++
    fmt.Fprintf(w, "counter = %d\n", ctr.n)
}

// --- 整形 ---

type Counter int

func (ctr *Counter) ServeHTTP(w http.ResponseWriter, req *http.Request) {
    *ctr++
    fmt.Fprintf(w, "counter = %d\n", *ctr)
}

// ---

// A channel that sends a notification on each visit.
// (Probably want the channel to be buffered.)
type Chan chan *http.Request

func (ch Chan) ServeHTTP(w http.ResponseWriter, req *http.Request) {
    ch <- req
    fmt.Fprint(w, "notification sent")
}

// --- 函数式写法 ---

// The HandlerFunc type is an adapter to allow the use of
// ordinary functions as HTTP handlers.  If f is a function
// with the appropriate signature, HandlerFunc(f) is a
// Handler object that calls f.
type HandlerFunc func(ResponseWriter, *Request)

// ServeHTTP calls f(w, req).
func (f HandlerFunc) ServeHTTP(w ResponseWriter, req *Request) {
    f(w, req)
}

// Argument server.
func ArgServer(w http.ResponseWriter, req *http.Request) {
    fmt.Fprintln(w, os.Args)
}

http.Handle("/args", http.HandlerFunc(ArgServer))
```

---

## 内嵌

* 内嵌类型放到结构体最上方，以明确其组合结构。
    * 注意：同名方法会覆盖同名字段。
* 尽量不要内嵌结构。
    * 根据 OOP 设计的原则，屏蔽内部（底层）实现细节会让代码结构更灵活也更健壮。 

---

##  并发

### Share By Communicating

* *Do not communicate by sharing memory; instead, share memory by communicating.*

### goroutiens

* 注意其生命周期，特别是跟 `chan` 结合使用的时候。
    * 如果内部有 `chan` 阻塞，那么 `grouting` 便不会被 `GC` 回收。
    * 如果不能简单地使用它，那么需要在文档或注释中说明。

### channel

* 使用无缓冲 ` chan` 或者只有一个缓冲的 `chan`，这种用例已经足够满足绝大部分负载性能需求。
    * 如果使用超过一个缓冲的 `chan`，可能在设计层面上需要重新考虑通道的使用边界、竞态模型，以及相关逻辑。
* 等待 空`chan` 时，永远处于阻塞状态。
    * 很常见的低级错误。

### 并行计算

* 需要使用到并行计算时，要求计算必须可拆分成独立计算单元，相互间没有任何依赖。

```go
const numCPU = runtime.GOMAXPROCS(0) // Use all the cpus that go proc can have

func (v Vector) DoAll(u Vector) {
    c := make(chan int, numCPU)  // Buffering optional but sensible.
    for i := 0; i < numCPU; i++ {
        go v.DoSome(i*len(v)/numCPU, (i+1)*len(v)/numCPU, u, c)
    }
    // Drain the channel.
    for i := 0; i < numCPU; i++ {
        <-c    // wait for one task to complete
    }
    // All done.
}
```

### 一个泄漏缓冲示例

```go
var freeList = make(chan *Buffer, 100)
var serverChan = make(chan *Buffer)

func client() {
    for {
        var b *Buffer
        // Grab a buffer if available; allocate if not.
        select {
        case b = <-freeList:
            // Got one; nothing more to do.
        default:
            // None free, so allocate a new one.
            b = new(Buffer)
        }
        load(b)              // Read next message from the net.
        serverChan <- b      // Send to server.
    }
}

func server() {
    for {
        b := <-serverChan    // Wait for work.
        process(b)
        // Reuse buffer if there's room.
        select {
        case freeList <- b:
            // Buffer on free list; nothing more to do.
        default:
            // Free list full, just carry on.
        }
    }
}
```



---

## Error

返回错误时，思考路径如下：

- 这是一个不需要额外信息的简单错误吗？
    - 是的。[`errors.New`](https://golang.org/pkg/errors/#New) 足够了。
- 客户需要检测并处理此错误吗？
    - 是的。使用自定义类型并实现该 `Error()` 方法。
- 是否正在传播下游函数*(downstream function)*返回的错误？
    - 是的。使用 ["pkg/errors".Wrap](https://godoc.org/github.com/pkg/errors#Wrap)。
- 否则，使用  [`fmt.Errorf`](https://golang.org/pkg/fmt/#Errorf)。

### panic

* 不要在业务代码或库里使用 `panic`。

### recover

* `recover` 不是错误处理机制。
    * 如果你的程序不需要常驻伺服，那么让他接受 `panic` 信息退出会更合理一些。

## 参考资料

* [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
* [Effective Go](https://golang.org/doc/effective_go.html)
* [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
* [Go Design Pattern](https://www.oreilly.com/library/view/go-design-patterns/9781786466204/)
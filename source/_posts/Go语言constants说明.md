---
title: Go语言constants说明
author: Bill Zong
tags:
  - golang
categories:
  - Golang
abbrlink: a646ef82
date: 2021-04-12 22:29:00
---
# Go语言constants说明

## 概述

本文翻译和摘选自Go博客的[constants](https://blog.golang.org/constants)。内容主要描述`const`在go语言中的实际使用，和一些注意事项。

## 背景

1. go是一种静态语言类型，不允许混合数字类型的操作。
    * 所以你不能把一个`int`和一个`int64`直接相加，尽管带来了一定的不便利性，但也解决了C语言中，各种类型混杂操作、比较、隐式类型转换带来的各种难以发现的问题。
    * 同时，也方便了编译器，让静态代码在开发阶段就可以做更清晰的检查，减少运行时错误。

2. go语言的`const`是个关键字，它描述的常量，就只是一个简单、不变的值。
    * 除此之外，它无法再像C语言那样编写更复杂的属性。
    * 在减少`const`编程特性的同时，也避免了类似于`const * int`，`const * int *`这种无聊又危险的游戏。
    * 后续只聊go语言的`const`。

## 常量

* 默认的常量是不带类型的xxx常量*(untyped xxx constant)*
    * `const hello = "Hello world" // untyped string constant`
    * `const a = 1 // untyped int constant`
    * 不带类型的xxx常量可以直接赋值为各种其它自定义类型。

```
const untypedHello = "Hello, world"

type MyString string
var m MyString = typedHello // OK
```

* 带类型的常量则无法再直接赋值给其它自定义类型了。

```
const typedHello string = "Hello, world"

type MyString string
// var m MyString = typedHello // Type error
var m Mystring = MyString(typedHello) // OK for type convertion
```

* `bool/floats/complex/ints`等类型的常量，表现同上。

## 默认类型

* **Q:** “如果常量是无类型的，那么如何str在这个变量声明中得到一个类型？”
    * **A:** 无类型常量具有默认类型，如果需要不提供类型，则将其转移到值的隐式类型。对于非类型化字符串常量，即默认的类型显然string。所以，下面几种描述方式是一致的：
    * `str := "Hello, world"`
    * `var str string = "Hello, world"`
* 换一种描述，不带类型常量的值空间比预想的更大（或者说更趋近于理想值空间），限制也更少，所以当它被赋值给一个具体类型的时候，才可以正确地被转换。
    * 例如，`const Pi = 3.14159265358979323846264338327950288419716939937510582097494459`，这个不带类型常量定义了一个超高精度的浮点数。而且这个精度定义可以被更新的更高。
    * 然而，实际赋值给具体类型的时候，才会被具象。
    * 如：`fmt.Printf("pi: %v\n", float64(math.Pi)) // pi: 3.141592653589793`


## 最大的unsigned int

```
const MaxUint32 = 1<<32 - 1 // 最大的 uint32
// 最大的 uint，不管uint的位数是32，还是64位，这个表达式都能返回正确结果。
const MaxUint = ^uint(0) 
```

* **Q:** 如果我们对无类型常量0取反，那么结果会是什么？
    * **A:** 在数值空间中，`^0`表示无限数量的值 ，因此如果我们将其分配给任何固定大小的整数，我们就会丢失信息。有符号整数可以表示出来，为`-1`。而无符号整数，则会报溢出错误。

* **拓展：**只要我们停留在数字常数的世界中，我们就可以根据需要混合和匹配值，而不用受限于类型。
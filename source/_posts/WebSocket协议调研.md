---
title: WebSocket协议调研
comments: true
abbrlink: beb9dd3
date: 2021-04-08 22:48:17
categories: 网络
tags: 网络
---

# 介绍

## 一些重要概念

* BNF
  * Backus-Naur Form
* ABNF
  * Augumented BNF
* SNI
  * Server Name Indication
* ESNI
  * Encrypted SNI

## WebSocket设计哲学

Conceptually, WebSocket is really just a layer on top of TCP that does the following:

* adds a web origin-based security model for browsers
* adds an addressing and protocol naming mechanism to support multiple services on one port and multiple host names on one IP address
* layers a framing mechanism on top of TCP to get back to the IP packet mechanism that TCP is built on, but without length limits
* includes an additional closing handshake in-band that is designed to work in the presence of proxies and other intermediaries

# 重要细节

细节太多，只挑重点和容易忽略的内容：

## URI

```
ws-URI = "ws:" "//" host [ ":" port ] path [ "?" query ]
wss-URI = "wss:" "//" host [ ":" port ] path [ "?" query ]
```

* 大小写敏感。
* 端口、query为可选。
* path对象为空时填为`/`。
* `#`需要使用百分号编码。

## 握手

* 一个客户端可以跟一个服务端创建多个连接，但不允许同一时间有多个通道处于 `CONNECTING` 状态。
* 服务端可在负载过高时限制同一客户端的连接数。
* 客户端通过代理连接时建议使用 `SOCKS5` 代理。
* TLS握手时，客户端、服务端需要支持`SNI`。
  * 然而`SNI`域名未被加密，依然可能被监听，更安全的角度需要去实现`ESNI`，业内实现少。
* 握手升级为 `ws` 通道的请求中，`Sec-WebSocket-Key`, `Origin`, `Sec-WebSocket-Version`等字段都是必须的。
* 请求回复的消息头字段都是**大小写敏感**。
* `WebSocket` 可用版本目前只有 **13**，但考虑到向前兼容，服务端、客户端需要做版本协商。

### 客户端请求规则

```
Sec-WebSocket-Key = base64-value-non-empty
Sec-WebSocket-Extensions = extension-list
Sec-WebSocket-Protocol-Client = 1#token
Sec-WebSocket-Version-Client = version

base64-value-non-empty = (1*base64-data [ base64-padding ]) |
                         base64-padding
base64-data      = 4base64-character
base64-padding   = (2base64-character "==") |
                   (3base64-character "=")
base64-character = ALPHA | DIGIT | "+" | "/"
extension-list = 1#extension
extension = extension-token *( ";" extension-param )
extension-token = registered-token
registered-token = token
extension-param = token [ "=" (token | quoted-string) ]
                  ; When using the quoted-string syntax variant, the value
                  ; after quoted-string unescaping MUST conform to the
                  ; 'token' ABNF.
NZDIGIT       =  "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
version = DIGIT | (NZDIGIT DIGIT) |
          ("1" DIGIT DIGIT) | ("2" DIGIT DIGIT)
          ; Limited to 0-255 range, with no leading zeros
```

### 服务端回复规则

```
Sec-WebSocket-Extensions = extension-list
Sec-WebSocket-Accept     = base64-value-non-empty
Sec-WebSocket-Protocol-Server = token
Sec-WebSocket-Version-Server = 1#version
```

## 数据分帧

### 原因

* 发送|接收不确定长度的消息，以便确定数据缓存大小。
* 多路复用，提高传输效率。

### 安全

* 客户端需要屏蔽（masking）全部（数据）帧，服务端不能屏蔽任何帧。

### 数据帧规则

```
      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-------+-+-------------+-------------------------------+
     |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
     |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
     |N|V|V|V|       |S|             |   (if payload len==126/127)   |
     | |1|2|3|       |K|             |                               |
     +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
     |     Extended payload length continued, if payload len == 127  |
     + - - - - - - - - - - - - - - - +-------------------------------+
     |                               |Masking-key, if MASK set to 1  |
     +-------------------------------+-------------------------------+
     | Masking-key (continued)       |          Payload Data         |
     +-------------------------------- - - - - - - - - - - - - - - - +
     :                     Payload Data continued ...                :
     + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
     |                     Payload Data continued ...                |
     +---------------------------------------------------------------+
```

* `opcode` 控制码位
  * 目前只有3种数据帧：continuation | text | binary，3种控制帧：connection close | ping | pong 。
  * opcode 提供了保留字段供使用（不建议用，将来协议变更可能会带来冲突）。
  * 控制角度来说是比较简单的。处理模式基本通用，就是逐帧解析、异常关闭。
* 数据长度
  * 都是使用变长字段，最高可支持 `2^63` 字节。然而，我们并不建议使用过长的数据帧字段。
  * 因为网络环境的不确定性，随时有可能出现半开放连接（Half Open Connection）的场景，所以要保持控制帧 `ping`, `pong` 的通信。过长数据帧可能会出现 `ping`, `pong` 超时问题。
  * 另外，WebSocket 通道数据需要缓冲（是否需要拷贝得看具体实现），需要提防 OOM、处理超时等问题。
* 数据屏蔽|揭露（masking | unmasking）规则
  * original-octet-i：为原始数据的第i字节。
  * transformed-octet-i：为转换后的数据的第i字节。
  * j：为`i mod 4`的结果。
  * masking-key-octet-j：为mask key第 j 字节。

```
transformed-octet-i = original-octet-i XOR masking-key-octet-j
```

### 控制帧

* 不能分帧，payload 总长度必须小于等于 125 字节。
* 一条消息在发送时不能插入其它消息的数据帧，除非扩展支持并做了约定协商。
* 一条消息的所有数据帧格式都必须一致。
* 收到关闭控制帧后，服务端必须立刻回复关闭控制帧并关闭底层 TCP 连接；客户端需要等待服务端关闭 TCP 连接，但也可能随时关闭此 TCP 连接。

### 数据帧

* text帧
  * UTF-8 编码。client 必须 mask，master 不能 mask。
* Binary帧
  * 最常用的帧，应用层业务协议约定后自行解析。

## 扩展

常见的扩展用途：

* 可以在“应用程序数据”之前的“有效载荷数据”中放置“扩展数据”。

  * 可以存放多路复用数据，元数据等。

* 可以为每帧需求分配保留位。

* 可以定义保留的操作码值。

* 如果需要更多操作码值，可以将保留位分配给操作码字段。

* 可以定义一个保留位或一个“扩展”操作码，该操作码从“有效载荷数据”中分配其他位以定义更大的操作码或更多的每帧位。

## 收发数据

* 一条消息发送的最后一帧数据需要将 `fin` 位设置为 1。

* 一般情况下，一条消息多个分帧总是接连读取拼接起来的。但扩展可能会改变这种读取行为，具体得看服务器、客户端的约定协议。

  * 例如，多路复用扩展可能会接收到来自两条消息混插在一块的帧序列，但每一帧还是确保完整的。

## 关闭连接

* 需要回复状态码及关闭原因

## 安全

* 客户端必须在每一帧中使用不同的 `masking key`，且使用难以预测的生成算法。

# 参考资料

* [RFC 6455 - The WebSocket Protocol](https://tools.ietf.org/html/rfc6455)
* [Server Name Indication](https://en.wikipedia.org/wiki/Server_Name_Indication)
* [Augmented Backus–Naur form]([https://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_form](https://en.wikipedia.org/wiki/Augmented_Backus–Naur_form))
* [Why does Websocket RFC allows control frame interleaved with multiframe](https://stackoverflow.com/questions/23080900/why-does-websocket-rfc-allows-control-frame-interleaved-with-multiframe)
* [Detection of Half-Open (Dropped) Connections](https://blog.stephencleary.com/2009/05/detection-of-half-open-dropped.html)
* [WebSockets is a stream, not a message based protocol](http://www.lenholgate.com/blog/2011/07/websockets-is-a-stream-not-a-message-based-protocol.html)
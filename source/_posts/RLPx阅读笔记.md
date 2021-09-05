---
title: RLPx阅读笔记
author: Bill Zong
tags:
  - ethereum
  - RLPx
  - source
categories:
  - 区块链
abbrlink: 5d25bab6
date: 2021-04-12 22:19:00
---
# 实现的组成部分
- Node Discovery
- Encrypted Transport
- Framing
- Flow Control

# Eth实现的节点发现(Node Discovery)

## 与Kademlia的主要区别点
- packets are signed
  - Verification is performed by recovering the public key from the signature and checking that it matches an expected value. Packet properties are serialized as RLP in the order in which they're defined.
- node ids are public keys
- DHT-related features are excluded. FIND_VALUE and STORE packets are not implemented.
- xor distance metric is based on sha3(nodeid)

## 使用了Kademlia的路由参数
- The parameters chosen for kademlia are a bucket size of 16 (denoted k in Kademlia), concurrency of 3 (denoted alpha in Kademlia), and 8 bits per hop (denoted b in Kademlia) for routing.

## 更新配置
- The eviction check interval is 75 milliseconds, request timeouts are 300ms, and the idle bucket-refresh interval is 3600 seconds.

## 为了防范重放攻击
- Until encryption is implemented packets have a timestamp property to reduce the window of time for carrying out replay attacks. How the timestamp is handled is up to the receiver and it's recommended that the receiver only accept packets created within the last 3 seconds; timestamps can be ignored for Pong packets.

## 为了防止包内容被分割
- In order to reduce the chance that packets are fragmented the maximum size of a datagram is 1280 bytes, as this is the minimum size of an IPv6 datagram.

## 比Kademlia多了一些内容
- Except for the previously described differences, node discovery employs the system and protocol described by Maymounkov and Mazieres.

## 连接策略
- RLPx provides a list of 'potential' nodes, based on distance metrics, and can maintain connections for well-formedness based on an ideal peer count (default is 5). This strategy is implemented by connecting to 1 random node for every 'close' node which is connected.
- Other connection strategies which can be manually implemented by a protocol; a protocol can use it's own metadata and strategies for making connectivity decisions.

# 加密的握手(Encrypted Transport)
## 定义
- Connections are established via a handshake and, once established, packets are encapsulated as frames which are encrypted using AES-256 in CTR mode. Key material for the session is derived via a KDF with ECDHE-derived keying material. ECC uses secp256k1 curve (ECP). Note: "remote" is host which receives the connection.

## 阶段划分
- The handshake is carried out in two phases. The first phase is key exchange and the second phase is authentication and protocol negotiation. The key exchange is an ECIES encrypted message which includes ephemeral keys for Perfect Forward Secrecy (PFS). The second phase of the handshake is a part of DEVp2p and is an exchange of capabilities that each node supports. It's up to the implementation how to handle the outcome of the second phase of the handshake.
  - There are several variants of ECIES, of which, some modes are malleable and must not be used. This specification relies on the implementation of ECIES as defined by Shoup. Thus, decryption will not occur if message authentication fails. http://en.wikipedia.org/wiki/Integrated_Encryption_Scheme
  - There are two kinds of connections which can be established. A node can connect to a known peer, or a node can connect to a new peer. A known peer is one which has previously been connected to and from which a corresponding session token is available for authenticating the requested connection.

## 错误处理和提示
- If the handshake fails upon initiating a connection TO a known peer, then the nodes information should be removed from the node table and the connection MUST NOT be reattempted. Due to the limited IPv4 space and common ISP practices, this is likely a common and normal occurrence, therefore, no other action should occur. If a handshake fails for a connection which is received, no action pertaining to the node table should occur.
- Either side may disconnect if and only if authentication of the first framed packet fails, or, if the protocol handshake isn't appropriate (ex: version is too old).

## 握手相关协议细节
具体参考[此链接](https://github.com/ethereum/devp2p/blob/master/rlpx.md#encrypted-handshake)

# 分帧(Framing)

## 定义
- When sending a packet over RLPx, the packet is framed. The frame header provides information about the size of the packet and the packet's source protocol. There are three slightly different frames, depending on whether or not the frame is delivering a multi-frame packet. A multi-frame packet is a packet which is split (aka chunked) into multiple frames because it's size is larger than the protocol window size (pws; see Multiplexing). When a packet is chunked into multiple frames, there is an implicit difference between the first frame and all subsequent frames. Thus, the three frame types are normal, chunked-0 (first frame of a multi-frame packet), and chunked-n (subsequent frames of a multi-frame packet).

## 实现思路
- Message authentication is achieved by continuously updating egress-mac or ingress-mac with the ciphertext of bytes sent (egress) or received (ingress); for headers the update is performed by xoring the header with the encrypted output of it's corresponding mac (see header-mac above for example). This is done to ensure uniform operations are performed for both plaintext mac and ciphertext. All macs are sent CLEARTEXT.

## 注意细节点
- Padding is used to prevent buffer starvation, such that frame components are byte-aligned to block size of cipher.
- context-id distinguishes concurrent packet transfers within a protocol. All chunked frames for a certain packet share the same context-id. The assignment of packet ids is implementation-defined. The ids are local to the protocol-type and not the connection; two protocols may reuse the same context ids.

# 流控制(Flow Control)

## 注意
- The initial version of RLPx will set a static window-size of 8KB; fair queueing and flow control (DeltaUpdate packet) will not be implemented.

## 定义
- The data transfer window is a 32-bit value set by the sender and indicates how many bytes of data the sender can transmit. The protocol window is the transfer window, divided by the number of active protocols.

## 过程细节
- After a connection is established, but before any frames have been transmitted, the sender begins with the initial window size. This window size is a measure of the buffering capability of the recipient. The sender must not send a data frame larger than the protocol window size. After sending each data frame, the sender decrements its transfer window size by the amount of data transmitted. When the window size becomes less than or equal to 0, the sender must pause transmitting data frames. At the other end of the stream, the recipient sends a DeltaUpdate packet back to notify the sender that it has consumed some data and freed up buffer space to receive more data. When a connection is first established the initial window size is 8KB.

## 多路传输过程细节
- Multiplexing of protocols is performed via dynamic framing and fair queueing. Dequeuing packets is performed in a cycle which dequeues one or more packets from the queue(s) of each active protocol. The multiplexor determines the amount of bytes to send for each protocol prior to each round of dequeuing packets.
- If the size of a frame is less than 1 KB then the protocol may request that the network layer prioritize the delivery of the packet. This should be used if the packet must be delivered before all other packets. The senders network layer maintains two queues and three buffers per protocol: a queue for normal packets, a queue for priority packets, a chunked-frame buffer, a normal-frame buffer, and a priority-frame buffer.

## 伪代码描述细节
```go
if priority packet and normal packet exist: send up to pws/2 bytes from each (priority first!)
else if priority packet and chunked-frame exist: send up to pws/2 bytes from each
else if normal packet and chunked-frame exist: send up to pws/2 bytes from each
else read pws bytes from active buffer

if there are bytes leftover -- for example, if the bytes sent is < pws, then repeat the cycle.
```
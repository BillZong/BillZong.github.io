title: balance-attack相关说明
author: Bill Zong
abbrlink: '7742e199'
tags:
  - Ethereum
  - blockchain
  - security
categories:
  - 区块链
date: 2021-04-11 16:39:00
---
# balance-attack相关说明

- [什么是Balance Attack](#%E4%BB%80%E4%B9%88%E6%98%AFbalance-attack)
- [如何执行](#%E5%A6%82%E4%BD%95%E6%89%A7%E8%A1%8C)
- [对GHOST的影响](#%E5%AF%B9ghost%E7%9A%84%E5%BD%B1%E5%93%8D)
- [攻击实验](#%E6%94%BB%E5%87%BB%E5%AE%9E%E9%AA%8C)
  - [R3](#r3)
  - [Ethereum私网](#ethereum%E7%A7%81%E7%BD%91)
- [攻击防范](#%E6%94%BB%E5%87%BB%E9%98%B2%E8%8C%83)
- [其它攻击简介](#%E5%85%B6%E5%AE%83%E6%94%BB%E5%87%BB%E7%AE%80%E4%BB%8B)
- [结论](#%E7%BB%93%E8%AE%BA)
- [词汇表](#%E8%AF%8D%E6%B1%87%E8%A1%A8)
- [参考资料：](#%E5%8F%82%E8%80%83%E8%B5%84%E6%96%99)

# 什么是Balance Attack

* 攻击者暂时破坏了近似算力的网络子组之间的通信。
* 在此期间，攻击者在其中一个子组（交易子组）发布交易。
* 攻击者在另一个子组中挖掘足够多的区块，以确保另一个子组的子树很可能超过交易子组的子树。
* 即使交易已提交，攻击者也可以通过超过包含此交易的子树来高概率地重写包含这些交易的区块，从而达到双花。
* **新颖之处：**确定具有相同挖矿算力的网络节点子组，并在他们之间推迟消息，而不是比其他人更快地进行竞争挖矿。
* **为什么要这么麻烦：**
	* 原文章标题：*The Balance Attack or Why Forkable Blockchains are Ill-Suited for Consortium*
	* 关注的是联盟链场景，因为联盟链算力较小，而且节点的拓扑关系和算力比较容易衡量。
	* 在已知网络环境下，算力占比越高，作恶成功率越高，且耗时较短；即使较低比例算力占比，也可以通过这种方式达到短时间内双花成功的可能。
	* 主备链切换时，已打包的有效交易会回收，所以依然会重新打包到主链上。

# 如何执行

![平衡攻击子网切分](https://lexiangla.com/assets/8b2fc65e002b11e9abe9525400ac2e73)
![平衡攻击伪代码](https://lexiangla.com/assets/97138168002b11e98829525400a20cd4)

# 对GHOST的影响

* **Bernoulli’s inequality**
* 全是公式证明，就不在这里粘贴了。
* 结论是：基于GHOST协议、选择主分支的区块链系统，使用这种攻击方式是可以破坏的(corruptible)。

# 攻击实验

## R3
* 网络算力评估：使用2016年6月份的状态
![R3-2016年6月网络算力分布](https://lexiangla.com/assets/ad32e3ae04c111e9b45c5254002ec14d)
* 结论：随着延迟的增加，概率以指数方式快速增加，并且攻击者控制的挖矿算力占比越高，概率增加的越快。
	* 例如，要使平衡攻击的成功率达到90%，12%算力的攻击者需要35分钟，而20％算力的攻击者只需要11分钟就足够了。
![算力占比和网络延迟调整攻击成功可能性](https://lexiangla.com/assets/60d090ba04c111e99327525400177fdc)
![难度和网络延迟调整攻击成功可能性](https://lexiangla.com/assets/79fafec204c111e9ae275254002ec14d)

## Ethereum私网
* 版本：V1.3.5
* 结果：
* ![以太坊私网测试结果](https://lexiangla.com/assets/a2c067a6002b11e98ca45254004f9daa)

# 攻击防范

* 作者表示，可分叉的链没办法防范这类攻击。不管是Bitcoin、Ethereum；不管使用PoW还是使用PoS。
* 究其根源是这些区块链更看重`CAP`中的`A`，而不是`C`。
* 联盟链应该使用不分叉的区块链共识，如拜占庭共识。
* 但目前依然没有真正实用的支持大量节点通讯的拜占庭共识实现，或仅存在于理论阶段。

# 其它攻击简介

1. Finney attack（延迟发块）——单次确认
2. Vector76 attack（结合Finney attack和race attack）——单次确认
3. Rosenfeld attack（自私挖矿）——Bitcoin
4. Eclipse attack（中间人攻击）——通用性受限
5. BGP hijacking attack（IP劫持攻击）——历史上成功过，目前Balance Attack的模拟实现可通过这种方式达成

# 结论

1. 平衡攻击是一种将挖矿算力与通信延迟相结合的新攻击方式，影响可分叉区块链协议。这种攻击只是说服正确的节点忽视特定的一系列块，导致双花。
2. 可分叉链设计不适合联合和私有区块链。

# 词汇表

|名称|描述|
|:-:|:-:|
|corruptible|![可破坏的](https://lexiangla.com/assets/bcd4df6e002b11e9b4f9525400a20cd4)|
|分析用符号|![分析用词汇表](https://lexiangla.com/assets/dd4a9144002b11e992be525400a20cd4)|

# 参考资料：
1. [The Balance Attack Against Proof-Of-Work Blockchains: The R3 Testbed as an Example](https://arxiv.org/pdf/1612.09426.pdf)
2. [Irreversible_Transactions ](https://en.bitcoin.it/wiki/Irreversible_Transactions)
3. [Vector76 Double Spend Attack?](https://www.reddit.com/r/Bitcoin/comments/2e7bfa/vector76_double_spend_attack/)
4. [BGP hijacking](https://en.wikipedia.org/wiki/BGP_hijacking)
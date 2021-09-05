title: 布洛城BaaS系统设计方案
author: Bill Zong
tags:
  - BaaS
  - blockchain
  - architecture
categories:
  - 区块链
abbrlink: d5577457
date: 2021-04-12 22:24:00
---
## 系统架构

### 架构图

![布洛城BaaS架构图](https://i.loli.net/2020/02/25/otE4QJ6scxhnWe8.jpg)

### 模块说明

* 网络层
    * 考虑到多个项目都是部署在内网环境，存在多节点管理、高可用、恢复服务等需求，同时存在不少需求变更可能。
    * 不再使用 `docker swarm` 来管理网络，更不用考虑 `docker-compose`。
    * K8S 的管理比较灵活，且第三方插件众多，适合做功能扩展。
* 内核层
    * Fabric 使用版本 `v1.4.4`，这是个 LTS 版本，支持 `EtcdRaft` 和 `Kafka` 协议。直接默认使用 `EtcdRaft`，为将来提升版本做准备。
    * 提供国密版本，并提供相应的支持 SDK 和 Docker 镜像。
* 平台控制层
    * 部署模块关注的是将 Fabric 网络部署到 K8S 上。
        * 当前会使用 `helm` 将编辑好的 `chart`，根据模板和具体配置下发到 K8S 集群上部署。
        * 后续拓展功能包括：连接已创建 Fabric 网络的功能（要求版本必须是平台能支持的）。
    * 管理模块关注的是 Fabric 网络的配置管理。
        * 功能：证书秘钥管理、节点管理、智能合约管理、联盟链管理、业务通道管理。
        * 考虑到工期原因，会逐步实现以上功能，在迭代周期内做功能裁剪。

## 技术选型

### 网络层

#### K8S

* 使用 `v1.13.3` 的 K8S。
    * 目前该版本已在多个测试集群上稳定运行。
    * 目前最新的稳定版本为 `v1.17.3`，其它低于 `v1.17` 版本的文档已不再维护。如果需要迁移，可考虑在一段时间后切换到 
* 使用 `v2.14.2` 的 helm。

### 核心网络层

#### Fabric

* 使用官方 `v1.4.4` 版本。
* 默认使用 `EtcdRaft` 协议，暂不考虑提供 `Kafka` 协议的模板，减少兼容的复杂度。
* 对其进行修改国密，提供 docker 镜像并提供相应 SDK。
    * 官方和国密版本两者都需要提供，允许管理员在创建时进行配置。
    * 暂不考虑加密配置兼容。后期可考虑在代码层面直接兼容两种算法，在接收配置后启用不同的算法处理。
    * [改造方案参考资料](https://www.cnblogs.com/laolieren/p/hyperledger_fabric_gm_summary.html)
* `PBFT` 协议支持。
    * 当前版本不考虑。
    * 可考虑基于 `Tendermint` 来改造，实现难度较低一些。参考[携程区块链部门的实现说明](https://blog.csdn.net/hexinming/article/details/86617482)
    * 或者等 HyperLedger Fabric 社区贡献 PBFT 版本。

### 平台控制层

#### 部署模块

* 使用 `nephos` 或 `fabric-on-helm` 或 `Ansible-Fabric-Starter` 项目改造
    * [nephos 项目工程](https://github.com/hyperledger-labs/nephos)
    * [fabric-on-helm 项目工程](https://github.com/horan-geeker/fabric-on-helm)
    * [Ansible-Fabric-Starter 项目工程](https://github.com/Altoros/Ansible-Fabric-Starter)

不考虑 `blockchain-automation-framework` 原因有几个：

* 暂时不支持 Fabric EtcdRaft 协议配置。
* 对第三方服务，包括 `aws/vault/flux/ambassador` 等依赖度很高，内网部署难度太大。
* 部署和管理耦合程度很高。
    * 虽然提供了便利，也增加了开发调试/测试的难度。

#### 管理模块

* 使用 `ansible` 模块进行任务管理。
    * 任务做成 API 的方式，粒度尽可能细。
* 难点
    * 管理模块和部署模块在解耦的要求下，如何确保其配置注入。
    * 管理模块的任务需要异步进行，方案包括：
        * 使用 ansible（版本 >= 2.3）的异步 Action 和状态轮询。**版本特性依赖较重**。
        * 上层分发给 ansible 的消息为异步，再使用 ansible 错误处理。考虑到 Fabric 网络配置变更基本是**非幂等**，ansible 使用同步模式（默认）应该更合理一些。
    * 管理模块的任务结果返回，方案包括：
        * 消息队列 + 消息 ID。这种方式层级间**耦合度较低**，可水平扩容增强吞吐能力，但部署难度更高一些。
        * WebSocket 长链路 + 会话 ID。**耦合较高**，开发较困难，稳定性和扩容能力较差，但调试和部署方便一些。

### 平台服务层

#### 链浏览器

* 使用 Fabric 官方开源的 `blockchain-explorer` 项目。
    * 进行一些业务裁剪。
    * 使用通用的配置。

#### 链日志/审计

使用运营管理日志服务的 API，进行权限管理下的日志展示、查询等操作。

难点：

* 分模块、分级别。
* 分布式系统业务流程追踪。
* 权限管理。
* 定时回滚，避免日志体量过大，塞满内网硬盘存储。

实现要点：

* 模块和业务流程追踪可以通过 meta + ID 的方式来做。
* 日志级别统一标准：verbose(trace)/debug/info/warm/error(fatal)，括号内的级别统一归到同一级别。
    * 系统日志如果没有级别，统一使用 info 输出，并独立模块。
* 权限管理需要结合 BaaS 用户来做。
    * BaaS 用户可查看自己组织和联盟内组件的日志。
    * BaaS 管理员和安全审计人员可查看所有组织和联盟组件的日志。
    * 可能需要结合 ELK 的权限控制插件来做管理。
* 定时回滚目前只能使用 ElasticSearch 的接口来定时删除数据。
    * 定时任务可使用 K8S 的 CronJob。
    * 该模块需要提供定时任务的周期配置等。
    * 考虑到审计需求，不删除用户操作记录。

#### 用户管理

这里的用户包括两个概念范畴，一个是 BaaS 系统用户（BaaS管理员、BaaS用户、安全审计人员等），另外一个是 MSP 用户（企业管理员、用户、审计人员等）。
两者的控制权限重叠部分少，需要进行分离。故此，我们会设定两类用户角色，其中：

* BaaS 系统用户
    * 邀请制创建，BaaS 管理员具有唯一审核权限。
    * 使用账号密码登陆。
    * 允许创建 key，开放部分功能给 API 调用。
    * 安全审计人员拥有整个网络的最高审核权限，但只读。
* MSP 用户
    * BaaS 用户可创建唯一一个顶层 MSP，其中默认创建一个 MSP 管理员。
    * MSP 下的用户管理模型同 Fabric，即 ACL、ABAC。
    * 每个 MSP 用户都有自己的证书，仅创建时可导出私钥。

用户系统的开源库实现可以使用 `Casbin`，其支持 ACL、RBAC、ABAC 等多种权限管理模式。
该开源组织有多个语言版本的实现，包括：

* [golang](https://github.com/casbin/casbin)
* [java](https://github.com/casbin/jcasbin)
* [nodejs](https://github.com/casbin/node-casbin)
* 等等。

#### 链管理平台

这块暂时没有成熟且一直维护的开源项目支持，只能考虑自研。内容参考一些知名的 BaaS 平台，或开源的 Fabric 管理工具，如 [hyperledger-fabric-manager](https://github.com/fabric-lab/hyperledger-fabric-manager)。

该层主要是调用平台控制层中的管理模块的 API 对底层 Fabric 网络做增删改查的工作，变更操作和结果需要进行持久化存储。

##### 证书秘钥管理

* 隶属于组织（MSP）管理的一部分。
* 暂时只考虑 OpenSSL 证书，国密证书需要改造完成后再支持。
* 允许导出。
* 用户列表查询。
* 吊销证书。
* 吊销证书查询。
* 用户状态查询。

##### 节点管理

* 添加节点。
* 启动节点。
* 停止节点。
* 删除节点。
* 节点列表查询。
* 节点状态查询。

##### 智能合约管理

* 添加合约。
* 初始化合约。
* 升级合约。
* 停止合约。
* 合约列表查询。
* 合约状态查询。
* 签名政策修改。

##### 联盟链管理

* 创建联盟。
* 修改联盟配置（包括区块等）。
* 邀请新组织。
* 加入新组织。
* 移除组织。
* 查询组织信息。
* 查询组织列表。
* 获取联盟信息。

### 运营管理

#### 日志服务

* 使用 `ELK` 技术栈
    * `ElasticSearch` + `Kinana` 是明确使用的存储 + 展示日志技术方案。
    * `Logstash` 可替换为 `fleuntd-pilot`。
        * 后者性能要求更匹配我们的硬件规格，一个节点仅运行一个实例。
        * 后者不需要多个组件，一次完成标准输出和文件日志的收集，且为无侵入式。
* 使用 `graylog`
    * `fleuntd-pilot` 收集的日志同样可以输出到 `graylog`。
    * 完整的日志系统，包括结构化日志存储和展示UI等，没有那么多组件。
        * 换个角度来说，存储和展示服务放在同一台机器，没办法放在不同设备，扩容不够灵活。
    * 实时通知。
    * TB 级别存储和查询支持。
    * 自动归档（如 SSD + HDD 存储并存时适用）。

#### 存储（数据库）管理

* 使用 CouchDB 做（配置、操作）数据存储。
    * Fabric 网络、组织、用户、通道等数据变更频率低。
* 适配多集群业务场景。
    * 多集群是后续版本迭代的方向，当前版本不考虑这部分。
    * CouchDB 多主同步数据能有效避免单点失效问题，且配置简单。

### 安全管理

#### 操作审计

* 用户操作日志全纪录。
* 访问权限同业务日志。
* 目前日志展示模块可合并到 `Kinaba`，即管理平台端也需要运行 `Logstash` 或者 `fleuntd-pilot`，进行日志收集汇总。

## 参考资料

### 携程BaaS

* [HyperLedger Fabric的架构与设计理念 - 2019携程技术峰](https://techsummit.ctrip.com/2018/pdf/hexinming.pdf)
* [HyperLedger Fabric在携程区块链服务平台的应用实战](https://mp.weixin.qq.com/s/tQCLIiaLoumffoGfxVO6Pg)
* [HyperLedger Fabric orderer过程解析&如何基于tendermint实现fabric的拜占庭容错排序](https://blog.csdn.net/hexinming/article/details/86617482)

### BaaS比较

* [阿里、腾讯、百度区块链落地案例大PK，谁弱谁强？](https://www.feixiaohao.com/news/6259724.html)
* [一文读懂百度、阿里、腾讯的区块链技术与布局对垒](https://www.chainnews.com/articles/847272068062.htm)

### XuperChain

* [XuperChain](https://github.com/xuperchain/xuperchain/blob/master/README.md)

### TBaaS

* [TBaaS产品架构](https://cloud.tencent.com/document/product/663/14016)
* [TBaaS操作指南-联盟](https://cloud.tencent.com/document/product/663/38470)

### WeBASE

* [什么是WeBASE](https://webasedoc.readthedocs.io/zh_CN/latest/docs/WeBASE/introduction.html)
* [节点前置服务概要介绍](https://webasedoc.readthedocs.io/zh_CN/latest/docs/WeBASE-Node-Manager/README.html)

### 阿里云BaaS

* [区块链Hyperledger Fabric在阿里云容器服务Kubernetes中的进阶使用技巧（一）](https://yq.aliyun.com/articles/326173)
* [阿里云容器服务区块链解决方案全新升级 支持Hyperledger Fabric v1.1](https://yq.aliyun.com/articles/563496)
* [配置部署区块链](https://help.aliyun.com/document_detail/64316.html)
* [阿里云BaaS产品架构](https://help.aliyun.com/document_detail/85269.html)
* [阿里云BaaS使用限制](https://help.aliyun.com/document_detail/107822.html)

### 开源BaaS

* [The Blockchain Automation Framework’s Features](https://blockchain-automation-framework.readthedocs.io/en/latest/keyConcepts/features.html)
* [Configuration file specification: Hyperledger-Fabric](https://blockchain-automation-framework.readthedocs.io/en/latest/operations/fabric_networkyaml.html)
* [Configuring pre-requisites for the Blockchain Automation Framework](https://blockchain-automation-framework.readthedocs.io/en/latest/operations/configure_prerequisites.html)
* [Architecture Reference of BAF](https://blockchain-automation-framework.readthedocs.io/en/latest/architectureref.html)
* [Hyperledger Fabric Architecture Reference of BAF](https://blockchain-automation-framework.readthedocs.io/en/latest/architectureref/hyperledger-fabric.html)
* [BAF未实现Fabric的Raft协议配置](https://github.com/hyperledger-labs/blockchain-automation-framework/issues/46)

### ansible

* [Asynchronous Actions and Polling](https://docs.ansible.com/ansible/latest/user_guide/playbooks_async.html)
* [Error Handling In Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_error_handling.html)

### 国密

* [支持国密SM2/SM3/SM4/SM9/ZUC/SSL的OpenSSL分支](https://github.com/guanzhi/GmSSL/blob/master/README.md)

### 日志

* [Docker日志收集最佳实践](https://yq.aliyun.com/articles/72700)
* [容器内应用日志收集方案](https://blog.csdn.net/rancherlabs/article/details/53688474)
* [Advantages of Graylog+Grafana Compared to ELK Stack](https://medium.com/@logicify/advantages-of-graylog-grafana-compared-to-elk-stack-a7c86d58bc2c)
* [Planning Your Log Collection](https://docs.graylog.org/en/3.2/pages/getting_started/planning.html)
* [给Elasticsearch 和Kibana添加基于角色的访问权限控制](https://blog.csdn.net/xuplus/article/details/51611658)
* [elasticsearch定期删除策略 - 日志分析系统ELK搭建](https://blog.csdn.net/xuezhangjun0121/article/details/80913678)

### 用户管理

* [Attribute-Based Access Control](https://hyperledger-fabric-ca.readthedocs.io/en/release-1.4/users-guide.html?spm=a2c4g.11186623.2.11.622f48cdPA27KC#attribute-based-access-control)
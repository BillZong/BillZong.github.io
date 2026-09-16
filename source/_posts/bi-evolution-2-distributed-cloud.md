---
title: 分布式计算与云原生数仓时代（计算与存储的解耦）
comments: true
mathjax: false
mermaid: true
series: BI系统的发展进程：数据建模、计算引擎与语义交互的架构演进
series_order: 3
series_status: published
categories:
  - bi-evolution
tags:
  - BI
  - 分布式计算
  - Hadoop
  - Spark
  - 列式存储
  - MPP
  - CBO
  - 向量化执行
  - 云原生数仓
  - 存算分离
  - Lakehouse
  - 开放表格式
  - Delta Lake
  - Iceberg
  - Medallion
  - ELT
  - 指标地狱
original_slug: 第二章V3.2
source_note: >-
  第二篇正文:从单机 RDBMS 到分布式 MPP, 再到云原生存算分离与 Lakehouse 湖仓一体, 聚焦"算得快≠算得对"衍生的指标地狱问题,为下一篇
  Headless 语义层铺垫
abbrlink: b39845b2
date: 2026-09-16 11:30:00
---

> 本节为系列第 2 / 8 节. 承接第一篇的"数据源+查询计算"两层奠基, 展开分布式计算, 云原生数仓, Lakehouse 三波底层范式跃迁, 并暴露第二代 BI 的核心新债务: 指标语义失控.

# 第二章: 分布式计算与云原生数仓时代 (计算与存储的解耦)

*Part II: Distributed Computing & The Cloud Data Warehouse Era (The Decoupling of Compute & Storage)*

## 1. 大规模分布式计算范式的兴起与局限

进入 2000 年代中后期, 互联网业务的爆发带来了半结构化日志与海量非结构化数据的几何级增长. 第一篇中所讨论的单机单体 RDBMS 存储与计算架构, 即使通过高昂的垂直扩展 (Scale-Up), 也无法在物理极限和成本效益内承接这一规模的数据处理吞吐. 为了打破算力的物理天花板, 数据工程界正式开启了从单机向分布式横向扩展 (Scale-Out) 的范式转移.

### 1.1. Hadoop / MapReduce 时代的得与失

由 Google 的早期研究所点燃, 并由 Apache Hadoop 生态发扬光大的大规模分布式计算范式, 率先颠覆了传统数仓的存算一体模式 [^1]. 其核心架构思想是通过廉价商品服务器集群横向扩展, 利用分布式文件系统 (HDFS) 切分存储海量原始数据, 并利用 **MapReduce (映射-归约)** 框架将计算任务分发至数据所在的物理节点上执行, 实现数据本地性 (Data Locality).

作为大规模批处理抽象, MapReduce 具有其特定的运行机制: 在任务执行过程中, Map 算子的中间输出通常会在本地进行缓冲并发生中间结果落盘, 随后通过高密度的网络 Shuffle 屏障分发给 Reduce 算子; 最终的任务输出结果才写入持久化存储 [^1]. 这种对频繁中间结果磁盘物化与网络 Shuffle 的深度依赖, 导致其在面临 BI 系统高频的**交互式敏捷分析 (Interactive Ad-hoc Queries)** 时, 面临无法忽视的响应延迟. MapReduce 解决了"能够处理海量数据"的工程规模问题, 却尚未能解决低延迟交互分析的痛点.

### 1.2. 内存计算与统一数据处理的飞跃

为了解除通用分布式批处理阶段性磁盘落盘的枷锁, Apache Spark 提出了基于**弹性分布式数据集 (RDD, Resilient Distributed Dataset)** 的内存计算范式 [^2]. Spark 引擎通过运行时构建**有向无环图 (DAG)** 调度器, 将连续的数据转换算子组合成不同的执行阶段 (Stages). 在单个 Stage 内部, 数据在内存中以流式流水线 (Pipelining) 的方式进行变换, 显着降低了中间结果物化的开销. 这里的"内存复用"是指通过 RDD 缓存和 DAG 中间结果复用减少不必要的磁盘物化, 而不是指所有 Spark 计算都完全在内存中完成. 原始论文在特定迭代机器学习任务中报告了相对于 Hadoop 约 10 倍的性能提升, 并展示了交互式数据分析的低延迟能力 [^2]. Spark 的出现将分布式计算从"磁盘时代"推进到了"内存复用时代".

### 1.3. 通用计算向专用分析引擎的桥接

需要指出的是, Hadoop 和 Spark 解决的首先是通用大规模数据处理与分布式编程的抽象问题, 而非直接作为交互式 BI 系统的专用替代品. 它们真正改变的是"可用于分析的数据规模与底层的计算拓扑". 这一通用计算范式的确立, 为后续以海量 SQL 分析为核心的专用分布式分析型数据库 (Parallel Databases) 和 SQL-on-Hadoop 系统的发展创造了关键的技术温床.

## 2. 列式存储、MPP、查询优化器与向量化执行

通用分布式计算框架解决了海量数据的批处理问题, 但要满足企业级 BI 对高并发、低延迟 SQL 分析的极致要求, 分析型数据库的底层核心必须完成从存储介质到处理器微架构的全局重构. 这一重构由以下四个交织在一起的技术变革共同驱动:

{% mermaid %}
flowchart LR
    Q[SQL] --> P[Parser] --> O{CBO} --> E[Plan] --> M{MPP} --> C[列存]
    style O fill:#fff3b0,stroke:#b58900
    style M fill:#fff3b0,stroke:#b58900
{% endmermaid %}

### 2.1. 行式存储向列式存储 (Columnar Storage) 的演进

传统 RDBMS 采用行式存储 (Row Store), 页面内部连续排布单条记录的所有字段. 在 OLAP 大范围只读聚合场景下, 这会导致大量的无效磁盘 I/O. 列式存储 (Columnar Storage) 则将同一个字段的所有记录在物理页面上连续排布 [^3].

- **I/O 裁剪**: 查询引擎可以根据 SQL 语句, 避免读取查询未涉及的列数据, 从而显着减少扫描 I/O.
- **编码与压缩红利**: 由于同列数据的数据类型和值域空间完全一致, 列存可以原生应用高效的压缩算法 (如字典编码, 游程编码 RLE, 位打包 Bit-packing), 在低基数, 重复度较高的分析数据上能够获得显着更高的压缩比 [^3].

### 2.2. MPP (大规模并行处理) 架构

MPP 数据库采用**无共享 (Shared-Nothing)** 架构, 本文所述 Shared-Nothing 指经典 MPP 语境中的节点本地资源独立, 即每个节点拥有独立的 CPU, 内存和存储资源 [^4]. 现代云数据仓库在此基础上进一步演化出了共享存储与解耦计算的架构. 数据通过哈希 (Hash) 或轮询 (Round-Robin) 分散存储在不同的数据节点上. 执行 SQL 时, 总控节点将查询请求解耦为分布式物理执行计划, 分发至所有数据节点并行计算. 在执行多表复杂关联 (`JOIN`) 时, MPP 架构依靠物理网络层进行数据重分布: 通过广播连接 (Broadcast Join) 将小表复制到所有节点, 或者通过洗牌连接 (Shuffle/Hash Join) 将大表基于 Join Key 重新计算哈希并重分布到对应节点, 打破了单机单体内存与 I/O 吞吐的局限 [^4].

### 2.3. 查询优化器 (Query Optimizer) 与物理执行计划

随着多表关联规模扩大以及分布式执行中 Join 顺序, 数据重分布和并行度选择变得更加复杂, 基于代价的查询优化器 (CBO, Cost-Based Optimizer) 在现代分析型数据库中承担了更加关键的角色 [^5]. 优化器遵循从 `SQL Parser → Logical Plan → Cost-Based Optimizer → Physical Plan` 的编译路径, 依据底层数据精确的统计信息, 由优化器及运行时执行机制共同应用以下优化:

- **谓词下推 (Predicate Pushdown) 与分区剪枝 (Partition Pruning)**: 将 `WHERE` 过滤条件尽可能推向最底层的存储引擎, 提前在文件系统级甚至存储块 (Block) 级别过滤数据, 极大限度削减计算层的元组输入量.
- **投影剪枝 (Projection Pruning)**: 分析 AST 树, 仅拉取 SQL 涉及的物理列, 丢弃未使用的字段.
- **连接重排 (Join Reordering)**: 动态评估不同连接顺序下的中间结果集 (Cardinality) 大小, 利用贪心或动态规划算法推导代价最小的 JOIN 树结构 (如 Left-Deep Tree 还是 Bushy Tree).
- **运行时过滤 (Runtime Filtering)**: 在大表连接小表时, 由小表 (Build 侧) 在内存中快速构建布隆过滤器 (Bloom Filter), 实时下发到大表的扫描算子中. 其具体下推位置取决于执行引擎和存储层能力, 可动态应用在 Scan, Storage 或 Network Exchange 阶段, 以此剔除无效数据行.

### 2.4. 向量化执行 (Vectorized Execution)

第一篇中讨论指出, 传统关系数据库的火山模型以单次元组 (Tuple-at-a-time) 为粒度进行迭代, 在海量数据扫描时面临严重的性能瓶颈. 向量化执行引擎彻底颠覆了这一模型 [^6]. 它改变了算子之间的数据传递契约, 传递一个固定大小或批量大小的数据块 (例如数百至上千行, 常以 1024 行为典型 Vector 粒度).

- **硬件级 SIMD 利用**: 数据块在物理内存中连续紧凑排布. 计算算子通过流式处理, 使现代单条 SIMD (单指令多数据) 指令可以对多个数据元素执行同一种操作, 从而显着提高处理器的数据处理吞吐 [^6].
- **降低解释开销**: 将单次元组级别的虚函数深度调用, 摊薄为面向连续内存块的扁平循环, 大幅降低了查询执行时的指令开销与 CPU Cache Miss, 提升了 Cache Locality [^6].

## 3. 云原生数仓与 Lakehouse 现代范式

当分布式计算, 列式存储以及高效执行器在技术栈底层成熟后, 云计算基础设施的普及推动了企业数据分析平台走向全新的现代化范式.

### 3.1. 存算分离 (Storage/Compute Separation) 的革命

传统的 MPP Shared-Nothing 架构虽然实现了横向扩展, 但其存储和计算在物理节点上依然是深度绑定的. 云原生数仓彻底斩断了这一纽带, 实现了**存储与计算的强解耦 (Storage/Compute Separation)** [^7].

- **BigQuery 模式**: Dremel 是 Google 内部的大规模交互式分析系统, BigQuery 是其思想和技术路线的重要产品化延伸 [^8]. 它通过独立的持久化存储与弹性计算资源池, 将存储容量和查询计算能力解耦, 由服务负责根据查询负载动态分配计算资源, 实现完全 Serverless 化的按需分析 [^7].
- **Snowflake 架构**: 明确将其技术栈划分为共享对象存储层, 独立计算层 (虚拟数仓 Virtual Warehouses) 以及全局云服务管理层 [^9]. 不同的业务部门可以为不同的工作负载独立创建计算集群, 这些虚拟数仓属于独立的计算集群, 在计算工作负载上彼此隔离以减少资源争用, 同时共享同一套底层的低成本对象存储 [^9].

### 3.2. 开放表格式 (Open Table Format) 与 Medallion 架构分层治理

与此同时, 分析系统开始打破数据仓库与数据湖之间的边界, 全面迈向 **Lakehouse (湖仓一体)** 新阶段 [^10].

- **开放表格式的突围**: 仅依赖对象存储上的裸文件时, 分析系统难以在多个数据文件之间提供可靠的原子提交, 事务一致性和并发更新语义. Delta Lake, Apache Iceberg 等开放表格式 (Open Table Formats) 的出现, 重新在开放的对象存储上引入了数据治理契约. 两者都在底层对象存储之上增加了事务一致性, 快照式表状态管理以及 Schema 管理等能力, 从而使对象存储上的文件集合具备更接近数据库表的管理语义.
  - *Delta Lake*: 通过轻量级事务日志 (Transaction Log) 和硬性的 Schema 强约束 (Schema Enforcement) 确保端到端的 ACID 事务特性与快照回溯 (Time Travel) [^11].
  - *Apache Iceberg*: 摒弃了文件目录依赖, 通过快照 (Snapshots) 与清单元数据文件管理表状态, 原生提供独立的模式演进 (Schema Evolution) 与分区演进 (Partition Evolution) 支持 [^12].
- **Medallion Architecture 的分层多模式建模**: 在湖仓一体的工程实践中, 企业不再固守单一体制, 而是基于 Databricks 的 Medallion 架构这一数据设计模式 (Data Design Pattern), 开展分层建模策略, 体现了现代湖仓常见的分层, 多模式建模实践 [^13]:
  - *Bronze 层 (原始区)*: 保留历史各种结构化与半结构化 (JSON) 的原始变动流 (Schema-on-Read).
  - *Silver 层 (清洗区)*: 通过基础清洗, Schema 管理与演进对齐, 消除数据异常.
  - *Gold 层 (聚合区)*: 重新引入针对核心业务主题的强约束维度建模 (星型/雪花模型), 承接下游业务决策.

### 3.3. 从 ETL 到 ELT 的范式跃迁

由于云原生数仓和湖仓一体提供了强悍的算力弹性, 改变了计算资源的成本和获取方式, 数据平台管道的物理拓扑发生了重心转移, 在云数仓和湖仓环境中, **ELT (Extract, Load, Transform)** 成为越来越常见的主流范式之一 [^5]. 数据团队不再需要在外部第三方中间服务器里进行预清洗加工, 而是选择"先原样高速加载入湖, 再利用湖仓内部的分布式弹性算力, 进行高速并行清洗转换". 这释放了原始数据的敏捷度, 使上层分析人员可以根据需要动态重构数据加工策略任务.

## 4. 第二代 BI 的核心变化与新衍生技术债

分布式计算与云原生数仓时代的爆发, 为商业智能系统带来了空前的计算红利. 第二代 BI (以 Self-Service 自助式分析与分布式 Ad-hoc 查询为典型代表) 完成了底层的彻底蜕变: 分析的主导方式逐步从大量预计算 Cube 转向基于分布式 SQL 引擎的按需计算 (On-demand Running SQL), 同时保留缓存, 物化视图和预聚合等性能优化手段.

然而, 当技术栈底层成功解决了"算得快, 算得海量"的问题后, 上层的商业世界并没有变得完美, 反而由于计算壁垒的瓦解, 衍生出了全新的架构级技术债务:

### 4.1. 指标逻辑的碎片化与"指标地狱 (Metrics Hell)"

由于计算资源的廉价与弹性, 业务和分析人员获得了更大的 **Ad-hoc 查询自由度**. 然而, 由于整个平台缺乏一套与物理底座完全解耦的**跨系统统一抽象语义协议**, 大量业务人员在拖拽配置个性化看数看板时, 直接将复杂的商业聚合计算逻辑, 统计口径定义, 甚至是针对敏感数据的行级安全权限 (RLS), 直接硬编码在各自前端看板文件或下游胶水层 SQL 中.

### 4.2. 算得快 ≠ 算得对

- *销售团队* 在自己的 BI 前端看板里写了一段 SQL 逻辑: `SELECT SUM(revenue) FROM ... WHERE status = 'completed'`.
- *财务团队* 在自己的另一个独立可视化工具中写了另一段 SQL 逻辑: `SELECT SUM(revenue) FROM ... WHERE settlement_date IS NOT NULL`.

这两段底层的 SQL 逻辑同时运行在同一个极速的云数仓 (如 Snowflake) 上, 两个查询都可以快速返回结果. 但当两份报表汇报到高管办公会时, 针对同一个商业指标 (如"上月销售额"), 由于口径硬编码散落各处, 算出了两个完全冲突的技术数值.

## 5. 第二篇核心技术主张

> **分布式计算解决的是"算得动"和"算得快", 而不是"算得对". 当计算能力成为廉价而通用的基础设施后, 真正稀缺的资源反而从算力转变为可信的业务语义.**

分布式分析平台和云原生数仓的跨越, 彻底解决了"算不出来"的算力枷锁, 却由于缺乏集中的语义契约, 将企业推入了由于语义失控, 口径碎片化导致的"指标地狱 (Metrics Hell)". 这一全新技术债的爆发, 直接推动了下一代 Headless 独立语义层技术的崛起.

## 下一篇技术演进预告

算力的泛滥并没有消灭数据治理, 反而证明了缺乏统一契约的计算民主化只是一场混乱. 当企业厌倦了散落在数百个下游 Dashboard 中的碎片化 SQL 逻辑后, 商业智能的架构重心正式开启了它的第三次大跃迁: 将指标和业务语义彻底从前端 BI 看板的视觉网格中**剥离, 解耦并服务化**.

语义不再是 BI 工具的附庸, 而是变为了一个平台无关, API 优先, 定义一次到处运行的独立架构层. 这一层不仅解救了处于"指标地狱"中的企业, 更意外地为即将到来的大模型和智能体时代, 铺设好了连接企业确定性物理数据不可或缺的唯一通路.

我们在 **《第三篇: 现代数据栈与语义层 (Semantic Layer) 的重新崛起》** 中再见.

## 参考资料

[^1]: [MapReduce: Simplified Data Processing on Large Clusters](https://scholar.google.com/scholar?q=MapReduce+Simplified+Data+Processing+on+Large+Clusters+Dean+Ghemawat+2004) — Jeffrey Dean and Sanjay Ghemawat, *ACM SIGOPS Operating Systems Review*, 38(5):137-150, 2004. (支撑大规模分布式批处理, 数据本地性, 调度与容错特性的划时代文献)
[^2]: [Spark: Cluster Computing with Working Sets](https://dl.acm.org/doi/10.5555/1863103.1863113) — Matei Zaharia, Mosharaf Chowdhury, Michael J. Franklin, Scott Shenker, and Ion Stoica, *Proceedings of the 2nd USENIX Conference on Hot Topics in Cloud Computing (HotCloud)*, 2010. (正式提出内存计算 RDD 模型与 DAG 调度机制, 特定迭代机器学习任务中报告约 10 倍性能提升的里程碑学术论文)
[^3]: [C-Store: A Column-oriented DBMS](https://dl.acm.org/doi/10.5555/1083592.1083658) — Michael Stonebraker, Daniel Abadi, Adam Batkin, Xuedong Chen, Mitch Cherniack, Miguel Ferreira, Edmond Lau, Amerson Lin, Sam Madden, Elizabeth O'Neil, Pat O'Neil, Alex Rasin, Nghia Tran, and Stan Zdonik, *Proceedings of the 31st VLDB*, 553-564, 2005. (图灵奖得主团队关于面向分析型工作负载的列式存储设计, I/O 裁剪与压缩红利的经典学术理论出处)
[^4]: [Parallel Database Systems: The Future of High Performance Database Systems](https://dl.acm.org/doi/10.1145/129888.129894) — David DeWitt and Jim Gray, *Communications of the ACM*, 35(6):85-98, 1992. (系统定义并行数据库, 大规模并行处理 (MPP) Shared-Nothing 架构与分布式连接/数据重分布的经典文献)
[^5]: [An Overview of Data Warehousing and OLAP Technology](https://dl.acm.org/doi/10.1145/248603.248616) — Surajit Chaudhuri and Umeshwar Dayal, *ACM SIGMOD Record*, 26(1):65-74, 1997. (多维分析与查询优化器通用关系代数演进路径的核心总括性文献引用)
[^6]: [MonetDB/X100: a DBMS in the CPU Cache](https://scholar.google.com/scholar?q=MonetDB+X100+Zukowski+Boncz+2005) — Marcin Zukowski, Peter Boncz, Nesime Guerdan, and Michiel Heman, *IEEE International Conference on Data Engineering (ICDE)*, 2005. (打破火山模型单次元组迭代开销, 确立固定大小高密度数据块向量化执行和单条 SIMD 指令处理多个数据元素的权威学术论文)
[^7]: [Separation of storage and compute in BigQuery](https://cloud.google.com/blog/products/bigquery/separation-of-storage-and-compute-in-bigquery) — Srivas Vaidyanathan, Google Cloud Architectural Blog, 2017. (官方技术文献, 支撑云原生数据仓库计算与存储分离解耦及按需资源调度演进的断言)
[^8]: [Dremel: Interactive Analysis of Web-Scale Datasets](https://scholar.google.com/scholar?q=Dremel+Interactive+Analysis+Web-Scale+Datasets+Melnik+2010) — Sergey Melnik, Andrey Gubarev, Jing Jing Long, Geoffrey Romer, Shiva Shivakumar, Matt Tolton, and Theo Vassilakis, *Proceedings of the VLDB Endowment*, 3(1-2):330-339, 2010. (揭示 Google BigQuery 核心思想源头 Dremel 引擎的多级执行树及大规模分布式交互分析机制的奠基性文献)
[^9]: [The Snowflake Elastic Data Warehouse](https://dl.acm.org/doi/10.1145/2882903.2903741) — Benoit Dageville, Thierry Cruanes, Marcin Zukowski, Vadim Antonov, Artin Avanes, et al., *Proceedings of the ACM SIGMOD International Conference on Management of Data*, 215-226, 2016. (详尽解构云原生数据仓库多集群共享数据架构 (Multi-cluster Shared Data Architecture), 虚拟数仓独立计算集群工作负载隔离的官方技术白皮书)
[^10]: [Lakehouse: A New Generation of Open Platforms that Unify Data Warehousing and Data Lakes](https://scholar.google.com/scholar?q=Lakehouse+New+Generation+Open+Platforms+Unify+Data+Warehousing+Data+Lakes+Armbrust+2021) — Michael Armbrust, Ali Ghodsi, Reynold Xin, and Matei Zaharia, *Proceedings of the 11th Conference on Innovative Data Systems Research (CIDR)*, 2021. (支撑湖仓一体 (Lakehouse) 统一开放平台架构思想演进的基石论文引用)
[^11]: [Delta Lake: High-Performance ACID Table Storage over Cloud Object Stores](https://dl.acm.org/doi/10.14778/3415478.3415560) — Michael Armbrust, et al., *Proceedings of the VLDB Endowment*, 13(12):3411-3424, 2020. (专门支撑 Delta Lake 元数据轻量级事务日志及唯一模式强约束技术落地实践的出处)
[^12]: [Apache Iceberg Table Format Specification](https://iceberg.apache.org/spec/) — Apache Iceberg Project, Apache Software Foundation, 2025. (专门支撑 Iceberg 开源快照元数据, 独立模式与分区演进落地细节的工业官方规范)
[^13]: [What is the Medallion Design Pattern in a Lakehouse Architecture?](https://docs.databricks.com/aws/en/lakehouse/medallion) — Databricks Engineering, Databricks Production Documentation Guide, 2026. (专门支撑 Medallion 架构及湖仓分层治理生命周期职责划分的标准指南)
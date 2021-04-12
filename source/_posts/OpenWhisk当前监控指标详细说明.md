---
title: OpenWhisk当前监控指标详细说明
author: Bill Zong
tags:
  - openwhisk
  - serverless
categories:
  - Serverless
abbrlink: b265443c
date: 2021-04-09 23:30:00
---
## 背景

系统指标是通过`Kamon`的方式收集，其中`Controller`包含了`Kamon-Prometheus`后端和`Kamon System Metrics`等模块，所以数据可以直接汇集到`Prometheus`服务上。

当前 OpenWhisk 集群并没有集成 Prometheus 服务，仅在`standalone`模式下（jar包）集成了本地的`Prometheus`服务。其上报模式是通过启动 Docker 打包好的服务镜像，接收`Kafka`相关的`events`主题事件，再暴露`9095`端口给`Prometheus`。

目前，`ansible`部署的`playbook`中并没有这些服务，`openwhisk-deploy-kube`项目在部署上仅提供了系统指标、用户事件（指标）的收集开关，并没有部署`user-events`和`Prometheus`等服务。整体完成度相对较低，但可以进行改造以达成用户事件监控的目标。

---

## 流程说明

![ow-metrics.png](/images/pasted-2.png)


* 默认的`Controller`镜像使用的是`Akka HTTP`接口提供指标数据，并关闭了本地`Prometheus`服务。
    * 之所以这么做，应该是基于`Controller`存在多实例部署场景的考虑。毕竟`Prometheus`多实例管理不会自动形成集群。
* 其 HTTP 路径类似于`https://{{openwhisk-nginx-ingress-host-name}}/metrics`。
    * 安全起见，一般不会直接暴露`nginx`服务到公网环境。例如，`FDN`用了`edge-gateway`进行转发管理。目前该路径暂不支持。
* 用户事件和系统指标是分开提供的。

---

## 系统指标

### 获取方式

目前采用的方式较为繁琐，详细过程如下：

* 开启指标功能：
    * 在`openwhisk-deploy-kube`项目的`helm/openwhisk/values.yaml`文件下修改以下内容。（或者另外创建一个文件，替换这部分内容）

```
# Metrics
metrics:
  prometheusEnabled: true
  whiskconfigFile: "whiskconfig.conf" # 功能的详细配置，一般不修改
  kamonEnabled: true
  kamonTags: true
  userMetricsEnabled: true # 用户指标
```

* （重新）部署 OpenWhisk 集群
    * `helm install helm/openwhisk --namespace=openwhisk --name=owdev`
    * 其中`openwhisk`是命名空间，`owdev`是本次`Release`的名称，具体根据部署情况进行替换。
* 使用端口转发到本地：
    * `kubectl -n openwhisk port-forward svc/owdev-nginx 12345:443`
* 直接通过 HTTP 接口获取统计指标：
    * `https://localhost:12345/metrics`

在网页浏览器上我们能看到详细的指标内容，即本次试验成功。

### 已采集指标

```
# TYPE counter_database_cacheMiss_counter_total counter
# TYPE counter_controller_blockingActivation_start_total counter
# TYPE counter_database_cacheHit_counter_total counter
# TYPE counter_database_getDocument_start_total counter
# TYPE counter_controller_startup_counter_total counter
# TYPE counter_database_saveDocument_start_total counter
# TYPE counter_controller_loadbalancer_start_total counter
# TYPE counter_database_saveDocumentAttachment_start_total counter
# TYPE counter_http_put_counter_total counter
# TYPE counter_controller_kafka_start_total counter
# TYPE counter_loadbalancer_invokerState_counter_total counter
# TYPE counter_http_get_counter_total counter
# TYPE counter_database_queryView_start_total counter
# TYPE counter_loadbalancer_activations_counter_total counter
# TYPE counter_loadbalancer_completionAck_counter_total counter
# TYPE gauge_loadbalancer_totalOfflineInvokerManaged_counter gauge
# TYPE gauge_loadbalancer_totalHealthyInvokerManaged_counter gauge
# TYPE gauge_loadbalancer_totalUnresponsiveInvokerManaged_counter gauge
# TYPE jvm_class_loading gauge
# TYPE gauge_loadbalancer_memoryBlackboxInflight_counter gauge
# TYPE gauge_loadbalancer_totalCapacityManaged_counter gauge
# TYPE gauge_loadbalancer_totalUnhealthyInvokerBlackBox_counter gauge
# TYPE jvm_threads gauge
# TYPE gauge_loadbalancer_memoryManagedInflight_counter gauge
# TYPE gauge_loadbalancer_totalUnresponsiveInvokerBlackBox_counter gauge
# TYPE gauge_kafka_topic_counter gauge
# TYPE jvm_memory_buffer_pool_count gauge
# TYPE gauge_loadbalancer_activationsInflight_counter gauge
# TYPE gauge_loadbalancer_totalCapacityBlackBox_counter gauge
# TYPE gauge_loadbalancer_memoryInflight_counter gauge
# TYPE gauge_loadbalancer_totalUnhealthyInvokerManaged_counter gauge
# TYPE jvm_memory_buffer_pool_usage gauge
# TYPE gauge_loadbalancer_totalHealthyInvokerBlackBox_counter gauge
# TYPE gauge_loadbalancer_totalOfflineInvokerBlackBox_counter gauge
# TYPE histogram_database_saveDocument_finish_seconds histogram
# TYPE histogram_kafka_topic_start_seconds histogram
# TYPE jvm_gc_seconds histogram
# TYPE jvm_memory_bytes histogram
# TYPE jvm_gc_promotion histogram
# TYPE histogram_database_queryView_finish_seconds histogram
# TYPE histogram_controller_blockingActivation_finish_seconds histogram
# TYPE histogram_http_put_counter_seconds histogram
# TYPE histogram_http_get_counter_seconds histogram
# TYPE histogram_database_saveDocumentAttachment_finish_seconds histogram
# TYPE histogram_controller_loadbalancer_finish histogram
# TYPE histogram_database_getDocument_finish_seconds histogram
# TYPE histogram_controller_kafka_finish_seconds histogram
```

主要分类包括以下几种：

* JMX收集的信息
    * 包括内存、GC、线程、类等。
    * 因为`Sigar`服务未开启，所以无法获取 CPU、文件系统 等系统指标。
       * `Sigar`实例非线程安全。
       * CPU 指标采集时间低于1秒的情况下不准确。
* 网络IO
    * HTTP PUT/GET 的统计。
* 数据库
    * 缓存和文档读写统计。
* Controller
    * 跟 Kafka 交互的统计。
* LoadBalancer
    * Activation运行情况、内存使用情况、Invoker分类及健康状况等。

---

## 用户指标

暂时还没有可使用 helm 进行便利集群部署的功能。

目前的方案是使用`openwhisk docker-compose`进行本地部署：

* 在同一`docker-compose`网络内(默认为`openwhisk_default`)启动服务。
* 该服务会占用9095端口。
* 该服务会使用`/metrics`路径和`9095`端口给`Prometheus`提供数据。

后续会针对这块做部署改造，其思路同流程说明示意图中的`Monitor`和`Prometheus`模块。

---

## 参考资料

[OpenWhisk Metric Support](https://github.com/apache/openwhisk/blob/master/docs/metrics.md)
[OpenWhisk User Events](https://github.com/apache/openwhisk/blob/master/core/monitoring/user-events/README.md)
[Kamon](https://index.scala-lang.org/kamon-io/kamon/kamon-spray/0.2.1)
[System Metrics](https://kamon.io/docs/v1/instrumentation/system-metrics/)
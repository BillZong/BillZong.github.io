title: GraphQL API构建示例(2)
comments: true
abbrlink: f80ec8a1
categories:
  - 网络
tags:
  - GraphQL
  - protocol
  - network
date: 2021-04-08 22:52:00
---

## 概要

1. [设计一个`GraphQL schema`方案](./d3239b62.html)
2. **设计并实现一个存储数据的后端数据方案**
3. 实现一个从**1**翻译到**2**的解析器 
4. 实现API的授权

前文已经提了基本的示例需求描述，以及基本数据结构和方案。

当前这篇文章会从后端数据存储切入，更详细的剖析如何构建这个示例的 GraphQL 解决方案。

## 数据库选择

GraphQL 的查询内容，往往决定了后端的存储方式。所以找到一个合适的可以支持所有（尽可能全面的）GraphQL Queries 的数据库，是很关键的一步。

考虑到管理和扩容问题，尽量使用云服务。可选的方案有：

* NoSQL DB Service
    * 优势：存储规模自动伸缩
    * 劣势：所有数据集聚合查询时会异常地会特别困难，也就意味着在 SQL 中相对简单的`avg()`之类的查询在这里成了性能瓶颈。
* NoSQL DB Service + [Elasticsearch 分布式数据查询](https://github.com/elastic/elasticsearch)
    * 细节：NoSQL DB 负责数据存储和修改，`Elasticsearch`负责数据聚合。绝大部分查询使用`Elasticsearch`，少量直接使用数据`key`访问的查询使用 NoSQL DB。
    * 优势：高效的全文本查询。
    * 劣势：同步问题会增加复杂度。另外，`Elasticsearch`是开源实现，目前暂时没有`serverless`部署实现，需要自己配置部署并解决缩放问题。
* 云 SQL DB，如 Azure/Google Cloud/Amazon Aurora Serverless
    * 优势：适用于关系型数据
    * 劣势：全文本检索效率相对较低。特别是在分布式SQL DB上。

实际参考案例：
**Stack Overflow** 最初是架构在 SQL 全文检索上，当性能碰到天花板后，则将查询架构迁移到了`Elasticsearch`。

再回到具体的查询需求，进行更细致的分解：

* findLocation（byGPS）要求我们在定位半径范围内进行餐馆查询。
* 位置（类型）要求我们返回收藏餐馆的个数和平均评级。
* 有几个查询（包括子查询）返回分页响应。

考虑到用户可能会更倾向于使用名称而不是GPS坐标查询位置范围内的信息（全文检索），我们也更倾向于使用`Elasticsearch`来作为查询的基础架构。

我们将使用`ID`和类型（`LOCATION`或`REVIEW`）在单个表中实现每个记录（位置和评论）。 然后将其传输到`ElasticSearch Service`进行搜索。 大多数查询将由`ElasticSearch Service`处理，尽管有一些查询（例如，某个位置的评论的分页查询）将通过`NoSQL DB Service`查询完成。

## 实现数据存储层

对于存储层的架构，我们有几项技术可以参考。

* [amplify-cli](https://github.com/aws-amplify/amplify-cli)，`GraphQL API`模型映射和代码生成。
* [cloud formation](https://aws.amazon.com/cn/cloudformation/)，允许配置后端的资源，但无法配置前端的资源。
* [serverless framework](https://github.com/serverless/serverless)，前后端资源都支持，配置也相对容易。

至于其他的技术，暂时未调研可行性。但基本的参考思路是一致的。

`amplify-cli`的功能可以节约我们大量的开发工作。

以下是配置文件`serverless.yaml`，内容较长，故分段说明。

### Amazon Dynamo 数据库服务配置

```
DynamoDBTable:
 Type: AWS::DynamoDB::Table
 Properties:
   TableName: ${self:custom.api}
   KeySchema:
     - AttributeName: id
       KeyType: HASH
     - AttributeName: typeName
       KeyType: RANGE
   AttributeDefinitions:
     - AttributeName: id
       AttributeType: S
     - AttributeName: typeName
       AttributeType: S
   ProvisionedThroughput:
     ReadCapacityUnits: ${self:custom.ddb_readIOPS}
     WriteCapacityUnits: ${self:custom.ddb_writeIOPS}
   StreamSpecification: # 这个流配置是重要的触发器，即数据新增、更新、删除时，会触发并发送给流
     StreamViewType: NEW_AND_OLD_IMAGES
```

### 自定义配置项

```
custom:
  # The base name of the API for resource generation - can't include dashes
  # [a-zA-Z0-9]+ only
  api: ${self:provider.stage}RestaurantReviews
  # ES Domain, must match [a-z][a-z0-9\-]+
  es_domain: ${self:provider.stage}-restaurant-reviews
  # The number of instances to launch into the ElasticSearch domain
  es_instanceCount: 1
  # The type of instance to launch into the ElasticSearch domain
  es_instanceType: "t2.small.elasticsearch"
  # The size in GB of the EBS volumes that contain the data
  es_ebsVolumeGB: 20
  # The number of read IOPS the DynamoDB table should support.
  ddb_readIOPS: 5
  # The number of write IOPS the DynamoDB table should support.
  ddb_writeIOPS: 5
```

### ElasticSearch配置项

```
ElasticSearchStreamingLambdaIAMRole:
      Type: AWS::IAM::Role # 授权服务
      Properties:
        RoleName: ${self:custom.api}-ESStreamingLambdaRole
        AssumeRolePolicyDocument:
          Version: "2012-10-17"
          Statement:
            - Effect: Allow
              Principal:
                Service: "lambda.amazonaws.com"
              Action: "sts:AssumeRole"
        Policies:
          - PolicyName: ElasticSearchAccess
            PolicyDocument:
              Version: "2012-10-17"
              Statement:
                - Action:
                    - "es:ESHttpPost"
                  Effect: Allow
                  Resource:
                    - "arn:aws:es:#{AWS::Region}:#{AWS::AccountId}:domain/${self:custom.es_domain}/_bulk"
          - PolicyName: DynamoDBStreamAccess
            PolicyDocument:
              Version: "2012-10-17"
              Statement:
                - Action:
                    - "dynamodb:DescribeStream"
                    - "dynamodb:GetRecords"
                    - "dynamodb:GetShardIterator"
                    - "dynamodb:ListStreams"
                  Effect: Allow
                  Resource:
                    - { Fn::GetAtt: [ DynamoDBTable, StreamArn ]}
          - PolicyName: CloudWatchLogsAccess
            PolicyDocument:
              Version: "2012-10-17"
              Statement:
                - Action:
                    - "logs:CreateLogGroup"
                    - "logs:CreateLogStream"
                    - "logs:PutLogEvents"
                  Effect: Allow
                  Resource:
                    - "arn:aws:logs:#{AWS::Region}:#{AWS::AccountId}:*"
```

### Amazon Lambda function 配置

对应到OpenWhisk则是trigger

```
functions:
  dynamodb_stream:
    handler: elasticsearch.lambda_handler # 回调方法
    name: ${self:custom.api}-dynamodb_stream_handler
    description: Stream data from DynamoDB to ElasticSearch
    runtime: python3.6
    memorySize: 128
    role: ElasticSearchStreamingLambdaIAMRole # 授权角色
    environment:
      ES_ENDPOINT: { Fn::GetAtt: [ ElasticSearchDomain, DomainEndpoint ]}
      DEBUG: 1
    events:
      - stream:
          type: dynamodb
          arn: { Fn::GetAtt: [ DynamoDBTable, StreamArn ]}
```


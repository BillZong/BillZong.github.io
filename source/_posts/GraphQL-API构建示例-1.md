---
title: GraphQL API构建示例(1)
comments: true
abbrlink: d3239b62
date: 2021-04-08 22:52:15
categories: 网络
tags: 网络
---

## 概要

[前文](./facd8695.html)提到过`GraphQL API`的优点和一些粗浅介绍。然而知道怎么回事，不代表我们能正确地使用它，特别是一些新的技术思路。

本文的绝大部分内容来自Medium一位AWS移动端[知名博主](https://medium.com/open-graphql/building-a-graphql-api-by-example-restaurant-reviews-acd80d60ec77)。作者通过一个简单的示例来描述如何正确地构建`GraphQL API`服务，并尝试说明其步骤和一般性的原则。

因为文章很长，所以我们也会分段进行叙述。

### 老生常谈

为什么反复提及`GrapthQL API`？

这门技术可以减少我们在开发`REST`风格后端时，为适应变化的需求不断地修改代码，也减少了为不同的前端业务需求进行开发的复杂性。
从此，我们不再为此类架构日趋复杂的业务维护问题而头疼。

### 实际步骤

1. **设计一个`GraphQL schema`方案。**
2. 设计并实现一个存储数据的后端数据方案。
3. 实现一个从**1**翻译到**2**的解析器。 
4. 实现API的授权。

## 用例说明

后续的描述，将从一个简单的用例开始。

* APP需求描述:
    * 一个餐馆评论App
    * 作为餐馆老板，我希望能够在数据库中添加餐厅。
    * 作为已登陆用户，我希望能够在餐馆评级列表中添加评论。
    * 作为已登陆用户，我希望能收藏餐馆。
    * 作为未登陆的用户，我想搜索餐馆并查看他们的平均评分。
    * 作为已登陆的用户，我想阅读特定餐厅的评论。

## 构建“方案”

关于设计“方案”，我们有一些可以参考的基本步骤。

* 找出我们需要的原始数据类型。
* 将任何返回列表的内容调整为“分页”查询。
* 确定应用程序可能需要的合理操作。
* 写入查询所需的输入类型。
* 确定用户体验的实时更新要求。
* 确定安全性的授权要求。

### 原始数据类型

回归到之前的需求，我们可以分解其基本类型及行为。

* 用户
    * 获取自己添加的餐馆列表
    * 获取收藏的餐馆列表
    * 获取我填写的评论
* 餐馆位置
    * 获取关于该位置的相关评论
* 评论
    * 有评级和内容

直观地翻译成GraphQL，就输出了我们的第一版内容:

```
type User {
    id: ID! // 常规设计
    name: String
    locations: [Location] // 直接引用
    reviews: [Review] // 直接引用
    favorites: [Location] // 直接引用
}

type Location {
    id: ID! // 常规设计
    owner: String!
    longitude: Float
    latitude: Float
    address: String
    averageRating: Float
    favoritesCount: Int
    reviews: [Review] // 直接引用
}

type Review {
    id: ID! // 常规设计
    owner: User!
    location: Location! // 直接引用
    content: String!
    rating: Number!
}
```

这三者是相互依赖的，每种类型都与其他两种类型有联系。
如果是使用SQL模式，我们只会引用ID，确保表之间关联度尽可能地低。
但是，在GraphQL里，我们直接嵌入类型，以便进行查询。
例如，我们可以这样做：

```
query getUser(id: ID!) {
  name
  email
  favorites {
    id
    name
    averageRating
  }
}
```

在查询用户信息的同时获取我收藏的餐馆及它们的平均评级。
前端在组合这些复杂（甚至更复杂）查询（更新）业务时，可以比使用ID获得更多的灵活性。

### 分页支持

两类基本方案：

* `limit + nextToken`方式
    * 最常用方案
* `start + end`方式
    * 还要考虑列表越界处理

于是我们在`User`上添加相应的功能：

```
input PagingRequest { // 表示入参均为可选
    limit: Int // 如未设置，则任由后端返回任意数值
    nextToken: String // 如未设置，则请求的是第一页
}

type User {
    id: ID!
    name: String!
    email: String
    location(paging: PagingRequest) LocationPagingConnection
    reviews(paging: PagingRequest) ReviewPagingConnection
    favorites(paging: PagingRequest) LocationPagingConnection
}

type LocationPagingConnection {
    items: [Location]
    nextToken: String // 没有返回的情况下，则表示没有数据了
}

type ReviewPagingConnection {
    items: [Review]
    nextToken: String // 没有返回的情况下，则表示没有数据了
}
```

关于`input`的说明，可以参考更详细的[文档](https://graphql.org/graphql-js/mutations-and-input-types/)

### 定义操作

这部分内容是后端开发中最常修改的部分，因为前端业务总有改不完的需求。

但针对当前这个示例而言，我们可以显式地定义出这些需求：

* 获取“我的用户”记录（包括我记录下的位置，评论和收藏）
* 搜索位置（GPS、名称）
* 添加一个位置
* 添加评论
* 将地点标记为收藏

转成`GraphQL`:

```
type Query { // 查询
    me: User!
    searchForLocation(byGPS: GPSInput, byAddress: AddressInput): LocationPagingConnection
}

type Mutation { // 修改
    addLocation(location: LocationInput): Location
    addReview(review: ReviewInput): Review
    addFavorite(locationId: ID!): Location
}
```

### 编辑输入类型

将前面定义的`Query`和`Mutation`接口参数定义清楚：

```
input GPSInput {
  longitude: Float
  latitude: Float
  radius: Float
}

input AddressInput {
  street: String
  city: String
  state: String
  zipcode: String
}

input LocationInput {
  name: String
  address: AddressInput // 参数复用!
}

input ReviewInput {
  locationId: ID!
  content: String!
  rating: Number!
}
```

更合适的映射方式是采用[Prisma](https://github.com/prisma/prisma)这类GraphQL后端数据引擎，这里暂时不做赘述。

### 实时数据分发

这个步骤主要是为了提升用户体验。

实时数据的方案一般是通过`WebSocket`订阅进行支持的。

在当前需求下，我们想更新用户在更新时所查看的位置，因为其中包含评级和收藏夹计数：

```
type Subscription {
  updatedLocation(locationId: ID!): Location
  @aws_subscribe(mutations: [ "addReview", "addFavorite" ]) // 云厂商的实时数据订阅
}
```

具体的`GraphQL server`实现，有不同的实时数据订阅设置。这里暂时不做赘述，go语言版本可参考[这个链接](https://outcrawl.com/go-graphql-realtime-chat)，基本思路就是使用`chan`来传递消息。

### 身份验证和授权

当前的接口需要根据业务，定义好哪些需要身份验证后才能访问的。一般而言，需要`mutation`和`subscription`的都需要身份验证，而部分非敏感数据的`query`都不需要身份验证。

大部分server实现都可以通过添加中间件，或者库的方式，接管身份和注册身份验证组建。所以在接口层面，不需要考虑太多信息，把接口文档标识清楚即可。


## 补充说明

本文是个系列，下篇会切换到其它主题，并进行扩展延伸。
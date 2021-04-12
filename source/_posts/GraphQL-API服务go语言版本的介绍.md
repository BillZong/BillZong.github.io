title: GraphQL API服务go语言版本的介绍
comments: true
abbrlink: facd8695
categories:
  - 网络
tags:
  - GraphQL
  - protocol
  - network
date: 2021-04-08 22:50:00
---

## GraphQL API 是什么
GraphQL 是一个用于 API 的查询语言，是一个使用基于类型系统来执行查询的服务端运行时（类型系统由你的数据定义）。GraphQL 并没有和任何特定数据库或者存储引擎绑定，而是依靠你现有的代码和数据支撑。

优势：

* 不多不少，只请求你所要的数据
* 只用一个请求，获取多个资源
* 类型系统，描述所有的可能

有需要的童鞋可以了解一下[详细的语法规范](http://spec.graphql.cn/)。

关于 GraphQL 的基本介绍和为什么选择 GraphQL，官方文档有相应的介绍，有兴趣的童鞋可以去看看。这里就不一一赘述了。

## 如何引入

引入 GraphQL API 在移动端后台架构是一个节约流量、提升性能、提高灵活性的不错选择。但怎么在已有的代码、框架中，引入这种编程模型接口，值得我们思考一番。

幸运的是，开源社区已经为我们做了不少工作。GraphQL有众多语言版本的服务端库实现，当然也包括 go 语言。

其中比较知名也比较成熟的库[graphql](https://github.com/graphql-go/graphql)，直接就可以集成。

当然，部分开源网络框架，如[iris](https://github.com/kataras/iris)，是通过中间件的方式进行注册使用的。
对于这种网络框架，我们需要将这些 API 库解析器作为中间件的方式连接上去，再绑定到接口上，就能节约大量的集成工作。

## 示例代码

```go
func main() {
   // 这里定义了 hello 字段和相应的返回结果
	fields := graphql.Fields{
		"hello": &graphql.Field{
			Type: graphql.String,
			Resolve: func(p graphql.ResolveParams) (interface{}, error) {
				return "world", nil
			},
		},
	}
	// 创建schema
	rootQuery := graphql.ObjectConfig{Name: "RootQuery", Fields: fields}
	schemaConfig := graphql.SchemaConfig{Query: graphql.NewObject(rootQuery)}
	schema, _ := graphql.NewSchema(schemaConfig)

	// 模拟一个 GraphQL query
	query := `
		{
			hello
		}
	`
	// 解析参数
	params := graphql.Params{Schema: schema, RequestString: query}
	r := graphql.Do(params) // 执行，这里忽略了错误处理
	rJSON, _ := json.Marshal(r) // rJSON = {“data”:{“hello”:”world”}}
}
```

考虑到支持原有 jSON 对象查询的方式，可以在目前已有的接口上增加一个顶层路径`/graphql`，对于该路径下的操作，支持 GraphQL API 操作，也是个不错的选择。示例如下：

```go
func main() {
	http.HandleFunc("/graphql", func(w http.ResponseWriter, r *http.Request) {
		result := executeQuery(r.URL.Query().Get("query"), schema) // 使用已创建好的域进行查询解析
		json.NewEncoder(w).Encode(result)
	})
	// Serve static files
	fs := http.FileServer(http.Dir("static"))
	http.Handle("/", fs)

	http.ListenAndServe(":8080", nil)
}
```

## 重点、难点

* 解耦业务逻辑
* 分解域

当集成不成问题后，怎么在原来业务代码里将逻辑解耦，重新组装成域，并提供相应的查询、更新业务支持，就成了我们接下去要解决的问题。

预知后事如何，且听下回分解。
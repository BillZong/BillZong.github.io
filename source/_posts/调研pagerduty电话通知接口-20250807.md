---
title: 调研 PagerDuty 电话通知接口
tags:
  - PagerDuty
  - 告警
  - 电话通知
  - 语音通知
  - 运维
  - 选型
  - 安全
  - Webhook
  - 事件管理
categories:
  - 安全
abbrlink: a7c3d9e1
date: 2025-08-07 18:00:00
---

# pagerduty

## 文档链接
https://support.pagerduty.com/main/docs/

## 创建 API Access Keys
- Integrations -> Developer Tools -> API Access Keys

## 创建 service
- 设置 escalation policy ，当事件触发时，谁值班就是会推给谁

## 推送事件
```go
func Test_Create(t *testing.T) {
	resp, err := client.CreateIncidentWithContext(context.TODO(), "winary@hepu.org", &pagerduty.CreateIncidentOptions{
		Title:            "this is title",
		Service:          &pagerduty.APIReference{ID: "PVFPQRI", Type: "service_reference"},           // 网页 url 中获取
		EscalationPolicy: &pagerduty.APIReference{ID: "PSGD0FT", Type: "escalation_policy_reference"}, // 网页 url 中获取
		Priority:         &pagerduty.APIReference{ID: "PFASJ15", Type: "priority_reference"},          // p1/p2，通过 ListPrioritiesWithContext
		Urgency:          "high",                                                                      // high/low
		IncidentKey:      fmt.Sprintf("IncidentKey-%d", time.Now().UnixMilli()), // 唯一 key
		Body: &pagerduty.APIDetails{
			Type:    "incident_body",
			Details: "Details of the incident...",
		},
		// Assignments: []pagerduty.Assignee{
		// 	{
		// 		Assignee: pagerduty.APIObject{ID: "P8VEFND", Type: "user_reference"},
		// 	},
		// }, // 不能与 EscalationPolicy 同时存在
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Incident ID: %s\n", resp.ID)
}
```

## webhook -> 打电话
- https://support.pagerduty.com/main/docs/webhooks
- 创建时可选推送哪些事件
- 需要起一个服务端程序，接收事件，再通过 pagerduty api 获取电话号码
- 调用阿里云服务进行语音播报
```go
func Test_ListUsers(t *testing.T) {
	users, err := client.ListUsersWithContext(context.TODO(), pagerduty.ListUsersOptions{})
	if err != nil {
		t.Fatal(err)
	}
	for _, p := range users.Users {
		fmt.Printf("%s\n\n\n", jsonDataIndent(p))
	}
}
// 获取联系方式
func Test_GetUserContactMethod(t *testing.T) {
	dat, err := client.GetUserContactMethodWithContext(context.Background(), "P8VEFND", "PTH6A14")
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%s", jsonDataIndent(dat))
}
```

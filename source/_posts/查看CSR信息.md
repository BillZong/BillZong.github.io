title: 查看CSR信息
comments: true
abbrlink: 1eec93ef
categories:
  - 网络
tags:
  - certificate
date: 2021-04-08 23:24:00
---

## 查看CSR信息

> openssl req -noout -text -in myCert.crt # 或者 openssl req -noout -text -in myCert.csr

其中，要关注的重点包括

`X509v3 Subject Alternative Name`

`X509v3 Certificate Policies`

`Signed Certificate Timestamp`
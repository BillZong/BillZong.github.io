title: 阿里云腾讯云OpenWhisk性能测试方案
author: Bill Zong
abbrlink: d13f2d70
tags:
  - OpenWhisk
  - performance
categories:
  - Serverless
date: 2021-04-11 16:38:00
---
```
python3 -m pip install vitualenv
```

## 阿里云-独享

```
locust --host=https://172.16.2.34:31001 --no-web -t 5m -r 10 -c 1
```

## 阿里云

```
locust --host=https://10.0.2.37:32387 --no-web -t 5m -r 10 -c 1
```

## 腾讯云

```
locust --host=https://172.21.48.6 --no-web -t 5m -r 10 -c 1
```
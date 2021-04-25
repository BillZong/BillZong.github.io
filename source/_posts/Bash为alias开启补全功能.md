---
title: Bash为alias开启补全功能
author: Bill Zong
tags:
  - bash
  - completion
categories:
  - Shell
abbrlink: ae364355
date: 2021-04-25 22:02:00
---
## 别名命令补全功能

```
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
```

同理，其它具备补全功能的命令也可以针对其别名提供补全。
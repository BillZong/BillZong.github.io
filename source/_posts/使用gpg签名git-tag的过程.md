---
title: 使用gpg签名git tag的过程
comments: true
abbrlink: '44e52148'
date: 2021-04-08 00:33:11
categories: 版本管理工具
tags: 版本管理工具
---

## 背景

开源项目在协作的过程中，很多都是远程贡献者，彼此间都互不认识。如何保证相互间的信任、确认身份、确保安全问题，是其中的重点。

而 git 在比 svn 更开放的同时，也缺失了权限控制，如何对成员进行鉴别，以确保少量用户具备直接操作权限，是其中的难点。

目前权限这块，都是利用GitHub、Gitlab、BitBucket等平台的账户权限管理。而身份证明基本都是用电子签名，并将签名公钥公布在社区内，由社区成员或基金会进行审核确认。

通过审核后，作为项目代码的直接提交者，所有的代码提交都需要经过签名认证，以确保是本人操作。一般而言，GitHub、Gitlab这类开源平台会在绑定账号公钥后处理这类工作，其认证原理类似于 ssh 的授信。

而给仓库打标签一般属于项目管理员的行为，其身份认证更为重要，必然需要进行签名以自证身份。

平时我们直接打标签 `git tag`，是无签名模式，在对作者认证时是无法通过的 `git tag -v 标签名`。

## 完成流程

* 安装GnuPG，以下简称GPG。
    * [下载路径](https://gnupg.org/download/)，然后放到系统PATH中。
    * 或者使用Homebrew安装。
* 使用gpg生成key。
    * 已存在有效key且同git账户相同，直接跳过。
    * 生成后key后，每个key都有自己的ID。

```
gpg --gen-key # 然后输入git仓库（例如GitHub）账户名称、邮箱，最后是签名密码。
```

* 配置git签名key。

```
git config --global user.signingkey 签名key的ID
```

* 给git仓库打标签并签名。

```
git tag -s -m '提交日志' # 终端首次签名需要输入签名密码
```

## 解决签名失败

在 Mac 上，如果你碰到git tag签名失败，有几个原因：

* gpg证书的名称、邮箱与你设置为全局的名称、邮箱不符。

查看git全局配置

```
git config --global -l
```

修改全局配置

```
git config --global user.name=账号名称
git config --global user.email=邮箱
```

* gpg证书的ID设置不对，或者已过期。

查看gpg的keyID
```
gpg --list-keys # 查看长ID
gpg -K --keyid-format SHORT # 或者查看短ID
```

短ID指令获得结果如下：

```
sec   rsa2048/A6D9D1A8 2019-08-14 [SC] [expires: 2021-08-13]
      12B7104B2EC168B55A0FE6DD9A341BB3A6D9D1A8
uid         [ultimate] BillZong <billzong@163.com>
ssb   rsa2048/7CB344A2 2019-08-14 [E] [expires: 2021-08-13]
```

短ID为：`A6D9D1A8`
长ID为：`12B7104B2EC168B55A0FE6DD9A341BB3A6D9D1A8`

将短ID或长ID设置到git配置中：

```
git config --global user.signingkey A6D9D1A8
```

* gpg守护进程异常。

```
killall gpg-agent && gpg-agent --daemon --pinentry-program /usr/local/bin/pinentry

# 过期指令
# killall gpg-agent && gpg-agent --daemon --use-standard-socket --pinentry-program /usr/local/bin/pinentry
```

## 参考资料

* [Git Tools - Signing Your Work](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
* [gpg failed to sign the data fatal: failed to write commit object \[Git 2.10.0]](https://stackoverflow.com/questions/39494631/gpg-failed-to-sign-the-data-fatal-failed-to-write-commit-object-git-2-10-0)


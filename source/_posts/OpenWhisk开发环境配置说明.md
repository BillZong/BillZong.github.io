title: OpenWhisk开发环境配置说明
author: Bill Zong
abbrlink: 73ccc9b4
tags:
  - OpenWhisk
  - develop
categories:
  - Serverless
date: 2021-04-11 16:33:00
---
这里描述的内容为本人自测通过的信息，其它平台建议在社区或者其它渠道查找。

---

## 开发环境

* 系统
    * Mac 10.15 beta

* Java
    * 下载[JDK 8](https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)，并安装到本地机器。
    * 使用**HomeBrew**安装管理 Java 版本。

```
brew install jenv

# 添加这部分内容到你使用的 shell rc 或者 profile 文件中，如 ~/.bashrc 或 ~/.bash_profile
# Init jenv
if which jenv > /dev/null; then eval "$(jenv init -)"; fi

# source 上边的配置文件，或者重新打开一个终端，完成后输入下面这行指令
jenv add /Library/Java/JavaVirtualMachines/jdk1.8.0_221.jdk/Contents/Home/

# 查看当前java版本，能看到除了系统默认的 Java 11，还有刚安装的 Java 8
jenv versions

# 切换全局版本到 Java 8
jenv global 1.8.0.221

# 如果你想在某些工程里使用回系统的高版本，如 Java 11，可切换到该工程，并进行下面的设置
cd my_project
jenv local 11
```

* Scala
    * 使用**HomeBrew**安装，方便本地`REPL`调试。`brew install scala`
    * 目前本人安装的版本是`stable 2.13.0`。
    * 你也可以使用`brew install scala@2.12`安装旧版本。

---

## 开发工具

* IntelliJ IDEA
    * 版本：ULTIMATE 2018.3
    * 自行解决`Hack`问题，或者使用社区版本。
* 安装 Scala 插件
    * `Preferences => Plugins`。
    * 安装后重启 IDE。

---

## 项目设置

* 下载[OpenWhisk工程](https://github.com/apache/openwhisk)到本地。
* 使用 IDEA 打开项目目录，并做好如下配置。
    * 打开`Preferences => Build,Execution,Deployment => Build Tools => Gradle`。
    * 修改`Gradle JVM`为我们前面下载的`JDK 8`目录，一般情况下为 `/Library/Java/JavaVirtualMachines/jdk1.8.0_221.jdk/Contents/Home`。
    * 打开`Preferences => Build,Execution,Deployment => Compiler => Java Compiler`。
    * 修改`Project bytecode version`为**8**。
    * 点击`OK`，随即完成设置。

具体设置说明：

1. OpenWhisk项目是使用`Maven`进行构建的。
2. 该项目的代码在使用`Scala 1.12`及以上版本后，要求必须使用`JDK 8`进行构建，其它版本会失败。

---

## 项目构建

* 打开`Maven`面板，刷新一下项目。
* 找到我们要开发和测试的某个模块，执行`build`构建（下载依赖，编译等），然后再执行`testClass`。
* 如果可以看到任务正常执行完成，且测试通过，则认为项目构建流程全部跑完。剩下来的就是继续“打码”了。

---

## 参考文档

* [GETTING STARTED WITH SCALA IN INTELLIJ](https://docs.scala-lang.org/getting-started/intellij-track/getting-started-with-scala-in-intellij.html)
* [Install Multiple Java Versions on Mac](http://davidcai.github.io/blog/posts/install-multiple-jdk-on-mac/)

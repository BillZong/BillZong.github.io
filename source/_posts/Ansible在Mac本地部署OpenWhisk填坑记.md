title: Ansible在Mac本地部署OpenWhisk填坑记
author: Bill Zong
abbrlink: 81965e0a
tags:
  - OpenWhisk
  - ansible
  - deploy
categories:
  - Serverless
date: 2021-04-11 16:31:00
---
## 背景

### 目的

本地开发调试用，非此目的不建议轻易尝试入坑。

另外，执行测试必须将环境部署起来。

### 系统说明

本人使用的是 MacOS 10.15 Beta 系统。
其它系统暂未测试，未确定实际效果。

### 背景知识

建议阅读少量`Ansible`的[文档](https://www.ansible.com/)，了解一些基本的概念。

---

## 环境准备

本地需要的一些工具和环境。其中版本参考的是本地的，部分标注**必须**，说明该版本不可修改。包括：

* Docker 18.09.1
* Java 8 or Open JDK 8 **必须**
* Scala 2.13.0
* Ansible 2.8.4

这里，JDK版本之所以使用8，是因为`Scala 2.12`以上版本开启`JVM`时依赖的版本问题。目前`JDK11`无法通过编译，不建议安装。

### 安装HomeBrew

Mac上应用/包/库管理最好用的工具。使用`HomeBrew`安装整个环境依赖是最方面的。

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

后续的工作也基本依赖于此。童鞋们如何有其它途径也可补充说明。

Linux平台也支持了，详细参考[这篇文章](https://docs.brew.sh/Homebrew-on-Linux)。

### 安装JDK8

Mac系统中同时安装JDK8及其它版本，并切换维护的说明请参考[此文档](https://lexiangla.com/teams/k100002/docs/87f7b8e2c89511e98f860a58ac1306e6?lxref=search-company&company_from=0afec89eb58611e8974552540005f435)。

### 安装Scala

```bash
brew install scala
brew install gnu-tar # 方便后面解压缩tar包用
```

### 安装pip

如果本地`pip`未安装，如Mac系统的2.7版本，并不会预先安装`pip`。

则需要执行下面的命令：

```bash
python -m ensurepip --default-pip
# 查看当前pip的信息
python -m pip -V
```

**如果之前使用过其它工具安装配置过`Python`，如`HomeBrew`、`pyenv`等，建议将其清理以确保系统Python路径不受到干扰。**

### 安装docker、ansible等工具和库

之所以不使用`python -m venv`创建个隔离环境来安装，是由于本人环境配置不当导致只能使用系统的`Python`路径。

```bash
python -m pip install docker --user
python -m pip install ansible --user
python -m pip install couchdb --user
python -m pip install httplib2 --user
```

目前，并没有强制要求哪些指定版本，所以直接执行即可。

**如果之前使用过其它`Python`版本（如3.x），并执行过`ansible-playbook`任务，需要到上次执行的`ansible`目录下，将已经编译过的`pyc`文件删除，才能正常运行。**

---

## 基本流程

基本过程如下：

* 编辑代码
    * 包括完成编译、通过单元测试等。
* 打包镜像
    * 进入项目根目录，执行`./gradlew distDocker`完成所有镜像打包。
        * 目前科学上网环境下，`ow-utils`依然会打包失败，建议直接跳过，使用网络镜像即可。
        * `Gradle`编译的语法和结构又有不少的坑在里边，目前不做理会。
    * 进入项目根目录，执行`./gradlew :core:invoker:distDocker`，则仅打包`Invoker`镜像。
        * 具体的任务路径请参考项目`gradle`文件。
* 使用`ansible`部署/替换镜像

### 从头开始部署

```
export OPENWHISK_HOME=$PWD # 可以不执行，因为项目已默认使用项目根目录设置为openwhisk_home

cd ansible
export ENVIRONMENT="local"

sudo ifconfig lo0 alias 172.17.0.1/24 # 每次电脑重启后必须执行，本地Docker的host都是指向该IP的
```

* 必须进入该目录，才能正常执行`ansible`任务。
    * 如果添加了环境变量`OPENWHISK_HOME`，执行目录不受限制。
* 目前选择的环境是`local`，也是`ansible`默认环境。
    * 如果选择的是`local`，后面所有指令中`-i environments/$ENVIRONMENT`都可以省略。
    * 其它环境的选择目前超出本文讨论范围。

#### 初始化

使用模板将本地配置环境部署好。

```
ansible-playbook -i environments/$ENVIRONMENT setup.yml
```

#### 修改部分配置

* 不再下载本地已有Docker镜像，加快部署速度。
    * 其中后面两项配置项需要使用`master`分支最新的内容才有效。——已提交PR并合入。

```
# 新增内容：
# ansible/environments/local/group_vars/all
couchdb:
  pull_couchdb: false
apigateway_local_build: true
kafka:
  pull_kafka: false
zookeeper:
  pull_zookeeper: false
skip_pull_runtimes: true # 不拉取运行时镜像
```

* （只）使用本地已有的`RunTime`镜像，编辑个`runtimes.json`文件，**放到仓库里**，格式如下：
    * 该文件路径要放到`ansible/files`目录，或者不在`ansible`目录下，否则会加载失败并警告（后续运行时环境无法启动）。

```
{
  "runtimes": {
    "nodejs": [
      {
        "kind": "nodejs:10",
        "default": true,
        "image": {
          "prefix": "openwhisk",
          "name": "action-nodejs-v10",
          "tag": "local-v0.1"
        },
        "deprecated": false,
        "attached": {
          "attachmentName": "codefile",
          "attachmentType": "text/plain"
        },
        "stemCells": [
          {
            "count": 2,
            "memory": "128 MB"
          }
        ]
      }
    ]
  },
  "blackboxes": [
    {
      "prefix": "openwhisk",
      "name": "dockerskeleton",
      "tag": "local-v0.1"
    }
  ]
}
```

* 在配置文件里修改`runtimes.json`的路径，使本地部署配置加载本地镜像，加快部署速度。

```
# 新增内容：
# ansible/environments/local/group_vars/all
manifest_file: "/runtimes.json" # 你刚刚保存的文件相对于项目根目录的路径
```

#### 继续安装

```
ansible-playbook -i environments/$ENVIRONMENT couchdb.yml
ansible-playbook -i environments/$ENVIRONMENT initdb.yml
ansible-playbook -i environments/$ENVIRONMENT wipe.yml
ansible-playbook -i environments/$ENVIRONMENT openwhisk.yml
```

* 如果需要新的CouchDB部署，我们每次需要执行`initdb.yml`。
* 如果你只是想重启服务，并不打算重新创建CouchDB，可以不执行`wipe.yml`。

*使用`d4d7ceb6`及更早提交点的代码，部署期间有个任务存在问题，导致部署失败。修复完成，已提交PR并合入。*

#### 部署Catalog和APIGateway

```
# 一些“预安装”的package
ansible-playbook -i environments/$ENVIRONMENT postdeploy.yml

# API Gateway 必备
ansible-playbook -i environments/$ENVIRONMENT apigateway.yml
ansible-playbook -i environments/$ENVIRONMENT routemgmt.yml
```

### 更新部分组件

我们在开发完`Controller`或者`Invoker`项目后，需要放到整个环境中查看一下执行情况是否跟预期吻合。因我们没有设置`CI`环境，目前需要手动编译打包部署。

其流程基本如上描述。

但是，在已启动了整个集群的本地环境中，我们只需要更新该组件即可，而不用将流程重新走一遍。

#### 打包镜像

* 将改动相关的模块重新打包镜像，执行`Gradle`任务。
    * 指定标签。

```
cd <openwhisk_home>
gradle :core:invoker:distDocker -PdockerImageTag=myNewInvoker
```

* 将新打包好的镜像替换上去

```
cd ansible
ansible-playbook -i environments/$ENVIRONMENT invoker.yml -e docker_image_tag=myNewInvoker
```

---

## 参考资料

* [Setting up OpenWhisk with Docker for Mac](https://github.com/apache/openwhisk/blob/master/tools/macos/README.md)
* [Deploying OpenWhisk using Ansible](https://github.com/apache/openwhisk/blob/master/ansible/README.md)
* [Ansible Documentation](https://docs.ansible.com/ansible/latest/index.html)
* [Running Tests](https://github.com/apache/openwhisk/tree/master/tests)
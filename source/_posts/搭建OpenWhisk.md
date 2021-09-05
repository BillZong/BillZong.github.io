title: 搭建OpenWhisk
author: Bill Zong
abbrlink: d6ffd7c3
tags:
  - OpenWhisk
  - deploy
categories:
  - Serverless
date: 2021-04-11 16:36:00
---
# 在云上购买机器

* 命名master为 btc-001
* 命令worker为 eth-001 eth-002 eth-003
* 这些机器全部使用了私网ip
* 前端部署负载均衡，ip为 10.1.2.3
    * 文中涉及到这个ip的地方都需要替换

* 这里购买了一个nfs，地址为 259ae4bcd9-gos35.cn-shenzhen.nas.aliyuncs.com
    * 文中涉及到这个nfs地址的地方都需要替换



# 登录每台机器，关闭swap分区，安装工具软件

```
#!/bin/bash
# turnoff swap (no need to reboot)
swapoff -a && sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# prepare install utils
apt-get -y update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# install docker ce
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y update
apt-get install -y docker-ce=5:18.09.2~3-0~ubuntu-bionic

# install kubeadm
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
add-apt-repository "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main"
apt-get -y update
apt-get install -y kubernetes-cni=0.6.0-00
apt-get install -y kubelet=1.13.3-00
apt-get install -y kubectl=1.13.3-00
apt-get install -y kubeadm=1.13.3-00 
```

# trick： 可能需要手动下载镜像（因为墙的关系，可能无法下载到k8s的所有的image）
* 这里跳过

# 在master上通过kubeadm初始化集群

```保存为配置文件 kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: 1.13.3
networking:
  podSubnet: "10.244.0.0/16"
apiServer:
  certSANs:
  - 10.1.2.3
```

* 注意上面的podSubnet无需修改，certSANs需要修改为你的前端负载均衡ip

```
kubeadm init --config=kubeadm-config.yaml
# 注意此命令运行完毕后会打印出一条加入命令，这条加入命令将在worker上执行（后续步骤中提示）
# 打印出来的命令格式如下： kubeadm join ... --token ... --discovery-token-ca-cert-hash ...
# 请将此命令保存好
```

# 在master上配置kubectl

```
# 执行以下命令后，就可以在master上直接执行kubectl命令了
mkdir -p ${HOME}/.kube && cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config && chown $(id -u):$(id -g) ${HOME}/.kube/config
```

# 配置网络，在master上执行以下命令

```
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/canal/rbac.yaml
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/canal/canal.yaml
```

# 在worker节点上执行命令，加入master初始化好的k8s集群

```
# 执行上文中“在master上通过kubeadm初始化集群”输出的命令
kubeadm join ... --token ... --discovery-token-ca-cert-hash ...
```

# 至此，集群安装结束，等待若干分钟后，在master上通过命令可以查看各个节点状态 

```
kubectl get nodes
# 如果看到全部ready，则说明集群已经初始化完毕
```

# 接下里的操作全部是在本地上执行的

# 安装helm
* 注意helm需要一个配置好的kubectl，我们可以选在在本地配置好kubectl。

```
# 把master上的 ~/.kube/config 拷贝到本地 ~/.kube/config即可
scp btc:~/.kube/config ~/.kube/config
# 注意同时还需要将负载均衡的6443端口转发到master的6443端口
```

* 下载helm

```
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.3-darwin-amd64.tar.gz
# 加压缩并添加到path中
```

* 配置helm，执行以下命令（请注意这里需要翻墙）
```
helm init
kubectl create clusterrolebinding tiller-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
```

# 通过helm来搭建openwhisk集群

* 首先需要配置worker角色

```
kubectl label nodes eth-001 openwhisk-role=invoker
kubectl label nodes eth-002 openwhisk-role=invoker
kubectl label nodes eth-003 openwhisk-role=invoker
```

* 配置持久化存储（这里需要在云服务商处购买nfs存储）

``` 编写配置文件，命令为 openwhisk-nfs-client-provisioner.yaml，注意修改server地址的配置
nfs:
   server: 259ae4bcd9-gos35.cn-shenzhen.nas.aliyuncs.com
   path: /

storageClass:
   name: openwhisk-nfs
   reclaimPolicy: Delete
```

# 通过helm在k8s中安装存储的storage class
* 注意，我们首先需要在所有的worker机器上安装mount nfs的命令
```
apt-get install -y nfs-common
```

* 然后继续安装

```
helm install --namespace openwhisk --values openwhisk-nfs-client-provisioner.yaml stable/nfs-client-provisioner
```

* 获取openwhisk的部署配置文件

```
git clone https://github.com/apache/incubator-openwhisk-deploy-kube
cd incubator-openwhisk-deploy-kube
# 注意这里我们使用给一个老的版本的openwhisk部署
git checkout 89f1787
```

* 编写openwhisk helm部署的配置文件

``` 保存为owdev.yaml
whisk:
  ingress:
    apiHostName: 10.1.2.3
  limits:
    actionsInvokesPerminute: 999999
    actionsInvokesConcurrent: 999999
    triggersFiresPerminute: 999999
    actionsSequenceMaxlength: 999999

k8s:
  persistence:
    enabled: true
    hasDefaultStorageClass: false
    explicitStorageClass: openwhisk-nfs
```

# 执行helm部署命令

```
helm install ./helm/openwhisk --namespace=openwhisk --name=owdev -f owdev.yaml
```

* 等到所有的pod完成执行即可


# 部署ingress

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml

# 通过 kubectl -ningress-nginx get pods 来查看nginx是否正常启动
```
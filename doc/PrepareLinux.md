# 准备部署环境

本指南主要涵盖Docker软件安装、交换空间配置以及关闭防火墙这三个方面。如果您对这些基本配置已经很熟悉，可以直接跳过本指南。

## 安装Docker环境(CentOS 6/7)

先升级 yum 源

```shell
yum update -y
```

下载 docker 安装脚本

```shell
curl -fsSL https://get.docker.com -o get-docker.sh
```

运行安装 docker 的脚本

```shell
sudo sh get-docker.sh
```

启动 docker

```shell
systemctl enable docker
systemctl restart docker
```

关闭防火墙

```shell
systemctl disable firewalld
systemctl stop firewalld
```

关闭 selinux

```shell
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
```

## 配置交换空间（若内存不足 8GB）

创建 Swap 文件

```shell
which /usr/bin/fallocate && /usr/bin/fallocate --length 8GiB /var/swap.1 || /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=8000
mkswap /var/swap.1
swapon /var/swap.1
sed -i '$a /var/swap.1 swap swap default 0 0' /etc/fstab
```

查看系统是否已启用 Swap

```shell
sysctl vm.swappiness
```

如果输出最后的数字不为 0，则代表已经启用 Swap，可不做处理。

如果输出最后的数字为 0，则使用下面的命令添加 Swap 配置（设定为比起内存，优先使用 Swap）

```shell
# 其中的 100 也可以进行修改，100 代表尽可能使用虚拟内存，0 代表尽可能使用物理内存
# 物理内存远快于虚拟内存，但对于 DNF 服务来说，个位数玩家在玩时，基本体会不到差异
sed -i '$a vm.swappiness = 100' /etc/sysctl.conf
```

重新启动服务器，或执行以下命令使 Swap 配置生效：

```shell
sysctl -p
```

## 拉取镜像

点击查看所有镜像版本: [记得点赞三连，帮助更多人了解到该镜像](https://hub.docker.com/repository/docker/llnut/dnf)

最新可用的镜像版本如下所示:
```shell
llnut/dnf:centos7-qf1031-latest
```

您可使用如下命令拉取镜像，例如：
```shell
docker pull llnut/dnf:centos7-qf1031-latest
```

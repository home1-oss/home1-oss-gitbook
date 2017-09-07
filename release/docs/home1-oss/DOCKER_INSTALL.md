# 环境依赖  
+ 64位系统  
+ 内核版本至少为3.10   
+ CentOS 7（之前的CentOS版本只能运行低版本的docker）  
+ 最新Docker版本： 1.12.1 （~2016年09月08日）

# 安装  
## 使用yum安装  
+ 确保用户拥有sudo权限，或者使用root用户。  
+ 确保系统存在的yum包已经更新至最新。  

```  
yum update  
```  

+ 添加yum软件源   
使用```vim /etc/yum.repos.d/docker.repo```创建并打开docker的软件源配置。加入如下内容：

```
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
```  

+ 安装并启动

```
yum update 
yum install docker-engine
systemctl start docker.service 
systemctl enable docker.service
```

完成！

# 其他

## 修改运行目录
默认目录```/var/lib/docker```。修改```/usr/lib/systemd/system/docker.service```, 将docker的数据目录修改为```/opt/data/docker```。

```
ExecStart=/usr/bin/dockerd --graph /opt/data/docker
```

之后执行如下命令重启docker服务。

```
systemctl daemon-reload
systemctl restart docker.service
```

> docker info查看docker的环境变量、运行状态等信息。


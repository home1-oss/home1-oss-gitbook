-----
如果你正在通过git服务查看此文档，请移步项目网站或gitbook查看文档，因为git服务生成的文档链接有问题。
+ [gitbook](http://mvn-site.internal/oss-develop/gitbook)
+ [RELEASE版网站](http://mvn-site.internal/oss/staging)
+ [SNAPSHOT版网站](http://mvn-site.internal/oss-develop/staging)
-----

# oss运行环境
所有项目均使用docker方式构建,可通过docker-compose可一键启动

+ [配置中心 oss-configserver](oss-configserver/)
+ 服务发现 oss-eureka
+ 管理平台 oss-admin
+ 消息总线 oss-cloudbus
+ docker相关环境
    > - java基础镜像
    > - mysql基础镜像
    > - docker仓库基础镜像

## 关于 Docker registry

  我们搭建了docker registry以方便在公司内部使用docker.  
  
  可以配置 `--insecure-registry=<docker-registry域名>` 以使用此registry.  
  不同的平台配置此参数的方法不同, 请自行搜索.  
  
  registry使用了自签名证书, 除了配置insecure-registry这种方法, 用户也可以导入自签名证书使用.  
  关于registry是如何搭建的以及如何导入证书请参考下面的文档.  
  [参考文档](./DOCKER_REGISTRY.html)

## 基于Docker 搭建本地开发/测试环境:

  我们已经在公司内网提供了测试环境.
  
  测试服务地址如下:
  
      服务发现地址: http://oss-eureka-peer1.internal:8761/eureka/,http://oss-eureka-peer2.internal:8761/eureka/,http://oss-eureka-peer3.internal:8761/eureka/
      配置中心地址: http://oss-configserver.internal:8888/config/
  
  如果你需要在家办公, 或对这些技术感兴趣, 想进一步探索, 可以尝试在本地搭建自己的环境.

    # 检查 docker 版本
    docker --version
    # 需要 >= 1.12.1

    # 检查 docker-compose 版本
    docker-compose --version
    # 需要 >= 1.9.0

    # /etc/hosts
    127.0.0.1 local-eureka
    127.0.0.1 local-configserver

    mkdir workspace
    cd workspace

    git clone git@gitlab.internal:configserver/common-config.git
    git clone git@gitlab.internal:configserver/oss-todomvc-app-config.git
    git clone git@gitlab.internal:configserver/oss-todomvc-thymeleaf-config.git

    export OSS_BUILD_VERSION=<例如:1.0.6.OSS-SNAPSHOT 或者最新版本latest>
    export HOST_IP_ADDRESS=<请填写你的局域网ip地址>
    docker network create oss-network

    docker-compose -f docker-compose-in-office.yml up -d
    
    #(cd oss-admin; docker-compose up -d;)
    #(cd oss-hystrixboard; docker-compose up -d;)
    # or start configserver with local git service
    # (cd oss-configserver; docker-compose -f docker-compose-git.yml up -d;)

#### 目前存在的一些小问题

- [Mac上到容器的路由问题](https://forums.docker.com/t/ip-routing-to-container/8424/2)
- [docker-compose变量默认值问题](https://github.com/docker/compose/issues/2441) 1.9版本解决

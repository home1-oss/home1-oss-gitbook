## docker常用命令
### docker exec -it container_name command
  * 进入运行容器控制台的命令： `docker exec -it production-admin /bin/bash`
  * 查看容器内部IP：`docker exec -it production-admin ifconfig`
  * 查看容器内部文件：`docker exec -it production-admin ls -l /root`
  
### docker logs：在容器外部查看容器运行日志
  * `docker logs -f --tail 100 container_name`
  
### 查看镜像、容器的配置信息
  * 查看容器启动时间、环境变量、镜像信息、域名等信息： `docker inspect container_name`
  * 查看镜像信息： `docker inspect image_name`

## 常见问题以及解决
 - 在测试环境中，我将admin配置在一个部署了eureka节点的机器上，此时admin和这个eureka配置了同一个hostname， `oss-eureka-peer3.internal`，这就导致当admin访问这个eureka的healthUrl时，当请求到同样的域名，就把这个域名当成是自己当前容器的域名了，导致访问失败。
 
 > 临时的解决方案就是，添加docker-compose.yml的配置`services.admin.extra_hosts`。告诉admin，当请求到统一域名的其他服务时，通过ip地址访问这个请求。


 ```
 version: '2.1'
services:
  admin:
    extends:
      file: docker-compose-base.yml
      service: admin
    container_name: production-admin
    command: ["start"]
    hostname: ${EUREKA_INSTANCE_HOSTNAME:-local-admin}
    ports:
    - "8700:8700"
    volumes:
    - admin-volume:/root/data/admin
    environment:
    - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=${EUREKA_CLIENT_SERVICEURL_DEFAULTZONE:-http://user:user_pass@local-eureka:8761/eureka/}
    - SERVER_PORT=8700
    - EUREKA_INSTANCE_HOSTNAME=${EUREKA_INSTANCE_HOSTNAME:-local-admin}
    extra_hosts:
    - "oss-eureka-peer3.internal:10.*.*.*"
```

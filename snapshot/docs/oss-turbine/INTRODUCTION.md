
turbine
=======

# 简介
在复杂的分布式系统中，相同服务的结点经常需要部署上百甚至上千个，很多时候，运维人员希望能够把相同服务的节点状态以一个整体集群的形式展现出来，这样可以更好的把握整个系统的状态。 为此，Netflix提供了一个开源项目（Turbine）来提供把多个hystrix.stream的内容聚合为一个数据源供Dashboard展示。
# 代码示例
## 1. POM.xml
新建Maven项目，并在pom.xml中添加如下内容:
> spring-cloud-starter-turbine, spring-cloud-netflix-turbine


## 2. bootstrap.yml,application.yml

- bootstrap.yml


    spring:
      application:
        name: turbine
      profiles: dev


- application.yml


    server:
      port: ${PORT:8989}
    
    management:
      port: 8990
    
    eureka:
      client:
        serviceUrl:
          defaultZone: http://oss-eureka.local:8761/eureka/
    
    security:
      basic:
        enabled: false
    
    
    turbine:
      aggregator:
        clusterConfig: default
      appConfig: ribbon-hystrix,feign-hystrix
      clusterNameExpression: new String("default")



## 3. 启动类: TurbineServer


    @SpringBootApplication
    @EnableTurbine
    public class TurbineServer {
    
      public static void main(String[] args) {
        new SpringApplicationBuilder(TurbineServer.class).web(true).run(args);
      }
    }

## 4. 配置完成
After running, use this url in the hystrix dashboard: http://oss-turbine.local:8989/turbine.stream

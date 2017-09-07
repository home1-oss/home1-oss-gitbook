# 健康检查

## 途径
常用的检查途径有两种，一种是通过心跳超时来判断(默认提供)；一种方式是通过定期调用HealthCheckHandler来判断，留给应用扩展。第一种方式相对简单，不在本文讨论范围内，本文重点讨论第二种途径。

## Eureka 实现细节
+ 实时性   
  HealthCheckHandler在注册到Eureka Instance中会立刻进行一次状态检查，以保证系统状态的实时性。  
  
  请看com.netflix.discovery.DiscoveryClient中
  
      @Override  
      public void registerHealthCheck(HealthCheckHandler healthCheckHandler) {
          if (instanceInfo == null) {
              logger.error("Cannot register a healthcheck handler when instance info is null!");
          }
          if (healthCheckHandler != null) {
              this.healthCheckHandler = healthCheckHandler;
              // schedule an onDemand update of the instanceInfo when a new healthcheck handler is registered
              if (instanceInfoReplicator != null) {
                  instanceInfoReplicator.onDemandUpdate();
              }
          }
        }

  
+ 周期检查  
在com.netflix.discovery.InstanceInfoReplicator中有一个名为DiscoveryClient-InstanceInfoReplicator的线程会定期执行以下功能：通过调用HealthCheckHandler来更新Instance状态、更新Instanceinfo、更新Metadata，注册Instance等。其默认周期为30s，可通过修改eureka.appinfo.replicate.interval的值来调整。 

## Spirng Cloud对HealthCheckHandler的扩展实现
+ 开启配置  
默认不开启。开启需要加如下配置：

      eureka:
        client:
          healthcheck:
            enabled: true


+ 源码分析   
结合org.springframework.cloud.netflix.eureka.EurekaDiscoveryClientConfiguration中的代码分析

      @Configuration  
    	@ConditionalOnProperty(value = "eureka.client.healthcheck.enabled", matchIfMissing = false)  
    	protected static class EurekaHealthCheckHandlerConfiguration {

    		@Autowired(required = false)  
    		private HealthAggregator healthAggregator = new OrderedHealthAggregator();  

    		@Bean
    		@ConditionalOnMissingBean(HealthCheckHandler.class)  
    		public EurekaHealthCheckHandler eurekaHealthCheckHandler() {  
    			return new EurekaHealthCheckHandler(this.healthAggregator);  
    		}  
    	}

可以得出上面的结论，同时可以看出EurekaHealthCheckHandler是可以被替换的，如果有设置则采用设置好的，没有设置则采用Spring Clound中提供的。

Spring Clound使用的默认的HealthAggregator实现是OrderedHealthAggregator，它的策略是收集所有的内部状态，然后选出在DOWN、OUT_OF_SERVICE、UP和UNKNOWN中间具有最低优先级的那个状态。这里使用策略设计模式，因此具体的状态判定策略可以改变和定制。

+ 可定制  
  HealthCheckHandler、HealthAggregator、HealthIndicator均可定制实现  
  
## 参考文件  
[Spring Boot应用的健康监控](http://www.jianshu.com/p/734519d3c383)    
[Spring Cloud: Fixing Eureka application status
Posted on](https://jmnarloch.wordpress.com/2015/09/02/spring-cloud-fixing-eureka-application-status/)  
  

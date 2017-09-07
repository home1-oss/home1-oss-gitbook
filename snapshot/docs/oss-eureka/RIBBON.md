# About Ribbon
## 线程模型
线程名 | 类名 | 功能描述 | 默认时间 | 参数 |    
--- | --- | --- | --- | --- |   
PollingServerListUpdater-|com.netflix.loadbalancer.PollingServerListUpdater|定期更新ServerList|30s|ServerListRefreshInterval
NFLoadBalancer-PingTimer-|com.netflix.loadbalancer.BaseLoadBalancer|定期ping，检查Server状态|30s|NFLoadBalancerPingInterval  

ServerList更新线程在每次更新完list列表后，也会调用一下ping检查。这两个线程的主要目的是维护一个可用的ServerList列表，供后续调度选取。

## Use ribbon in Spring Cloud
### 重要实行类
比较简单，同时官方文档有说明，所以此处不做特殊说明。  

属性| only ribbon | with Eureka 
---|---|---
IClientConfig ribbonClientConfig|DefaultClientConfigImpl | --  
IRule ribbonRule| ZoneAvoidanceRule |   -- 
IPing ribbonPing| NoOpPing  | NIWSDiscoveryPing
ServerList&lt;Server&gt; ribbonServerList| ConfigurationBasedServerList  |DomainExtractingServerList  
ServerListFilter&lt;Server&gt; ribbonServerListFilter| ZonePreferenceServerListFilter |--  
ILoadBalancer ribbonLoadBalancer | ZoneAwareLoadBalancer | --  

com.netflix.loadbalancer.ServerStats  

### 熔断机制
默认情况下一个服务，如果连续3次访问都出现错误的话，会处于熔断状态。有的负载均衡算法（如spring cloud采用的ZoneAvoidanceRule）在选取服务器时会屏蔽掉处于熔断状态的服务。
   
熔断主要由3个参数控制：  
+ connectionFailureCountThreshold： 控制连续出错多少次触发熔断，默认3次  
+ circuitTrippedTimeoutFactor：熔断因子，控制熔断时间。实际熔断时间2^(errorNum-connectionFailureCountThreshold)\*circuitTrippedTimeoutFactor，默认10s  
+ maxCircuitTrippedTimeout:最大熔断时间，实际熔断时间不能超过最大熔断时间，默认为30s  
   官方文档对于熔断时间的解释比较模糊，容易让人产生误解。  
   
   参考代码如下：


    private long getCircuitBreakerBlackoutPeriod() {
        int failureCount = successiveConnectionFailureCount.get();
        int threshold = connectionFailureThreshold.get();
        if (failureCount < threshold) {
            return 0;
        }
        int diff = (failureCount - threshold) > 16 ? 16 : (failureCount - threshold);
        int blackOutSeconds = (1 << diff) * circuitTrippedTimeoutFactor.get();
        if (blackOutSeconds > maxCircuitTrippedTimeout.get()) {
            blackOutSeconds = maxCircuitTrippedTimeout.get();
        }
        return blackOutSeconds * 1000L;
    }


### 服务关闭时，Ribbon的响应流程
本文重点分析Ribbon通过Eureka负载均衡时的处理流程
+ 服务优雅关闭时  
Ribbon利用Eureka client来判断Instance的状态，一个服务从关闭到被Ribbon发现的时间取决与Eureka Server、Eureka client以及Ribbon的缓存刷新时间，默认情况下以上三者的时间均为30s，故最大延时为90s。90s中内已关闭服务被调用的次数最多为6次：包括连续3次错误后触发熔断，第1次熔断（第3次调用）10s，第2次熔断20s，第3、4次熔断30s
+ 服务暴力关闭时  
此时Eureka Server需要通过Instnce的心跳来判断Instance是否存在，默认情况下，心跳超时时长为90s，当时在判断时存在bug，所以计算时采用的超时时长时设定值的2倍，默认情况下即为180s。  
 + 不开启保护模式  
   参照上面的分析，最大延时为270s，理论上已关闭服务被调用到的次数为12次  
 + 开启保护模式  
   已关闭的服务不会被发现，在被错误调用5次后，将按30s一次的频率被调用  
  
  
   

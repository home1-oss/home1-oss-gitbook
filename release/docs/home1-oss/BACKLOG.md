
条目末尾的[n人周]只是基于目前对需求和技术的了解做出的粗略估计，仅供参考，实际会有出入。
以下内容还需于全部参与者过一遍，根据集体讨论的结果进行调整。

+ docker的SDN研究。 liangjian, zhanghaolun
	- 开发环境的SDN方案。
	- SDN上的DNS。
	- 测试／生成环境的SDN方案。
	- 调整目前服务的docker配置以适应SDN。

+ 单个用户行为的跟踪机制。 fengshuangjie
	- 在网关处给用户请求加上标识。
	- 后续服务和网关要能识别出该标识。
	- 日志库要能识别出该标识，并忽略当前logLevel的设置。
	- 日志收集和展示工具要能尽快收集到带标识的日志消息并能按顺序集中显示出来。

+ 与唯一id整合提供JPA的id生成器。 wanghao
	- 使用微服务maven骨架重构唯一id服务。
	- 按微服务标准提供客户端mock和服务的桩。
	- docker化。
	- 各环境通用配置。
	- 完善唯一id服务测试。
	- 最后才是编写一个客户端id生成器。

+ 类似strompath的认证授权服务。 zhaozecheng
	- 梳理数据结构模型。
	- 开发数据接口。
	- 管理界面照搬。
	- 要求使用strompath官方SDK测试通过。
	- oauth2要兼容spring的方案，可能要对lib-security进行扩展。
	- 支持客户端的简化授权方式。

+ 更完整的日志收集处理机制[未知]。
	- docker容器的log插件。
	- 要能标记产生日志的服务和实例id。
	- 不阻塞上游进程。
	- 下游故障时能堆积。
	- 保证日志顺序。
	- 能有效处理java异常(多行)。

+ admin的多租户。  jinyuliang
	- 已完成设计。
	- 需要实现RBAC模型及前端管理界面。

+ Ratelimit 限制API访问的频次。 zhangyan
	- 已调研，文档需转化成markdown。
	- 目前没有直接可用的方案。
	- 支持普通webmvc应用。
	- 支持zuul网关上对单独后端服务进行限制。
	- 要进行细致的自动化测试。

+ 服务降级为只读的开关。 zhupengcheng
	- 尽量不要求用户使用annotation。
	- 要在admin服务上可以控制。
	- 提供一个受保护的management endpoint。
	- swagger要能看到management endpoint，并显示合适的文档。
	- 要进行细致的自动化测试。

+ 基于时间序列数据库的RPC监控(收集turbine数据)。 zhangqingyun, zhaopengfei
	- 至少要支持2-3天内高频数据查询。
	- 后端时间序列数据看的调研选型，部署运维方案。
	- 数据收集和查询服务开发。
	- 前端开发。

+ 改善spring-mvc到spring-data-jpa的枚举类型jodatime等扩展类型的支持。
	- 要做到流畅地映射，尽量不要求用户加注解。
	- 枚举类型的webmvc映射和JPA映射, 如果有可能开发mongodb和ES映射, jodatime库和框架支持但需测试总结用法。
	- 要确保RPC时feign也能正确映射。
	- Map的JAXB映射或其它xml方案。
	- 要进行细致的自动化测试。
	- 看似简单但需要了解spring的dataConverter,dataFormatter,argumentResolver,JPA的userType,jackson2的序列化器／反序列化器等机制才能做好。

+ 与后端lib-errorhandle，lib-security相对应的前端库。
	- 研究JSR-303如何更好地自定义错误消息, 如有可能, 支持i18n。
	- 研究错误信息如何与前端控件／字段对接上。
	- lib-security登陆，退出，获取用户信息，查询用户角色／权限。
	- 针对react和jquery提供js库。
	- 虽然是js项目，但需要像Java项目一样使用maven构建并测试。
	- 发布webjar和npm包。
	- 研究如何进行前端的自动化测试，以自动测试此功能。

+ 与cicada整合。
	- 调研spring-cloud-sleuth。
	- 使用微服务maven骨架重构cicada服务。
	- docker化。
	- 完善cicada的自动化测试。
	- cicada客户端目前是基于dubbo的，需针对feign重新开发，要重用代码会涉及到既有代码的重构和测试。
	- 或者使cicada后端兼容sleuth的数据，使用spring的客户端。
	- 改动量目前不好评估。

+ RocketMQ整合进spring-cloud-stream。
	- 了解spring对消息的抽象。
	- 使RocketMQ客户端适配spring-cloud。
	- 将RocketMQ服务docker化。
	- 要进行细致的自动化测试。
	- 各环境通用配置。

+ 短链接, 分布式文件系统的SDK[3人周]。
	- 服务docker化。
	- 各环境的通用配置。
	- 单测使用的mock库。

+ HATEOAS方案研究。
	- spring-data-rest拦截事件的方式并不适合一般应用的开发。
	- 使用spring-webmvc和spring-hateoas实现HATEOAS。
	- react的HATEOAS支持。
	- feign的HATEOAS支持。
	- restTemplate的HATEOAS支持。
	- swagger的HATEOAS支持。
	- restdocs的HATEOAS支持。
	- RPC和测试都要能支持HATEOAS。

+ 结合docker环境服务编排及使用spinnaker实现持续发布。
	- 搭建stage环境，服务发布前fan in到stage环境进行测试。
	- 根据spinnaker的需要调整docker环境和ci脚本。
	- 研究端到端测试方法。
	- 任务不多但都比较重。

服务间调用认证 url签名

数据自动脱敏

灰度发布

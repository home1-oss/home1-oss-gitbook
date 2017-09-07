
    # 本地docker构建
    DOCKER_HOST=unix:///var/run/docker.sock mvn clean package docker:build docker:push

## spring boot admin文档
### spring boot admin主要功能
This application provides a simple UI to administrate Spring Boot applications. It provides the following features for registered application.

+ Show health status
+ Show details, like
  + JVM & memory metrics
  + Counter & gauge metrics
  + Datasource metrics
  + Cache metrics
+ Show build-info number
* Follow and download logfile
* View jvm system- & environment-properties
* Support for Spring Cloud's postable /env- &/refresh-endpoint
* Easy loglevel management (currently for Logback only)
* Interact with JMX-beans
* View thread dump
* View traces
* Hystrix-Dashboard integration
* Download heapdump
* Notification on status change (via mail, Slack, Hipchat, ...)
* Event journal of status changes (non persistent)

### Security
Below endpoints should not be secured by spring security or other security policies because spring boot admin need to read these endpoints to monitor the web application.
> "env", "metrics","trace", "dump", "jolokia", "info","activiti", "logfile", "refresh","flyway", "liquibase", "heapdump"

### 客户端注册到admin服务端过程
RegistrationApplicationListener监听客户端应用启动后,调用客户端ApplicationRegistrator的registe方法进行服务注册。

### 配置说明
 + app.adminPrivateKey: 配置admin公钥,用于访问admin client的endpoints。
 ```yml
 app.adminPrivateKey: MIICXQIBAAKBgQC/gmBcdQZxiQmhQrP1awAZuuOl4snl7cEV8n65osVO7CdqxXG5mUYNVr6siwuTm/SsmBV+86JISlzvMK/Bxwsmf/ApZicgItChmDuU9TCaZIksqnpbtONnCm/sHWwa/2hqPTjdc0LC+jQ/FCU2b9vpbSId0Wg28/gtoGaLWbsm/QIDAQABAoGBAI7dOfl/K5FjA5YTZqB8dBS9wLmtl6Q5W0N+JV9iuAKKVVVnedFVMFcfERsyly5Et6BRzCdqpPN81htxnIvYas2+Nvu5be1NwPAYLW2NUFDRzEAH/vWOLhY2F5uo24AJBHRRCRnLiqq/8aZ9STDdzS8WlHBg5kOforoqREXwmxKBAkEA/lFwu3ftQQyIavV56za+o6C8W/S7GqCWurOo3C+kKHOpUtqRjkacdEoxFCjs92RNJzd+fhGMzUhupKGX1+uKjQJBAMDGmdVknB8iLxm0CWjuRm+q0ciK0Ech2tB+39DsUvVNguvJAbxD+CMiusJ7dCFbVy1G9rjQR2gTLEI52BM0qjECQDHVb4usolb+x7R9yZgnsA+MLZyvRgKfuSl4jvwmcbpjf6h2n9MLTxkSeK+EnXqUsvGeVDEL61VGfjfQWlq7EvkCQQC1/IcLUeCk75OBc1oSyiaKkrta09kN3eMBQ1UtmXwzgYof53GQ9qWRHd8rbHpUZzNkVgLitBVFJhx5JLxcXTJxAkBalCMEuhXGYBkLMhcstJzs+Gk07FkkgV1fC4Kf9Xeu5YLkxS+tjkZt3iwfUo4Ll3m3fWhguLUtf05jUgWClx0t
 ```

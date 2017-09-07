# oss 各系统搭建使用流程

## 准备工作

2. DNS配置，oss项目使用自定义域名internal,所以需要搭建自己的服务器来服务于项目。
   
    需要配置如下域名(各项目搭建时，有详细说明):
        
        k8s.internal                        #k8s-server       k8s服务器节点IP
        node1.k8s.internal                  #k8s-node x       k8s服务x节点IP

    **注意**: 搭建过程中每台机器都要配置DNS服务器地址，配置方法在安装文档中。 

## 业务基础服务

3. 项目相关

    gitlab上的服务初始化如下项目

    - home1oss/oss-internal                       存放项目一些敏感信息，有些需要更新比如***k8s***的配置

    gitlab搭建完毕后，可从github引入样例项目

    - home1oss/oss-jenkins-pipeline               负责jenkins pipeline部署的项目
    
    - home1oss/oss-todomvc                        样例项目(引入后需要1.稍加[修改ci.sh脚本](TODOMVC.md)，
    比如 GIT_REPO_OWNER即该项目拥有者需要修改，并且有个约定todomvc等项目要和oss-internal拥有者一致，还有脚本最后有跳过执行步骤的，直接去掉判断。
    2.把Dockerfile中的java镜像的registry换成home1oss,或者人工pull一个到docker.registry.internal)

### jenkins

4. 登录jenkins配置一个名为(注意是ID字段)jenkinsfile的证书访问gitlab，jenkins pipeline 脚本中用到

## 正常开发注意事项

### oss-jenkins-pipeline

- 脚本中默认使用ID为`jenkinsfile`的证书  
- 兼容docker-compose,k8s部署，但是k8s项目文件夹都用-k8s结尾来区分  

## TODO 关于项目todomvc样例项目的k8s部署文档都在 oss-jenkins-pipeline项目中
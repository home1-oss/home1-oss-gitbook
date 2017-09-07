# todomvc 项目相关

## ci调整

1. 修改 ci.sh 文件，将最底部的判断逻辑去掉

将  
        
        if [ "${1}" != "test_and_build" ] && ([ "${GIT_REPO_OWNER}" != "home1-oss" ] || [ "pull_request" == "${TRAVIS_EVENT_TYPE}" ]); then
            echo "skip deploy/publish on forked repo or which trigger by pull request "
        else
            $@
        fi
改为
         
         $@
         
2. 修改 gitlab-ci.yml,设置合适的环境变量
         
        before_script:
          - export OSS_BUILD_REF_BRANCH="develop"            
          - export OSS_BUILD_CONFIG_REF_BRANCH="develop"
          - export GIT_REPO_OWNER="oss"
          - export OSS_BUILD_GIT_SERVICE="https://github.com"  ## oss-build项目地址
          - export OSS_BUILD_GIT_REPO_OWNER="home1-oss"        ## oss-build ownner

3. 其他   
         
   - 测试环境configserver通用配置k8s配置的common-config的分支一定要存在，否则出错日志是debug级别有问题也难看出来。      
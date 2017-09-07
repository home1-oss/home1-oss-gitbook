[toc]

[本文源地址](http://note.youdao.com/noteshare?id=6cfe6bd7da2f5c009ac04061e24c4991)

# gitlab jira 集成

## 每次提交必须带有有效的jira号

### 综述

为了将对代码的每一个操作都被记录下来, 所以, 对代码操作的每一个动机都要在 jira 中记录. 所以在提交 git 以前判断 comment 里面是否存在有效的 jira 号, 如不存在, 则提交失败.

### 使用方法

> 使用以前, 请项目中所有人员将未 `push` 的本地提交, 先 `push` 到中央仓库.

#### 整体步骤

1. 开发人员在本机项目中启用本地hook (步骤稍后呈现)
2. 运维人员保证服务端项目启用服务端hook (步骤稍后呈现)
3. 在 jira 中创建任务, 获得 jira 号, 例如: PORJ-123
4. 开发代码, 在提交代码的时候, comment 中要 **提及** 此 jira 号, 例如: `git commit -am"fix checkstyle bug. refer: PROJ-123"`, 此时如果忘记写 JIRA 号, 则本地 hook 会提示你, 并拒绝此次提交.
5. 将代码 push 到远程. 此时, 如果有某个提交 comment 里面没有写JIRA号, 则服务端 hook 拒绝此次 push. 请参考此文档 `急救:如何修改未push的comment` 部分.
6. 开发去 jira 中将此任务手工设置为 `已解决` 状态.
7. 测试验收完成以后, 手工将 jira 任务关闭.

#### 开发人员在本机项目中启用本地 hook 步骤

1. 将文中 `客户端hook代码`修改脚本中配置以后, 保存为 `commit-msg` 文件名, 放到项目根目录下`hooks`目录下(实际应用中, 参数可能会以环境变量的方式带入,例如:`JIRA="internal-jira"`)
2. 赋予`commit-msg` 文件执行权限
3. 执行 `git config --local core.hooksPath /path/to/xxxx/hooks` 设置全局hooks目录(git 2.9版本以前, 请参考本文 `开启git hooks方式`部分)
4. commit一下, 测试是否生效(如果测试不生效, commit成功, 请参考此文档 `急救:如何修改未push的comment`)

#### 运维人员在服务端项目中启用服务端 hook 步骤

1. 将本文中`服务端hook代码`修改对应配置以后, 保存为`update`文件名, 放到服务端项目的 `.git/hooks/` 目录下
2. 赋予`update`文件执行权限, 并把owner改为 `git`
3. push一个commit, 测试一下是否生效(如果测试生效, push失败, 请参考此文档 `急救:如何修改未push的comment`)

### 原理

git hooks 中有一个 `commit-msg` 的 hook. 可以在代码提交以前, 对提交的代码和comment进行校验, 如果不符合要求, 则提交失败. 同理, git服务端有一个`update`hook, 来完成对push上来的commit进行校验的任务.  
通过 http 请求 jira 的 `/rest/api/latest/issue/xxx` 路径, 如果issue号不存在, 则返回 `404`. 如果存在, 则返回 `401`.  

### 详细描述

#### 校验过程

见后面代码

#### 两种模式

因需要 http 访问 jira 判断 jira 号是否存在, 就存在无法访问的情况. 客户端我们提供`严格模式` 和 `宽松模式`. 并且可以配置.  
服务端只有严格模式. 不存在的jira号不允许提交.

##### 严格模式(HARD_MODE)
必须jira服务可访问, 并且存在才可提交.

##### 宽松模式
只要服务器返回不是 404(jira号不存在), 则允许提交. 服务器访问超时, 服务器错误等, 都允许提交. 主要考虑到在家办公时, 会有无法访问jira的情况.


### 开启git hooks方式
git hooks的文件现在放在项目根目录下的 `.git/hooks` 目录, 这些文件不会被版本控制所跟踪, 需手工开启. 如果想要开启本地 hooks 功能,需要进行如下设置

#### 最简单文件拷贝方式 

将脚本放到git项目 .git/hooks 文件夹, 并给予执行权限.

> 这种方式缺点很明显, 每个项目都需要拷贝一下.

#### 通过链接或者设置脚本目录实现
##### git version < 2.9
+ 对于低版本的git，建立从项目目录到`.git/hooks`目录下的软链接,比如: `ln -sf $(pwd)/hooks/pre-commit $(pwd)/.git/hooks/pre-commit`
+ 该方式使用不便，而且 windows 开发平台对软链接的支持很弱。

##### git version >= 2.9
+ 使用git config --local core.hooksPath hooks，设置hooks脚本目录即可。

### git hooks 脚本代码

#### 服务端 update hook 脚本代码

> 钩子文件名是 `update`

> 参考 [git enforced policy](https://git-scm.com/book/en/v2/Customizing-Git-An-Example-Git-Enforced-Policy)

    #!/bin/bash
    
    JIRA_API_ISSUE_URL=http://jira7.{xxxx}.org/rest/api/latest/issue/
    TIME_OUT=5
    
    # --- Command line
    refname="$1"
    oldrev="$2"
    newrev="$3"
    
    # --- Safety check
    # if [ -z "$GIT_DIR" ]; then
    #    echo "Don't run this script from the command line." >&2
    #    echo " (if you want, you could supply GIT_DIR then run" >&2
    #    echo "  $0 <ref> <oldrev> <newrev>)" >&2
    #    exit 1
    # fi
    
    if [ -z "$refname" -o -z "$oldrev" -o -z "$newrev" ]; then
        echo "usage: $0 <ref> <oldrev> <newrev>" >&2
        exit 1
    fi
    
    hashStrs=""
    if [[ "$oldrev" =~ ^0+$ ]]; then
        # list everything reachable from newrev but not any heads
        hashStrs=$(git rev-list $(git for-each-ref --format='%(refname)' refs/heads/* | sed 's/^/\^/') "$newrev")
    else
        hashStrs=$(git rev-list "$oldrev..$newrev")
    fi
    
    echo ${hashStrs}
    
    hashArr=($hashStrs)
    for hash in "${hashArr[@]}"; do
        message=$(git cat-file commit ${hash} | sed '1,/^$/d')
        if grep -i 'merge'<<<"$message";then
                # echo "INFO : branch: ${refname}, hash: ${hash}, 'merge' keyword exists. continue check other commit.."
            continue
        fi
    
        jira_num=$(grep -ohE -m 1 '[ABCDEFGHIJKLMNOPQRSTUVWXYZ0-9]+-[0-9]+' <<< "$message" | head -1)
        
        if [ "${jira_num}" == "" ];then
            echo "ERROR :  branch: ${refname}, hash commit (${hash}) does not contains JIRA_NUM. for example: PROJ-123"
            exit 1
        fi
        check_url=${JIRA_API_ISSUE_URL}${jira_num}
        http_response=$(curl -m ${TIME_OUT} --write-out %{http_code} --silent --output /dev/null ${check_url})
    
        if [ "$http_response" -eq "401" ]; then
            # echo "INFO :  branch: ${refname}, hash commit (${hash}) can find jira issue number, continue check other commit..";
            continue;
        else
            echo "ERROR :  branch: ${refname}, hash commit (${hash}) can not find the jira issue num:${jira_num}, http code return:"${http_response}", please check: ${check_url}";
            exit 1;
        fi
    
    done
    
    
    # --- Finished
    # echo "INFO : branch: ${refname}, all commits with JIRA numbers, allow commit."
    exit 0


#### 客户端 commit-msg hook 脚本代码
> 钩子文件名是 `commit-msg`

    #!/usr/bin/env bash
    
    # usage:
    # git version >= 2.9
    # git config --local core.hooksPath hooks
    
    JIRA_API_ISSUE_URL="${JIRA}/rest/api/latest/issue/"
    echo "JIRA_API_ISSUE_URL: ${JIRA_API_ISSUE_URL}"
    HARD_MODE="true"
    TIME_OUT=10
    
    $(grep -i 'merge' "$1")
    result=$?
    if [ $result -eq 0 ];then
        # echo "INFO : can commit because 'merge' keyword exists."
        exit 0
    fi
    
    jira_num=$(grep -ohE -m 1 '[ABCDEFGHIJKLMNOPQRSTUVWXYZ0-9]+-[0-9]+' "$1" | head -1)
    if [ "${jira_num}" == "" ];then
    	echo "ERROR : commit does not contains JIRA_NUM. for example: PROJ-123"
    	exit 1
    fi
    check_url=${JIRA_API_ISSUE_URL}${jira_num}
    http_response=$(curl -m ${TIME_OUT} --write-out %{http_code} --silent --output /dev/null ${check_url})
    
    if [ ${HARD_MODE} == "true" ];then
    	if [ "$http_response" -eq "401" ]; then
    		# echo "INFO : can find jira issue number, allow commit";
    		exit 0;
    	else
    		echo "ERROR : can not find the jira issue num:${jira_num}, please check: ${check_url}";
    		exit 1;
    	fi
    else
    	if [ "$http_response" -eq "404" ]; then
    		echo "ERROR : can not find the jira issue num:${jira_num}, please check: ${check_url}";
    		exit 2;
    	elif [ "$http_response" -eq "000" ]; then
    		echo "WARN : request time out or error occured, url:${check_url}, but allow commit in loose mode.";
    		exit 0;
    	else
    		# echo "INFO : http response:${http_response}, not 404, allow commit. url: ${check_url}";
    		exit 0;
    	fi
    fi

    
### 急救: 如何修改未push的comment

#### 修改刚刚提交的comment

执行以下命令, 会允许你修改最新提交的comment.

    git commit --amend
    
#### 修改不是最新提交的comment

> 注意! `git rebase` 操作相对比较危险, 操作前, 建议将整个项目备份一遍!!! 再进行操作!!!

 执行以下命令, 进入交互模式, 允许你修改前几次的comment. X代表你想修改据最新提交多少个提交的comment.
    
    // X is the number of commits to the last commit you want to be able to edit
    git rebase -i HEAD~X
    
进入交互模式以后, 将你想要修改的 comment 前面的 `pick` 改为 `r` 或者 `e`. 保存以后, 后面会一步会允许你修改 comment.

> 注意, 保存的时候, git可能会提示编辑器错误, 导致修改失败. 按照如下修改默认编辑器即可:  
>    git config --global core.editor /usr/bin/vim

##### rebase 操作界面示例

    pick f308e14 this is a test commit1
    pick 8df49e1 this is a test commit2
    pick 188f590 this is a test commit3
    
    # Rebase b63eb09..aed0e44 onto b63eb09 (3 command(s))
    #
    # Commands:
    # p, pick = use commit
    # r, reword = use commit, but edit the commit message
    # e, edit = use commit, but stop for amending
    # s, squash = use commit, but meld into previous commit
    # f, fixup = like "squash", but discard this commit's log message
    # x, exec = run command (the rest of the line) using shell
    # d, drop = remove commit
    #
    # These lines can be re-ordered; they are executed from top to bottom.
    #
    # If you remove a line here THAT COMMIT WILL BE LOST.
    #
    # However, if you remove everything, the rebase will be aborted.
    #
    # Note that empty commits are commented out

> 如果感觉在 rebase 的时候, 感觉改坏了, 那就不要提交, `q!`强制退出编辑器以后, 再执行 `git rebase --abort` 取消此次rebase操作.

参考链接:  
[how-to-modify-existing-unpushed-commits](http://stackoverflow.com/questions/179123/how-to-modify-existing-unpushed-commits)  
[git-rebase](https://git-scm.com/docs/git-rebase)
    
## 每次提交代码后, 自动将 commit 号关联到对应 jira

### 综述
在提交代码时, 在comment中提到jira中的 issue 号码, 则这个提交信息会自动添加到jira里面相应的issue评论里面. 方便项目记录和查询.

### 使用
0. 在 gitlab 上配置开启`JIRA service`功能
1. 在jira中创建任务, 获得任务号码, 例如: `MYPROJ-123`
2. 在提交代码时, 备注里面提到issue号(示例:`git commit -am"fix checkstyle issue. refer: MYRPOJ-123"`), push到gitlab时, gitlab会自动在jira相应的issue下面添加此次提交的gitlab链接.

> **其他功能:** *可以使用关键字关闭issue(**前提是issue状态是标准的!!**, 例如: Open, Reopened 等,我们的jira中不标准, 此功能无法使用), 支持关键字如下(PROJ-123 是 issue号):
>    + Resolves PROJ-123
>    + Closes PROJ-123
>    + Fixes PROJ-123

### 原理
gitlab CE(社区版)里面已经有 Jira issue tracker 功能. 只需要配置开启即可.


### 配置过程

#### 运维在JIRA中创建gitlab用户

+ 在 jira 中创建 `gitlab` 用户. 此操作只需一次.

> 参考: [configuring-jira](https://docs.gitlab.com/ce/project_services/jira.html#configuring-jira)

#### 在 JIRA 上给 `gitlab` 用户赋予添加备注权限

+ 在相应项目中 `项目管理` 菜单下, 点击`权限`菜单, 点击`行为`下拉菜单, 选择`修改权限`, 找到 `使用备注权限`下的`添加备注`功能, `编辑` 并添加 `单一用户`, 将上一步中的`gitlab`选中添加即可.

#### 在gitlab项目中配置启用JIRA功能

+ 点击gitlab项目中, 设置图标, 并选择 `service` 菜单.
+ 在列表中选择 `JIRA`, 配置如下(应该是版本问题, 官网配置说明和我们gitlab会有不同):



项目 | 值 | 说明
---|---|---
Active | 勾选 | 激活此 JIRA 服务
Trigger | 勾选 |
Description |        |描述
Project url |http://jira_url/browse/PROJECT_KEY| 访问项目的地址
Issues url  |http://jira_url/browse/:id        | 访问issue的地址
New issue url| http://jira_url/secure/CreateIssue!default.jspa?selectedProjectId=10346 | projectId 如何查看:[sebnukem 的答案](http://stackoverflow.com/questions/9884381/how-to-get-project-id-to-create-a-direct-link)(这个答案没有对勾, 不需要admin权限即可获取)
Api url| http://jira_url/rest/api/2 | api调用地址
Username | gitlab                   |此用户名最好有对所有项目写的权限(至少有当前项目写权限)
Change Password | 找运维获取                |密码
Jira issue transition | 2           |

### 参考链接

[gitlab 配置示例-版本和我们相同](http://stackoverflow.com/questions/26775374/how-to-configure-jira-external-issue-tracker-on-gitlab)  
[gitlab 官网文档](https://docs.gitlab.com/ce/integration/external-issue-tracker.html)


## 在生成 mvn site 时, 自动从 jira 获取 issue 变动信息

### 概述
在生成项目报告时, 能够自动从jira获取release版本变动相关信息. 就不用手工写 release note.

### 原理
通过 maven 插件 [Maven Changes Plugin](https://maven.apache.org/plugins/maven-changes-plugin/index.html) 实现.  
**前提**是jira的release版本管理和pom文件中的一一对应, 并且每个issue都指定了要在哪个版本中fix. (jira中的Releases也应该是 1.x.x 这种类型的). 

### 使用步骤

#### 首先在java项目中pom文件添加:

    <project>
        ...    
        <issueManagement>
          <system>JIRA</system>
          <url>http://jira7.{xxxxx}.org/browse/{对应的projectKey}</url>
        </issueManagement>        
        <reporting>
          <plugins>
            <plugin>
              <groupId>org.apache.maven.plugins</groupId>
              <artifactId>maven-changes-plugin</artifactId>
              <version>2.12.1</version>
              <!-- if jira version > 5.1, use this flag -->
              <configuration>
                <useJql>true</useJql>
                <jiraUser>gitlab</jiraUser>
                <jiraPassword>xxx{找运维获取}</jiraPassword>
                <!-- 
                    <onlyCurrentVersion>true</onlyCurrentVersion>
                 -->
                    <!-- http://jira7.{xxxxx}.org/rest/api/2/resolution/ -->
                    <!-- http://jira7.{xxxxx}.org/rest/api/2/status/ -->
                    <resolutionIds>完成</resolutionIds>
                    <!--  -->
                    <statusIds>关闭</statusIds>
              </configuration>
              <reportSets>
                <reportSet>
                  <reports>
                  <!-- 
                    <report>changes-report</report>
                   -->
                    <report>jira-report</report>
                  </reports>
                </reportSet>
              </reportSets>
            </plugin>
          </plugins>
        </reporting>
        ...
    
    </project>
    

> `onlyCurrentVersion`字段指定了只拿当前版本.  
> 强烈建议`JIRA`使用用默认的`status`和`resolution`. 否则就需要配置`resolutionIds`和`statusIds`. 默认获取的`status`是`Closed`, 默认获取的`resolution`是 `Fixed`. 如果JIRA已经自定义了状态和解决方方法, 则按照以下步骤配置:  
> 因为我们 JIRA 系统自定义了 `resolution`和`status`, 所以我们的配置是`<resolutionIds>完成</resolutionIds>` 和 `<statusIds>关闭</statusIds>` .只是拿取解决方式为`完成` 和 状态为 `关闭` 的jira数据. 这个id和我们jira强相关.  
> 获取 JIRA 自定义状态的简便方式: 将jira的issue拖到`已完成`, 然后通过以下链接获取`已完成`状态下的 `status` 和 `resolution`, 链接:http://jira7.{xxxxx}.org/rest/api/latest/issue/xxx(issue号)/. 

>参考:  
[usage](https://maven.apache.org/plugins/maven-changes-plugin/usage.html)  
[customizing jira](https://maven.apache.org/plugins/maven-changes-plugin/examples/customizing-jira-report.html)  
[resolution](http://stackoverflow.com/questions/22013481/maven-changes-plugin-cant-generate-jira-report/41295319#41295319)  

#### 然后jira使用约定

+ jira中版本保持和pom文件版本一致(不要有snapshot, 插件会自动将snapshot去除). 版本管理在项目主页的 Releases 菜单下.
+ 新建每一个issue的时候, 都要指定解决版本(Fix for字段).

#### 最后通过mvn site 生成网站

在执行 ` mvn site` 时, 在生成网站下, 会多出 `JIRA Report` 的菜单, 里面包含了jira相关信息.

### 备注:jira中 resolution 和 status 的不同

+ status 代表工作流中状态的流转
+ resolution 是对issue状态原因的一种描述(可以认为通过什么解决方案达到这种状态)

举例:  
为了避免有如下这么多冗杂状态, 便于维护, 所以将 resolution 提出来一个单独概念:
+ "Closed and Fixed"
+ "Closed and Won't Fix"
+ "Closed because Duplicate"

>参考:  
[Practical JIRA Development](http://jiradev.blogspot.com/2010/11/resolved-resolution-and-resolution-date.html)

### 参考链接
[Maven Changes Plugin 插件地址](https://maven.apache.org/plugins/maven-changes-plugin/index.html)  

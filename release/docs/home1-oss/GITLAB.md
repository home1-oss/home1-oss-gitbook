
gitlab环境

    ```
    rm -rf ~/ws/docker-volumes/gitlab/postgresql/*;
    rm -rf ~/ws/docker-volumes/gitlab/redis/*;
    rm -rf ~/ws/docker-volumes/gitlab/gitlab/*;
    
    docker pull sameersbn/postgresql:9.4-23
    docker pull sameersbn/redis:latest
    docker pull sameersbn/gitlab:8.10.0
    
    mkdir -p ~/ws/docker-volumes/gitlab/postgresql; chmod 777 ~/ws/docker-volumes/gitlab/postgresql
    docker run --name gitlab-postgresql -d \
        --env 'DB_NAME=gitlabhq_production' \
        --env 'DB_USER=gitlab' --env 'DB_PASS=password' \
        --env 'DB_EXTENSION=pg_trgm' \
        --volume ~/ws/docker-volumes/gitlab/postgresql:/var/lib/postgresql \
        sameersbn/postgresql:9.4-23
    
    mkdir -p ~/ws/docker-volumes/gitlab/redis; chmod 777 ~/ws/docker-volumes/gitlab/redis
    docker run --name gitlab-redis -d \
        --volume ~/ws/docker-volumes/gitlab/redis:/var/lib/redis \
        sameersbn/redis:latest
    
    # bash generate random 32 character alphanumeric string (upper and lowercase) and 
    #cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
    # bash generate random 32 character alphanumeric string (lowercase only)
    #cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1
    long_and_random_alpha_numeric_string=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)
    mkdir -p ~/ws/docker-volumes/gitlab/gitlab; chmod 777 ~/ws/docker-volumes/gitlab/gitlab
    docker run --name gitlab -d \
        --link gitlab-postgresql:postgresql --link gitlab-redis:redisio \
        --publish 10022:22 --publish 10080:80 \
        --env GITLAB_PORT=10080 --env GITLAB_SSH_PORT=10022 \
        --env GITLAB_SECRETS_DB_KEY_BASE=${long_and_random_alpha_numeric_string} \
        --env GITLAB_ROOT_PASSWORD=rootpassword \
        --volume ~/ws/docker-volumes/gitlab/gitlab:/home/git/data \
        sameersbn/gitlab:8.10.0
    # username/password root/root123
    ```

vagrant外加virtualbox shared folder

[config.vm.synced_folder](https://www.vagrantup.com/docs/synced-folders/basic_usage.html)
[Vagrant can't mount shared folder in VirtualBox 4.3.10](https://github.com/mitchellh/vagrant/issues/3341)

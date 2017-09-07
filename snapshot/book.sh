#!/usr/bin/env bash

# args: docs_path
function book_clean() {
    local docs_path="${1}"
    rm -rf _book;
    rm -rf ${docs_path}
}

function book_generate_resources() {
    local base_path="${1}"
    local projects=(`(cd ${base_path}; find . -maxdepth 1 -name '*' -type d)`)
    for project in "${projects[@]}"; do
        project=${project:2}
        project_path="${base_path}${project}"
        if [ -f ${project_path}/pom.xml ]; then
            echo "project ${project}"
            (cd ${project_path}; mvn clean:clean@auto-clean-readme resources:resources@auto-copy-readme-to-markdown resources:resources@auto-copy-readme-assets-to-markdown)
        fi
    done
}

# args: docs_path
function book_copy_resources() {
    local base_path="${1}"
    local docs_path="${2}"
    local file_type="${3}"
    files=(`(cd ${base_path}; find . -name "*.${file_type}" -print0 | xargs -0 ls | grep -E '^./(oss)-.+|home1-oss' | grep -v 'node_modules' | grep -v 'bower_components' | grep -v 'deprecated' | grep '/src/site/markdown/')`)
    for file in "${files[@]}"; do
        file=${file:2}
        local directory="$(echo $(dirname ${file}) | sed 's#/src/site/markdown##g')"
        #echo "directory: ${directory}"
	    #echo "file: ${file}"
	    echo "mkdir -p ${docs_path}/${directory}"
        mkdir -p ${docs_path}/${directory}

        local target="${docs_path}/$(echo ${file} | sed 's#/src/site/markdown##g')"
        echo "cp ${base_path}${file} ${target}"
        cp ${base_path}${file} ${target}
    done
}

function book_process_resources() {
    local base_path="${1}"
    local docs_path="docs"
    book_clean "${docs_path}"
    book_generate_resources "${base_path}"
    book_copy_resources "${base_path}" "${docs_path}" "md"
    # file not found cause error
    #book_copy_resources "${base_path}" "${docs_path}" "gif"
    #book_copy_resources "${base_path}" "${docs_path}" "jpeg"
    book_copy_resources "${base_path}" "${docs_path}" "jpg"
    book_copy_resources "${base_path}" "${docs_path}" "png"
}

function book_build() {
    local base_path="${1}"

    book_process_resources "${base_path}"
    echo "book_build@$(pwd)"
    gitbook build
    ls -lh ./*
}

function book_deploy_prepare_github_ghpages() {
    local channel="${1}"
    local repo_name="${2}"
    local repo_url_prefix="${3}"

    if [ -d "gitbook-ghpages" ]; then rm -rf gitbook-ghpages; fi
    if [ -d "${repo_name}" ]; then rm -rf ${repo_name}; fi

    local repo_url="${repo_url_prefix}/${repo_name}"
    (git clone ${repo_url} && mv ${repo_name} gitbook-ghpages && cd gitbook-ghpages && git checkout gh-pages && git pull)
    if [ ! -d gitbook-ghpages/${channel} ]; then mkdir -p gitbook-ghpages/${channel}; fi

    rm -rf gitbook-ghpages/.git
    rm -rf gitbook-ghpages/${channel}/*
    cp -R _book/* gitbook-ghpages/${channel}/
    ls -lh gitbook-ghpages/*
}

function book_deploy_ssh() {
    local directory="${1}"
    local id="${2}"
    local port="${3}"
    local user_host="${4}"
    # ssh
    echo "ssh ${id} -p ${port} ${user_host} 'rm -rf ${directory}; mkdir -p ${directory}'"
    ssh ${id} -p ${port} ${user_host} "rm -rf ${directory}; mkdir -p ${directory}"
    echo "scp ${id} -P ${port} -r ./_book/* ${user_host}:${directory}"
    scp ${id} -P ${port} -r ./_book/* ${user_host}:${directory}
}

function book_deploy_webdav() {
    local channel="${1}"
    local directory="${2}"
    local target="${3}"
    local url="${4}"

    # webdav
    local files=($(find ./_book -type f -print0 | xargs -0 ls))
    for file in "${files[@]}"; do
        local remote_file="${directory}/$(echo "${file}" | sed 's#^./_book/##')"
        echo "upload file: ${file}, to: ${repository_url}${remote_file}"
        #curl --user "deployment:deployment" --upload-file "${file}" "${repository_url}${remote_file}"
        # TODO read username/password from file
        curl --user "deployment:deployment" -T "${file}" "${url}/${remote_file}"
    done
}

function book_deploy() {
    local channel="snapshot"
    local target="${1}"

    if [ ! -z "${BUILD_PUBLISH_CHANNEL}" ]; then channel="${BUILD_PUBLISH_CHANNEL}"; fi
    if [ -z "${target}" ]; then target="${INFRASTRUCTURE}"; fi

    echo "book_deploy@$(pwd) channel: ${channel}, target: ${target}"
    ls -lh ./*

    if [ "${target}" == "local" ]; then
        #directory="/usr/share/nginx/html/${directory}/"
        #id="-i ~/.ssh/mvnsite.local"
        #port="10022"
        #user_host="root@mvnsite.local"
        #book_deploy_ssh "${directory}" "${id}" "${port}" "${user_host}"
        local directory="oss-${channel}/gitbook"
        local url="http://nexus3.local:28081/nexus/repository/mvnsite"
        if [ ! -z "${LOCAL_NEXUS3}" ]; then url="${LOCAL_NEXUS3}/nexus/repository/mvnsite"; fi
        book_deploy_webdav "${channel}" "${directory}" "${target}" "${url}"
    elif [ "${target}" == "internal" ]; then
        #directory="/opt/mvnsite/${directory}/"
        #id="-i ~/.ssh/mvnsite.internal"
        #port="22"
        #user_host="root@mvnsite.internal"
        #book_deploy_ssh "${directory}" "${id}" "${port}" "${user_host}"
        local directory="oss-${channel}/gitbook"
        local url="http://nexus3.internal:28081/nexus/repository/mvnsite"
        if [ ! -z "${INTERNAL_NEXUS3}" ]; then url="${INTERNAL_NEXUS3}/nexus/repository/mvnsite"; fi
        book_deploy_webdav "${channel}" "${directory}" "${target}" "${url}"
    elif [ "${target}" == "github" ]; then
        local repo_url_prefix="https://${GITHUB_INFRASTRUCTURE_CONF_GIT_TOKEN}:x-oauth-basic@github.com/${OSS_GITBOOK_GHPAGES_REPO_OWNER}"
        book_deploy_prepare_github_ghpages "${channel}" "${OSS_GITBOOK_GHPAGES_REPO_NAME}" "${repo_url_prefix}"
    else
        echo "no valid target '${target}' specified"
        exit 1
    fi
}

# 将oss全套项目和配置repo逐个clone到当前目录下
# arguments: git_domain, source_group
function clone_oss_repositories() {
    local repo_url_prefix="${1}"
    local upstream_url_prefix="${2}"
    local source_group="${3}"

    for repository in ${!OSS_REPOSITORIES_DICT[@]}; do
        echo "clone ${repository} into $(pwd)"
        original_repository_path=$(echo ${OSS_REPOSITORIES_DICT[${repository}]} | sed 's#^/##')

        if [ ! -z "${source_group}" ]; then
            source_repository_path="${source_group}/${repository}"
            repository_path="${source_repository_path}"
        else
            repository_path="${original_repository_path}"
        fi

        # https://github.com/blog/1270-easier-builds-and-deployments-using-git-over-https-and-oauth
        remote_url="${repo_url_prefix}/${repository_path}"
        if [ -d ${repository} ]; then
            if [ ! -d ${repository}/.git ]; then
                ehco "${repository}/.git not found, please 'rm -rf ${repository}' manually"
                exit 1
            else
                echo "git repository already exists"
            fi
        else
            echo clone repository ${repository}
            git clone ${remote_url}
        fi

        #if [ ! -z "${upstream_url_prefix}" ]; then
            #upstream_url="${upstream_url_prefix}:${original_repository_path}.git"
            #if [ "${repository_path}" != "${original_repository_path}" ] && [ -z "$(cd ${repository}; git remote -v | grep -E 'upstream.+(fetch)')" ]; then
            #    (cd ${repository} && git remote add upstream ${upstream_url} && git fetch upstream)
            #fi
        #fi
    done
}

function gitbook_build() {
    if [ ! -d oss-workspace ]; then mkdir -p oss-workspace; fi

    # http: (http://)${git_domain}/${repository_path}(.git)
    # ssh: (ssh://)git@${git_domain}:${repository_path}(.git)
    local repo_url_prefix="https://${GITHUB_INFRASTRUCTURE_CONF_GIT_TOKEN}:x-oauth-basic@github.com"
    (cd oss-workspace; clone_oss_repositories "${repo_url_prefix}")

    for repository in ${!OSS_REPOSITORIES_DICT[@]}; do
        source_git_branch=""
        if [ "release" == "${BUILD_PUBLISH_CHANNEL}" ]; then source_git_branch="master"; else source_git_branch="develop"; fi
        (echo "checkout ${source_git_branch} of ${repository}"; cd oss-workspace/${repository}; git checkout ${source_git_branch} && git pull)
    done

    book_build "oss-workspace/"
    rm -rf _book/oss-workspace
}

if command -v nvm; then
    nvm install 6.11.0
    nvm use 6.11.0
fi

if type -p gitbook; then
    echo "gitbook executable found in PATH."
else
    echo "gitbook executable not found in PATH."
    if type -p npm; then
        echo "auto install gitbook via npm."
        npm --registry=https://registry.npm.taobao.org install 'gitbook-cli@2.3.0' -g
    else
        echo "gitbook executable not found in PATH."
        echo "can not auto install gitbook via npm."
    fi
fi

arg_base_path=""
if [ "deploy" != "${1}" ] && [ ! -z "${2}" ] && [ -d "${2}" ]; then
    arg_base_path="${2}"
    if [[ "${arg_base_path}" != */ ]]; then
        arg_base_path="${arg_base_path}/"
    fi
else
    arg_base_path="../../../"
fi
echo "arg_base_path: ${arg_base_path} ($(cd ${arg_base_path}; pwd))"

if [ -z "${OSS_GITBOOK_GHPAGES_REPO_OWNER}" ]; then export OSS_GITBOOK_GHPAGES_REPO_OWNER="home1-oss"; fi
if [ -z "${OSS_GITBOOK_GHPAGES_REPO_NAME}" ]; then export OSS_GITBOOK_GHPAGES_REPO_NAME="home1-oss-gitbook"; fi

case $1 in
    "serve")
        book_process_resources "${arg_base_path}"
        exec gitbook serve
        ;;

    "build")
        book_build "${arg_base_path}"
        ;;

    "build_debug")
        book_process_resources "${arg_base_path}"
        exec gitbook build ./ --log=debug --debug
        ;;

    "deploy")
        target="${2}"
        book_deploy "${target}"
        ;;

    "pdf")
        book_process_resources "${arg_base_path}"
        exec gitbook pdf ./ ./oss.pdf
        ;;

    "epub")
        book_process_resources "${arg_base_path}"
        exec gitbook epub ./ ./oss.epub
        ;;

    "mobi")
        book_process_resources "${arg_base_path}"
        exec gitbook mobi ./ ./oss.mobi
        ;;

    *)
        echo -e "Usage: $0 param
    param are follows:
        serve       Preview and serve your book
        build       Build the static website using
        build_debug Debugging build
        pdf         Generate a PDF file
        epub        Generate an ePub file
        mobi        Generate a Mobi file
        deploy      deploy to [ local | internal ]
        "
        ;;
esac

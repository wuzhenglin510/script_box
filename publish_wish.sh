#!/bin/bash
# Date    : 2018-02-07
# Version : 1.0

# global config
#--------------------------
SCRIPT_PATH=$(cd "$(dirname "$0")"; pwd)
SCRIPT_NAME=$(basename "$0")
USERNAME='leowu'
HOME_DIR=$(cd ~; pwd)
PROJECT_DIR="/Users/leo/projects/temp/shell/backend"
LOG_DIR="${SCRIPT_PATH}/logs/wish"

REMOTE_HOST="10.10.5.19"
REMOTE_PORT="22"
REMOTE_USER="leowu"
REMOTE_SECRET_KEY="leowu"
REMOTE_SNAPSHOP_DIR="/home/${REMOTE_USER}/publish/project_snap"
REMOTE_SNAPSHOP_DIR="/home/leowu/rs"
#--------------------------

usage() {
    echo -e "\033[32mUsage:\033[0m\\n \033[31m./${SCRIPT_NAME}\033[36m [src] [config]\033[0m"
    exit 2
}

check() {
    if [ "${1}" != "src" ] && [ "${1}" != "config" ]; then
        usage
    fi
}

rsync_src() {
    local log_file="${LOG_DIR}/src.${today}.list"
    echo -e "\033[32m Rsync src to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_SNAPSHOP_DIR} ...\033[0m"
    /usr/bin/rsync -av -e "ssh -p ${REMOTE_PORT} -i ${REMOTE_SECRET_KEY}" \
    --exclude="api/config" \
    --exclude="proxy/config" \
    --exclude=".git" \
    --exclude=".gitignore" \
    "${PROJECT_DIR}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_SNAPSHOP_DIR}" > "${log_file}"
    return 0
}

rsync_config() {
    local log_file="${LOG_DIR}/config.${today}.list"
    echo -e "\033[34m Rsync config to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_SNAPSHOP_DIR} ...\033[0m"
    /usr/bin/rsync -av -e "ssh -p ${REMOTE_PORT} -i ${REMOTE_SECRET_KEY}" \
    --include="api/config" \
    --include="proxy/config" \
    "${PROJECT_DIR}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_SNAPSHOP_DIR}" > "${log_file}"
    return 0
}

run() {
    echo "${1}"
    case "${1:-NONE}" in
    src)
        rsync_src
        ;;
    config)
        rsync_config 
        ;;
    *)
        return 0
        ;;
    esac
}

#----------------Main---------------------
today=$(date '+%Y%m%d.%H%M')
PARAMS=(NULL NULL)
[ $# -eq 0 ] && usage
idx=0
while [ $# -gt 0 ]
do
    check "$1"
    PARAMS[$idx]="$1"
    let "idx++"
    shift
done

cd ${PROJECT_DIR}
git checkout master
git pull origin master >> "${LOG_DIR}"/git.${today}.log
git tag -a "v$(date +'%Y-%m-%d-%H-%M-%S')" -m "publish version"
git push

cd "${SCRIPT_PATH}"
ridx=0
while(( ridx<idx ))
do
    run "${PARAMS[$ridx]}"
    let "ridx++"
done
#-----------------------------------------

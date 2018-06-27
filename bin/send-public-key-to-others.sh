#########################################################################
# File Name: send-public-key-to-others.sh
# Author: chaofei
# mail: chaofeibest@163.com
# Created Time: 2017-08-08 00:35:53
#########################################################################
#!/bin/bash

function convert_relative_path_to_absolute_path() {
  this="${0}"
  bin=`dirname "${this}"`
  script=`basename "${this}"`
  bin=`cd "${bin}"; pwd`
  this="${bin}/${script}"
}
      
function get_soft_home() {
  if [ -z "${SOFT_HOME}" ]; then
    export SOFT_HOME=`dirname "${bin}"`
  fi
}

function load_args_file() {
  if [ -f "${1}" ]; then
    rpm -qa | grep dos2unix > /dev/null
    DOS2UNIX_IS_INSTALL=$?
    if [ "${DOS2UNIX_IS_INSTALL}" -eq 0 ]; then
      dos2unix "${1}" > /dev/null 2>&1
    fi
    source "${1}"
  else
    echo "${1} is not exist!"
  fi
}
                    
convert_relative_path_to_absolute_path
get_soft_home
load_args_file "${SOFT_HOME}/conf/config.cfg"

function ssh_copy_id() {
  OLD_IFS="${IFS}"
  IFS=",${now},"
  for TMP_IP_USER_PWD in ${IPS_USERS_PWDS}; do
    TMP_IP=`echo "${TMP_IP_USER_PWD}" | sed 's|:| |g' | awk '{print$1}'`
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@${TMP_IP}
  done
  IFS="${OLD_IFS}"
}

ssh_copy_id

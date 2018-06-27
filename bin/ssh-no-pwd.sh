#########################################################################
# File Name: ssh-no-pwd.sh
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

function get_root_disk() {
  ROOT_DISK=`dirname ${SOFT_HOME}`
  echo "${ROOT_DISK}"
}

function get_all_local_ips() {
  ifconfig | grep "\([0-9]\)\{1,3\}\.\([0-9]\)\{1,3\}\.\([0-9]\)\{1,3\}" \
  | awk '{print $2}' | grep -v "127.0.0.1" | sed 's/addr://' \
  | xargs | sed 's/ /,/g'
}

function is_local_ip() {
  if [ -n "${1}" ]; then
    ARGS_IP="${1}"
    if [ "${ARGS_IP}" == "localhost" ] || [ "${ARGS_IP}" == "127.0.0.1" ]; then
      echo true
    else
      ALL_LOCAL_IPS=`get_all_local_ips`
      OLD_IFS="${IFS}"
      IFS=",${now},"
      for TMP_IP in ${ALL_LOCAL_IPS}; do
        if [ -n "${TMP_IP}" ] && [ "${ARGS_IP}" == "${TMP_IP}" ]; then
          echo true
        break
        fi
      done
      IFS="${OLD_IFS}"
    fi
  fi
}

function update_self_or_args() {
  OLD_IFS="${IFS}"
  IFS=",${now},"
  for TMP_IP_USER_PWD in ${IPS_USERS_PWDS}; do
    TMP_IP=`echo "${TMP_IP_USER_PWD}" | sed 's|:| |g' | awk '{print$1}'`
    ROOT_DISK=`get_root_disk`
    IS_LOCAL_IP=`is_local_ip "${TMP_IP}"`
    if [ ! "${IS_LOCAL_IP}" == "true" ]; then
      if [ -n "${1}" ]; then
        DEST_DIR=`dirname "${1}"`
        scp -r "${1}" ${TMP_IP}:"${DEST_DIR}/"
      else
        scp -r "${SOFT_HOME}" ${TMP_IP}:"${ROOT_DISK}/"
      fi
    fi
  done
  IFS="${OLD_IFS}"
}

function ssh_ken_gen() {
  OLD_IFS="${IFS}"
  IFS=",${now},"
  for TMP_IP_USER_PWD in ${IPS_USERS_PWDS}; do
    TMP_IP=`echo "${TMP_IP_USER_PWD}" | sed 's|:| |g' | awk '{print$1}'`
    IS_LOCAL_IP=`is_local_ip "${TMP_IP}"`
    if [ ! "${IS_LOCAL_IP}" == "true" ]; then
      ssh ${TMP_IP} "rm -rf ~/.ssh"
      ssh ${TMP_IP} "ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa"
      ssh ${TMP_IP} "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
      ssh ${TMP_IP} "chmod 600 ~/.ssh/authorized_keys"
      ssh-copy-id -i ~/.ssh/id_rsa.pub root@${TMP_IP}
    else
      rm -rf ~/.ssh
      ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
      cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
      chmod 600 ~/.ssh/authorized_keys
      ssh-copy-id -i ~/.ssh/id_rsa.pub root@${TMP_IP}
    fi
  done
  IFS="${OLD_IFS}"
}

function ssh_copy_id() {
  OLD_IFS="${IFS}"
  IFS=",${now},"
  for TMP_IP_USER_PWD in ${IPS_USERS_PWDS}; do
    TMP_IP=`echo "${TMP_IP_USER_PWD}" | sed 's|:| |g' | awk '{print$1}'`
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@${TMP_IP}
  done
  IFS="${OLD_IFS}"
}

function call_send_public_key_to_others() {
  OLD_IFS="${IFS}"
  IFS=",${now},"
  for TMP_IP_USER_PWD in ${IPS_USERS_PWDS}; do
    TMP_IP=`echo "${TMP_IP_USER_PWD}" | sed 's|:| |g' | awk '{print$1}'`
    ssh ${TMP_IP} "${SOFT_HOME}/bin/send-public-key-to-others.sh"
  done
  IFS="${OLD_IFS}"
}

function ssh_no_pwd() {
  ssh_ken_gen
  if [ "${1}" == "update" ]; then
    shift
    update_self_or_args $*
  else
    update_self_or_args $*
  fi
  ssh_copy_id
  call_send_public_key_to_others
}

ssh_no_pwd

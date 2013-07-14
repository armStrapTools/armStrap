#!/bin/bash

#############################################################################
#
# hookscript.sh
#
# This is a very crude and ugly example of hook script that can be used with
# the -A switch to polulate a website/repository.
#
# There should be more errorcheck and better logic to handle the different
# parts but i'm a bit lazy :) Use at your own risk...
#

TMP_DIR="`pwd`"

TMP_KERNEL="/var/www/armstrap/kernel"
TMP_ROOTFS="/var/www/armstrap/rootfs"
TMP_UBOOT="/var/www/armstrap/uboot"
TMP_LOG="/var/www/armstrap/log"

if [ ! -z "${2}" ]; then
  if [ -f "${2}" ]; then
    cp ${2} /${TMP_LOG}/armStrap-builder.log
  fi
fi

if [ -d "${1}" ]; then
  cd ${1}

  for i in *.sh; do
    TMP_TYPE="`echo ${i} | cut -d- -f2`"
    cp ${i} ${TMP_KERNEL}/${TMP_TYPE}/
  done
  
  for i in *.deb; do
    TMP_TYPE="`echo ${i} | cut -d- -f1`"
    TMP_OLD="`echo ${i} | cut -d'_' -f1`"
    echo "${TMP_TYPE} : ${TMP_OLD}"
    REPREPRO_BASE_DIR="/var/www/packages/apt/armstrap" reprepro -C main remove ${TMP_TYPE} ${TMP_OLD}
    REPREPRO_BASE_DIR="/var/www/packages/apt/armstrap" reprepro -C main includedeb ${TMP_TYPE} ${i}    
  done
  
  for i in *.txz; do
    TMP_TYPE="`echo ${i} | cut -d- -f1`"
    TMP_BOOT="`echo ${i} | cut -d- -f2`"
    case ${TMP_TYPE} in
      debian)
        cp ${i} ${TMP_ROOTFS}/
        ;;
      ubuntu)
        cp ${i} ${TMP_ROOTFS}/
        ;;
    esac
    
    case ${TMP_BOOT} in
      u)
        cp ${i} ${TMP_UBOOT}/
        ;;
      esac
  done
else
 echo "Usage $0 <PKG_DIRECTORY> <LOGFILE>"
fi

cd ${TMP_DIR}

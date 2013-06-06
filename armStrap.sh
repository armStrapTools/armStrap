#!/bin/bash

#
# Variables that should never be changed
#

ARMSTRAP_VERSION="0.39"
ARMSTRAP_NAME=`basename ${0}`

printf "\n%s version %s\n" "${ARMSTRAP_NAME}" "${ARMSTRAP_VERSION}"
printf "Copyright (C) 2013 Eddy Beaupre\n\n"

if [ "`id -u`" -ne "0" ]; then
  . ./lib/utils.sh
  showUsage
  printf "\nYou (%s) are not root! Try again with 'sudo %s'.\n\n" "`whoami`" "${ARMSTRAP_NAME}"
  exit 1
fi

ARMSTRAP_DATE=`date +%y%m%d_%H%M%S`
ARMSTRAP_ROOT=`pwd`
ARMSTRAP_THREADS="16"

ARMSTRAP_MNT="${ARMSTRAP_ROOT}/mnt"
ARMSTRAP_SRC="${ARMSTRAP_ROOT}/src"
ARMSTRAP_LOG="${ARMSTRAP_ROOT}/log"
ARMSTRAP_IMG="${ARMSTRAP_ROOT}/img"
ARMSTRAP_WRK="${ARMSTRAP_ROOT}/wrk"
ARMSTRAP_DEB="${ARMSTRAP_ROOT}/deb"

ARMSTRAP_BOARDS="${ARMSTRAP_ROOT}/boards"

mkdir -p ${ARMSTRAP_LOG}

# The logfile will be renamed to the real log file later
ARMSTRAP_LOG_FILE=`mktemp ${ARMSTRAP_LOG}/armStrap.XXXXXXXX`

# The image name is defined later.
ARMSTRAP_IMAGE_NAME=""

# ARMSTRAP_IMAGE_SIZE is in MB
ARMSTRAP_IMAGE_SIZE="2048"
ARMSTRAP_DEVICE=""
ARMSTRAP_IMAGE_DEVICE=""
ARMSTRAP_DEVICE_MAPS=("")

# The version of the kernel that has been build
ARMSTRAP_KERNEL_VERSION=""

# If we only want to create a kernel
ARMSTRAP_KERNEL_BUILDER=""

#
# Here we go...
#

source ./config.sh

for i in ./lib/*.sh; do
  source ${i}
done
ARMSTRAP_EXIT=""
while getopts ":b:d:i:s:h:p:z:n:r:cCSIwWNk" opt; do
  case $opt in
    b)
      ARMSTRAP_CONFIG="${OPTARG}"
      ;;
    d)
      ARMSTRAP_DEVICE="${OPTARG}"
      ;;
    i)
      ARMSTRAP_IMAGE_NAME="${OPTARG}"
      ;;
    s)
      ARMSTRAP_IMAGE_SIZE="${OPTARG}"
      ;;
    h)
      ARMSTRAP_HOSTNAME="${OPTARG}"
      ;;
    p)
      ARMSTRAP_PASSWORD="${OPTARG}"
      ;;
    w)
      ARMSTRAP_SWAP="yes"
      ;;
    W)
      ARMSTRAP_SWAP=""
      ;;
    z)
      ARMSTRAP_SWAP_SIZE=="${OPTARG}"
      ;;
    n)
      ARMSTRAP_ETH0_MODE="static"
      ip=(${OPTARG})
      ARMSTRAP_ETH0_IP=${ip[0]}
      ARMSTRAP_ETH0_MASK="${ip[1]}"
      ARMSTRAP_ETH0_GW="${ip[2]}"
      ;;
    N)
      ARMSTRAP_ETH0_MODE="dhcp"
      ;;
    r)
      ARMSTRAP_ETH0_DNS="${OPTARG}"
      ;;
    e)
      ARMSTRAP_ETH0_DOMAIN="${OPTARG}"
      ;;
    k)
      ARMSTRAP_KERNEL_BUILDER="YES"
      ;;
    c)
      showLicence
      ARMSTRAP_EXIT="Yes"
      ;;
    C)
      printStatus "armStrap" "Cleaning ${ARMSTRAP_LOG} directory"
      rm -rf ${ARMSTRAP_LOG}/*
      printStatus "armStrap" "Cleaning ${ARMSTRAP_WRK} directory"
      rm -rf ${ARMSTRAP_WRK}/*
      printStatus "armStrap" "Cleaning ${ARMSTRAP_DEB} directory"
      rm -rf ${ARMSTRAP_DEB}/*
      ARMSTRAP_EXIT="Yes"
      ;;
    S)
      printStatus "armStrap" "Cleaning ${ARMSTRAP_SRC} directory"
      rm -rf ${ARMSTRAP_SRC}/*
      ARMSTRAP_EXIT="Yes"
      ;;
    I)
      printStatus "armStrap" "Cleaning ${ARMSTRAP_IMG} directory"
      rm -rf ${ARMSTRAP_IMG}/*
      ARMSTRAP_EXIT="Yes"
      ;;
    \?)
      showUsage
      ARMSTRAP_EXIT="Yes"
      ;;
    :)
      printf "Option -%s requires an argument.\n\n" "${OPTARG}"
      showUsage
      exit 1
    ;;
  esac
done

if [ ! -z "${ARMSTRAP_EXIT}" ]; then
  exit 0
fi

checkDirectory ${ARMSTRAP_SRC}
checkDirectory ${ARMSTRAP_MNT}
checkDirectory ${ARMSTRAP_IMG}
checkDirectory ${ARMSTRAP_WRK}
checkDirectory ${ARMSTRAP_DEB}

printStatus "initBuild" "Reading ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/config.sh"
source ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/config.sh

rm -f ${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BUILD_DEBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log
mv ${ARMSTRAP_LOG_FILE} ${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BUILD_DEBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log
ARMSTRAP_LOG_FILE="${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BUILD_DEBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log"

if [ -z "${ARMSTRAP_KERNEL_BUILDER}" ]; then
  if [ -z "${ARMSTRAP_DEVICE}" ]; then
    if [ -z "${ARMSTRAP_IMAGE_NAME}" ]; then
      ARMSTRAP_IMAGE_NAME=${ARMSTRAP_IMG}/${ARMSTRAP_CONFIG}-${BUILD_DEBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.img
    fi
  fi
fi

for i in ${BUILD_SCRIPTS}; do
  printStatus "initBuild" "Reading ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/${i}"
  source ./boards/${ARMSTRAP_CONFIG}/${i}
done

if [ -z "${ARMSTRAP_KERNEL_BUILDER}" ]; then
  showConfig
fi

funExist init
if [ ${?} -eq 0 ]; then
  init
fi

if [ -z "${ARMSTRAP_KERNEL_BUILDER}" ]; then
  if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
    setupImg ${BUILD_DISK_LAYOUT[@]}
  else
    setupSD ${BUILD_DISK_LAYOUT[@]}
  fi
fi

  installOS

if [ -z "${ARMSTRAP_KERNEL_BUILDER}" ]; then
  if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
    finishImg ${BUILD_DISK_LAYOUT[@]}
  else
    finishSD ${BUILD_DISK_LAYOUT[@]}
  fi
fi


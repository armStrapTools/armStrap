#!/bin/bash

PRG_VERSION="0.21"

BUILD_DATE=`date +%y%m%d`
BUILD_ROOT=`pwd`
BUILD_MNT="${BUILD_ROOT}/mnt"
BUILD_SRC="${BUILD_ROOT}/src"
BUILD_OBJ="${BUILD_ROOT}/obj"
BUILD_LOG="${BUILD_ROOT}/log"
BUILD_LOG_FILE="${BUILD_LOG}/${BOARD_CONFIG}-${BUILD_DEB_SUITE}_${BOARD_HOSTNAME}-${BUILD_DATE}.log"
BUILD_THREADS="16"

# These are defined in boards/<name>/config.sh 
BUILD_MNT_ROOT=""
BUILD_MNT_BOOT=""

# This is in MB
BUILD_IMAGE_SIZE=1024
BUILD_IMAGE_DEVICE=""
BUILD_IMAGE_NAME=${BUILD_ROOT}/${BOARD_CONFIG}-${BUILD_DEB_SUITE}_${BOARD_HOSTNAME}-${BUILD_DATE}.img
BUILD_IMAGE_BOOTP=""
BUILD_IMAGE_ROOTP=""

# Here we go...
source ./config.sh

for i in ./lib/*.sh; do
  source $i
done

showTitle

while getopts ":b:d:i:s:h:p:z:n:r:cwWN" opt; do
  case $opt in
    b)
      BOARD_CONFIG="${OPTARG}"
      ;;
    d)
      BUILD_DEVICE="${OPTARG}"
      ;;
    i)
      BUILD_IMAGE_NAME="${OPTARG}"
      ;;
    s)
      BUILD_IMAGE_SIZE="${OPTARG}"
      ;;
    h)
      BOARD_HOSTNAME="${OPTARG}"
      ;;
    p)
      BOARD_PASSWORD="${OPTARG}"
      ;;
    w)
      BOARD_SWAP="yes"
      ;;
    W)
      BOARD_SWAP=""
      ;;
    z)
      BOARD_SWAP_SIZE=="${OPTARG}"
      ;;
    n)
      BOARD_ETH0_MODE="static"
      ip=(${OPTARG})
      BOARD_ETH0_IP=${ip[0]}
      BOARD_ETH0_MASK="${ip[1]}"
      BOARD_ETH0_GW="${ip[2]}"
      ;;
    N)
      BOARD_ETH0_MODE="static"
      ;;
    r)
      BOARD_DNS="${OPTARG}"
      ;;
    e)
      BOARD_DOMAIN="${OPTARG}"
      ;;
    c)
      showLicence
      exit 0
      ;;
    \?)
      showUsage
      exit 1
      ;;
    :)
      printf "Option -%s requires an argument.\n\n" "${OPTARG}"
      showUsage
      exit 1
    ;;
  esac
done

isRoot
checkStatus "Only root can run this script"

checkDirectory ${BUILD_SRC}
checkDirectory ${BUILD_OBJ}
checkDirectory ${BUILD_MNT}
checkDirectory ${BUILD_LOG}

rm -f ${BUILD_LOG_FILE}

printStatus "initBuild" "Reading ./boards/${BOARD_CONFIG}/config.sh"
source ./boards/${BOARD_CONFIG}/config.sh

for i in ${BUILD_SCRIPTS}; do
  printStatus "initBuild" "Reading ./boards/${BOARD_CONFIG}/${i}"
  source ./boards/${BOARD_CONFIG}/${i}
done

funExist init
if [ ${?} -eq 0 ]; then
  init
fi

installPrereqs

if [ -z "${BUILD_DEVICE}" ] then
  mkImage ${IMAGE_NAME} ${IMAGE_SIZE}
else
  setupDevice ${BUILD_DEVICE}
fi

createFS ${IMAGE_ROOTP}

mountAll

installOS

unmountAll

if [ -z "${BUILD_DEVICE}" ]; then
  freeImage ${IMAGE_DEVICE}
fi

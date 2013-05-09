#!/bin/bash

#
# Variables that should never be changed
#

PRG_VERSION="0.21"
PRG_NAME=`basename ${0}`

BUILD_DATE=`date +%y%m%d_%H%M%S`
BUILD_ROOT=`pwd`
BUILD_THREADS="16"

BUILD_MNT="${BUILD_ROOT}/mnt"
BUILD_SRC="${BUILD_ROOT}/src"
BUILD_LOG="${BUILD_ROOT}/log"
BUILD_IMG="${BUILD_ROOT}/img"

mkdir -p ${BUILD_LOG}

# The logfile will be renamed to the real log file later
BUILD_LOG_FILE=`mktemp ${BUILD_LOG}/armStrap.XXXXXXXX`

# These are defined in boards/<name>/config.sh 
BUILD_MNT_ROOT=""
BUILD_MNT_BOOT=""

# The image name is defined later.
BUILD_IMAGE_NAME=""

# BUILD_IMAGE_SIZE is in MB
BUILD_IMAGE_SIZE="1024"
BUILD_IMAGE_DEVICE=""
BUILD_IMAGE_BOOTP=""
BUILD_IMAGE_ROOTP=""

#
# Functions that can't be included because they are too soon
#

# Usage: logStatus <function> <message>

function logStatus {
  local TMP_TIME=`date +%y/%m/%d-%H:%M:%S`
  printf "[% 17s] % 15s : %s\n" "${TMP_TIME}" "${1}" "${2}" >> ${BUILD_LOG_FILE}
}

# Usage: printStatus <function> <message>

function printStatus {
  printf "** % 15s : %s\n" "${1}" "${2}"
  logStatus "${1}" "${2}"
}

function checkStatus {
  if [ $? -ne 0 ]; then
    echo ""
    printStatus "checkStatus" "Aborting (${1})"
    exit 1
  fi
}

# Usage: checkDirectory <path>

function checkDirectory {
  if [ ! -d "${1}" ]; then
    mkdir -p ${1}
    checkStatus "Creation of directory ${1} failed"
    printStatus "checkDirectory" "Creating ${1}"
  fi
}

# Usage: isRoot
function isRoot {
  if [ "`id -u`" -ne "0" ]; then
    logStatus "isRoot" "User `whoami` (`id -u`) is not root"
    return 1
  fi
  return 0
}

function showTitle {
 printf "\n%s version %s\n" "${PRG_NAME}" "${PRG_VERSION}"
 printf "Copyright (C) 2013 Eddy Beaupre\n\n"
}

#
# Here we go...
#

showTitle
isRoot
checkStatus "Only root can run this script"

checkDirectory ${BUILD_SRC}
checkDirectory ${BUILD_MNT}
checkDirectory ${BUILD_IMG}

printStatus "${PRG_NAME}" "Reading ./config.sh"
source ./config.sh

for i in ./lib/*.sh; do
  printStatus "${PRG_NAME}" "Reading ${i}"
  source ${i}
done

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

rm -f ${BUILD_LOG_FILE}

printStatus "initBuild" "Reading ./boards/${BOARD_CONFIG}/config.sh"
source ./boards/${BOARD_CONFIG}/config.sh

rm -f ${BUILD_LOG}/${BOARD_CONFIG}-${BUILD_DEB_SUITE}_${BOARD_HOSTNAME}-${BUILD_DATE}.log
mv ${BUILD_LOG_FILE} ${BUILD_LOG}/${BOARD_CONFIG}-${BUILD_DEB_SUITE}_${BOARD_HOSTNAME}-${BUILD_DATE}.log
BUILD_LOG_FILE="${BUILD_LOG}/${BOARD_CONFIG}-${BUILD_DEB_SUITE}_${BOARD_HOSTNAME}-${BUILD_DATE}.log"

if [ -z ${BUILD_IMAGE_NAME} ]; then
  BUILD_IMAGE_NAME=${BUILD_IMG}/${BOARD_CONFIG}-${BUILD_DEB_SUITE}_${BOARD_HOSTNAME}-${BUILD_DATE}.img
fi

for i in ${BUILD_SCRIPTS}; do
  printStatus "initBuild" "Reading ./boards/${BOARD_CONFIG}/${i}"
  source ./boards/${BOARD_CONFIG}/${i}
done

showConfig

funExist init
if [ ${?} -eq 0 ]; then
  init
fi

installPrereqs

if [ -z "${BUILD_DEVICE}" ]; then
  setupImage ${BUILD_IMAGE_NAME} ${BUILD_IMAGE_SIZE}
else
  setupDevice ${BUILD_DEVICE}
fi

createFS ${BUILD_IMAGE_ROOTP}

mountAll

installOS

unmountAll

if [ -z "${BUILD_DEVICE}" ]; then
  freeImage ${BUILD_IMAGE_DEVICE}
fi

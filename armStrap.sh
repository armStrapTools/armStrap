#!/bin/bash

#
# First, we need to be root...
#

if [ "`id -u`" -ne "0" ]; then
  sudo -p "`basename $0` must be run as root, please enter your sudo password : " $0 $@
  exit 0
fi

#
# Variables that should never be changed
#

ARMSTRAP_VERSION="0.75"
ARMSTRAP_NAME=`basename ${0}`

ARMSTRAP_DATE=`date +%y%m%d_%H%M%S`
ARMSTRAP_ROOT=`pwd`

ARMSTRAP_MNT="${ARMSTRAP_ROOT}/mnt"
ARMSTRAP_LOG="${ARMSTRAP_ROOT}/log"
ARMSTRAP_IMG="${ARMSTRAP_ROOT}/img"
ARMSTRAP_SRC="${ARMSTRAP_ROOT}/src"
ARMSTRAP_PKG="${ARMSTRAP_ROOT}/pkg"
ARMSTRAP_CFG="${ARMSTRAP_ROOT}/cfg"

ARMSTRAP_BOARDS="${ARMSTRAP_ROOT}/boards"

if [ ! -d "${ARMSTRAP_LOG}" ]; then
  mkdir -p ${ARMSTRAP_LOG}
fi

# The logfile will be renamed to the real log file later
ARMSTRAP_LOG_FILE=`mktemp ${ARMSTRAP_LOG}/armStrap.XXXXXXXX`

# The image name is defined later.
ARMSTRAP_IMAGE_NAME=""

# ARMSTRAP_IMAGE_SIZE is in MB
ARMSTRAP_IMAGE_SIZE="2048"
ARMSTRAP_DEVICE=""
ARMSTRAP_IMAGE_DEVICE=""
ARMSTRAP_DEVICE_MAPS=("")

# ARMSTRAP default distribution, board may override this.
ARMSTRAP_OS="debian"

ARMSTRAP_MFLAGS="-j16"

# Theses are internal values that should not be changed unless you understand
# exactly what they are doing.
ARMSTRAP_KBUILDER=""
ARMSTRAP_RUPDATER=""
ARMSTRAP_UBUILDER=""
ARMSTRAP_ABUILDER=""
ARMSTRAP_ABUILDER_HOOK=""
ARMSTRAP_UPDATE=""
ARMSTRAP_EXIT=""

#
# Here we go...
#

source ./config.sh

for i in ./lib/*.sh; do
  source ${i}
done

detectAnsi
showTitle "${ARMSTRAP_NAME}" "${ARMSTRAP_VERSION}"

ARMSTRAP_EXIT=""
while getopts ":b:d:i:s:h:p:w:n:r:e:C:F:H:V:cWNKRUIA" opt; do
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
      ARMSTRAP_SWAP_SIZE="${OPTARG}"
      ;;
    W)
      ARMSTRAP_SWAP=""
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
    c)
      showLicence
      ARMSTRAP_EXIT="Yes"
      ;;
    K)
      ARMSTRAP_KBUILDER="Yes"
      ;;
    V)
      ARMSTRAP_KBUILDER_VERSION="${OPTARG}"
      ;;
    C)
      ARMSTRAP_KBUILDER_CONF="${OPTARG}"
      ;;
    I)
      ARMSTRAP_KBUILDER_MENUCONFIG="Yes"
      ;;
    R)
      ARMSTRAP_RUPDATER="Yes"
      ;;
    F)
      ARMSTRAP_OS="${OPTARG}"
      ;;
    U)
      ARMSTRAP_UBUILDER="Yes"
      ;;
    A)
      ARMSTRAP_ABUILDER="Yes"
      ;;
    H)
      ARMSTRAP_ABUILDER_HOOK="${OPTARG}"
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

isTrue "${ARMSTRAP_EXIT}"
if [ $? -ne 0 ]; then
  exit 0
fi

ARMSTRAP_BOARD_CONFIG="${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}"

checkDirectory ${ARMSTRAP_MNT}
checkDirectory ${ARMSTRAP_IMG}
checkDirectory ${ARMSTRAP_SRC}
checkDirectory ${ARMSTRAP_PKG}

isTrue "${ARMSTRAP_ABUILDER}"
if [ $? -ne 0 ]; then
  allBuilder
  exit 0
fi

source ${ARMSTRAP_BOARD_CONFIG}/config.sh

checkConfig
checkRootFS

loadLibrary "${ARMSTRAP_BOARD_CONFIG}" ${BUILD_INIT_SCRIPTS}

rm -f ${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BUILD_ARMBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log
mv ${ARMSTRAP_LOG_FILE} ${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BUILD_ARMBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log
ARMSTRAP_LOG_FILE="${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BUILD_ARMBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log"

isTrue "${ARMSTRAP_KBUILDER}"
if [ $? -ne 0 ]; then
  kBuilder
  ARMSTRAP_EXIT="Yes"
fi

isTrue "${ARMSTRAP_RUPDATER}"
if [ $? -ne 0 ]; then
  rBuilder
  ARMSTRAP_EXIT="Yes"
fi

isTrue "${ARMSTRAP_UBUILDER}"
if [ $? -ne 0 ]; then
  uBuilder
  ARMSTRAP_EXIT="Yes"
fi

if [ ! -z "${ARMSTRAP_EXIT}" ]; then
  exit 0
fi

if [ -z "${ARMSTRAP_DEVICE}" ]; then
  if [ -z "${ARMSTRAP_IMAGE_NAME}" ]; then
    ARMSTRAP_IMAGE_NAME=${ARMSTRAP_IMG}/${ARMSTRAP_CONFIG}-${BUILD_ARMBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.img
  fi
fi

showConfig

loadLibrary "${ARMSTRAP_BOARD_CONFIG}" ${BUILD_INSTALL_SCRIPTS}

if [ ! -z "${BUILD_PREREQ}" ]; then
  installPrereqs ${BUILD_PREREQ}
fi

if [ ! -z "${BUILD_MAC_VENDOR}" ]; then
  macAddress "${BUILD_MAC_VENDOR}"
fi

funExist ${BOARD_INIT_FUNCTION}
if [ ${?} -eq 0 ]; then
  ${BOARD_INIT_FUNCTION}
fi

if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
  setupImg ${BUILD_DISK_LAYOUT[@]}
else
  setupSD ${BUILD_DISK_LAYOUT[@]}
fi

funExist ${BUILD_INSTALL_FUNCTION}
if [ ${?} -eq 0 ]; then
  ${BUILD_INSTALL_FUNCTION}
else
  default_installOS
fi

if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
  finishImg ${BUILD_DISK_LAYOUT[@]}
else
  finishSD ${BUILD_DISK_LAYOUT[@]}
fi

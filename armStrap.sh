#!/bin/bash

#
# First, we need to be root...
#

if [ "`id -u`" -ne "0" ]; then
  sudo -p "`basename $0` must be run as root, please enter your sudo password : " $0 $@ 
  exit 0
fi

#
# Variables that should never be changed, unless you know what you're doing.
#

ARMSTRAP_VERSION="0.86"
ARMSTRAP_NAME=`basename ${0}`

ARMSTRAP_DATE=`date +%y%m%d_%H%M%S`
ARMSTRAP_ROOT=`pwd`

ARMSTRAP_MNT="${ARMSTRAP_ROOT}/mnt"
ARMSTRAP_LOG="${ARMSTRAP_ROOT}/log"
ARMSTRAP_IMG="${ARMSTRAP_ROOT}/img"
ARMSTRAP_SRC="${ARMSTRAP_ROOT}/src"
ARMSTRAP_PKG="${ARMSTRAP_ROOT}/pkg"

ARMSTRAP_BOARDS="${ARMSTRAP_ROOT}/boards"
ARMSTRAP_KERNELS="${ARMSTRAP_ROOT}/builder/kernels"
ARMSTRAP_BOOTLOADERS="${ARMSTRAP_ROOT}/builder/bootloaders"
ARMSTRAP_ROOTFS="${ARMSTRAP_ROOT}/builder/rootfs"

if [ ! -d "${ARMSTRAP_LOG}" ]; then
  mkdir -p ${ARMSTRAP_LOG}
fi

# The logfile will be renamed to the real log file later
ARMSTRAP_LOG_FILE="`mktemp ${ARMSTRAP_LOG}/armStrap.XXXXXXXX`"

# Theses are our control for the UI.
ARMSTRAP_GUI_FF1=$(mktemp --tmpdir armStrap_UI.XXXXXXXX)
ARMSTRAP_GUI_FF2=$(mktemp --tmpdir armStrap_UI.XXXXXXXX)
ARMSTRAP_GUI_PCT=0
ARMSTRAP_GUI_DISABLE=""

# The image name is defined later.
ARMSTRAP_IMAGE_NAME=""

# ARMSTRAP_IMAGE_SIZE is in MB
ARMSTRAP_IMAGE_SIZE="2048"
ARMSTRAP_DEVICE=""
ARMSTRAP_IMAGE_DEVICE=""
ARMSTRAP_DEVICE_MAPS=("")

# ARMSTRAP defaults
ARMSTRAP_HOSTNAME="armStrap"
ARMSTRAP_PASSWORD="armStrap"
ARMSTRAP_TIMEZONE="America/Montreal"

ARMSTRAP_SWAPFILE="/var/swap"
ARMSTRAP_SWAPSIZE="128"
ARMSTRAP_SWAPFACTOR="2"
ARMSTRAP_SWAPMAX="2048"

ARMSTRAP_ETH0_MODE="dhcp"

# Any flags you want to add to make
ARMSTRAP_MFLAGS="-j8"

# Internal variables that may be changes by the script
ARMSTRAP_KBUILDER=""
ARMSTRAP_RUPDATER=""
ARMSTRAP_UBUILDER=""
ARMSTRAP_UPDATE=""
ARMSTRAP_EXIT=""
ARMSTRAP_ABUILDER=""
ARMSTRAP_ABUILDER_HOOK=""
ARMSTRAP_KERNEL_LIST=""
ARMSTRAP_LOADER_LIST=""
ARMSTRAP_ROOTFS_LIST=""
# Theses are used by postArmStrap to populate the web server and by
# armStrap to fetch them.
ARMSTRAP_ABUILDER_URL="http://archive.armstrap.net"
ARMSTRAP_ABUILDER_ROOT="/var/www/armstrap-archive"
ARMSTRAP_ABUILDER_KERNEL="${ARMSTRAP_ABUILDER_ROOT}/kernel"
ARMSTRAP_ABUILDER_KERNEL_URL="${ARMSTRAP_ABUILDER_URL}/kernel"
ARMSTRAP_ABUILDER_ROOTFS="${ARMSTRAP_ABUILDER_ROOT}/rootfs"
ARMSTRAP_ABUILDER_ROOTFS_URL="${ARMSTRAP_ABUILDER_URL}/rootfs"
ARMSTRAP_ABUILDER_LOADER="${ARMSTRAP_ABUILDER_ROOT}/loader"
ARMSTRAP_ABUILDER_LOADER_URL="${ARMSTRAP_ABUILDER_URL}/loader"
ARMSTRAP_ABUILDER_LOGS="${ARMSTRAP_ABUILDER_ROOT}/logs"
ARMSTRAP_ABUILDER_LOGS_URL="${ARMSTRAP_ABUILDER_URL}/logs"
ARMSTRAP_ABUILDER_REPO="/var/www/packages/apt/armstrap"
ARMSTRAP_ABUILDER_REPO_URL="${ARMSTRAP_ABUILDER_URL}/apt/armstrap/"

ARMSTRAP_TAR_EXTRACT="tar -xJ"
ARMSTRAP_TAR_COMPRESS="tar -cJvf"
ARMSTRAP_TAR_EXTENSION=".txz"

# Theses are packages that armStrap need for itself.
ARMSTRAP_PREREQ="dialog"

# Our cleanup function
trap on_exit EXIT

# There are still much more stuff to cleanup on fail (Mounts)...
function on_exit()
{
  if [ -p "${ARMSTRAP_GUI_FF1}" ]; then
    guiStop
  fi
}

#
# Here we go...
#

source ./config.sh

# This is basically a hack i use for myself to stop playing with
# the default config.sh, any values set in config_local.sh override
# what is in config.sh.

if [ -f ./config_local.sh ]; then
  source ./config_local.sh
fi

for i in ./lib/*.sh; do
  source ${i}
done

if [ ! -z "${ARMSTRAP_PREREQ}" ]; then
  installPrereqs ${ARMSTRAP_PREREQ}
fi

detectAnsi
fetchIndex

ARMSTRAP_EXIT=""
while getopts ":b:d:i:s:h:p:w:n:r:e:K:O:B:F:H:R:clWANIMgq" opt; do
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
      cleanDirectory
      ARMSTRAP_EXIT="Yes"
      ;;
    l)
      showLicence
      ARMSTRAP_EXIT="Yes"
      ;;
    K)
      ARMSTRAP_KBUILDER="${OPTARG}"
      ;;
    I)
      ARMSTRAP_KBUILDER_MENUCONFIG="Yes"
      ;;
    R)
      ARMSTRAP_RUPDATER="${OPTARG}"
      ;;
    M)
      ARMSTRAP_RMOUNT="Yes"
      ;;
    O)
      ARMSTRAP_OS="${OPTARG}"
      ;;
    B)
      ARMSTRAP_BBUILDER="${OPTARG}"
      ;;
    F)
      ARMSTRAP_BBUILDER_FAMILY="${OPTARG}"
      ;;
    A)
      ARMSTRAP_ABUILDER="Yes"
      if [ ! -z "${OPTARG}" ]; then
        ARMSTRAP_ABUILDER_HOOK="${OPTARG}"
      fi
      ;;
    g)
      ARMSTRAP_GUI_DISABLE="Yes"
      ;;
    q)
      ARMSTRAP_LOG_SILENT="Yes"
      ARMSTRAP_GUI_DISABLE="Yes"
      ;;
    \?)
      showUsage
      ARMSTRAP_EXIT="Yes"
      ;;
    :)
      printf "Option -%s requires an argument.\n\n" "${OPTARG}"
      showTitle "${ARMSTRAP_NAME}" "${ARMSTRAP_VERSION}"
      showUsage
      exit 1
    ;;
  esac
done

isTrue "${ARMSTRAP_EXIT}"
if [ $? -ne 0 ]; then
  exit 0
fi

showTitle "${ARMSTRAP_NAME}" "${ARMSTRAP_VERSION}"

ARMSTRAP_BOARD_CONFIG="${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}"

checkDirectory ${ARMSTRAP_MNT}
checkDirectory ${ARMSTRAP_IMG}
checkDirectory ${ARMSTRAP_SRC}
checkDirectory ${ARMSTRAP_PKG}

if [ ! -z "${ARMSTRAP_ABUILDER}" ]; then
  armStrapBuild
  exit 0
fi

if [ ! -z "${ARMSTRAP_KBUILDER}" ]; then
  kernelPost ${ARMSTRAP_KBUILDER}
  exit 0
fi

if [ ! -z "${ARMSTRAP_BBUILDER}" ]; then
  if [ "${ARMSTRAP_BBUILDER}" = "-" ]; then
    loaderPost
  else
    bootBuilder "${ARMSTRAP_BBUILDER}" "${ARMSTRAP_BBUILDER_FAMILY}"
  fi
  exit 0
fi

if [ ! -z "${ARMSTRAP_RUPDATER}" ]; then
  if [ "${ARMSTRAP_RUPDATER}" = "-" ]; then
    rootfsPost
  else
    if [ -z "${ARMSTRAP_RMOUNT}" ]; then
      rootfsUpdater "${ARMSTRAP_RUPDATER}" "${ARMSTRAP_OS}"
    else
      rootfsMount "${ARMSTRAP_RUPDATER}" "${ARMSTRAP_OS}"
    fi
  fi
  exit 0
fi

source ${ARMSTRAP_BOARD_CONFIG}/config.sh

checkConfig
checkRootFS

rm -f ${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BOARD_ROOTFS}-${BOARD_ROOTFS_FAMILY}-${BOARD_ROOTFS_VERSION}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log
mv ${ARMSTRAP_LOG_FILE} ${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BOARD_ROOTFS}-${BOARD_ROOTFS_FAMILY}-${BOARD_ROOTFS_VERSION}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log
ARMSTRAP_LOG_FILE="${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BOARD_ROOTFS}-${BOARD_ROOTFS_FAMILY}-${BOARD_ROOTFS_VERSION}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log"

isTrue "${ARMSTRAP_RMOUNT}"
if [ $? -ne 0 ]; then
  rMount
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
    ARMSTRAP_IMAGE_NAME=${ARMSTRAP_IMG}/${ARMSTRAP_CONFIG}-${BOARD_ROOTFS}-${BOARD_ROOTFS_FAMILY}-${BOARD_ROOTFS_VERSION}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.img
  fi
fi

showConfig

if [ ! -z "${BOARD_PREREQ}" ]; then
  installPrereqs ${BOARD_PREREQ}
fi

if [ -z "${ARMSTRAP_MAC_ADDRESS}" ]; then
  macAddress "${BOARD_MAC_PREFIX}"
fi

funExist ${BOARD_INIT_FUNCTION}
if [ ${?} -eq 0 ]; then
  ${BOARD_INIT_FUNCTION}
fi

if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
  setupImg ${BOARD_DISK_LAYOUT[@]}
else
  setupSD ${BOARD_DISK_LAYOUT[@]}
fi

funExist ${BOARD_INSTALL_FUNCTION}
if [ ${?} -eq 0 ]; then
  ${BOARD_INSTALL_FUNCTION}
else
  default_installOS
fi

if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
  finishImg ${BOARD_DISK_LAYOUT[@]}
else
  finishSD ${BOARD_DISK_LAYOUT[@]}
fi

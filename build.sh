#!/bin/bash

PRG_VERSION="0.21"

BOARD_CONFIG="CubieBoard"
BOARD_HOSTNAME="Debian-Wheezy"
BOARD_PASSWORD="cubiedebian"

#BOARD_ROOT_DEV="/dev/nandb"
BOARD_ROOT_DEV="/dev/mmcblk0p1"
BOARD_MAC_ADDRESS="008010EDDF01"
BOARD_CMDLINE="console=tty0 console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x720p60 root=${BOARD_ROOT_DEV} rootwait panic=10"
# If you want a swapfile, uncomment this.
BOARD_SWAP="yes"
# If you want a fixed size swapfile, set this.
BOARD_SWAP_SIZE="256"

BOARD_ETH0_MODE="dhcp"

# If you want a static IP, use the following
#BOARD_ETH0_MODE="static"
#BOARD_ETH0_IP="192.168.0.100"
#BOARD_ETH0_MASK="255.255.255.0"
#BOARD_ETH0_GW="192.168.0.1"
#BOARD_DNS1="8.8.8.8"
#BOARD_DNS2="8.8.4.4"
#BOARD_DOMAIN="localhost.com"

DEB_SUITE="wheezy"
# Not all packages can be install this way.
DEB_EXTRAPACKAGES="nvi locales ntp ssh"
# Not all packages can (or should be) reconfigured this way.
DEB_RECONFIG="locales tzdata"

BUILD_DATE=`date +%y%m%d`
BUILD_ROOT=`pwd`
BUILD_MNT="${BUILD_ROOT}/mnt"
BUILD_SRC="${BUILD_ROOT}/src"
BUILD_OBJ="${BUILD_ROOT}/obj"
BUILD_LOG="${BUILD_ROOT}/log"
BUILD_LOG_FILE="${BUILD_LOG}/${BOARD_CONFIG}-${DEB_SUITE}_${BOARD_HOSTNAME}-${BUILD_DATE}.log"
BUILD_THREADS="16"

BUILD_DEVICE="/dev/sdc"

# These are defined in boards/<name>/config.sh 
BUILD_MNT_ROOT=""
BUILD_MNT_BOOT=""

# This is in MB
IMAGE_SIZE=1024
IMAGE_DEVICE=""
IMAGE_NAME=${BUILD_ROOT}/${BOARD_CONFIG}-${DEB_SUITE}_${BOARD_HOSTNAME}-${BUILD_DATE}.img
IMAGE_BOOTP=""
IMAGE_ROOTP=""

# This is in MB
BOOT_PARTITION_SIZE="16"

# Here we go...
for i in ./lib/*.sh; do
  . $i
done

showTitle

while getopts ":b:d:i:c" opt; do
  case $opt in
    b)
      BOARD_CONFIG="${OPTARG}"
      ;;
    d)
      BUILD_DEVICE="${OPTARG}"
      ;;
    i)
      IMAGE_NAME="${OPTARG}"
      ;;
    \?)
      showUsage
      exit 1
      ;;
    c)
      showLicence
      exit 0
      ;;
    :)
      printf "Option -%s requires an argument.\n\n" "${OPTARG}"
      showUsage
      exit 1
    ;;
  esac
done

checkDirectory ${BUILD_SRC}
checkDirectory ${BUILD_OBJ}
checkDirectory ${BUILD_MNT}
checkDirectory ${BUILD_LOG}

rm -f ${BUILD_LOG_FILE}

printStatus "initBuild" "Reading ./boards/${BOARD_CONFIG}/config.sh"
. ./boards/${BOARD_CONFIG}/config.sh

for i in ${BUILD_SCRIPTS}; do
  printStatus "initBuild" "Reading ./boards/${BOARD_CONFIG}/${i}"
  . ./boards/${BOARD_CONFIG}/${i}
done

isRoot
checkStatus "Only root can run this script"

init
installPrereqs
macAddress

echo "Mac Address : ${BOARD_MAC_ADDRESS}"

#mkImage ${IMAGE_NAME} ${IMAGE_SIZE}

setupDevice ${BUILD_DEVICE}

createFS ${IMAGE_ROOTP}

mountAll

installOS

unmountAll

sync

#freeImage ${IMAGE_DEVICE}

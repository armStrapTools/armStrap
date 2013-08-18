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

ARMSTRAP_VERSION="0.65"
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

# ARMSTRAP default distribution
ARMSTRAP_OS="debian"

# Theses can be modified by the board's config file
ARMSTRAP_INIT_SCRIPTS="initBuilder.sh"
ARMSTRAP_INIT_FUNCTION="initBuilder"

ARMSTRAP_KBUILDER=""
ARMSTRAP_RUPDATER=""
ARMSTRAP_UBUILDER=""
ARMSTRAP_ABUILDER=""
ARMSTRAP_ABUILDER_HOOK=""
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
while getopts ":b:d:i:s:h:p:w:n:r:e:C:F:A:V:cWNKRUI" opt; do
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
  printStatus "armStrap" "Build Everything"
  TMP_ROOTFS_LIST=""
  TMP_UBOOT_LIST=""
  
  rm -f ${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}.log
  mv ${ARMSTRAP_LOG_FILE} ${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}.log
  ARMSTRAP_LOG_FILE="${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}.log"
  
  rm -f ${ARMSTRAP_PKG}/*
  
  #
  # First, update all the avalable rootFS
  #

  for i in $(boardConfigs); do
    ARMSTRAP_CONFIG="${i}"
    ARMSTRAP_BOARD_CONFIG="${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}"
    source ${ARMSTRAP_BOARD_CONFIG}/config.sh
    
    for k in ${BUILD_ARMBIAN_ROOTFS_LIST}; do
      if [[ ${TMP_ROOTFS_LIST} != *!${k}!* ]]; then
        TMP_ROOTFS_LIST="${TMP_ROOTFS_LIST} !${k}!"
        ARMSTRAP_OS="${k}"
        source ${ARMSTRAP_BOARD_CONFIG}/config.sh
        TMP_ROOTFS="`basename ${BUILD_ARMBIAN_ROOTFS}`"
        TMP_ROOTFS="${TMP_ROOTFS%.txz}"
        
        printStatus "rootfsUpdater" "----------------------------------------"
        printStatus "rootfsUpdater" "- image : ${TMP_ROOTFS}"
        printStatus "rootfsUpdater" "----------------------------------------"
        
        if [ ! -d "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" ]; then
          checkDirectory "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
          httpExtract "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "${BUILD_ARMBIAN_ROOTFS}" "${BUILD_ARMBIAN_EXTRACT}"
        fi
        
        shellRun "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "apt-get update && apt-get dist-upgrade"
        
        printStatus "armStrap" "Compressing root filesystem ${TMP_ROOTFS} to ${ARMSTRAP_PKG}"
        rm -f "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz"
        ${BUILD_ARMBIAN_COMPRESS} "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz" -C "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" --one-file-system ./ >> ${ARMSTRAP_LOG_FILE} 2>&1
      fi
    done
  done
  
  #  for j in $(kernelConfigs ${i}); do
  #    ARMSTRAP_CONFIG="${i}"
  #    ARMSTRAP_KBUILDER_CONF="${j}"
  #    ARMSTRAP_BOARD_CONFIG="${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}"
  #    source ${ARMSTRAP_BOARD_CONFIG}/config.sh
  #
  #    for k in ${BUILD_ARMBIAN_ROOTFS_LIST}; do
  #      if [[ ${TMP_ROOTFS_LIST} != *!${k}!* ]]; then
  #        TMP_ROOTFS_LIST="${TMP_ROOTFS_LIST} !${k}!"
  #        ARMSTRAP_OS="${k}"
  #        source ${ARMSTRAP_BOARD_CONFIG}/config.sh
  #        TMP_ROOTFS="`basename ${BUILD_ARMBIAN_ROOTFS}`"
  #        TMP_ROOTFS="${TMP_ROOTFS%.txz}"
  #
  #        printStatus "rootfsUpdater" "----------------------------------------"
  #        printStatus "rootfsUpdater" "- image : ${TMP_ROOTFS}"
  #        printStatus "rootfsUpdater" "----------------------------------------"
  #       
  #        if [ ! -d "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" ]; then
  #          checkDirectory "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
  #          httpExtract "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "${BUILD_ARMBIAN_ROOTFS}" "${BUILD_ARMBIAN_EXTRACT}"
  #        fi
  #
  #        shellRun "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "apt-get update && apt-get dist-upgrade"
  #
  #        printStatus "armStrap" "Compressing root filesystem ${TMP_ROOTFS} to ${ARMSTRAP_PKG}"
  #        rm -f "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz"
  #        ${BUILD_ARMBIAN_COMPRESS} "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz" -C "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" --one-file-system ./ >> ${ARMSTRAP_LOG_FILE} 2>&1
  #      fi
  #    done
  #    
  #  if [[ ${TMP_UBOOT_LIST} != *!${i}!* ]]; then
  #    TMP_UBOOT_LIST="${TMP_UBOOT_LIST} !${i}!"
  #    makeUBoot "${BUILD_UBUILDER_SOURCE}" "${BUILD_UBUILDER_FAMILLY}" "${ARMSTRAP_PKG}"
  #    makeFex "${BUILD_SBUILDER_CONFIG}" "${BUILD_UBUILDER_FAMILLY}" "${ARMSTRAP_PKG}"
  #    printStatus "armStrap" "Compressing ${BUILD_UBUILDER_FAMILLY}-u-boot files to ${ARMSTRAP_PKG}"
  #    ${BUILD_ARMBIAN_COMPRESS} "${ARMSTRAP_PKG}/${BUILD_UBUILDER_FAMILLY}-u-boot.txz" -C "${ARMSTRAP_PKG}/${BUILD_UBUILDER_FAMILLY}" --one-file-system . >> ${ARMSTRAP_LOG_FILE} 2>&1
  #    rm -rf "${ARMSTRAP_PKG}/${BUILD_UBUILDER_FAMILLY}"
  #  fi
    
  #  kernelConf "${BUILD_KBUILDER_FAMILLY}" "${BUILD_KBUILDER_TYPE}" "${BUILD_KBUILDER_CONF}" "${BUILD_KBUILDER_VERSION}"
  #  gitClone "${BUILD_KBUILDER_SOURCE}" "${BUILD_KBUILDER_GITSRC}" "${BUILD_KBUILDER_GITBRN}"
  #  kernelBuilder "${BUILD_KBUILDER_SOURCE}" "${BUILD_KBUILDER_CONFIG}" "${BUILD_KBUILDER_FAMILLY}" "${BUILD_KBUILDER_ARCH}" "${BUILD_KBUILDER_TYPE}" "${BUILD_KBUILDER_CONF}"
  #  done
  #done
  
    if [ -x "${ARMSTRAP_ABUILDER_HOOK}" ]; then
      "${ARMSTRAP_ABUILDER_HOOK}" "${ARMSTRAP_PKG}" "${ARMSTRAP_LOG_FILE}"
    fi
  
  exit 0
fi

source ${ARMSTRAP_BOARD_CONFIG}/config.sh

checkConfig
checkRootFS

for i in ${ARMSTRAP_INIT_SCRIPTS}; do
  if [ -f "${ARMSTRAP_BOARD_CONFIG}/${i}" ]; then
    source "${ARMSTRAP_BOARD_CONFIG}/${i}"
  fi
done

rm -f ${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BUILD_ARMBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log
mv ${ARMSTRAP_LOG_FILE} ${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BUILD_ARMBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log
ARMSTRAP_LOG_FILE="${ARMSTRAP_LOG}/${ARMSTRAP_CONFIG}-${BUILD_ARMBIAN_SUITE}_${ARMSTRAP_HOSTNAME}-${ARMSTRAP_DATE}.log"

isTrue "${ARMSTRAP_KBUILDER}"
if [ $? -ne 0 ]; then
  printStatus "armStrap" "Kernel Builder"
  kernelConf "${BUILD_KBUILDER_FAMILLY}" "${BUILD_KBUILDER_TYPE}" "${BUILD_KBUILDER_CONF}" "${BUILD_KBUILDER_VERSION}"
  gitClone "${BUILD_KBUILDER_SOURCE}" "${BUILD_KBUILDER_GITSRC}" "${BUILD_KBUILDER_GITBRN}"
  kernelBuilder "${BUILD_KBUILDER_SOURCE}" "${BUILD_KBUILDER_CONFIG}" "${BUILD_KBUILDER_FAMILLY}" "${BUILD_KBUILDER_ARCH}" "${BUILD_KBUILDER_TYPE}" "${BUILD_KBUILDER_CONF}"
  ARMSTRAP_EXIT="Yes"
fi

isTrue "${ARMSTRAP_RUPDATER}"
if [ $? -ne 0 ]; then
  TMP_ROOTFS="`basename ${BUILD_ARMBIAN_ROOTFS}`"
  TMP_ROOTFS="${TMP_ROOTFS%.txz}"
  
  printStatus "rootfsUpdater" "----------------------------------------"
  printStatus "rootfsUpdater" "- image : ${TMP_ROOTFS}"
  printStatus "rootfsUpdater" "----------------------------------------"

  if [ ! -d "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" ]; then
    checkDirectory "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
    httpExtract "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "${BUILD_ARMBIAN_ROOTFS}" "${BUILD_ARMBIAN_EXTRACT}"
  fi

  shellRun "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "apt-get update && apt-get dist-upgrade"
  
  printStatus "armStrap" "Compressing root filesystem ${TMP_ROOTFS} to ${ARMSTRAP_PKG}"
  rm -f "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz"
  ${BUILD_ARMBIAN_COMPRESS} "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz" -C "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" --one-file-system ./ >> ${ARMSTRAP_LOG_FILE} 2>&1

  ARMSTRAP_EXIT="Yes"
fi

isTrue "${ARMSTRAP_UBUILDER}"
if [ $? -ne 0 ]; then
  printStatus "armStrap" "U-Boot Builder"
  makeUBoot "${BUILD_UBUILDER_SOURCE}" "${BUILD_UBUILDER_FAMILLY}" "${ARMSTRAP_PKG}"
  makeFex "${BUILD_SBUILDER_CONFIG}" "${BUILD_UBUILDER_FAMILLY}" "${ARMSTRAP_PKG}"
  printStatus "armStrap" "Compressing ${BUILD_UBUILDER_FAMILLY}-u-boot files to ${ARMSTRAP_PKG}"
  ${BUILD_ARMBIAN_COMPRESS} "${ARMSTRAP_PKG}/${BUILD_UBUILDER_FAMILLY}-u-boot.txz" -C "${ARMSTRAP_PKG}/${BUILD_UBUILDER_FAMILLY}" --one-file-system . >> ${ARMSTRAP_LOG_FILE} 2>&1
  rm -rf "${ARMSTRAP_PKG}/${BUILD_UBUILDER_FAMILLY}"
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

funExist ${ARMSTRAP_INIT_FUNCTION}
if [ ${?} -eq 0 ]; then
  ${ARMSTRAP_INIT_FUNCTION} "${ARMSTRAP_CONFIG}" "${ARMSTRAP_BOARD_CONFIG}"
fi

if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
  setupImg ${BUILD_DISK_LAYOUT[@]}
else
  setupSD ${BUILD_DISK_LAYOUT[@]}
fi

installOS

if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
  finishImg ${BUILD_DISK_LAYOUT[@]}
else
  finishSD ${BUILD_DISK_LAYOUT[@]}
fi

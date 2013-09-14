function showLicence {
  cat <<EOF
-------------------------------------------------------------------------------
Copyright (c) 2013 Eddy Beaupre. All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
        
THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------
EOF
}

function showUsage {
  local TMP_BOARDS="$(boardConfigs)"
  printf "Usage : ${ANS_BLD}sudo %s${ANS_RST} [PARAMETERS]\n" "${ARMSTRAP_NAME}"
  printf "\n${ANS_BLD}Image/SD Builder${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-b" "<BOARD>" "Use board definition <BOARD>."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-d" "<DEVICE>" "Write to <DEVICE> instead of creating an image."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-i" "<FILE>" "Set image filename to <FILE>."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-s" "<SIZE>" "Set image size to <SIZE>MB."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-h" "<HOSTNAME>" "Set hostname."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-p" "<PASSWORD>" "Set root password."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-w" "<SIZE>" "Enable swapfile."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-W" "" "Disable swapfile."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-Z" "<SIZE>" "Set swapfile size to <SIZE>MB."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-n" "\"<IP> <MASK> <GW>\"" "Set static IP."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-N" "" "Set DHCP IP."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-r" "\"<NS1> [NS2] [NS3]\"" "Set nameservers."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-e" "<DOMAIN>" "Set search domain."
  printf "\n${ANS_BLD}Kernel Builder${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-K" "" "Build Kernel (debian packages)."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-V" "<version>" "Select an alternate kernel version (if avalable)."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-C" "<CONFIG>" "Select a different kernel configuration."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-I" "" "Call menuconfig before building Kernel."
  printf "\n${ANS_BLD}U-Boot Builder${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-U" "" "Build U-Boot (txz package)."
  printf "\n${ANS_BLD}RootFS updater${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-R" "" "Update RootFS (txz package)."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-F" "" "Select which RootFS to update."
  printf "\n${ANS_BLD}All Builder${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-A" "" "Build Kernel/RootFS/U-Boot for all boards/configurations"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-H" "<hookscript>" "Script to execute after building everything with"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "" "" "<PKG_PATH> and <LOGFILE> as parameters"
  printf "\n${ANS_BLD}Utilities${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-c" "" "Show licence."
  printf "\n${ANS_BLD}Supported boards and kernel configurations:${ANS_RST}\n"
  for i in ${TMP_BOARDS}; do
    local TMP_BRDCFG="$(kernelConfigs ${i})"
    printf "  ${ANS_BLD}%- 24s${ANS_RST}%s\n" "${i}" "${TMP_BRDCFG}"
  done
  printf "\nWith no parameter, create an image using values found in ${ANS_BLD}config.sh${ANS_RST}.\n\n"
}

function showTitle {
  printf "\n${ANS_BLD}%s version %s${ANS_RST}\n" "${1}" "${2}"
  printf "Copyright (C) 2013 Eddy Beaupre\n\n"
}

# Usage: printStatus <function> <message>
function printStatus {
  local TMP_NAME="${1}"
  local TMP_TIME="`date '+%y/%m/%d %H:%M:%S'`"
  shift

  if [ -z "${ARMSTRAP_LOG_SILENT}" ]; then
    case "${TMP_NAME}" in
      "checkStatus")
        printf "[${ANF_GRN}${TMP_TIME}${ANS_RST} ${ANS_BLD}${ANF_RED}%.15s${ANS_RST}] ${ANS_BLD}${ANF_YEL}Aborting${ANS_RST}: ${ANSI_BLD}%s${ANS_RST}\n\n" "${TMP_NAME}" "$@"
        ;;
      "isBlockDev")
        printf "[${ANF_GRN}${TMP_TIME}${ANS_RST} ${ANS_BLD}${ANF_YEL}%.15s${ANS_RST}] ${ANS_BLD}${ANF_YEL}Warning${ANS_RST}: ${ANSI_BLD}%s${ANS_RST}\n" "${TMP_NAME}" "$@"
        ;;
      *)
        printf "[${ANF_GRN}${TMP_TIME}${ANS_RST} ${ANF_CYN}%.15s${ANS_RST}] %s\n" "${TMP_NAME}" "$@"
        ;;
    esac
  fi
  
  if [ -f "${ARMSTRAP_LOG_FILE}" ]; then
    printf "[${TMP_TIME} %.15s] %s\n" "${TMP_NAME}" "$@" >> ${ARMSTRAP_LOG_FILE}
  fi
}

function checkStatus {
  if [ $? -ne 0 ]; then
    printStatus "checkStatus" "${@}"
    exit 1
  fi
}

# Usage: checkDirectory <path>
function checkDirectory {
  if [ ! -d "${1}" ]; then
    mkdir -p ${1}
    checkStatus "Creation of directory ${1} failed"
    printStatus "checkDirectory" "Directory ${1} created"
  fi
}

# Usage: isRoot
function isRoot {
  if [ "`id -u`" -ne "0" ]; then
    printStatus "isRoot" "User `whoami` (`id -u`) is not root"
    return 1
  fi
  return 0
}

# Usage: installPrereq <PREREQ1> [<PREREQ2> ... ]
function installPrereqs {

  for i in ${@}; do 
    testInstall ${i}; 
  done
}

# Usage: testInstall <package>
function testInstall {
  local IN=(`dpkg-query -W -f='${Status} ${Version}\n' ${1} 2> /dev/null`)
  if [ "${IN[0]}" != "install" ]; then
    if [ -z "${ARMSTRAP_UPDATE}" ]; then
      /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y update 2>> ${ARMSTRAP_LOG_FILE}
      /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y dist-upgrade 2>> ${ARMSTRAP_LOG_FILE}
      ARMSTRAP_UPDATE="Done"
    fi
    printStatus "testInstall" "Prerequisition ${1} not found, Installing..."
    /usr/bin/debconf-apt-progress --logstderr -- apt-get --quiet -y install ${1} 2>> ${ARMSTRAP_LOG_FILE}
  fi
}

# Usage : isBlockDev <DEVICE>
function isBlockDev {
  if ! [ -b ${1} ]; then
    echo ""
    printStatus "isBlockDev" "Device ${1} is not a block device"
    return 1
  fi  
  return 0
}

# Usage: isRemDevice <DEVICE>
function isRemDevice {
  local TMP_DEVICE=`basename ${1}`
  if [ `cat /sys/block/${TMP_DEVICE}/removable` != "1" ]; then
    printStatus "isRemDevice" "Device ${1} is not a removeable device"
    return 1
  fi
  return 0
}

# Usage: partSync
function partSync {
  local TMP_DEV=""
  printStatus "partSync" "Flush file system buffers"
  sync >> ${ARMSTRAP_LOG_FILE} 2>&1
  printStatus "partSync" "Inform the OS of partition table changes on ${ARMSTRAP_DEVICE}"  
  partprobe ${ARMSTRAP_DEVICE} >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage: promptYN "<question>"
function promptYN {
  echo ""
  while true; do
    read -n 1 -p "$1 " yn
    case $yn in
      [Yy]* ) 
        printf "\n\n"
        return 0
        ;;
      [Nn]* ) 
        printf "\n\n"
        return 1
        ;;
      * ) 
        printf "\nPlease answer ${ANS_BLD}${ANF_RED}Y${ANF_DEF}${ANS_RST}es or ${ANS_BLD}${ANF_RED}N${ANF_DEF}${ANS_RST}o.\n"
        ;;
    esac
  done
  echo ""
}

function isTrue {
  case ${1} in
    [YyTt1]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

# Usage macAddress [<VENDOR_ID>]
function macAddress {
  if [ -z "${1}" ]; then
    BUILD_MAC_VENDOR=0x000246
  fi
  
  if [ -z ${ARMSTRAP_MAC_ADDRESS} ]; then
    ARMSTRAP_MAC_ADDRESS=$( printf "%012x" $((${1} * 16777216 + $[ $RANDOM % 16777216 ])) )
    printStatus "macAddress" "Generated Mac Address : ${ARMSTRAP_MAC_ADDRESS}"
  fi
}

function funExist {
  if [ -z "${1}" ]; then
    return 1
  fi

  declare -f -F ${1} > /dev/null
}

# usage fixSymLink <TARGET_LINK> <TARGET_DIRECTORY> <SOURCE>
function fixSymLink {
  printStatus "fixSymLink" "Fixing symlink for ${1}"
  cd ${2}
  ln -fs ${3} ${1}
  cd ${ARMSTRAP_ROOT}
}

function showConfig {
  printf "\n${ANS_BLD}${ANS_SUL}${ANF_CYN}% 20s${ANS_RST}\n\n" "CONFIGURATION"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Board" "${ARMSTRAP_CONFIG}"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Distribution" "${ARMSTRAP_OS}"
  if [ ! -z "${BUILD_KBUILDER_CONF}" ]; then
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Kernel Config" "${BUILD_KBUILDER_CONF}"
  fi

  printf "\n${ANF_GRN}% 20s${ANS_RST}: %s\n" "Hostname" "${ARMSTRAP_HOSTNAME}"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Root Password" "${ARMSTRAP_PASSWORD}"
  if [ ! -z "${ARMSTRAP_SWAP}" ]; then
    printf "${ANF_GRN}% 20s${ANS_RST}: %sMB\n" "Swapfile Size" "${ARMSTRAP_SWAP_SIZE}"
  fi

  if [ ! -z "${ARMSTRAP_MAC_ADDRESS}" ]; then
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Mac Address" "${ARMSTRAP_MAC_ADDRESS}"
  fi
  if [ "${ARMSTRAP_ETH0_MODE}" == "dhcp" ]; then
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "IP Address" "${ARMSTRAP_ETH0_MODE}"
  else
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "IP Address" "${ARMSTRAP_ETH0_IP}"
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Mask" "${ARMSTRAP_ETH0_MASK}"
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Gateway" "${ARMSTRAP_ETH0_GW}"
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Search Domain" "${ARMSTRAP_ETH0_DOMAIN}"
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "DNS" "${ARMSTRAP_ETH0_DNS}"
  fi
  printf "\n${ANF_GRN}% 20s${ANS_RST}: %s\n" "Log File" "${ARMSTRAP_LOG_FILE}"
  if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Image File" "${ARMSTRAP_IMAGE_NAME}"
    if [ -e "${ARMSTRAP_IMAGE_NAME}" ]; then
      printf "\n% 20s : %s\n" "${ANS_BLD}${ANF_YEL}!!! Warning !!!${ANF_DEF}${ANS_RST}" "Image file exists, will be overwritten"
    fi
    printf "${ANF_GRN}% 20s${ANS_RST}: %sMB\n" "Image Size" "${ARMSTRAP_IMAGE_SIZE}"
  else
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Content of" "${ARMSTRAP_DEVICE}"
    isBlockDev ${ARMSTRAP_DEVICE}
    checkStatus "${ARMSTRAP_DEVICE} is not a block device"
    isRemDevice ${ARMSTRAP_DEVICE}
    checkStatus "${ARMSTRAP_DEVICE} is not a removable device"
    fdisk -l ${ARMSTRAP_DEVICE}
  fi
  
  promptYN "OK to proceed?"
  checkStatus "Not ok to proceed."    
    
}

# usage unComment <FILE> <SEARCH VALUE>
function unComment {
  local TMP_SED=`mktemp sedscript.XXXXXX`
  local TMP_CNF_MOD=`mktemp .config.XXXXXX`
  
  printStatus "unComment" "Uncommenting line starting with # ${2} in ${1}"
  printf "s/^# ${2}/${2}/g\n" > ${TMP_SED}
  sed -f ${TMP_SED} ${1} > ${TMP_CNF_MOD}
  rm -f ${TMP_SED}
  rm -f ${1}
  mv ${TMP_CNF_MOD} ${1}
}

# Usage ubootImage <SRC> <DST>
function ubootImage {
  if [ -f "${1}" ]; then
    printStatus "ubootImage" "Generating ${2} from ${1}"
    mkimage -C none -A ${BUILD_ARCH} -T script -d ${1} ${2} >> ${ARMSTRAP_LOG_FILE} 2>&1
  else
    printStatus "ubootImage" "WARNING: ${1} not found. Cannot generate image."
  fi
}

# Usage ubootSetEnv <TARGET_FILE> <VARIABLE> <VALUE>
function ubootSetEnv {
  local TMP_CFG="${1}"
  local TMP_VAR="${2}"
  shift
  shift

  if [ -f "${TMP_CFG}" ]; then
    if [ ! -z "${@}" ]; then
      printStatus "ubootSetEnv" "Setting variable ${TMP_VAR} to ${@}"
      echo "setenv ${TMP_VAR} ${@}" >> ${TMP_CFG}
    else
      printStatus "ubootSetEnv" "Setting command ${TMP_VAR}"
      echo "${TMP_VAR}" >> ${TMP_CFG}
    fi
  else
    printStatus "ubootSetEnv" "WARNING: File ${TMP_CFG} not found"
  fi
}

# Usage ubootSetCMD <TARGET_FILE> <COMMAND> <VALUE>
function ubootSetCMD {
  local TMP_CFG="${1}"
  local TMP_VAR="${2}"
  shift
  shift

  if [ -f "${TMP_CFG}" ]; then
    if [ ! -z "${@}" ]; then
      printStatus "ubootSetCMD" "Setting command ${TMP_VAR} to ${@}"
      echo "${TMP_VAR} ${@}" >> ${TMP_CFG}
    else
      printStatus "ubootSetCMD" "WARNING: No value to set command ${TMP_VAR}"
    fi
  else
    printStatus "ubootSetCMD" "WARNING: File ${TMP_CFG} not found"
  fi
}

# Usage ddLoader <DEVICE> <FILE:BS:SEEK> [<FILE:BS:SEEK> ...]
function ddLoader {
  local TMP_DEV="${1}"
  shift
  
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    printStatus "ddLoader" "Installing ${TMP_ARR[0]} to ${TMP_DEV}, block size ${TMP_ARR[1]}, seek ${TMP_ARR[2]}"
    dd if=${TMP_ARR[0]} of=${TMP_DEV} bs=${TMP_ARR[1]} seek=${TMP_ARR[2]} >> ${ARMSTRAP_LOG_FILE} 2>&1
  done
}

# Usage fexMac <TARGET_FILE> <MAC_ADDRESS>
function fexMac {
  if [ -f "${1}" ]; then
    printStatus "fexMac" "Configuring board mac address to ${2}"
    editIni ${1} "dynamic" "MAC" "\"${2}\""
  else
    printStatus "fexMac" "WARNING: ${1} not found. Cannot add Mac Address."
  fi
}

# Usage <TARGET_FILE> <SECTION> <PARAMETER> <VALUE>
function editIni {
  local TMP_TEMP="`mktemp $1.XXXXXX`"
  local TMP_FILE="$1"
  local TMP_SECTION="$2"
  local TMP_PARAM="$3"
  shift
  shift
  shift
  
  local TMP_I
  
  printStatus "editIni" "Configuring [${TMP_SECTION}]/${TMP_PARAM} to '${@}' in `basename ${TMP_FILE}`"
  
  while read TMP_I; do
    if [[ ${TMP_I} == *]* ]]; then
      if [[ ${TMP_SEC} == ${TMP_SECTION,,} ]] && [ -z "${TMP_FOUND}" ]; then
        echo "${TMP_PARAM} = ${@}"
        local TMP_FOUND=1
      fi
      if [ ! -z "${TMP_SEC}" ]; then
        echo ""
      fi
      local TMP_SEC=$(echo ${TMP_I,,} | cut -d "]" -f 1)
      TMP_SEC="${TMP_SEC/[}"
    elif [[ ${TMP_I} == *=* ]]; then
      local TMP_PAR=($(echo ${TMP_I,,} | cut -d "=" -f 1))
      local TMP_PAR="${TMP_PAR[0]}"
    fi
    
    if [[ ${TMP_SEC} == ${TMP_SECTION,,} ]] && [[ ${TMP_PAR} == ${TMP_PARAM,,} ]]; then
      echo "${TMP_PARAM} = ${@}"
      local TMP_FOUND="1"
    else
      if [ ! -z "${TMP_I}" ]; then
        echo "${TMP_I}"
      fi
    fi
  done < ${TMP_FILE} > ${TMP_TEMP}
  
  if [[ ${TMP_SEC} == ${TMP_SECTION,,} ]] && [ -z "${TMP_FOUND}" ]; then
    printStatus "editIni" "${TMP_PARAM} not found in [${TMP_SECTION}], added."
    echo "${TMP_PARAM} = ${@}" >> ${TMP_TEMP}
    local TMP_FOUND=1
  fi
  
  if [ -z ${TMP_FOUND} ]; then
    printStatus "editIni" "[${TMP_SECTION}] not found, added."
    echo "" >> ${TMP_TEMP}
    echo "[${TMP_SECTION}]" >> ${TMP_TEMP}
    printStatus "editIni" "${TMP_PARAM} not found in [${TMP_SECTION}], added."
    echo "${TMP_PARAM} = ${@}" >> ${TMP_TEMP}
  fi
  
  printStatus "editIni" "All done."

  rm -f ${TMP_FILE}.bak    
  mv ${TMP_FILE} ${TMP_FILE}.bak
  mv ${TMP_TEMP} ${TMP_FILE}
}

ANS_BLD=""
ANS_DIM=""
ANS_REV=""
ANS_RST=""
ANS_SUL=""
ANS_RUL=""
ANS_SSO=""
ANS_RSO=""
	
ANF_BLK=""
ANF_RED=""
ANF_GRN=""
ANF_YEL=""
ANF_BLU=""
ANF_MAG=""
ANF_CYN=""
ANF_GRA=""
ANF_DEF=""
	
ANB_BLK=""
ANB_RED=""
ANB_GRN=""
ANB_YEL=""
ANB_BLU=""
ANB_MAG=""
ANB_CYN=""
ANB_GRA=""
ANB_DEF=""

function detectAnsi {
  local TMP_TPUT="`/bin/which tput`"

  if [ ! -z "${TMP_TPUT}" ]; then
    if [ `${TMP_TPUT} colors` -ge 8 ]; then
      ANS_BLD="`${TMP_TPUT} bold`"
      ANS_DIM="`${TMP_TPUT} dim`"
      ANS_REV="`${TMP_TPUT} rev`"
      ANS_RST="`${TMP_TPUT} sgr0`"
      ANS_SUL="`${TMP_TPUT} smul`"
      ANS_RUL="`${TMP_TPUT} rmul`"

      ANS_SSO="`${TMP_TPUT} smso`"
      ANS_RSO="`${TMP_TPUT} rmso`"
	
      ANF_BLK="`${TMP_TPUT} setaf 0`"
      ANF_RED="`${TMP_TPUT} setaf 1`"
      ANF_GRN="`${TMP_TPUT} setaf 2`"
      ANF_YEL="`${TMP_TPUT} setaf 3`"
      ANF_BLU="`${TMP_TPUT} setaf 4`"
      ANF_MAG="`${TMP_TPUT} setaf 5`"
      ANF_CYN="`${TMP_TPUT} setaf 6`"
      ANF_GRA="`${TMP_TPUT} setaf 7`"
      ANF_DEF="`${TMP_TPUT} setaf 9`"
	
      ANB_BLK="`${TMP_TPUT} setab 0`"
      ANB_RED="`${TMP_TPUT} setab 1`"
      ANB_GRN="`${TMP_TPUT} setab 2`"
      ANB_YEL="`${TMP_TPUT} setab 3`"
      ANB_BLU="`${TMP_TPUT} setab 4`"
      ANB_MAG="`${TMP_TPUT} setab 5`"
      ANB_CYN="`${TMP_TPUT} setab 6`"
      ANB_GRA="`${TMP_TPUT} setab 7`"
      ANB_DEF="`${TMP_TPUT} setab 9`"
    fi
  fi
}

#usage gitClone <TARGET_DIR> <GIT_SRC> [<BRANCH>]

function gitClone {
  local TMP_GIT="${2}"
  
  if [ -d "${1}" ]; then
    printStatus "gitClone" "Updating `basename ${1}`"
    cd "${1}"
    git pull >> ${ARMSTRAP_LOG_FILE} 2>&1
    cd "${ARMSTRAP_ROOT}"
  else
    if [ ! -z "${3}" ]; then
      local TMP_GIT="${TMP_GIT} -b ${3}"
      printStatus "gitClone" "Cloning `basename ${1}` (branch ${3})"
      git clone "${2}" -b "${3}" "${1}" >> ${ARMSTRAP_LOG_FILE} 2>&1
    else
      printStatus "gitClone" "Cloning `basename ${1}`"
      git clone "${2}" "${1}" >> ${ARMSTRAP_LOG_FILE} 2>&1
    fi
  fi
}

# usage boardConfigs
function boardConfigs {
  for i in ${ARMSTRAP_BOARDS}/*; do
    if [ -d "${i}" ]; then
      printf "%s " "`basename ${i}`"
    fi
  done
}

# usage kernelConfigs <BOARD_NAME>
function kernelConfigs {
  local TMP_FILE=""
  local TMP_I=""
  local TMP_J=""
  
  if [ -d "${ARMSTRAP_BOARDS}/${1}/kernel/" ]; then
    for TMP_J in ${ARMSTRAP_BOARDS}/${1}/kernel/*_defconfig; do
      TMP_FILE="`echo "${TMP_J}" | cut -d- -f2 | cut -d_ -f1`"
      printf "%s " ${TMP_FILE}
    done
  else
    for TMP_I in ${ARMSTRAP_BOARDS}/${1}/kernel*; do
      if [ ! -z "${TMP_FILE}" ]; then
        printf "\n                          "
      fi
      printf "%s : " "`basename ${TMP_I}`"
      for TMP_J in ${ARMSTRAP_BOARDS}/${1}/`basename ${TMP_I}`/*_defconfig; do
        TMP_FILE="`basename ${TMP_J}`"
        TMP_FILE="`echo "${TMP_FILE}" | cut -d- -f2 | cut -d_ -f1`"
        printf "%s " "`basename ${TMP_FILE}`"
      done
    done
  fi
}

# usage checkConfig 
function checkConfig {
  local TMP_FND=""
  local TMP_I=""
  
  if [ ! -d "${ARMSTRAP_BOARD_CONFIG}" ]; then
    $(exit 1)
    checkStatus "Board configuration ${ARMSTRAP_CONFIG} not found"
  fi
  
  for TMP_I in ${BUILD_KBUILDER_CONFIG}/*; do
    case `basename ${TMP_I}` in
      *${BUILD_KBUILDER_CONF}*)
        TMP_FND="Yes"
        ;;
    esac
  done
  
  isTrue ${TMP_FND}
  if [ $? -eq "0" ]; then
    $(exit 1)
    checkStatus "Kernel configuration ${BUILD_KBUILDER_CONF} not found"
  fi
}

# usage checkRootFS 
function checkRootFS {
  local TMP_FND=""

  for i in ${BUILD_ARMBIAN_ROOTFS_LIST}; do
    case ${i} in
      ${ARMSTRAP_OS})
        TMP_FND="Yes"
        ;;
    esac
  done
  
  isTrue ${TMP_FND}
  if [ $? -eq "0" ]; then
    $(exit 1)
    checkStatus "rootFS ${ARMSTRAP_OS} not found for this board, valid choices are : ${BUILD_ARMBIAN_ROOTFS_LIST}"
  fi
}

# usage loadLibrary <LIBPATH> <LIB1> [<LIB2> ...]
function loadLibrary {
  local TMP_PATH="${1}"
  shift
  for i in $@; do
    if [ -f ${TMP_PATH}/${i} ]; then
      printStatus "loadLibrary" "Loading `basename ${i}`"
      source ${TMP_PATH}/${i}
    fi
  done
}

# usage resetEnv
function resetEnv {
  local TMP_I=""
  local TMP_LST=""
  
  printStatus "resetEnv" "Resetting environment"
  for TMP_I in `set`; do
    local TMP_ENV="`echo "${TMP_I}" | cut -d "_" -f 1`"
    local TMP_VAR="`echo "${TMP_I}" | cut -d "=" -f 1`"
    if [ "${TMP_ENV}" == "BUILD" ]; then
      TMP_LST="${TMP_VAR} ${TMP_LST}"
    fi
  done
  
  unset ${TMP_LST}
}

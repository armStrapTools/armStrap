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
  local TMP_IFS="${IFS}"
  local TMP_I=""
  local TMP_J=""
  
  showTitle "${ARMSTRAP_NAME}" "${ARMSTRAP_VERSION}"  
  
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
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-K" "<ARCH>" "Build Kernel (debian packages). (Build all if arg is -)"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "" "-" "Build all avalables Kernel."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-I" "" "Call menuconfig before building Kernel."
  printf "\n${ANS_BLD}BootLoader Builder${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-B" "<BOOTLOADER>" "Build BootLoader (${ARMSTRAP_TAR_EXTENSION} package)."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "" "-" "Build all avalables BootLoaders."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-F" "<FAMILY>" "Select bootloader family."
  printf "\n${ANS_BLD}RootFS updater${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-R" "<VERSION>" "Update RootFS (${ARMSTRAP_TAR_EXTENSION} package)."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "" "-" "Update all avalables RootFS."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-O" "<ARCH>" "Select which architecture to update."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-M" "" "Execute a shell into the RootFS instead of updating it."
  printf "\n${ANS_BLD}All Builder${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-A" "" "Build Kernel/RootFS/U-Boot for all boards/configurations"
  printf "\n${ANS_BLD}Utilities${ANS_RST}:\n"
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-g" "" "Disable GUI."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-q" "" "Quiet."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-c" "" "Directory Cleanup."
  printf "${ANS_BLD}% 4s %- 20s${ANS_RST} %s\n" "-l" "" "Show licence."
  
  printf "\n${ANS_BLD}Default boards configuration:${ANS_RST}\n"
  
  printf "\n${ANS_BLD}%15s %15s %10s %21s${ANS_RST}\n--------------- --------------- ---------- ---------------------\n" "Board" "Kernel" "Family" "BootLoader"
  for TMP_I in ${ARMSTRAP_BOARDS}/*; do
    local TMP_BOARD=$(basename ${TMP_I})
    source ${TMP_I}/config.sh
    printf "% 15s % 15s % 10s % 21s\n" ${TMP_BOARD} ${BOARD_CPU} ${BOARD_CPU_ARCH}${BOARD_CPU_FAMILY} ${BOARD_LOADER}
  done
  
  printf "\n${ANS_BLD}Avalable BootLoaders:${ANS_RST}\n"
  
  printf "\n${ANS_BLD}%15s %21s${ANS_RST}\n--------------- ---------------------\n" "Board" "BootLoader"
  for TMP_I in ${ARMSTRAP_LOADER_LIST}; do
    IFS="-"
    TMP_BOARD=(${TMP_I})
    TMP_BOARD=${TMP_BOARD[0]}
    TMP_LOADER=${TMP_I##$TMP_BOARD-}
    TMP_LOADER=${TMP_LOADER%%.$ARMSTRAP_TAR_EXTENSION}
    IFS="${TMP_IFS}"
    printf "% 15s % 21s\n" ${TMP_BOARD} ${TMP_LOADER}
  done
  
  printf "\n${ANS_BLD}Avalable Kernels:${ANS_RST}\n"
  printf "\n${ANS_BLD}%15s %10s %10s${ANS_RST}\n--------------- ---------- ----------\n" "Kernel" "Config" "Version"
  for TMP_I in ${ARMSTRAP_KERNEL_LIST}; do
    local TMP_KRN=${TMP_I%%-linux-*}
    local TMP_CFG=${TMP_I##$TMP_KRN-linux-}
    IFS="_"
    local TMP_VER=(${TMP_I})
    IFS="-"
    TMP_VER=(${TMP_VER[1]})
    TMP_VER=${TMP_VER[0]}
    TMP_CFG=(${TMP_CFG})
    TMP_CFG=${TMP_CFG[0]}
    IFS="${TMP_IFS}"
    printf "% 15s % 10s % 10s\n" ${TMP_KRN} ${TMP_CFG} ${TMP_VER}
  done
  
  printf "\n${ANS_BLD}Avalable RootFS:${ANS_RST}\n"
  printf "\n${ANS_BLD}%15s %10s %10s${ANS_RST}\n--------------- ---------- ----------\n" "Arch" "Family" "Version"
  for TMP_I in ${ARMSTRAP_ROOTFS_LIST}; do
    IFS="-"
    TMP_I=(${TMP_I})
    IFS="."
    TMP_J=(${TMP_I[2]})
    IFS="${TMP_IFS}"
    printf "% 15s % 10s % 10s\n" ${TMP_I[0]} ${TMP_I[1]} ${TMP_J[0]}
  done
  
  printf "\nWith no parameter, create an image using values found in ${ANS_BLD}config.sh${ANS_RST}.\n\n"
}

function showTitle {
  if [ -z "${ARMSTRAP_LOG_SILENT}" ]; then
    printf "\n${ANS_BLD}%s version %s${ANS_RST}\n" "${1}" "${2}"
    printf "Copyright (C) 2013 Eddy Beaupre\n\n"
  fi
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
    /usr/bin/dialog --backtitle "armStrap" --title "Abort" --msgbox "${@}" 0 0

  if [ -f "${ARMSTRAP_LOG_FILE}" ]; then
  local TMP_TIME="`date '+%y/%m/%d %H:%M:%S'`"
    printf "[${TMP_TIME} %.15s] %s\n" "checkStatus" "$@" >> ${ARMSTRAP_LOG_FILE}
  fi
    
    exit 1
  fi
}

# Usage: rmDirectory <path>
function rmDirectory {
  if [ ! -d "${1}" ]; then
    printStatus "rmDirectory" "Directory ${1} does not exist"
  else
    rm -rf "${1}"
    checkStatus "rmDirectory" "Removal of ${1} failed"
    printStatus "rmDirectory" "Directory ${1} removed"
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
      #/usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y dist-upgrade 2>> ${ARMSTRAP_LOG_FILE}
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

# Usage: promptYN "<question>"
function promptYN {
  /usr/bin/dialog --yesno "${1}" 0 0
  return $?
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
    BOARD_MAC_PREFIX=0x000246
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
  local TMP_INFO="${TMP_INFO}        Board : ${ARMSTRAP_CONFIG}\n"
        TMP_INFO="${TMP_INFO} Distribution : ${BOARD_ROOTFS_FAMILY} (${BOARD_ROOTFS_VERSION})\n"
        TMP_INFO="${TMP_INFO}     Hostname : ${ARMSTRAP_HOSTNAME}\n"
        TMP_INFO="${TMP_INFO}Root Password : ${ARMSTRAP_PASSWORD}\n"
  if [ ! -z "${ARMSTRAP_SWAP}" ]; then
        TMP_INFO="${TMP_INFO}Swapfile Size : ${ARMSTRAP_SWAPSIZE}\n"
  fi

  if [ ! -z "${ARMSTRAP_MAC_ADDRESS}" ]; then
        TMP_INFO="${TMP_INFO}  Mac Address : ${ARMSTRAP_MAC_ADDRESS}\n"
  fi
  if [ "${ARMSTRAP_ETH0_MODE}" == "dhcp" ]; then
        TMP_INFO="${TMP_INFO}   IP Address : ${ARMSTRAP_ETH0_MODE}\n"
  else
        TMP_INFO="${TMP_INFO}   IP Address : ${ARMSTRAP_ETH0_IP}\n"
        TMP_INFO="${TMP_INFO}         Mask : ${ARMSTRAP_ETH0_MASK}\n"
        TMP_INFO="${TMP_INFO}      Gateway : ${ARMSTRAP_ETH0_GW}\n"
        TMP_INFO="${TMP_INFO}Search Domain : ${ARMSTRAP_ETH0_DOMAIN}\n"
        TMP_INFO="${TMP_INFO}          DNS : ${ARMSTRAP_ETH0_DNS}\n"
  fi
        TMP_INFO="${TMP_INFO}     Log File : ${ARMSTRAP_LOG_FILE}\n"
  if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
        TMP_INFO="${TMP_INFO}   Image File : ${ARMSTRAP_IMAGE_NAME}"
    if [ -e "${ARMSTRAP_IMAGE_NAME}" ]; then
        TMP_INFO="${TMP_INFO}(Image file exists, will be overwritten)\n"
    else
        TMP_INFO="${TMP_INFO}\n"
    fi
        TMP_INFO="${TMP_INFO}   Image Size : ${ARMSTRAP_IMAGE_SIZE}\n"
  else
        TMP_INFO="${TMP_INFO}\nContent of ${ARMSTRAP_DEVICE} :\n"
        
        while read -r i; do
          TMP_INFO="${TMP_INFO}${i}\n"
        done <<< "`/sbin/fdisk -l ${ARMSTRAP_DEVICE}`"
    isBlockDev ${ARMSTRAP_DEVICE}
    checkStatus "${ARMSTRAP_DEVICE} is not a block device"
    isRemDevice ${ARMSTRAP_DEVICE}
    checkStatus "${ARMSTRAP_DEVICE} is not a removable device"
  fi

  dialog --backtitle "armStrap" --title "Configuration summary" --yesno "${TMP_INFO}" 0 0
  
#  promptYN "OK to proceed?"
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
    mkimage -C none -A ${BOARD_CPU_ARCH} -T script -d ${1} ${2} >> ${ARMSTRAP_LOG_FILE} 2>&1
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

ANC_LIN="24"
ANC_COL="80"

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
      
      ANC_COL="`${TMP_TPUT} cols`"
      ANC_LIN="`${TMP_TPUT} lines`"
    fi
  fi
}

#usage gitClone <TARGET_DIR> <GIT_SRC> [<BRANCH>]

function gitClone {
  local TMP_GIT="${2}"
  
  if [ -d "${1}" ]; then
    printStatus "gitClone" "Updating `basename ${1}`"
    cd "${1}"
    git pull --progress >> ${ARMSTRAP_LOG_FILE} 2>&1
    cd "${ARMSTRAP_ROOT}"
  else
    if [ ! -z "${3}" ]; then
      local TMP_GIT="${TMP_GIT} -b ${3}"
      printStatus "gitClone" "Cloning `basename ${1}` (branch ${3})"
      git clone --progress "${2}" -b "${3}" "${1}" >> ${ARMSTRAP_LOG_FILE} 2>&1
    else
      printStatus "gitClone" "Cloning `basename ${1}`"
      git clone --progress "${2}" "${1}" >> ${ARMSTRAP_LOG_FILE} 2>&1
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
  
}

# usage checkRootFS 
function checkRootFS {
  printStatus "checkRootFS" "XXX Disabled function"
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

# usage unsetEnv <PATTERN>
function unsetEnv {
  local TMP_I=""
  local TMP_IFS="${IFS}"
  local TMP_LST=""
  IFS="="
  
  while read TMP_I; do
    TMP_I=(${TMP_I})
    if [[ "${TMP_I[0]}" == "${1}"* ]]; then
      TMP_LST="${TMP_I[0]} ${TMP_LST}"
    fi
  done <<< "`set`"
  
  IFS="${TMP_IFS}"
  unset ${TMP_LST}
}

function cleanDirectory {
  ARMSTRAP_LOG_FILE="`mktemp --tmpdir armStrap_Log.XXXXXXXX`"
  local TMP_GUI
  guiStart
  TMP_GUI=$(guiWriter "name" "armStrap")
  TMP_GUI=$(guiWriter "start" "Cleaning up" "Progress")
  

  for i in ${ARMSTRAP_MNT} ${ARMSTRAP_LOG} ${ARMSTRAP_IMG} ${ARMSTRAP_SRC} ${ARMSTRAP_PKG}; do
    TMP_GUI=$(guiWriter "add" 19 "Cleaning directory ${i}")
    rmDirectory $i
    checkDirectory $i
  done
  
  TMP_GUI=$(guiWriter "set" 100 "All done.")

  guiStop
  
  rm -f "${ARMSTRAP_LOG_FILE}"  
}

function ccMake {
  local TMP_CPUARC="${1}"
  local TMP_CPUABI="${2}"
  local TMP_WRKDIR="${3}"
  local TMP_CFLAGS="${4}"
  local TMP_CCPREF="${TMP_CPUARC}-linux-gnueabi${TMP_CPUABI}"
  local TMP_ARCABI="${TMP_CPUARC}${TMP_CPUABI}"
  shift
  shift
  shift
  shift
  
  if [ -z "${TMP_CFLAGS}" ]; then
    CC=${TMP_CCPREF}-gcc dpkg-architecture -a${TMP_ARCABI} -t${TMP_CCPREF} -c make ${ARMSTRAP_MFLAGS} ARCH="${TMP_CPUARC}" CROSS_COMPILE="${TMP_CCPREF}-" -C "${TMP_WRKDIR}" ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  else
    CC=${TMP_CCPREF}-gcc dpkg-architecture -a${TMP_ARCABI} -t${TMP_CCPREF} -c make ${ARMSTRAP_MFLAGS} CFLAGS="${TMP_CFLAGS}" CXXFLAGS="${TMP_CFLAGS}" ARCH="${TMP_CPUARC}" CROSS_COMPILE="${TMP_CCPREF}-" -C "${TMP_WRKDIR}" ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
}

function ccMakeNoLog {
  local TMP_CPUARC="${1}"
  local TMP_CPUABI="${2}"
  local TMP_WRKDIR="${3}"
  local TMP_CFLAGS="${4}"
  local TMP_CCPREF="${TMP_CPUARC}-linux-gnueabi${TMP_CPUABI}"
  local TMP_ARCABI="${TMP_CPUARC}${TMP_CPUABI}"
  shift
  shift
  shift
  shift
  
  if [ -z "${TMP_CFLAGS}" ]; then
    CC=${TMP_CCPREF}-gcc dpkg-architecture -a${TMP_ARCABI} -t${TMP_CCPREF} -c make ARCH="${TMP_CPUARC}" CROSS_COMPILE="${TMP_CCPREF}-" -C "${TMP_WRKDIR}" ${@}
  else
    CC=${TMP_CCPREF}-gcc dpkg-architecture -a${TMP_ARCABI} -t${TMP_CCPREF} -c make ${ARMSTRAP_MFLAGS} CFLAGS="${TMP_CFLAGS}" CXXFLAGS="${TMP_CFLAGS}" ARCH="${TMP_CPUARC}" CROSS_COMPILE="${TMP_CCPREF}-" -C "${TMP_WRKDIR}" ${@}
  fi
}

# usage : getLoader <BOARD_NAME>
function getLoader {
  local TMP_IFS="${IFS}"
  local TMP_I=""
  local TMP_J=""
  local TMP_BOARD="${1,,}"
  local TMP_LOADER=""
  
  for TMP_I in ${ARMSTRAP_LOADER_LIST}; do
      IFS="-"
      local TMP_J=(${TMP_I})
      TMP_J=${TMP_J[0]}
      IFS="${TMP_IFS}"
      TMP_I=${TMP_I/${TMP_J}-/}
      TMP_I=${TMP_I/${ARMSTRAP_TAR_EXTENSION}/}
      if [ "${TMP_BOARD}" = "${TMP_J}" ]; then
        TMP_LOADER="${TMP_I} ${TMP_LOADER}"
      fi
    done
  printf "%s" "${TMP_LOADER}"
}

# usage : fetchIndex
function fetchIndex {
  local TMP_IFS="${IFS}"
  local TMP_I=""
  
  printStatus "fetchIndex" "Fetching and indexing armStrap repository informations."
  while read TMP_I; do
    TMP_I=(${TMP_I//// })
    case ${TMP_I[0]} in
      kernel)  ARMSTRAP_KERNEL_LIST="${TMP_I[1]} ${ARMSTRAP_KERNEL_LIST}"
               ;;
      loader)  ARMSTRAP_LOADER_LIST="${TMP_I[1]} ${ARMSTRAP_LOADER_LIST}"
               ;;
      rootfs)  ARMSTRAP_ROOTFS_LIST="${TMP_I[1]} ${ARMSTRAP_ROOTFS_LIST}"
               ;;
    esac
  done <<< "`wget -a ${ARMSTRAP_LOG_FILE} -O - ${ARMSTRAP_ABUILDER_URL}/.index.php`"
  printStatus "fetchIndex" "Done"
  
}

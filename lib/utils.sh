
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
  printf "Usage : sudo %s [PARAMETERS]\n" "${ARMSTRAP_NAME}"
  printf "\nImage/SD Builder :\n"
  printf "% 4s %- 20s %s\n" "-b" "<BOARD>" "Use board definition <BOARD>."
  printf "% 4s %- 20s %s\n" "-d" "<DEVICE>" "Write to <DEVICE> instead of creating an image."
  printf "% 4s %- 20s %s\n" "-i" "<FILE>" "Set image filename to <FILE>."
  printf "% 4s %- 20s %s\n" "-s" "<SIZE>" "Set image size to <SIZE>MB."
  printf "% 4s %- 20s %s\n" "-h" "<HOSTNAME>" "Set hostname."
  printf "% 4s %- 20s %s\n" "-p" "<PASSWORD>" "Set root password."
  printf "% 4s %- 20s %s\n" "-w" "" "Enable swapfile."
  printf "% 4s %- 20s %s\n" "-W" "" "Disable swapfile."
  printf "% 4s %- 20s %s\n" "-Z" "<SIZE>" "Set swapfile size to <SIZE>MB."
  printf "% 4s %- 20s %s\n" "-n" "\"<IP> <MASK> <GW>\"" "Set static IP."
  printf "% 4s %- 20s %s\n" "-N" "" "Set DHCP IP."
  printf "% 4s %- 20s %s\n" "-r" "\"<NS1> [NS2] [NS3]\"" "Set nameservers."
  printf "% 4s %- 20s %s\n" "-e" "<DOMAIN>" "Set search domain."
  printf "% 4s %- 20s %s\n" "-c" "" "Show licence."
  printf "\nKernel Builder :\n"
  printf "% 4s %- 20s %s\n" "-k" "" "Create debian packages for Kernel/Sources/Headers."
  printf "% 4s %- 20s %s\n" "-B" "" "Create U-Boot and Fex configuration."
  printf "\nUtilities :\n"
  printf "% 4s %- 20s %s\n" "-C" "" "Clean Log/Work/Deb directory."
  printf "% 4s %- 20s %s\n" "-S" "" "Clean Sources directory."
  printf "% 4s %- 20s %s\n" "-I" "" "Clean Images directory."
  printf "\nSupported boards :"
  for i in boards/*; do 
    printf " %s" `basename ${i}`
  done
  printf "\n\nWith no parameter, create an image using values found in config.sh.\n"
}

# Usage: logStatus <function> <message>

function logStatus {
  local TMP_TIME=`date "+%y/%m/%d-%H:%M:%S"`
  local TMP_NAME=${1}
  shift
  
  printf "[% 17s] % 15s : " "${TMP_TIME}" "${TMP_NAME}" >> ${ARMSTRAP_LOG_FILE}
  echo "${@}" >> ${ARMSTRAP_LOG_FILE}
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

# Usage: installPrereq <PREREQ1> [<PREREQ2> ... ]
function installPrereqs {
  for i in ${@}; do 
    testInstall ${i}; 
  done
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

# Usage: testInstall <package>

function testInstall {
  local IN=(`dpkg-query -W -f='${Status} ${Version}\n' ${1} 2> /dev/null`)
  if [ "${IN[0]}" != "install" ]; then
    printStatus "testInstall" "Installing ${1}"
    apt-get --quiet -y install ${1} >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
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

# Usage: gitSources <repos> <target_directory> <git_parameter> [<git_parameter2> ...]

function gitSources {
  local TMP_REP="${1}"
  local TMP_DST="${2}"
  shift;
  shift;
  
  printStatus "gitSources" "Checking Sources for ${TMP_DST}"
  if [ -d "${TMP_DST}" ]; then
    local TMP_WORKDIR=`pwd`
    cd ${TMP_DST}
    printStatus "gitSources" "Updating sources for ${TMP_DST}"
    git pull --quiet >> ${ARMSTRAP_LOG_FILE} 2>&1
    cd ${TMP_WORKDIR}
  else
    printStatus "gitSources" "Cloning ${TMP_DST} from ${TMP_REP}"
    git clone --quiet ${@} ${TMP_REP} ${TMP_DST} >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
  
  if [ ! -d "${TMP_DST}" ]; then
    printStatus "gitSources" "Aborting, Cannot find ${TMP_DST}"
    exit 1
  fi
}

function gitExport {
  local TMP_DIR=`basename ${1}`
  printStatus "gitExport" "Exporting ${TMP_DIR} to ${2}"
  cd "${1}"
  checkDirectory "${2}/${TMP_DIR}"
  git archive --format tar HEAD | tar -x -C "${2}/${TMP_DIR}"
  cd "${ARMSTRAP_ROOT}"
}

# Usage macAddress <VENDOR_ID>
function macAddress {
  if [ -n ${1} ]; then
    if [ -z ${ARMSTRAP_MAC_ADDRESS} ]; then
      ARMSTRAP_MAC_ADDRESS=$( printf "%012x" $((${1} * 16777216 + $[ $RANDOM % 16777216 ])) )
    fi
  fi
}

function funExist {
  declare -f -F ${1} > /dev/null
}

# usage <TARGET_LINK> <TARGET_DIRECTORY> <SOURCE>
function fixSymLink {
  printStatus "fixSymLink" "Fixing symlink for ${1}"
  cd ${2}
  rm -f ${1}
  ln -s ${3} ${1}
  cd ${ARMSTRAP_ROOT}
}

function showConfig {
  printf "\n${ANS_BLD}${ANS_SUL}${ANF_CYN}% 20s${ANS_RST}\n\n" "CONFIGURATION"
#  printf "%s\n\n" "--------------------"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Board" "${ARMSTRAP_CONFIG}"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Distribution" "${ARMSTRAP_OS}"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Hostname" "${ARMSTRAP_HOSTNAME}"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Root Password" "${ARMSTRAP_PASSWORD}"
  if [ ! -z "${ARMSTRAP_SWAP}" ]; then
    printf "${ANF_GRN}% 20s${ANS_RST}: %sMB\n" "Swapfile Size" "${ARMSTRAP_SWAP_SIZE}"
  fi
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Log File" "${ARMSTRAP_LOG_FILE}"
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
  if [ ! -z "${ARMSTRAP_IMAGE_NAME}" ]; then
    printf "${ANF_GRN}% 20s${ANS_RST}: %sMB\n" "Image Size" "${ARMSTRAP_IMAGE_SIZE}"
    printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Image File" "${ARMSTRAP_IMAGE_NAME}"
    if [ -e "${ARMSTRAP_IMAGE_NAME}" ]; then
      printf "\n% 20s : %s\n" "!!! Warning !!!" "Image file exists, will be overwritten"
    fi
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

# usage makeDeb <PACKAGE CONTENT> <PACKAGE NAME>
function makeDeb {
  printStatus "makeDeb" "Creating package ${2}.deb"
  
  dpkg-deb --build "${1}" "${2}.deb" >> ${ARMSTRAP_LOG_FILE} 2>&1
}
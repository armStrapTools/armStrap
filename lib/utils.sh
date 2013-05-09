
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
  printf "Usage : sudo %s [PARAMETERS]\n\n" "${PRG_NAME}"
  printf "% 4s %- 20s %s\n" "-b" "<BOARD>" "Use board definition <BOARD>."
  printf "% 4s %- 20s %s\n" "-d" "<DEVICE>" "Write to <DEVICE> instead of creating an image."
  printf "% 4s %- 20s %s\n" "-i" "<FILE>" "Set image filename to <FILE>."
  printf "% 4s %- 20s %s\n" "-s" "<SIZE>" "Set image size to <SIZE>MB."
  printf "% 4s %- 20s %s\n" "-h" "<HOSTNAME>" "Set hostname"
  printf "% 4s %- 20s %s\n" "-h" "<HOSTNAME>" "Set hostname"
  printf "% 4s %- 20s %s\n" "-p" "<PASSWORD>" "Set root password"
  printf "% 4s %- 20s %s\n" "-w" "" "Enable swapfile"
  printf "% 4s %- 20s %s\n" "-W" "" "Disable swapfile"
  printf "% 4s %- 20s %s\n" "-Z" "<SIZE>" "Set swapfile size to <SIZE>MB"
  printf "% 4s %- 20s %s\n" "-n" "\"<IP> <MASK> <GW>\"" "Set static IP"
  printf "% 4s %- 20s %s\n" "-N" "" "Set DHCP IP"
  printf "% 4s %- 20s %s\n" "-r" "\"<NS1> [NS2] [NS3]\"" "Set nameservers"
  printf "% 4s %- 20s %s\n" "-e" "<DOMAIN>" "Set search domain"
  printf "% 4s %- 20s %s\n\n" "-c" "" "Show licence."
  printf "With no parameter, create an image using values found in config.sh.\n"
  printf "\nYou need to be root to run this script.\n\n"
}

# Usage: installPrereq 
function installPrereqs {
  for i in ${BUILD_PREREQ}; do testInstall ${i}; done
}



# Usage : isBlockDev <DEVICE>

function isBlockDev {
  if ! [ -b ${1} ]; then
    logStatus "isBlockDev" "Device ${1} is not a block device"
    return 1
  fi  
  return 0
}

# Usage: isRemDevice <DEVICE>

function isRemDevice {
  local TMP_DEVICE=`basename ${1}`
  if [ `cat /sys/block/${TMP_DEVICE}/removable` != "1" ]; then
    logStatus "isRemDevice" "Device ${1} is not a removeable device"
    return 1
  fi
  return 0
}

# Usage: testInstall <package>

function testInstall {
  local IN=(`dpkg-query -W -f='${Status} ${Version}\n' ${1} 2> /dev/null`)
  if [ "${IN[0]}" != "install" ]; then
    printStatus "testInstall" "Installing ${1}"
    apt-get --quiet -y install ${1} >> ${BUILD_LOG_FILE} 2>&1
  fi
}

# Usage: partSync

function partSync {
  logStatus "partSync" "Flush file system buffers"
  sync
  logStatus "partSync" "Inform the OS of partition table changes"  
  partprobe
}

# Usage: promptYN "<question>"

function promptYN {
  echo ""
  while true; do
    read -p "$1 " yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes or no.";;
    esac
  done
  echo ""
}

# Usage: getSources <repos> <target_directory>

function getSources {
  printStatus "getSources" "Checking Sources for ${2}"
  if [ -d "${2}" ]; then
    local TMP_WORKDIR=`pwd`
    cd ${2}
    printStatus "getSources" "Updating sources for ${2}"
    git pull --quiet >> ${BUILD_LOG_FILE} 2>&1
    cd ${TMP_WORKDIR}
  else
    printStatus "getSources" "Cloning $2 from $1"
    git clone --quiet $1 $3 $4 $2 >> ${BUILD_LOG_FILE} 2>&1
  fi
  
  if [ ! -d "${2}" ]; then
    printStatus "getSources" "Aborting, Cannot find ${2}"
    exit 1
  fi
}

# Usage: mkImage <FILE> <SIZE IN MB>
function mkImage {

  printStatus "mkImage" "Creating image ${1}, size ${2}MB"
  
  if [ -e "${1}" ]; then
    logStatus "mkImage" "${1} exist"
    promptYN "${1} exist, overwrite?"
    checkStatus "Not overwriting ${1}"
  fi

  dd if=/dev/zero of=${1} bs=1M count=${2} >> ${BUILD_LOG_FILE} 2>&1
  checkStatus "dd exit with status $?"
}

# Usage macAddress <VENDOR_ID>
function macAddress {
  if [ -n ${1} ]; then
    if [ -z ${BOARD_MAC_ADDRESS} ]; then
      BOARD_MAC_ADDRESS=$( printf "%012x" $((${1} * 16777216 + $[ $RANDOM % 16777216 ])) )
    fi
  fi
}

function funExist {
  declare -f -F ${1} > /dev/null
}


function showConfig {
  printf "\n% 20s\n" "Configuration"
  printf "%s\n\n" "--------------------"
  printf "% 20s : %s\n" "Board" "${BOARD_CONFIG}"
  printf "% 20s : %s\n" "Hostname" "${BOARD_HOSTNAME}"
  printf "% 20s : %s\n" "Root Password" "${BOARD_PASSWORD}"
  if [ ! -z "${BOARD_SWAP}" ]; then
    printf "% 20s : %sMB\n" "Swapfile Size" "${BOARD_SWAP_SIZE}"
  fi

  printf "% 20s : %s\n" "Log File" "${BUILD_LOG_FILE}"
  if [ ! -z "${BOARD_MAC_ADDRESS}" ]; then
    printf "% 20s : %s\n" "Mac Address" "${BOARD_MAC_ADDRESS}"
  fi
  if [ "${BOARD_ETH0_MODE}" == "dhcp" ]; then
    printf "% 20s : %s\n" "IP Address" "${BOARD_ETH0_MODE}"
  else
    printf "% 20s : %s\n" "IP Address" "${BOARD_ETH0_IP}"
    printf "% 20s : %s\n" "Mask" "${BOARD_ETH0_MASK}"
    printf "% 20s : %s\n" "Gateway" "${BOARD_ETH0_GW}"
    printf "% 20s : %s\n" "Search Domain" "${BOARD_DOMAIN}"
    printf "% 20s : %s\n" "DNS" "${BOARD_DNS}"
  fi
    if [ -z "${BUILD_DEVICE}" ]; then
    printf "% 20s : %sMB\n" "Image Size" "${BUILD_IMAGE_SIZE}"
    printf "% 20s : %s\n" "Image File" "${BUILD_IMAGE_NAME}"
    if [ -e "${BUILD_IMAGE_NAME}" ]; then
      printf "\n% 20s : %s\n" "!!! Warning !!!" "Image file exists, will be overwritten"
    fi
  else
    printf "% 20s : %s\n" "Content of" "${BUILD_DEVICE}"
    isBlockDev ${BUILD_DEVICE}
    checkStatus "${BUILD_DEVICE} is not a block device"
    isRemDevice ${BUILD_DEVICE}
    checkStatus "${BUILD_DEVICE} is not a removable device"
    fdisk -l ${BUILD_DEVICE}
  fi
  
  promptYN "OK to proceed?"
  checkStatus "Not ok to proceed."    
    
}

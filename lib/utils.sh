
function showTitle {
 printf "\n%s version %s\n" "`basename ${0}`" "${PRG_VERSION}"
 printf "Copyright (C) 2013 Eddy Beaupre\n\n"
}

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
  printf "Usage :\n\n"
  printf "% 4s %- 15s %s\n" "-b" "<BOARD>" "Use board definition <BOARD>."
  printf "% 4s %- 15s %s\n" "-d" "<DEVICE>" "Write to <DEVICE> instead of creating an image."
  printf "% 4s %- 15s %s\n" "-i" "<FILE>" "Set image filename to <FILE>."
  printf "% 4s %- 15s %s\n\n" "-c" "" "Show licence."
  printf "With no parameter, create an image using default values.\n"
  printf "\nYou need to be root to run this script.\n\n"
}

# Usage: logStatus <function> <message>

function logStatus {
  local TMP_TIME=`date +%y/%m/%d-%H:%M:%S`
  
  if [ ! -d "${BUILD_LOG}" ]; then
    mkdir -p ${BUILD_LOG}
  fi
  
  printf "[% 17s] % 15s : %s\n" "${TMP_TIME}" "${1}" "${2}" >> ${BUILD_LOG_FILE}
}

# Usage: printStatus <function> <message>

function printStatus {
  printf "** % 15s : %s\n" "${1}" "${2}"
  logStatus "${1}" "${2}"
}

# Usage: installPrereq 
function installPrereqs {
  for i in ${PREREQ}; do testInstall ${i}; done
}

# Usage: isRoot

function isRoot {
  if [ "`id -u`" -ne "0" ]; then
    logStatus "isRoot" "User `whoami` (`id -u`) is not root"
    return 1
  fi
  return 0
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

# Usage: checkDirectory <path>

function checkDirectory {
  if [ ! -d "${1}" ]; then
    printStatus "checkDirectory" "Creating ${1}"
    mkdir -p ${1}
    checkStatus "Creation of directory ${1} failed"
  fi
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

function checkStatus {
  if [ $? -ne 0 ]; then
    printStatus "checkStatus" "Aborting (${1})"
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

# Generate a mac address if the board need one.
function macAddress {
  if [ -n ${BOARD_MAC_VENDOR} ]; then
    if [ -z ${BOARD_MAC_ADDRESS} ]; then
      BOARD_MAC_ADDRESS=$( printf "%012x" $((${BUILD_MAC_VENDOR}*16777216+$[ $RANDOM % 16777216 ])) )
    fi
  fi
}


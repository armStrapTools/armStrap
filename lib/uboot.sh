
# Usage ubootSetEnv <TARGET_FILE> <VARIABLE> <VALUE>
function ubootSetEnv {
  local TMP_CFG="${1}"
  shift
  
  printStatus "ubootSetEnv" "Adding setenv ${@} to ${TMP_CFG}"
  echo "setenv ${@}" >> ${TMP_CFG}
}

# Usage ubootExt2Load <TARGET_FILE> <INTEFACE> <DEV[:PART]> <ADDR> <FILENAME>
function ubootExt2Load {
  local TMP_CFG="${1}"
  shift
  
  printStatus "ubootExt2Load" "Adding ext2load ${@} to ${TMP_CFG}"
  echo "ext2load ${@}" >> ${TMP_CFG}
}

# Usage ubootBootM <TARGET_FILE> <ADDR> [ARG]
function ubootBootM {
  local TMP_CFG="${1}"
  shift
  
  printStatus "ubootBootM" "Adding bootm ${@} to ${TMP_CFG}"
  echo "bootm ${@}" >> ${TMP_CFG}
}

# Usage ubootDDLoader <FILE> <DEVICE> <BS> <SEEK>
function ubootDDLoader {
  printStatus "ubootDDLoader" "Installing ${1} to ${2}, block size ${3}, seek ${4}"
  dd if=${1} of=${2} bs=${3} seek=${4} >> ${BUILD_LOG_FILE} 2>&1
}

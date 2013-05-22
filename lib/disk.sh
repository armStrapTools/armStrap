
# Usage: makeImg <FILE> <SIZE IN MB>
function makeImg {

  printStatus "mkImage" "Creating image ${1}, size ${2}MB"
  
  if [ -e "${1}" ]; then
    logStatus "mkImage" "${1} exist"
    promptYN "${1} exist, overwrite?"
    checkStatus "Not overwriting ${1}"
  fi

  dd if=/dev/zero of=${1} bs=1M count=${2} >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "dd exit with status $?"
  partSync
}

# Usage partDevice <DEVICE> <SIZE:FS> [<SIZE:FS> ...]
function partDevice {
  local TMP_DEV="${1}"
  local TMP_OFF=1
  shift
  printStatus "partDevice" "Creating new MSDOS label on ${TMP_DEV}"
  parted ${TMP_DEV} --script -- mklabel msdos >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "parted exit with status $?"
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    if [ "${TMP_ARR[0]}" -gt "0" ]; then
      local TMP_SIZE=$(($TMP_OFF + ${TMP_ARR[0]}))
      printStatus "partDevice" "Creating a ${TMP_ARR[0]}Mb partition (${TMP_ARR[1]})" 
      parted ${TMP_DEV} --script -- mkpart primary ${TMP_ARR[1]} ${TMP_OFF} ${TMP_SIZE} >> ${ARMSTRAP_LOG_FILE} 2>&1
      checkStatus "parted exit with status $?"
      TMP_OFF=$(($TMP_SIZE + 1))
    else
      printStatus "partDevice" "Creating a partition using remaining free space (${TMP_ARR[1]})"
      parted ${TMP_DEV} --script -- mkpart primary ${TMP_ARR[1]} ${TMP_OFF} -1 >> ${ARMSTRAP_LOG_FILE} 2>&1
      checkStatus "parted exit with status $?"
    fi
  done
  partSync
}

# Usage loopImg <FILE>
function loopImg {
  printStatus "loopImg" "Attaching ${1} to loop device"
  ARMSTRAP_DEVICE_LOOP=($(losetup -f --show "${1}"))
  checkStatus "losetup exit with status $?"
  partSync
}

# Usage uloopImg
function uloopImg {
  printStatus "uloopImg" "Detaching ${ARMSTRAP_DEVICE_LOOP} from loop device"
  losetup -d ${ARMSTRAP_DEVICE_LOOP} >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "losetup exit with status $?"
  partSync
}

# Usage mapImg <FILE>
function mapImg {
  local TMP_MAP
  printStatus "mapImg" "Mapping ${1} to loop device"
  while read i; do
    x=($i)
    if [ -z "${TMP_MAP}" ]; then
      TMP_MAP="/dev/mapper/${x[2]}"
    else
      TMP_MAP="${TMP_MAP} /dev/mapper/${x[2]}"
    fi
  done <<< "`kpartx -avs ${1}`"
  checkStatus "kpartx exit with status $?"
  ARMSTRAP_DEVICE_MAPS=(${TMP_MAP})
  partSync
}

# Usage umapImg <FILE>
function umapImg {
  printStatus "umapImg" "UnMapping ${1} from loop device"
  kpartx -d ${1} >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "kpartx exit with status $?"
  partSync
}

# Usage formatPartitions <DEVICE:FS> [<DEVICE:FS> ...]
function formatPartitions {
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    printStatus "fmtParts" "Formatting ${1} (${TMP_ARR[1]})"
    if [[ ${TMP_ARR[1]} = fat* ]]; then
      mkfs.vfat ${TMP_ARR[0]} >> ${ARMSTRAP_LOG_FILE} 2>&1
    else
      mkfs.${TMP_ARR[1]} ${TMP_ARR[0]} >> ${ARMSTRAP_LOG_FILE} 2>&1
    fi
    checkStatus "mkfs.${TMP_ARR[1]} exit with status $?"
  done
  partSync
}

# Usage mountPartitions <DEVICE:MOUNTPOINT> [<DEVICE:MOUNTPOINT> ...]
function mountPartitions {
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    checkDirectory "${TMP_ARR[1]}"
    mount ${TMP_ARR[0]} ${TMP_ARR[1]} >> ${ARMSTRAP_LOG_FILE} 2>&1
  done
  partSync
}

# Usage umountPartitions <MOUNTPOINT> [<MOUNTPOINT> ...]
function umountPartitions {
  for i in "$@"; do
    umount ${i} >> ${ARMSTRAP_LOG_FILE} 2>&1
  done
  partSync
}

# Usage setupImg <FILE> <SIZE> <MNT_ORDER:MNT_POINT:FSTYPE:SIZE> [<MNT_ORDER:MNT_POINT:FSTYPE:SIZE>]
function setupImg {
  local TMP_IMAGE="${1}"
  local TMP_SIZE="${2}"
  local TMP_PARTS=""
  local TMP_FST=""
  local TMP_FS=""
  local TMP_MNT=""
  local TMP_SORT=("")
  shift
  shift
  local TMP_CNT=0
  
  makeImg "${TMP_IMAGE}" "${TMP_SIZE}"
  
  loopImg "${TMP_IMAGE}"
  
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    if [ -z "${TMP_PARTS}" ]; then
      TMP_PARTS="${TMP_ARR[3]}:${TMP_ARR[2]}"
      TMP_FST="${TMP_ARR[2]}"
      TMP_MNT="${TMP_ARR[0]}:${TMP_ARR[1]}"
    else
      TMP_PARTS="${TMP_PARTS} ${TMP_ARR[3]}:${TMP_ARR[2]}"
      TMP_FST="${TMP_FST} ${TMP_ARR[2]}"
      TMP_MNT="${TMP_MNT} ${TMP_ARR[0]}:${TMP_ARR[1]}"
    fi
  done
  TMP_FST=(${TMP_FST})
  TMP_MNT=(${TMP_MNT})
  
  readarray -t TMP_SORT < <(printf '%s\0' "${TMP_MNT[@]}" | sort -z | xargs -0n1)
  
  TMP_MNT=(${TMP_SORT[@]})
  
  echo "Sorted Mount : ${TMP_MNT[@]}"
 
  partDevice "${ARMSTRAP_DEVICE_LOOP}" ${TMP_PARTS}
  
  uloopImg
  
  mapImg "${TMP_IMAGE}"

  for i in "${ARMSTRAP_DEVICE_MAPS[@]}"; do
    if [ -z "${TMP_FS}" ]; then
      TMP_FS="${i}:${TMP_FST[$TMP_COUNT]}"
    else
      TMP_FS="${TMP_FS} ${i}:${TMP_FST[$TMP_COUNT]}"
    fi
    (( TMP_COUNT++ ))
  done
  
  formatPartitions ${TMP_FS}
  
  # Usage mountPartitions <DEVICE:MOUNTPOINT> [<DEVICE:MOUNTPOINT> ...]
  
  umapImg "${TMP_IMAGE}"     
  
  #formatPartitions <DEVICE:FS> [<DEVICE:FS> ...]
}
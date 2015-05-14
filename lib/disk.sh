
# Usage: syncFS
function syncFS {
  printStatus "syncFS" "Flushing file system buffers"
  /bin/sync >> ${ARMSTRAP_LOG_FILE} 2>&1
}

function probeFS {
  local TMP_PROBE="${ARMSTRAP_DEVICE}"
  
  if [ -n ${1} ]; then
    TMP_PROBE="${1}"
  fi
  
  printStatus "probeFS" "Probing ${TMP_PROBE} for partitions changes"
  /sbin/partprobe ${TMP_PROBE} >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage: makeImg <FILE> <SIZE IN MB>
function makeImg {

  printStatus "mkImage" "Creating image ${1}, size ${2}MB"
  
  if [ -e "${1}" ]; then
    printStatus "mkImage" "${1} exist"
    promptYN "${1} exist, overwrite?"
    checkStatus "Not overwriting ${1}"
  fi

  dd if=/dev/zero of=${1} bs=1M count=${2} >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "dd exit with status $?"
  syncFS
}

# Usage partDevice <DEVICE> <SIZE:FS> [<SIZE:FS> ...]
function partDevice {
  local TMP_DEV="${1}"
  local TMP_OFF=1
  local TMP_I
  local TMP_J=1
  shift

  printStatus "partDevice" "Creating new MSDOS label on ${TMP_DEV}"
  parted ${TMP_DEV} --script -- mklabel msdos >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "parted exit with status $?"

  for TMP_I in "$@"; do
    IFS=":"
    local TMP_ARR=(${TMP_I})
    IFS="${ARMSTRAP_IFS}"
    if [[ "${TMP_ARR[1]}" == *"fat"* ]]; then
      TMP_ARR[1]="fat32"
    fi
    if [ "${TMP_ARR[0]}" -gt "0" ]; then
      local TMP_SIZE=$(($TMP_OFF + ${TMP_ARR[0]}))
      printStatus "partDevice" "Creating a ${TMP_ARR[0]}Mb partition on ${TMP_DEV} (${TMP_ARR[1]})" 
      parted ${TMP_DEV} --script -- mkpart primary ${TMP_ARR[1]} ${TMP_OFF} ${TMP_SIZE} >> ${ARMSTRAP_LOG_FILE} 2>&1
      checkStatus "parted exit with status $?"
      TMP_OFF=$((${TMP_OFF} + ${TMP_SIZE}))
    else
      printStatus "partDevice" "Creating a partition on ${TMP_DEV} using remaining free space (${TMP_ARR[1]})"
      parted ${TMP_DEV} --script -- mkpart primary ${TMP_ARR[1]} ${TMP_OFF} -1 >> ${ARMSTRAP_LOG_FILE} 2>&1
      checkStatus "parted exit with status $?"
      break
    fi
  done
  syncFS
  probeFS ${TMP_DEV}
}

# Usage loopImg <FILE>
function loopImg {
  printStatus "loopImg" "Attaching ${1} to loop device"
  ARMSTRAP_DEVICE=($(losetup -f --show "${1}"))
  checkStatus "losetup exit with status $?"
}

# Usage uloopImg
function uloopImg {
  printStatus "uloopImg" "Detaching ${ARMSTRAP_DEVICE} from loop device"
  syncFS
  losetup -d ${ARMSTRAP_DEVICE} >> ${ARMSTRAP_LOG_FILE} 2>&1
  while [ $? -ne 0 ]; do
    printStatus "uloopImg" "${ARMSTRAP_DEVICE} is busy, waiting 10 seconds before retrying"
    sleep 10
    syncFS
    losetup -d ${ARMSTRAP_DEVICE} >> ${ARMSTRAP_LOG_FILE} 2>&1
  done
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
  probeFS
}

# Usage umapImg <FILE> <DEVICE>
function umapImg {
  printStatus "umapImg" "UnMapping ${1} from loop device"
  syncFS
  kpartx -d ${1} >> ${ARMSTRAP_LOG_FILE} 2>&1
  sleep 2
  kpartx -d ${2} >> ${ARMSTRAP_LOG_FILE} 2>&1
  sleep 2
  losetup -d ${2} >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage formatParts <DEVICE:FS> [<DEVICE:FS> ...]
function formatParts {
  local TMP_I
  for TMP_I in "$@"; do
    IFS=":"
    local TMP_ARR=(${TMP_I})
    IFS="${ARMSTRAP_IFS}"
    waitParts ${TMP_ARR[0]} 10
    printStatus "fmtParts" "Formatting ${TMP_ARR[0]} (${TMP_ARR[1]})"
    if [[ ${TMP_ARR[1]} = *"fat"* ]]; then
      mkfs.vfat ${TMP_ARR[0]} >> ${ARMSTRAP_LOG_FILE} 2>&1
    else
      mkfs.${TMP_ARR[1]} -q ${TMP_ARR[0]} >> ${ARMSTRAP_LOG_FILE} 2>&1
    fi
    checkStatus "mkfs.${TMP_ARR[1]} exit with status $?"
    syncFS
  done
}

# Usage waitParts <DEVICE> <TIMEOUT>
function waitParts {
  local TMP_I=0
  
  while [ ! -e ${1} ]; do
    printStatus "waitParts" "Waiting for ${1}."
    sleep 1
    (( TMP_I++ ))
    if [ "${TMP_I}" -gt "${2}" ]; then
      break;
    fi
  done
  
  if [ ! -e ${1} ]; then
    exitStatus "Device ${1} not found!"
  fi
}

# Usage mountParts <DEVICE:MOUNTPOINT> [<DEVICE:MOUNTPOINT> ...]
function mountParts {
  local TMP_I
  local TMP_J=0
  
  for TMP_I in "$@"; do
    IFS=":"
    local TMP_ARR=(${TMP_I})
    IFS="${ARMSTRAP_IFS}"
    waitParts ${TMP_ARR[0]} 10
    printStatus "mountParts" "Mounting ${TMP_ARR[0]} on ${ARMSTRAP_MNT}${TMP_ARR[1]}"
    checkDirectory "${ARMSTRAP_MNT}${TMP_ARR[1]}"
    if [ -e ${TMP_ARR[0]} ]; then
      mount ${TMP_ARR[0]} ${ARMSTRAP_MNT}${TMP_ARR[1]} >> ${ARMSTRAP_LOG_FILE} 2>&1
      checkStatus "mount exit with status $?"
    else
      exitStatus "Device ${TMP_ARR[0]} not found!"
    fi
  done
}

# Usage umountParts <MOUNTPOINT> [<MOUNTPOINT> ...]
function umountParts {
  local TMP_I
  syncFS
  for TMP_I in "$@"; do
    printStatus "umountParts" "Unmounting ${ARMSTRAP_MNT}${TMP_I}"
    umount ${ARMSTRAP_MNT}${TMP_I} >> ${ARMSTRAP_LOG_FILE} 2>&1
    checkStatus "umount exit with status $?"
  done
}

# Usage : cleanDev <DEVICE>
function cleanDev {
  printStatus "cleanDev" "Erasing ${1}"
  dd if=/dev/zero of=${1} bs=512 count=1  >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "dd exit with status $?"
  syncFS
  probeFS ${1}
}

#Usage: partList <MNT_ORDER:MNT_POINT:FSTYPE:SIZE> [<MNT_ORDER:MNT_POINT:FSTYPE:SIZE>]
function partList {
  local TMP_I
  local TMP_J
  
  for TMP_I in ${@}; do
    IFS=":"
    TMP_I=(${TMP_I})
    if [ -n "${TMP_J}" ]; then
      TMP_J="${TMP_J} ${TMP_I[3]}:${TMP_I[2]}"
    else
      TMP_J="${TMP_I[3]}:${TMP_I[2]}"
    fi
    IFS="${ARMSTRAP_IFS}"
  done
  
  echo "${TMP_J}"
}

#Usage: mkfsList <DEVICE> <MNT_ORDER:MNT_POINT:FSTYPE:SIZE> [<MNT_ORDER:MNT_POINT:FSTYPE:SIZE>]
function mkfsList {
  local TMP_I
  local TMP_J
  local TMP_K=1
  local TMP_DEV="${1}"
  shift
  
  for TMP_I in ${@}; do
    IFS=":"
    TMP_I=(${TMP_I})
    if [ -n "${TMP_J}" ]; then
      TMP_J="${TMP_J} ${TMP_DEV}${TMP_K}:${TMP_I[2]}:${TMP_I[3]}"
    else
      TMP_J="${TMP_DEV}${TMP_K}:${TMP_I[2]}:${TMP_I[3]}"
    fi
    TMP_K=$((${TMP_K} + 1))
    IFS="${ARMSTRAP_IFS}"
  done
  echo "${TMP_J}"
}

#Usage: mountList <DEVICE> <MNT_ORDER:MNT_POINT:FSTYPE:SIZE> [<MNT_ORDER:MNT_POINT:FSTYPE:SIZE>]
function mountList {
  local TMP_I
  local TMP_J
  local TMP_K=1
  local TMP_DEV="${1}"
  shift
  
  for TMP_I in ${@}; do
    IFS=":"
    TMP_I=(${TMP_I})
    if [ -n "${TMP_J}" ]; then
      TMP_J="${TMP_J} ${TMP_I[0]}:${TMP_DEV}${TMP_K}:${TMP_I[1]}"
    else
      TMP_J="${TMP_I[0]}:${TMP_DEV}${TMP_K}:${TMP_I[1]}"
    fi
    TMP_K=$((${TMP_K} + 1))
    IFS="${ARMSTRAP_IFS}"
  done
  
  TMP_K=(${TMP_J})
  IFS=$'\n'
  TMP_K=($(sort <<<"${TMP_K[*]}"))
  
  TMP_J=""
  for TMP_I in ${TMP_K[*]}; do
    IFS=":"
    TMP_I=(${TMP_I})
    if [ -n "${TMP_J}" ]; then
      TMP_J="${TMP_J} ${TMP_I[1]}:${TMP_I[2]}"
    else
      TMP_J="${TMP_I[1]}:${TMP_I[2]}"
    fi
    IFS="${ARMSTRAP_IFS}"
  done
  
  echo "${TMP_J}"
}

# Usage setupImg <MNT_ORDER:MNT_POINT:FSTYPE:SIZE> [<MNT_ORDER:MNT_POINT:FSTYPE:SIZE>]
function setupImg {
  local TMP_PARTS=""
  local TMP_FST=""
  local TMP_FS=""
  local TMP_MNT=""
  local TMP_MT=""
  local TMP_SORT=("")
  local TMP_CNT=0
  local TMP_GUI
  local TMP_I
  
  guiStart
  TMP_GUI=$(guiWriter "start" "Setting up disk image" "Progress")

  ARMSTRAP_GUI_PCT=$(guiWriter "add" 1 "Creating disk image ${ARMSTRAP_IMAGE_NAME}")
  makeImg "${ARMSTRAP_IMAGE_NAME}" "${ARMSTRAP_IMAGE_SIZE}"
  loopImg "${ARMSTRAP_IMAGE_NAME}"
  
  for TMP_I in "$@"; do
    IFS=":"
    local TMP_ARR=(${TMP_I})
    IFS="${ARMSTRAP_IFS}"
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

  partDevice "${ARMSTRAP_DEVICE}" ${TMP_PARTS}
  
  uloopImg
  
  mapImg "${ARMSTRAP_IMAGE_NAME}"

  for TMP_I in "${ARMSTRAP_DEVICE_MAPS[@]}"; do
    if [ -z "${TMP_FS}" ]; then
      TMP_FS="${TMP_I}:${TMP_FST[$TMP_COUNT]}"
    else
      TMP_FS="${TMP_FS} ${TMP_I}:${TMP_FST[$TMP_COUNT]}"
    fi
    (( TMP_COUNT++ ))
  done
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add" 5 "Formating partitions")
  formatParts ${TMP_FS}
  
  TMP_COUNT=0
  for TMP_I in "${TMP_MNT[@]}"; do
    IFS=":"
    local TMP_ARR=(${TMP_I})
    IFS="${ARMSTRAP_IFS}"
    if [ -z "${TMP_MT}" ]; then
      TMP_MT="${TMP_ARR[0]}:${ARMSTRAP_DEVICE_MAPS[$TMP_COUNT]}:${ARMSTRAP_MNT}${TMP_ARR[1]}"
    else
      TMP_MT="${TMP_MT} ${TMP_ARR[0]}:${ARMSTRAP_DEVICE_MAPS[$TMP_COUNT]}:${ARMSTRAP_MNT}${TMP_ARR[1]}"
    fi
    (( TMP_COUNT++ ))
  done
  
  printStatus "setupIMG" "TMP_MT: ${TMP_MT}"
  
  TMP_MT=(${TMP_MT})
  readarray -t TMP_SORT < <(printf '%s\0' "${TMP_MT[@]}" | sort -z | xargs -0n1)
  TMP_MT=(${TMP_SORT[@]})
  
  for TMP_I in "${TMP_MT[@]}"; do
    IFS=":"
    local TMP_ARR=(${TMP_I})
    IFS="${ARMSTRAP_IFS}"
    if [ -z "${ARMSTRAP_MOUNT_MAP}" ]; then
      ARMSTRAP_MOUNT_MAP="${TMP_ARR[1]}:${TMP_ARR[2]}"
    else
      ARMSTRAP_MOUNT_MAP="${ARMSTRAP_MOUNT_MAP} ${TMP_ARR[1]}:${TMP_ARR[2]}"
    fi
  done
  
  ARMSTRAP_MOUNT_MAP=(${ARMSTRAP_MOUNT_MAP})
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add" 4 "Mounting partitions")
  mountParts ${ARMSTRAP_MOUNT_MAP[@]}
  
  guiStop
}

function finishImg {
  local TMP_RMAP=""
  local TMP_GUI
  local TMP_I
  
  guiStart
  TMP_GUI=$(guiWriter "start" "Finishing disk image" "Progress")

  ARMSTRAP_GUI_PCT=$(guiWriter "add" 3 "Flushing buffers")
  syncFS

  for TMP_I in ${ARMSTRAP_MOUNT_MAP[@]}; do
    IFS=":"
    local TMP_ARR=(${TMP_I})
    IFS="${ARMSTRAP_IFS}"
    if [ -z "${TMP_RMAP}" ]; then
      TMP_RMAP="${TMP_ARR[1]}"
    else
      TMP_RMAP="${TMP_ARR[1]} ${TMP_RMAP}"
    fi
  done
  
  TMP_RMAP=(${TMP_RMAP})
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add" 1 "Unmounting image")
  umountParts ${TMP_RMAP[@]}
  umapImg "${ARMSTRAP_IMAGE_NAME}" "${ARMSTRAP_DEVICE}"
  ARMSTRAP_GUI_PCT=$(guiWriter "add" 1 "Done")
  guiStop
}

# Usage setupSD <MNT_ORDER:MNT_POINT:FSTYPE:SIZE> [<MNT_ORDER:MNT_POINT:FSTYPE:SIZE>]
function setupSD {
  local TMP_PARTS=""
  local TMP_FST=""
  local TMP_FS=""
  local TMP_MNT=""
  local TMP_MT=""
  local TMP_SORT=("")
  local TMP_CNT=0
  local TMP_GUI
  local TMP_I
  
  guiStart
  TMP_GUI=$(guiWriter "start" "Setting up SD card" "Progress")
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add" 1 "Cleaning device ${ARMSTRAP_DEVICE}")
  cleanDev ${ARMSTRAP_DEVICE}
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add" 4 "Creating partitions")
  partDevice "${ARMSTRAP_DEVICE}" $(partList ${@})

  formatParts $(mkfsList ${ARMSTRAP_DEVICE} ${@})

  ARMSTRAP_MOUNT_MAP=($(mountList ${ARMSTRAP_DEVICE} ${@}))
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add" 1 "Mounting partitions")
  mountParts ${ARMSTRAP_MOUNT_MAP[@]}
  
  guiStop
}

function finishSD {
  local TMP_RMAP=""
  local TMP_GUI
  local TMP_I
  
  guiStart
  TMP_GUI=$(guiWriter "start" "Finishing SD" "Progress")

  ARMSTRAP_GUI_PCT=$(guiWriter "add" 3 "Flushing buffers")
  
  syncFS

  for TMP_I in ${ARMSTRAP_MOUNT_MAP[@]}; do
    IFS=":"
    local TMP_ARR=(${TMP_I})
    IFS="${ARMSTRAP_IFS}"
    if [ -z "${TMP_RMAP}" ]; then
      TMP_RMAP="${TMP_ARR[1]}"
    else
      TMP_RMAP="${TMP_ARR[1]} ${TMP_RMAP}"
    fi
  done
  
  TMP_RMAP=(${TMP_RMAP})

  ARMSTRAP_GUI_PCT=$(guiWriter "add" 1 "Unmounting SD")  
  umountParts ${TMP_RMAP[@]}  
  ARMSTRAP_GUI_PCT=$(guiWriter "add" 1 "Done")
  guiStop
}

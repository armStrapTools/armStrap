
# Usage: mkImage <FILE> <SIZE IN MB>
function mkImage {

  printStatus "mkImage" "Creating image ${1}, size ${2}MB"
  
  if [ -e "${1}" ]; then
    logStatus "mkImage" "${1} exist"
    promptYN "${1} exist, overwrite?"
    checkStatus "Not overwriting ${1}"
  fi

  dd if=/dev/zero of=${1} bs=1M count=${2} >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "dd exit with status $?"
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
      printStatus "partDevice" "Creating a ${TMP_SIZE}Mb partition (${TMP_ARR[1]})" 
      parted ${TMP_DEV} --script -- mkpart primary ${TMP_ARR[1]} ${TMP_OFF} ${TMP_SIZE} >> ${ARMSTRAP_LOG_FILE} 2>&1
      checkStatus "parted exit with status $?"
      TMP_OFF=$(($TMP_SIZE + 1))
    else
      printStatus "partDevice" "Creating a partition using remaining free space (${TMP_ARR[1]})"
      parted ${TMP_DEV} --script -- mkpart primary ${TMP_ARR[1]} ${TMP_OFF} -1 >> ${ARMSTRAP_LOG_FILE} 2>&1
      checkStatus "parted exit with status $?"
    fi
  done
}

# Usage loopImg <FILE>
function loopImg {
  printStatus "loopImg" "Attaching ${1} to loop device"
  ARMSTRAP_DEVICE_LOOP=($(losetup -f --show "${1}"))
  checkStatus "losetup exit with status $?"
}

# Usage uloopImg
function uloopImg {
  printStatus "uloopImg" "Detaching ${ARMSTRAP_DEVICE_LOOP} from loop device"
  losetup -d ${ARMSTRAP_DEVICE_LOOP} >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "losetup exit with status $?"
}

# Usage mapImg <FILE>
# XXX NEED TO SET A VARIABLE TO WORK!!!
function mapImg {
  printStatus "mapImg" "Mapping ${1} to loop device"
  while read i; do
    x=($i)
    if [ -z "${ARMSTRAP_DEVICE_MAPS}" ]; then
      ARMSTRAP_DEVICE_MAPS="/dev/mapper/${x[2]}"
    else
      ARMSTRAP_DEVICE_MAPS="${ARMSTRAP_DEVICE_MAPS} /dev/mapper/${x[2]}"
    fi
  done <<< "`kpartx -avs ${1}`"
  checkStatus "kpartx exit with status $?"
}

# Usage umapImg <FILE>
function umapImg {
  printStatus "umapImg" "UnMapping ${1} from loop device"
  kpartx -d ${1} >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "kpartx exit with status $?"
}

# Usage formatPartitions <DEVICE:FS> [<DEVICE:FS> ...]
function formatPartitions {
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    printStatus "fmtParts" "Formatting ${0} (${TMP_ARR[1]})"
    mkfs.${TMP_ARR[1]} ${TMP_ARR[0]} >> ${ARMSTRAP_LOG_FILE} 2>&1
    checkStatus "mkfs.${TMP_ARR[1]} exit with status $?"
  done
}

# Usage mountPartitions <DEVICE:MOUNTPOINT> [<DEVICE:MOUNTPOINT> ...]
function mountPartitions {
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    checkDirectory "${TMP_ARR[1]}"
    mount ${TMP_ARR[0]} ${TMP_ARR[1]} >> ${ARMSTRAP_LOG_FILE} 2>&1
  done
}

# Usage umountPartitions <MOUNTPOINT> [<MOUNTPOINT> ...]
function umountPartitions {
  for i in "$@"; do
    umount ${i} >> ${ARMSTRAP_LOG_FILE} 2>&1
  done
}

#createImg ${IMG_FILE} 1024

#tmp=($(loopImg "${IMG_FILE}"))
#partDevice "${tmp}" "16:fat32" "512:ext4" "-1:ext4"
#uloopImg "${tmp}"

#tmp=($(mapImg "${IMG_FILE}"))
#for i in "${tmp[@]}"; do
#    echo " Map Device : $i"
#done

#formatPartitions "${tmp[0]}:vfat" "${tmp[1]}:ext4" "${tmp[2]}:ext4" 
#
#mountPartitions "${tmp[2]}:./root" "${tmp[1]}:./root/home" "${tmp[0]}:./root/boot"
#
#df
#
#umountPartitions "./root/boot" "./root/home" "./root"
#
#umapImg ${IMG_FILE}

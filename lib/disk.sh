
# Usage createImg <FILE> <SIZE>
function createImg {
  dd if=/dev/zero of=${1} bs=1M count=${2}
}

# Usage partDevice <DEVICE> <SIZE:FS> [<SIZE:FS> ...]
function partDevice {
  local TMP_DEV="${1}"
  local TMP_OFF=1
  shift
  parted ${TMP_DEV} --script -- mklabel msdos
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    if [ "${TMP_ARR[0]}" -gt "0" ]; then
      local TMP_SIZE=$(($TMP_OFF + ${TMP_ARR[0]}))
      parted ${TMP_DEV} --script -- mkpart primary ${TMP_ARR[1]} ${TMP_OFF} ${TMP_SIZE}
      TMP_OFF=$(($TMP_SIZE + 1))
    else
      parted ${TMP_DEV} --script -- mkpart primary ${TMP_ARR[1]} ${TMP_OFF} -1
    fi
  done
}

# Usage loopImg <FILE>
function loopImg {
  losetup -f --show ${1}
}

# Usage uloopImg <DEVICE>
function uloopImg {
  losetup -d ${1}
}

# Usage mapImg <FILE>
function mapImg {
  while read i; do
    x=($i)
    printf "%s " "/dev/mapper/${x[2]}"
  done <<< "`kpartx -avs ${1}`"
}

# Usage umapImg <FILE>
function umapImg {
  kpartx -d ${1}
}

# Usage formatPartitions <DEVICE:FS> [<DEVICE:FS> ...]
function formatPartitions {
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    mkfs.${TMP_ARR[1]} ${TMP_ARR[0]}
    echo ""
  done
}

# Usage mountPartitions <DEVICE:MOUNTPOINT> [<DEVICE:MOUNTPOINT> ...]
function mountPartitions {
  for i in "$@"; do
    local TMP_ARR=(${i//:/ })
    if [ ! -d "${TMP_ARR[1]}" ]; then
      mkdir -p ${TMP_ARR[1]}
    fi
    mount ${TMP_ARR[0]} ${TMP_ARR[1]}
  done
}

# Usage umountPartitions <MOUNTPOINT> [<MOUNTPOINT> ...]
function umountPartitions {
  for i in "$@"; do
    umount ${i}
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

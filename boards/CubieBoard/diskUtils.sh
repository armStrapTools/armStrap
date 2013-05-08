# usage createParts <DEVICE>

function createParts {
  isBlockDev ${1}
  checkStatus "${1} is not a block device"

  printStatus "createParts" "Creating partions in ${1}"
  fdisk ${1} << EOF > /dev/null 2>&1
n
p
1


w
EOF

  partSync
}

# Usage setupImage <IMAGE FILE>

function setupImage {
  BUILD_IMAGE_DEVICE=`losetup -f --show ${1}`
  printStatus "setupImage" "loop device is ${BUILD_IMAGE_DEVICE}"

  createParts ${BUILD_IMAGE_DEVICE}

  losetup -d ${BUILD_IMAGE_DEVICE}

  BUILD_IMAGE_DEVICE=`kpartx -va ${1} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
  BUILD_IMAGE_ROOTP="/dev/mapper/${BUILD_IMAGE_DEVICE}p1"
  BUILD_IMAGE_DEVICE="/dev/${BUILD_IMAGE_DEVICE}"
  printStatus "setupImage" "Image device is ${BUILD_IMAGE_DEVICE}"
  printStatus "setupImage" "Root partition is ${BUILD_IMAGE_ROOTP}"
}

# Usage setupDevice <DEVICE>
function setupDevice {
  isBlockDev ${1}
  checkStatus "${1} is not a block device"
  isRemDevice ${1}
  checkStatus "${1} is not a removable device"
  
  printf "Content of ${1} :\n"
  
  fdisk -l ${1}
  
  promptYN "The content of ${1} will be erased, continue?"
  checkStatus "Not erasing ${1}"
  
  printStatus "setupDevice" "Erasing ${1}"
  dd if=/dev/zero of=${1} bs=1M count=1 >> ${BUILD_LOG_FILE} 2>&1
  checkStatus "dd exit with status $?"
  
  createParts ${1}
  
  if [ ! -b ${1} ]; then
    BUILD_IMAGE_ROOTP=${1}p1
    if [ ! -b ${BUILD_IMAGE_ROOTP} ]; then
      printStatus "setupDevice" "Aborting, can't find root partition"
      exit 1
    fi
  else
    BUILD_IMAGE_ROOTP=${1}1
    printStatus "setupDevice" "Root partition is ${BUILD_IMAGE_ROOTP}"
  fi
}

# Usage createFS <ROOT PARTITION>

function createFS {
  isBlockDev ${1}
  checkStatus "${1} is not a block device"
  printStatus "createFS" "Formatting partitions ${1} (ext4)"
  mkfs.ext4 ${1} >> ${BUILD_LOG_FILE} 2>&1
  partSync
}

function mountAll {
  printStatus "mountAll" "Mounting ${BUILD_IMAGE_ROOTP} to ${BUILD_MNT_ROOT}"
  checkDirectory ${BUILD_MNT_ROOT}
  mount ${BUILD_IMAGE_ROOTP} ${BUILD_MNT_ROOT}
  checkStatus "Mount of ${BUILD_IMAGE_ROOTP} to ${BUILD_MNT_ROOT} failed, error code ${?}"
  partSync
}


function unmountAll {
  printStatus "unmountAll" "Unmounting ${BUILD_IMAGE_ROOTP} from ${BUILD_MNT_ROOT}"
  umount ${BUILD_MNT_ROOT}
  checkStatus "Unmount of ${BUILD_IMAGE_ROOTP} from ${BUILD_MNT_ROOT} failed, error code ${?}"
  partSync
}

function freeImage {
  printStatus "freeImage" "Running kpartx -d ${1}"
  kpartx -d ${1}

  printStatus "freeImage" "Running losetup -d ${1}"
  losetup -d ${1}
}

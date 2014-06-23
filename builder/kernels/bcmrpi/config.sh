BUILD_KERNEL_TYPE="bcmrpi"
BUILD_KERNEL_GITSRC="https://github.com/raspberrypi/linux.git"
BUILD_KERNEL_GITBRN="rpi-3.6.y"
BUILD_KERNEL_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=hard"
BUILD_KERNEL_MKIMAGE="${ARMSTRAP_KERNELS}/${BUILD_KERNEL_TYPE}/mkimage"
BUILD_KERNEL_PREHOOK="bcmrpiFirmware"
BUILD_KERNEL_IMAGE="zImage"

BUILD_KERNEL_FIRMWARE_SRC="${ARMSTRAP_SRC}/${BUILD_KERNEL_TYPE}/firmware"
BUILD_KERNEL_FIRMWARE_GIT="https://github.com/raspberrypi/firmware.git"
BUILD_KERNEL_FIRMWARE_BRN=""

function bcmrpiFirmware {
  printStatus "bcmrpiFirmware" "Updating ${BUILD_KERNEL_TYPE} firmware"

  gitClone "${BUILD_KERNEL_FIRMWARE_SRC}" "${BUILD_KERNEL_FIRMWARE_GIT}" "${BUILD_KERNEL_FIRMWARE_BRN}"

  printStatus "bcmrpiFirmware" "${BUILD_KERNEL_TYPE} firmware done"
}

source ${ARMSTRAP_KERNELS}/.defaults/config.sh

BUILD_KERNEL_TYPE="bcmrpi"
BUILD_KERNEL_GITSRC="https://github.com/raspberrypi/linux.git"
BUILD_KERNEL_GITBRN="rpi-3.6.y"
BUILD_KERNEL_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=hard"
BUILD_KERNEL_MKIMAGE="${ARMSTRAP_KERNELS}/${BUILD_KERNEL_TYPE}/tools/mkimage"
BUILD_KERNEL_PREHOOK="rpiFirmware"

source ${ARMSTRAP_KERNELS}/.defaults/config.sh

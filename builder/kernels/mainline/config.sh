BUILD_KERNEL_TYPE="mainline"
BUILD_KERNEL_GITSRC="git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"
BUILD_KERNEL_PARAM="LOADADDR=0x40008000 "
BUILD_KERNEL_DTBS=1

source ${ARMSTRAP_KERNELS}/.defaults/config.sh

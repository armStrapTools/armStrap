BUILD_KERNEL_TYPE="sunxi-next"
BUILD_KERNEL_GITBRN="sunxi-next"
BUILD_KERNEL_GITSRC="https://github.com/linux-sunxi/linux-sunxi.git"
BUILD_KERNEL_PARAM="LOADADDR=0x40008000 "
BUILD_KERNEL_DTBS=1

source ${ARMSTRAP_KERNELS}/.defaults/config.sh

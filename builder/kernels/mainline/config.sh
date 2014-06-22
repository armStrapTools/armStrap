BUILD_KERNEL_TYPE="mainline"
#BUILD_KERNEL_GITBRN="sunxi-next"
BUILD_KERNEL_GITSRC="git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"
BUILD_KERNEL_PARAM="LOADADDR=0x40008000 "
BUILD_KERNEL_EXTRA_MAKE="dtbs"
#BUILD_KERNEL_EXTRA_DEB="arch/arm/boot/dts/sun7i-a20-cubietruck.dtb"

source ${ARMSTRAP_KERNELS}/.defaults/config.sh

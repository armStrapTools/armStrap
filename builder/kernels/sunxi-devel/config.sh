BUILD_KERNEL_TYPE="sunxi-devel"
BUILD_KERNEL_GITBRN="sunxi-devel"
BUILD_KERNEL_GITSRC="https://github.com/linux-sunxi/linux-sunxi.git"
BUILD_KERNEL_PARAM="LOADADDR=0x40008000 "
BUILD_KERNEL_EXTRA_MAKE="dtbs"
#BUILD_KERNEL_EXTRA_DEB="arch/arm/boot/dts/sun7i-a20-cubietruck.dtb"

source ${ARMSTRAP_KERNELS}/.defaults/config.sh

BUILD_KERNEL_TYPE="sun7i-test"
BUILD_KERNEL_GITBRN="sunxi-test"
BUILD_KERNEL_GITSRC="https://github.com/jwrdegoede/linux-sunxi.git"
BUILD_KERNEL_PARAM="LOADADDR=0x40008000 "
BUILD_KERNEL_EXTRA_MAKE="dtbs"
BUILD_KERNEL_EXTRA_DEB="arch/arm/boot/dts/sun7i-a20-cubietruck.dtb"

source ${ARMSTRAP_KERNELS}/.defaults/config.sh

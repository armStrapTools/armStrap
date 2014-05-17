# Theses must always be set for a board configuration
BOARD_CPU="sun4i"
BOARD_CPU_ARCH="arm"
BOARD_CPU_FAMILY="v7l"

BOARD_LOADER="u-boot-sunxi"

BOARD_KERNEL="${BOARD_CPU}"
BOARD_KERNEL_CONFIG="default"
BOARD_KERNEL_MODULES="sw_ahci_platform lcd hdmi ump disp mali mali_drm"
BOARD_KERNEL_DTB="sun4i-a10-hackberry.dtb"

BOARD_ROOTFS="${BOARD_CPU_ARCH}${BOARD_CPU_FAMILY}"
BOARD_ROOTFS_FAMILY="debian"
BOARD_ROOTFS_VERSION="saucy"

# Include the default values last.
source ${ARMSTRAP_BOARDS}/.defaults/sunxi.sh

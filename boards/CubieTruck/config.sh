# Theses must always be set for a board configuration
BOARD_CPU="sun7i-stage"
BOARD_CPU_ARCH="arm"
BOARD_CPU_FAMILLY="v7l"

BOARD_KERNEL="${BOARD_CPU}"
BOARD_KERNEL_CONFIG="default"
BOARD_KERNEL_VERSION="3.4.67+"
BOARD_KERNEL_MODULES="sw_ahci_platform lcd hdmi ump disp mali mali_drm bcmdhd"
BOARD_KERNEL_DTB="sun7i-a20-cubietruck.dtb"

BOARD_ROOTFS="${BOARD_CPU_ARCH}${BOARD_CPU_FAMILLY}"
BOARD_ROOTFS_FAMILLY="debian"
BOARD_ROOTFS_VERSION="stable"

# Include the default values last.
source ${ARMSTRAP_BOARDS}/.defaults/sunxi.sh

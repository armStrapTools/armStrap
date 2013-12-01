# Theses must always be set for a board configuration
BOARD_CPU="sun4i"
BOARD_CPU_ARCH="arm"
BOARD_CPU_FAMILLY="v7l"

BOARD_KERNEL="${BOARD_CPU}"
BOARD_KERNEL_CONFIG="default"
BOARD_KERNEL_VERSION="3.4.67"
BOARD_KERNEL_LOADER="u-boot-sunxi"

BOARD_ROOTFS="${BOARD_CPU_ARCH}${BOARD_CPU_FAMILLY}"
BOARD_ROOTFS_FAMILLY="debian"
BOARD_ROOTFS_VERSION="saucy"

# Theses are overrides from the default board configuration

# Include the default values last.
source ${ARMSTRAP_BOARDS}/.defaults/config.sh

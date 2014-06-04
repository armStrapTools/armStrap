# Theses must always be set for a board configuration
BOARD_CPU="sun7i-ct"
BOARD_CPU_ARCH="arm"
BOARD_CPU_FAMILY="v7l"

BOARD_LOADER="u-boot-sunxi"

BOARD_KERNEL="${BOARD_CPU}"
BOARD_KERNEL_CONFIG="default"
BOARD_KERNEL_MODULES="gpio_sunxi pwm_sunxi sunxi_gmac disp lcd hdmi ump mali sunxi_cedar_mod ap6210"

BOARD_KERNEL_DTB="sun7i-a20-cubietruck.dtb"

BOARD_LOADER_NAND_KERNEL="/boot/bootloader/uImage"

BOARD_ROOTFS="${BOARD_CPU_ARCH}${BOARD_CPU_FAMILY}"
BOARD_ROOTFS_FAMILY="debian"
BOARD_ROOTFS_VERSION="stable"

# Include the default values last.
source ${ARMSTRAP_BOARDS}/.defaults/sunxi.sh

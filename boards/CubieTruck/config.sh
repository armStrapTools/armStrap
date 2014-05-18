# Theses must always be set for a board configuration
BOARD_CPU="sun7i-ct"
BOARD_CPU_ARCH="arm"
BOARD_CPU_FAMILY="v7l"

BOARD_LOADER="u-boot-sunxi"

BOARD_KERNEL="${BOARD_CPU}"
BOARD_KERNEL_CONFIG="default"
#BOARD_KERNEL_MODULES="gpio_sunxi pwm_sunxi sunxi_gmac sw_ahci_platform lcd hdmi ump disp mali mali_drm sunxi_cedar_mod bcmdhd"
BOARD_KERNEL_MODULES="gpio_sunxi pwm_sunxi sunxi_gmac disp lcd hdmi ump mali sunxi_cedar_mod bcmdhd"

BOARD_KERNEL_DTB="sun7i-a20-cubietruck.dtb"

BOARD_ROOTFS="${BOARD_CPU_ARCH}${BOARD_CPU_FAMILY}"
BOARD_ROOTFS_FAMILY="debian"
BOARD_ROOTFS_VERSION="stable"

# Include the default values last.
source ${ARMSTRAP_BOARDS}/.defaults/sunxi.sh

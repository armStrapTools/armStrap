# Theses must always be set for a board configuration
BOARD_CPU="sun7i"
BOARD_CPU_ARCH="arm"
BOARD_CPU_FAMILY="v7l"

BOARD_LOADER="u-boot-sunxi"

BOARD_KERNEL="${BOARD_CPU}"
BOARD_KERNEL_CONFIG="default"
BOARD_KERNEL_MODULES="sw_ahci_platform lcd hdmi ump disp mali mali_drm"
BOARD_KERNEL_DTB="sun7i-a20-cubieboard2.dtb"

BOARD_LOADER_NAND_KERNEL="/boot/bootloader/uImage"

# Include the default values last.
source ${ARMSTRAP_BOARDS}/.defaults/sunxi.sh

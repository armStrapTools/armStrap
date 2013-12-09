
if [ ! -z "${ARMSTRAP_BOARD_KERNEL}" ]; then
  BOARD_KERNEL="${ARMSTRAP_BOARD_KERNEL}"
fi

BOARD_DPKG_LOCALPACKAGES="${ARMSTRAP_BOARDS}/.defaults/sunxi-dpkg/sunxi-tools_1.0-1_armhf.deb ${BOARD_DPKG_LOCALPACKAGES}"
source ${ARMSTRAP_BOARDS}/.defaults/config.sh

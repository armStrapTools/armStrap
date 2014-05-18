
if [ ! -z "${ARMSTRAP_BOARD_KERNEL}" ]; then
  BOARD_KERNEL="${ARMSTRAP_BOARD_KERNEL}"
fi

if [ ! -z "${ARMSTRAP_BOARD_LOADER}" ]; then
  BOARD_LOADER="${ARMSTRAP_BOARD_LOADER}"
fi

BOARD_DPKG_LOCALPACKAGES="${ARMSTRAP_BOARDS}/.defaults/sunxi-dpkg/sunxi-tools_1.0-2_armhf.deb ${BOARD_DPKG_LOCALPACKAGES}"
source ${ARMSTRAP_BOARDS}/.defaults/config.sh

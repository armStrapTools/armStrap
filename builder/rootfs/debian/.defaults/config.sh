if [ -z "${BUILD_ROOTFS_TYPE}" ]; then
  BUILD_ROOTFS_TYPE="debian"
fi

if [ -z "${BUILD_ROOTFS_FAMILLY}" ]; then
  BUILD_ROOTFS_FAMILLY="wheezy"
fi

source "${ARMSTRAP_ROOTFS}/.defaults/config.sh"
  
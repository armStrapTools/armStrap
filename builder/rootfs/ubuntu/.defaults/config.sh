if [ -z "${BUILD_ROOTFS_TYPE}" ]; then
  BUILD_ROOTFS_TYPE="ubuntu"
fi

if [ -z "${BUILD_ROOTFS_FAMILLY}" ]; then
  BUILD_ROOTFS_FAMILLY="saucy"
fi

source "${ARMSTRAP_ROOTFS}/.defaults/config.sh"

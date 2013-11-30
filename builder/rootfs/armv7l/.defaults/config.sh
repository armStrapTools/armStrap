if [ -z "${BUILD_ROOTFS_ARCH}" ]; then
  BUILD_ROOTFS_ARCH="armv7l"
fi

source "${ARMSTRAP_ROOTFS}/.defaults/config.sh"

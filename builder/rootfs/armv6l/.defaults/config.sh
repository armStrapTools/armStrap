if [ -z "${BUILD_ROOTFS_ARCH}" ]; then
  BUILD_ROOTFS_ARCH="armv6l"
fi

source "${ARMSTRAP_ROOTFS}/.defaults/config.sh"

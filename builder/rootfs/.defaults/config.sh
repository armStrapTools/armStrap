if [ -z "${BUILD_ROOTFS_TYPE}" ]; then
  BUILD_ROOTFS_TYPE="debian"
fi

if [ -z "${BUILD_ROOTFS_FAMILLY}" ]; then
  BUILD_ROOTFS_FAMILLY="wheezy"
fi

if [ -z "${BUILD_ROOTFS_URL}" ]; then
  BUILD_ROOTFS_URL="http://armstrap.vls.beaupre.biz/rootfs/${BUILD_ROOTFS_TYPE}-${BUILD_ROOTFS_FAMILLY}-${BUILD_ROOTFS_ARCH}.txz"
fi

if [ -z "${BUILD_ROOTFS_SRC}" ]; then
  BUILD_ROOTFS_SRC="${ARMSTRAP_SRC}/${BUILD_ROOTFS_TYPE}/${BUILD_ROOTFS_FAMILLY}/${BUILD_ROOTFS_ARCH}"
fi

if [ -z "${BUILD_ROOTFS_EXTRACT}" ]; then
  BUILD_ROOTFS_EXTRACT="tar -xJ"
fi

if [ -z "${BUILD_ROOTFS_COMPRESS}" ]; then
  BUILD_ROOTFS_COMPRESS="tar -cJvf"
fi

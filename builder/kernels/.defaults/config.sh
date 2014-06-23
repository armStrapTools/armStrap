if [ -z "${BUILD_KERNEL_ARCH}" ]; then 
  BUILD_KERNEL_ARCH="arm"
fi

if [ -z "${BUILD_KERNEL_EABI}" ]; then 
  BUILD_KERNEL_EABI="hf"
fi

if [ -z "${ARMSTRAP_KERNEL_CONF}" ]; then
  BUILD_KERNEL_CONF="default"
else
  BUILD_KERNEL_CONF="${ARMSTRAP_KERNEL_CONF}"
fi

if [ -z "${BUILD_KERNEL_SOURCE}" ]; then
  BUILD_KERNEL_SOURCE="${ARMSTRAP_SRC}/${BUILD_KERNEL_TYPE}/linux"
fi

if [ -z "${BUILD_KERNEL_CONFIG}" ]; then
  BUILD_KERNEL_CONFIG="${ARMSTRAP_KERNELS}/${BUILD_KERNEL_TYPE}"
fi

if [ -z "${BUILD_KERNEL_GITSRC}" ]; then
  BUILD_KERNEL_GITSRC="https://github.com/linux-sunxi/linux-sunxi.git"
fi

if [ -z "${BUILD_KERNEL_GITBRN}" ]; then
  BUILD_KERNEL_GITBRN=""
fi

if [ -z "${BUILD_KERNEL_CFLAGS}" ]; then
  BUILD_KERNEL_CFLAGS=""
fi

if [ -z "${BUILD_KERNEL_IMAGE}" ]; then
  BUILD_KERNEL_IMAGE="uImage"
fi

if [ -z "${BUILD_KERNEL_MKIMAGE}" ]; then
  BUILD_KERNEL_MKIMAGE=""
fi

if [ -z "${BUILD_KERNEL_PREHOOK}" ]; then
  BUILD_KERNEL_PREHOOK=""
fi

if [ -z "${BUILD_KERNEL_PSTHOOK}" ]; then
  BUILD_KERNEL_PSTHOOK=""
fi

if [ -z "${BUILD_KERNEL_FIRMWARE_SRC}" ]; then
  BUILD_KERNEL_FIRMWARE_SRC=""
fi

if [ -z "${BUILD_KERNEL_FIRMWARE_GIT}" ]; then
  BUILD_KERNEL_FIRMWARE_GIT=""
fi

if [ -z "${BUILD_KERNEL_FIRMWARE_BRN}" ]; then
  BUILD_KERNEL_FIRMWARE_BRN=""
fi

# Usage buildKernel

function buildKernel {
  printStatus "buildKernel" "Starting"
  
  getSources https://github.com/linux-sunxi/linux-sunxi.git ${BUILD_SRC}/linux-sunxi -b sunxi-3.4

  printStatus "buildKernel" "Configuring sun4i_defconfig"
  make -C ${BUILD_SRC}/linux-sunxi ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} distclean >> ${BUILD_LOG_FILE} 2>&1
  make -C ${BUILD_SRC}/linux-sunxi ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} sun4i_defconfig >> ${BUILD_LOG_FILE} 2>&1
  
  if [ -d "${BUILD_ROOT}/boards/${BOARD_CONFIG}/patches" ]; then
    cd ${BUILD_SRC}/linux-sunxi
    for i in ${BUILD_ROOT}/boards/${BOARD_CONFIG}/patches/kernel_*.patch; do  
      printStatus "buildKernel" "Applying patch ${i}"
      patch -p0 < ${i} >> ${BUILD_LOG_FILE} 2>&1
    done
    cd ${BUILD_ROOT}
  fi
  
  printStatus "buildRoot" "Configuring option CONFIG_CMDLINE"
  sed 's/^CONFIG_CMDLINE=.*/CONFIG_CMDLINE="${BOARD_CMDLINE}"/' ${BUILD_SRC}/linux-sunxi/.config > ${BUILD_SRC}/linux-sunxi/.config.tmp
  rm -f ${BUILD_SRC}/linux-sunxi/.config
  mv ${BUILD_SRC}/linux-sunxi/.config.tmp ${BUILD_SRC}/linux-sunxi/.config
  
  printStatus "buildRoot" "Running make menuconfig"
  make --quiet -C ${BUILD_SRC}/linux-sunxi ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} menuconfig
  
  printStatus "buildRoot" "Running make -j${BUILD_THREADS} uImage modules"
  make -C ${BUILD_SRC}/linux-sunxi ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} -j${BUILD_THREADS} uImage modules >> ${BUILD_LOG_FILE} 2>&1

  printStatus "buildRoot" "Running make INSTALL_MOD_PATH=${BUILD_MNT_ROOT} modules_install"
  make -C ${BUILD_SRC}/linux-sunxi ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} INSTALL_MOD_PATH=${BUILD_MNT_ROOT} modules_install >> ${BUILD_LOG_FILE} 2>&1
  
  printStatus "buildRoot" "Installing kerlen to ${BUILD_MNT_BOOT}/uImage"
  cp ${BUILD_SRC}/linux-sunxi/arch/${BUILD_ARCH}/boot/uImage ${BUILD_MNT_BOOT}/
  
  printStatus "buildKernel" "Done"
}

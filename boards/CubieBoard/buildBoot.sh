# Usage: buildBoot

function buildBoot {
  printStatus "buildBoot" "Starting"
  
  getSources https://github.com/linux-sunxi/u-boot-sunxi.git ${BUILD_SRC}/u-boot-sunxi
  getSources https://github.com/linux-sunxi/sunxi-boards.git ${BUILD_SRC}/sunxi-boards
  getSources https://github.com/linux-sunxi/sunxi-tools.git ${BUILD_SRC}/sunxi-tools

  printStatus "Building" "${BUILD_SRC}/sunxi-tools"
  make -C ${BUILD_SRC}/sunxi-tools/ clean >> ${BUILD_LOG_FILE} 2>&1
  make -C ${BUILD_SRC}/sunxi-tools/ >> ${BUILD_LOG_FILE} 2>&1
  
  printStatus "Building" "${BUILD_SRC}/u-boot-sunxi"
  make -C ${BUILD_SRC}/u-boot-sunxi/ distclean ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} >> ${BUILD_LOG_FILE} 2>&1
  make -C ${BUILD_SRC}/u-boot-sunxi/ cubieboard ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} >> ${BUILD_LOG_FILE} 2>&1

  printStatus "Setting up" "/boot/boot.cmd"
  cat > ${BUILD_MNT_ROOT}/boot/boot.cmd <<END
setenv bootargs console=tty0 console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x720p60 root=${BUILD_ROOT_DEV} rootwait panic=10 ${extra}
ext2load mmc 0 0x43000000 boot/script.bin
ext2load mmc 0 0x48000000 boot/uImage
bootm 0x48000000
END

  printStatus "Setting up" "/boot/boot.scr"
  mkimage -C none -A ${BUILD_ARCH} -T script -d ${BUILD_MNT_ROOT}/boot/boot.cmd ${BUILD_MNT_ROOT}/boot/boot.scr >> ${BUILD_LOG_FILE} 2>&1
  
  printStatus "Setting up" "/boot/cubieboard.fex"
  cp ${BUILD_SRC}/sunxi-boards/sys_config/a10/cubieboard.fex ${BUILD_MNT_ROOT}/boot/

  if [ "${BUILD_MAC_ADDRESS}" != "" ]; then
    cat >> ${BUILD_MNT_ROOT}/boot/cubieboard.fex <<END

[dynamic]
MAC = "${BUILD_MAC_ADDRESS}"
END
  fi

  printStatus "Setting up" "/boot/script.bin"
  ${BUILD_SRC}/sunxi-tools/fex2bin ${BUILD_MNT_ROOT}/boot/cubieboard.fex ${BUILD_MNT_ROOT}/boot/script.bin
  
  printStatus "Setting up" "Bootloader"
  if [ -z ${BUILD_DEVICE} ]; then
    dd if=${BUILD_SRC}/u-boot-sunxi/spl/sunxi-spl.bin of=${BUILD_IMAGE_DEVICE} bs=1024 seek=8 >> ${BUILD_LOG_FILE} 2>&1
    dd if=${BUILD_SRC}/u-boot-sunxi/u-boot.bin of=${BUILD_IMAGE_DEVICE} bs=1024 seek=32 >> ${BUILD_LOG_FILE} 2>&1
  else
    dd if=${BUILD_SRC}/u-boot-sunxi/spl/sunxi-spl.bin of=${BUILD_DEVICE} bs=1024 seek=8 >> ${BUILD_LOG_FILE} 2>&1
    dd if=${BUILD_SRC}/u-boot-sunxi/u-boot.bin of=${BUILD_DEVICE} bs=1024 seek=32 >> ${BUILD_LOG_FILE} 2>&1
  fi
  
  printStatus "buildBoot" "Done"
}

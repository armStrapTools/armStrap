
# Usage sunxiMkTools <SUNXI_TOOLS_DIR>
function makeSunxiTools {
  printStatus "makeSunxiTools" "Building ${1}"
  make -C ${1} clean >> ${BUILD_LOG_FILE} 2>&1
  make -C ${1} >> ${BUILD_LOG_FILE} 2>&1
}

# usage sunxiMkUBoot <SUNXI_UBOOT_DIR>
function makeSunxiUBoot {
  printStatus "makeSunxiUBoot" "Building ${1}"
  make -C ${1} ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} distclean >> ${BUILD_LOG_FILE} 2>&1
  make -C ${1} ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} cubieboard >> ${BUILD_LOG_FILE} 2>&1
}

# Usage sunxiMkImage <SRC> <DST>
function sunxiMkImage {
  printStatus "ubootMkImage" "Generating ${2} from ${1}"
  mkimage -C none -A ${BUILD_ARCH} -T script -d ${1} ${2} >> ${BUILD_LOG_FILE} 2>&1
}

# Usage sunxiSetFex <CPUTYPE> <BOARDTYPE>
function sunxiSetFex {
  printStatus "sunxiSetFex" "Configuring for ${2} (${1} CPU)"
  cp ${BUILD_SUNXI_BOARD_DIR}/sys_config/${1}/${2}.fex ${BUILD_MNT_ROOT}/boot/
}

# Usage suxiSetMac <TARGET_FILE> <MAC_ADDRESS>
function sunxiSetMac {
  printStatus "sunxiSetMac" "Configuring board mac address to ${2}"
  printf "\n[dynamic]\nMAC = \"%s\"\n" "${2}" >> ${1}
}

# Usage sunxiFex2Bin <SRC> <DST>
function sunxiFex2Bin {
  printStatus "sunxiFex2Bin" "Generating ${2} from ${1}"
  ${BUILD_SUNXI_TOOLS_DIR}/fex2bin ${1} ${2}
}

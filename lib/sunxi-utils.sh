
# Usage sunxiMkTools <SUNXI_TOOLS_DIR>
function sunxiMkTools {
  printStatus "sunxiMkTools" "Building ${1}"
  make -C ${1} clean >> ${BOARD_LOG_FILE} 2>&1
  make -C ${1} >> ${BOARD_LOG_FILE} 2>&1
}

# usage sunxiMkUBoot <SUNXI_UBOOT_DIR>
function sunxiMkUBoot {
  printStatus "sunxiMkUBoot" "Building ${1}"
  make -C ${1} ARCH=${BOARD_ARCH} CROSS_COMPILE=${BOARD_ARCH_PREFIX} distclean >> ${BOARD_LOG_FILE} 2>&1
  make -C ${1} ARCH=${BOARD_ARCH} CROSS_COMPILE=${BOARD_ARCH_PREFIX} cubieboard >> ${BOARD_LOG_FILE} 2>&1
}

# Usage sunxiMkImage <SRC> <DST>
function sunxiMkImage {
  printStatus "sunxiMkImage" "Generating ${2} from ${1}"
  mkimage -C none -A ${BOARD_ARCH} -T script -d ${1} ${2} >> ${BOARD_LOG_FILE} 2>&1
}

# Usage sunxiSetFex <CPUTYPE> <BOARDTYPE>
function sunxiSetFex {
  printStatus "sunxiSetFex" "Configuring for ${2} (${1} CPU)"
  cp ${BOARD_SUNXI_BOARD_DIR}/sys_config/${1}/${2}.fex ${BOARD_MNT_ROOT}/boot/
}

# Usage suxiSetMac <TARGET_FILE> <MAC_ADDRESS>
function sunxiSetMac {
  printStatus "sunxiSetMac" "Configuring board mac address to ${2}"
  printf "\n[dynamic]\nMAC = \"%s\"\n" "${2}" >> ${1}
}

# Usage sunxiFex2Bin <SRC> <DST>
function sunxiFex2Bin {
  printStatus "sunxiFex2Bin" "Generating ${2} from ${1}"
  ${BOARD_SUNXI_TOOLS_DIR}/fex2bin ${1} ${2}
}

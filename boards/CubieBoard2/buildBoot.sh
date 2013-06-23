# Usage: buildBoot

function buildBoot {
  printStatus "buildBoot" "Starting"

  buildSxTools
  buildUBoot
  buildFex ${BUILD_BOOT_CMD} ${BUILD_BOOT_SCR} ${BUILD_BOOT_FEX} ${BUILD_BOOT_BIN} ${BUILD_MNT_BOOT}
  
  ubootDDLoader "${BUILD_BOOT_SPL}" "${ARMSTRAP_DEVICE}" "${BUILD_BOOT_SPL_SIZE}" "${BUILD_BOOT_SPL_SEEK}"
  ubootDDLoader "${BUILD_BOOT_UBOOT}" "${ARMSTRAP_DEVICE}" "${BUILD_BOOT_UBOOT_SIZE}" "${BUILD_BOOT_UBOOT_SEEK}"
  
  gitExport ${BUILD_UBOOT_DIR} ${BUILD_UBOOT_SRCDST}
  gitExport ${BUILD_SUNXI_BOARD_DIR} ${BUILD_SUNXI_BOARD_SRCDST}
  gitExport ${BUILD_SUNXI_TOOLS_DIR} ${BUILD_SUNXI_TOOLS_SRCDST}
  
  printStatus "buildBoot" "Done"
}

# Usage: buildUBoot [<output directory>]
function buildUBoot {
  printStatus "buildUBoot" "Starting"
  gitSources ${BUILD_UBOOT_GIT} ${BUILD_UBOOT_DIR} ${BUILD_UBOOT_GIT_PARAM}
  sunxiMkUBoot ${BUILD_UBOOT_DIR} ${BUILD_UBOOT_BOARD}
  
  if [ ! -z "${1}" ]; then
    printStatus "buildUBoot" "Copying `basename ${BUILD_BOOT_SPL}` to ${1}"
    cp ${BUILD_BOOT_SPL} ${1}
    printStatus "buildUBoot" "Copying `basename ${BUILD_BOOT_UBOOT}` to ${1}"
    cp ${BUILD_BOOT_UBOOT} ${1}
  fi
  printStatus "buildUBoot" "Done"
}

function buildSxTools {
  printStatus "buildSxTools" "Starting"
  gitSources ${BUILD_SUNXI_TOOLS_GIT} ${BUILD_SUNXI_TOOLS_DIR} ${BUILD_SUNXI_TOOLS_GIT_PARAM}  
  sunxiMkTools ${BUILD_SUNXI_TOOLS_DIR}
  printStatus "buildSxTools" "Done"
}

#Usage: buildFex <boot_cmd> <boot_scr> <fex_src> <fex_bin>
function buildFex {
printStatus "buildFex" "Starting"
  gitSources ${BUILD_SUNXI_BOARD_GIT} ${BUILD_SUNXI_BOARD_DIR} ${BUILD_SUNXI_BOARD_GIT_PARAM}

  ubootSetEnv "${1}" "bootargs" "${BUILD_CONFIG_CMDLINE}"
  ubootSetEnv "${1}" "machid" "0xf35"
  ubootExt2Load "${1}" "${BUILD_BOOT_BIN_LOAD}"
  ubootExt2Load "${1}" "${BUILD_BOOT_KERNEL_LOAD}"
  ubootBootM "${1}" "${BUILD_BOOT_KERNEL_ADDR}"

  sunxiMkImage ${1} ${2}
  
  if [ -f "${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/fex/${BUILD_SUNXI_BOARD_FEX}.fex" ]; then
    cp ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/fex/${BUILD_SUNXI_BOARD_FEX}.fex "`dirname ${3}`/"
  else
    sunxiSetFex ${BUILD_SUNXI_BOARD_DIR} "${BUILD_SUNXI_BOARD_CPU}" "${BUILD_SUNXI_BOARD_FEX}" "`dirname ${3}`/"
  fi
  
  if [ ! -z "${ARMSTRAP_MAC_ADDRESS}" ]; then
    sunxiSetMac "${3}" "${ARMSTRAP_MAC_ADDRESS}"
  fi
  
  sunxiFex2Bin ${BUILD_SUNXI_TOOLS_DIR} ${3} ${4}

  printStatus "buildFex" "Done"
}

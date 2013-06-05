
# Usage buildKernel <TARGET DIRECTORY>
function buildKernel {
  printStatus "buildKernel" "Starting"
  
  gitSources ${BUILD_KERNEL_GIT} ${BUILD_KERNEL_DIR} ${BUILD_KERNEL_GIT_PARAM}

  configKernel "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}" "${BUILD_BOARD_KERNEL}"
  
  patchKernel "${BUILD_KERNEL_DIR}"

  editConfig "${BUILD_KERNEL_CNF}" "CONFIG_CMDLINE" "${BUILD_CONFIG_CMDLINE}"

  menuConfig "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}"
  
  kernelVersion "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}"

  makeKernel "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}" "${BUILD_KERNEL_NAME} modules"

  makeKernel "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}" "INSTALL_MOD_PATH=${1} modules_install"
  
  installKernel "${BUILD_ARCH}" "${BUILD_KERNEL_DIR}" "${BUILD_KERNEL_NAME}" "${1}/boot"
  
  gitExport "${BUILD_KERNEL_DIR}" "${1}/usr/src"
  
  fixSymLink "build" "${1}/lib/modules/${ARMSTRAP_KERNEL_VERSION}/" "../../../usr/src/linux-sunxi/"
  fixSymLink "source" "${1}/lib/modules/${ARMSTRAP_KERNEL_VERSION}/" "../../../usr/src/linux-sunxi/"
  
  printStatus "buildKernel" "Done"
}

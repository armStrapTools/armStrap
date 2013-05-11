
# usage editConfig <KERNEL_CONFIG_FILE> <PARAMETER> <VALUE>
function editConfig {
  local TMP_SED=`mktemp sedscript.XXXXXX`
  local TMP_CNF_MOD=`mktemp .config.XXXXXX`
  local TMP_CNF="${1}"
  local TMP_PRM="${2}"
  shift
  shift

  printStatus "editConfig" "Configuring parameter ${TMP_PRM} to ${@}"
  printf "s#^${TMP_PRM}=.*#${TMP_PRM}=\"%s\"#\n" "${@}" > ${TMP_SED}
  sed -f ${TMP_SED} ${BUILD_SRC}/linux-sunxi/.config > ${TMP_CNF_MOD}
  rm -f ${TMP_SED}
  rm -f ${TMP_CNF}
  mv ${TMP_CNF_MOD} ${TMP_CNF}
}

# usage patchKernel <KERNEL_DIRECTORY>
function patchKernel {
  if [ -d "${BUILD_ROOT}/boards/${BOARD_CONFIG}/patches" ]; then
    cd ${1}
    for i in ${BUILD_ROOT}/boards/${BOARD_CONFIG}/patches/kernel_*.patch; do
      printStatus "patchKernel" "Applying patch ${i}"
      patch -p0 < ${i} >> ${BUILD_LOG_FILE} 2>&1
    done
    cd ${BUILD_ROOT}
  fi
}

# usage configKernel <KERNEL_DIRECTORY> <BOARD_DEFCONFIG>
function configKernel {
  printStatus "configKernel" "Configuring ${1} for ${2}"
  make -C ${1} ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} distclean >> ${BUILD_LOG_FILE} 2>&1
  make -C ${1} ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} ${2} >> ${BUILD_LOG_FILE} 2>&1
}

# usage menuConfig <KERNEL_DIRECTORY>
function menuConfig {
  printStatus "menuConfig" "Running make menuconfig"
  make --quiet -C ${1} ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} menuconfig
}

# usage makeKernel <KERNEL_DIRECTORY> <MODULE1> [<MODULE2> ... ]
function makeKernel {
  local TMP_DIR="${1}"
  shift
  printStatus "makeKernel" "Running make ${@}"
  make -C ${TMP_DIR} ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} -j${BUILD_THREADS} ${@} >> ${BUILD_LOG_FILE} 2>&1
}

# usage installKernel <KERNEL_DIRECTORY> <KERNEL_FILE> <TARGET_DIRECTORY
function installKernel {
  printStatus "installKernel" "Installing ${2} to ${3}"
  checkDirectory ${3}
  cp ${1}/arch/${BUILD_ARCH}/boot/${2} ${3}/
}

# usage kernelVersion
function kernelVersion {
  BUILD_KERNEL_VERSION=`make --quiet -C ${1} ARCH=${BUILD_ARCH} CROSS_COMPILE=${BUILD_ARCH_PREFIX} kernelrelease`
  printStatus "kernelVersion" "Linux Kernel version is ${BUILD_KERNEL_VERSION}"
}

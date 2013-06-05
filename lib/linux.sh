
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
  sed -f ${TMP_SED} ${ARMSTRAP_SRC}/linux-sunxi/.config > ${TMP_CNF_MOD}
  rm -f ${TMP_SED}
  rm -f ${TMP_CNF}
  mv ${TMP_CNF_MOD} ${TMP_CNF}
}

# usage patchKernel <KERNEL_DIRECTORY>
function patchKernel {
  if [ -d "${ARMSTRAP_ROOT}/boards/${ARMSTRAP_CONFIG}/patches" ]; then
    cd ${1}
    for i in ${ARMSTRAP_ROOT}/boards/${ARMSTRAP_CONFIG}/patches/kernel_*.patch; do
      printStatus "patchKernel" "Applying patch ${i}"
      patch -p0 < ${i} >> ${ARMSTRAP_LOG_FILE} 2>&1
    done
    cd ${ARMSTRAP_ROOT}
  fi
}

# usage configKernel <ARCH> <COMP_PREFIX> <KERNEL_DIRECTORY> <BOARD_DEFCONFIG>
function configKernel {
  printStatus "configKernel" "Configuring ${3} for ${4}"
  make -C ${3} ARCH=${1} CROSS_COMPILE=${2} distclean >> ${ARMSTRAP_LOG_FILE} 2>&1
  make -C ${3} ARCH=${1} CROSS_COMPILE=${2} ${4} >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# usage menuConfig <ARCH> <COMP_PREFIX> <KERNEL_DIRECTORY>
function menuConfig {
  printStatus "menuConfig" "Running make menuconfig"
  make --quiet -C ${3} ARCH=${1} CROSS_COMPILE=${2} menuconfig
}

# usage makeKernel <ARCH> <COMP_PREFIX> <KERNEL_DIRECTORY> <MODULE1> [<MODULE2> ... ]
function makeKernel {
  local TMP_ARCH=${1}
  local TMP_PRFX=${2}
  local TMP_DIR="${3}"
  shift
  shift
  shift
  
  printStatus "makeKernel" "Running make ${@}"
  make -C ${TMP_DIR} ARCH=${TMP_ARCH} CROSS_COMPILE=${TMP_PRFX} -j${ARMSTRAP_THREADS} ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# usage installKernel <ARCH> <KERNEL_DIRECTORY> <KERNEL_FILE> <TARGET_DIRECTORY
function installKernel {
  printStatus "installKernel" "Installing ${3} to ${4}"
  checkDirectory ${4}
  cp ${2}/arch/${1}/boot/${3} ${4}/
}

# usage kernelVersion <ARCH> <COMP_PREFIX> <KERNEL_DIRECTORY>
function kernelVersion {
  ARMSTRAP_KERNEL_VERSION=`make --quiet -C ${3} ARCH=${1} CROSS_COMPILE=${2} kernelrelease`
  printStatus "kernelVersion" "Linux Kernel version is ${ARMSTRAP_KERNEL_VERSION}"
}

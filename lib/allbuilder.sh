function allBuilder {

  printStatus "armStrap" "Build Everything"
  TMP_ROOTFS_LIST=""
  TMP_UBOOT_LIST=""
  
  rm -f "${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}*.log"
  mv "${ARMSTRAP_LOG_FILE}" "${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}.log"
  ARMSTRAP_LOG_FILE="${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}.log"
  
  rm -f ${ARMSTRAP_PKG}/*
  
  #
  # First, update all the avalable rootFS
  #

  printStatus "allBuilder" "----------------------------------------"
  printStatus "allBuilder" "- Stage 1 - Updating rootFS"
  printStatus "allBuilder" "----------------------------------------"

  for i in $(boardConfigs); do
    ARMSTRAP_CONFIG="${i}"
    ARMSTRAP_BOARD_CONFIG="${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}"
    resetEnv
    source ${ARMSTRAP_BOARD_CONFIG}/config.sh
    loadLibrary "${ARMSTRAP_BOARD_CONFIG}" ${BUILD_INIT_SCRIPTS}
    
    printStatus "allBuilder" "Searching for rootFS in ${ARMSTRAP_CONFIG}"
    
    for k in ${BUILD_ARMBIAN_ROOTFS_LIST}; do
      if [[ ${TMP_ROOTFS_LIST} != *!${k}!* ]]; then
        TMP_ROOTFS_LIST="${TMP_ROOTFS_LIST} !${k}!"
        ARMSTRAP_OS="${k}"
        resetEnv
        source ${ARMSTRAP_BOARD_CONFIG}/config.sh
        loadLibrary "${ARMSTRAP_BOARD_CONFIG}" ${BUILD_INIT_SCRIPTS}
        local TMP_LOG_ROOT="${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}_RootFS-${k}.log"
        local TMP_LOG_FILE="${ARMSTRAP_LOG_FILE}"
        printStatus "allBuilder" "Logging to ${TMP_LOG_ROOT}"
        touch "${TMP_LOG_ROOT}"
        ARMSTRAP_LOG_FILE="${TMP_LOG_ROOT}"
        rBuilder
        ARMSTRAP_LOG_FILE="${TMP_LOG_FILE}"
      else
        printStatus "allBuilder" "----------------------------------------"
        printStatus "allBuilder" "rootFS ${k} is up to date."
        printStatus "allBuilder" "----------------------------------------"
      fi
    done
  done
  
  printStatus "allBuilder" "----------------------------------------"
  printStatus "allBuilder" "- Stage 2 - Updating BootLoaders"
  printStatus "allBuilder" "----------------------------------------"
  
  for i in $(boardConfigs); do
    ARMSTRAP_CONFIG="${i}"
    ARMSTRAP_BOARD_CONFIG="${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}"
    resetEnv
    source ${ARMSTRAP_BOARD_CONFIG}/config.sh
    loadLibrary "${ARMSTRAP_BOARD_CONFIG}" ${BUILD_INIT_SCRIPTS}
    
    isTrue "${BUILD_UBUILDER}"
    if [ $? -ne 0 ]; then
      if [[ ${TMP_UBOOT_LIST} != *!${i}!* ]]; then
        TMP_UBOOT_LIST="${TMP_UBOOT_LIST} !${i}!"
        local TMP_LOG_BOOT="${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}_BootLoader-${i}.log"
        local TMP_LOG_FILE="${ARMSTRAP_LOG_FILE}"
        printStatus "allBuilder" "Logging to ${TMP_LOG_BOOT}"
        touch "${TMP_LOG_BOOT}"
        ARMSTRAP_LOG_FILE="${TMP_LOG_BOOT}"
        uBuilder
        ARMSTRAP_LOG_FILE="${TMP_LOG_FILE}"
      else
        printStatus "allBuilder" "----------------------------------------"
        printStatus "allBuilder" "- BootLoader for ${ARMSTRAP_CONFIG} is up to date"
        printStatus "allBuilder" "----------------------------------------"
      fi
    fi
  done

  printStatus "allBuilder" "----------------------------------------"
  printStatus "allBuilder" "- Stage 3 - Kernels"
  printStatus "allBuilder" "----------------------------------------"

  for i in $(boardConfigs); do
    ARMSTRAP_CONFIG="${i}"
    ARMSTRAP_BOARD_CONFIG="${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}"
    
    printStatus "allBuilder" "Searching for Kernel in ${ARMSTRAP_CONFIG}"
    
    if [ -d "${ARMSTRAP_BOARD_CONFIG}/kernel/" ]; then
      for j in `echo ${ARMSTRAP_BOARD_CONFIG}/kernel/*_defconfig`; do
        ARMSTRAP_KBUILDER_VERSION=""
        ARMSTRAP_KBUILDER_CONF="`echo ${j} | cut -d- -f2 | cut -d_ -f1`"
        local TMP_LOG_KRNL="${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}_Kernel-${ARMSTRAP_CONFIG}-${ARMSTRAP_KBUILDER_CONF}.log"
        local TMP_LOG_FILE="${ARMSTRAP_LOG_FILE}"
        printStatus "allBuilder" "Logging to ${TMP_LOG_KRNL}"
        touch "${TMP_LOG_KRNL}"
        ARMSTRAP_LOG_FILE="${TMP_LOG_KRNL}"
        resetEnv
        source ${ARMSTRAP_BOARD_CONFIG}/config.sh
        loadLibrary "${ARMSTRAP_BOARD_CONFIG}" ${BUILD_INIT_SCRIPTS}
        kBuilder
        ARMSTRAP_LOG_FILE="${TMP_LOG_FILE}"
      done
    else
      for k in ${ARMSTRAP_BOARD_CONFIG}/kernel*; do
        for j in ${k}/*_defconfig; do
          TMP_KERNEL="`basename ${k}`"
          TMP_CONFIG="`basename ${j}`"
          ARMSTRAP_KBUILDER_VERSION="`echo ${TMP_KERNEL} | cut -d- -f2`"
          ARMSTRAP_KBUILDER_CONF="`echo ${TMP_CONFIG} | cut -d- -f2 | cut -d_ -f1`"
          local TMP_LOG_KRNL="${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}_Kernel-${ARMSTRAP_KBUILDER_VERSION}-${ARMSTRAP_CONFIG}-${ARMSTRAP_KBUILDER_CONF}.log"
          printStatus "allBuilder" "Logging to ${TMP_LOG_KRNL}"
          touch "${TMP_LOG_KRNL}"
          ARMSTRAP_LOG_FILE="${TMP_LOG_KRNL}"
          resetEnv
          source ${ARMSTRAP_BOARD_CONFIG}/config.sh
          loadLibrary "${ARMSTRAP_BOARD_CONFIG}" ${BUILD_INIT_SCRIPTS}
          kBuilder
          ARMSTRAP_LOG_FILE="${TMP_LOG_FILE}"
        done
      done
    fi
  done
  
  if [ -x "${ARMSTRAP_ABUILDER_HOOK}" ]; then
    printStatus "allBuilder" "Executing post hook script ${ARMSTRAP_ABUILDER_HOOK}"
    "${ARMSTRAP_ABUILDER_HOOK}" "${ARMSTRAP_PKG}" "${ARMSTRAP_LOG}/armStrap_Builder-${ARMSTRAP_DATE}"
  fi
  
  printStatus "allBuilder" "All done"
}

function kBuilder {
  local TMP_KRNDIR="${ARMSTRAP_KERNELS}/${1}"
  local TMP_LOG="${ARMSTRAP_LOG}/armStrap-Kernel_${1}_${ARMSTRAP_DATE}.log"
  if [ -f "${TMP_KRNDIR}/config.sh" ]; then
    printStatus "kBuilder" "Kernel Builder"
    source ${TMP_KRNDIR}/config.sh
    rm -f ${TMP_LOG}
    mv ${ARMSTRAP_LOG_FILE} ${TMP_LOG}
    ARMSTRAP_LOG_FILE="${TMP_LOG}"
    gitClone "${BUILD_KERNEL_SOURCE}" "${BUILD_KERNEL_GITSRC}" "${BUILD_KERNEL_GITBRN}"
    kernelBuilder "${BUILD_KERNEL_SOURCE}" "${TMP_KRNDIR}" "${BUILD_KERNEL_TYPE}" "${BUILD_KERNEL_ARCH}" "${BUILD_KERNEL_EABI}" "${BUILD_KERNEL_CONF}" "${BUILD_KERNEL_CFLAGS}" "${BUILD_KERNEL_PREHOOK}" "${BUILD_KERNEL_PSTHOOK}"
    unsetEnv "BUILD_KERNEL_"
    printStatus "kBuilder" "Kernel Builder Done"
  else
    printStatus "kBuilder" "Kernel Builder is not avalable for ${1}"
  fi
}

# Usage bBuilder <bootloader_type> <bootloader_familly>
function bBuilder {
  local TMP_BLRDIR="${ARMSTRAP_BOOTLOADERS}/${1}"
  local TMP_BLRCFG="${TMP_BLRDIR}/${2}"
  local TMP_LOG="${ARMSTRAP_LOG}/armStrap-BootLoader_${1}-${2}_${ARMSTRAP_DATE}.log"
  if [ -f "${TMP_BLRCFG}/config.sh" ]; then
    BUILD_BOOTLOADER_TYPE="${1}"
    printStatus "bBuilder" "Loading configuration for ${1} (${2})"
    source ${TMP_BLRCFG}/config.sh
    rm -f ${TMP_LOG}
    mv ${ARMSTRAP_LOG_FILE} ${TMP_LOG}
    ARMSTRAP_LOG_FILE="${TMP_LOG}"
    case ${BUILD_BOOTLOADER_TYPE} in
      "u-boot-sunxi") printStatus "bBuilder" "Updating ${BUILD_BOOTLOADER_TYPE} for ${BUILD_BOOTLOADER_FAMILLY}"
                      gitClone "${BUILD_BOOTLOADER_SOURCE}" "${BUILD_BOOTLOADER_GITSRC}" "${BUILD_BOOTLOADER_GITBRN}"
                      gitClone "${BUILD_BOOTLOADER_FEXSRC}" "${BUILD_BOOTLOADER_FEXGIT}" "${BUILD_BOOTLOADER_FEXBRN}"
                      printStatus "bBuilder" "Cleaning ${BUILD_BOOTLOADER_TYPE}"
                      kernelMake "${BUILD_BOOTLOADER_ARCH}" "${BUILD_BOOTLOADER_EABI}" "${BUILD_BOOTLOADER_SOURCE}" "${BUILD_BOOTLOADER_CFLAGS}" distclean
                      printStatus "bBuilder" "Building ${BUILD_BOOTLOADER_TYPE}"
                      kernelMake "${BUILD_BOOTLOADER_ARCH}" "${BUILD_BOOTLOADER_EABI}" "${BUILD_BOOTLOADER_SOURCE}" "${BUILD_BOOTLOADER_CFLAGS}" "${BUILD_BOOTLOADER_FAMILLY}"
                      checkDirectory "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_FAMILLY}"
                      printStatus "bBuilder" "Packaging ${BUILD_BOOTLOADER_TYPE}"
                      cp -v "${BUILD_BOOTLOADER_SOURCE}/u-boot-sunxi-with-spl.bin" "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_FAMILLY}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      cp -v "${BUILD_BOOTLOADER_FEXSRC}/sys_config/${BUILD_BOOTLOADER_CPU}/${BUILD_BOOTLOADER_FEX}" "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_FAMILLY}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      ${BUILD_BOORLOADER_COMPRESS} "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_FAMILLY}.txz" -C "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_FAMILLY}" --one-file-system . >> ${ARMSTRAP_LOG_FILE} 2>&1
                      rm -rf "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_FAMILLY}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      unsetEnv "BUILD_BOOTLOADER_"
                      printStatus "bBuilder" "Builder done."
                      ;;
                   *) printStatus "Builder is not avalable for ${1}"
                      ;;
    esac
  unsetEnv "BUILD_BOOTLOADER_"
  else
    printStatus "Builder is not avalable for ${1}"
  fi
}

function rBuilder {
  local TMP_ROOTFS="`basename ${BUILD_ARMBIAN_ROOTFS}`"
  local TMP_ROOTFS="${TMP_ROOTFS%.txz}"
  
  printStatus "rBuilder" "----------------------------------------"
  printStatus "rBuilder" "- Updating rootFS ${TMP_ROOTFS}"
  printStatus "rBuilder" "----------------------------------------"

  if [ ! -d "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" ]; then
    printStatus "rBuilder" "Creating work directory ${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
    checkDirectory "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
  else
    printStatus "rBuilder" "Cleaning work directory ${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
    rm -rf "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
    checkDirectory "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
  fi
  
  httpExtract "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "${BUILD_ARMBIAN_ROOTFS}" "${BUILD_ARMBIAN_EXTRACT}"

  shellRun "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "apt-get -q -y update && apt-get -q -y dist-upgrade"
  
  printStatus "rBuilder" "Compressing root filesystem ${TMP_ROOTFS} to ${ARMSTRAP_PKG}"
  rm -f "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz"
  ${BUILD_ARMBIAN_COMPRESS} "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz" -C "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" --one-file-system ./ >> ${ARMSTRAP_LOG_FILE} 2>&1
  printStatus "rBuilder" "rootFS Updater Done"
}


function rMount {
  local TMP_ROOTFS="`basename ${BUILD_ARMBIAN_ROOTFS}`"
  local TMP_ROOTFS="${TMP_ROOTFS%.txz}"
  
  printStatus "rMount" "----------------------------------------"
  printStatus "rMount" "- Entering rootFS ${TMP_ROOTFS}"
  printStatus "rMount" "----------------------------------------"

  if [ ! -d "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" ]; then
    printStatus "rMount" "Creating work directory ${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
    checkDirectory "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
  else
    printStatus "rMount" "Cleaning work directory ${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
    rm -rf "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
    checkDirectory "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
  fi
  
  if [ -f "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz" ]; then
    printStatus "rMount" "Using local copy found in ${ARMSTRAP_PKG}"
    pkgExtract "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz" "${BUILD_ARMBIAN_EXTRACT}"
  else
    httpExtract "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" "${BUILD_ARMBIAN_ROOTFS}" "${BUILD_ARMBIAN_EXTRACT}"
  fi

  shellRun "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}"
  
  printStatus "rMount" "Compressing root filesystem ${TMP_ROOTFS} to ${ARMSTRAP_PKG}"
  rm -f "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz"
  ${BUILD_ARMBIAN_COMPRESS} "${ARMSTRAP_PKG}/${TMP_ROOTFS}.txz" -C "${ARMSTRAP_SRC}/rootfs/${TMP_ROOTFS}" --one-file-system ./ >> ${ARMSTRAP_LOG_FILE} 2>&1
  printStatus "rMount" "rootFS mount Done"
}

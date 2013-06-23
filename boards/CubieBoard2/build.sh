
# installOS is called once everything is mounted and ready. 

function installOS {

  local TMP_KERNEL_IMG="${ARMSTRAP_WRK}/`basename ${BUILD_KERNEL_DIR}`"
  local TMP_KERNEL_SRC="${ARMSTRAP_WRK}/`basename ${BUILD_KERNEL_DIR}`-sources"
  local TMP_KERNEL_HDR="${ARMSTRAP_WRK}/`basename ${BUILD_KERNEL_DIR}`-headers"

  if [ -z "${ARMSTRAP_KERNEL_BUILDER}${ARMSTRAP_BOOT_BUILDER}" ]; then
    if [ ! -z "${ARMSTRAP_KERNEL_COMPILE}" ]; then
      buildKernel
      exportKrnlImg ${TMP_KERNEL_IMG} ${BUILD_KERNEL_INSTIMG}
      exportKrnlSrc ${TMP_KERNEL_SRC} ${BUILD_KERNEL_INSTSRC}
      exportKrnlHdr ${TMP_KERNEL_HDR} ${BUILD_KERNEL_INSTHDR}
    else
      if [ ! -z "${BUILD_KERNEL_INSTIMG}" ]; then
        printStatus "installOS" "Using included `basename ${BUILD_KERNEL_DEB_IMG}`"
        BUILD_DPKG_LOCALPACKAGES="${BUILD_DPKG_LOCALPACKAGES} ${BUILD_KERNEL_DEB_IMG}"
      fi
            
      if [ ! -z "${BUILD_KERNEL_INSTHDR}" ]; then
        printStatus "installOS" "Using included `basename ${BUILD_KERNEL_DEB_HDR}`"
        BUILD_DPKG_LOCALPACKAGES="${BUILD_DPKG_LOCALPACKAGES} ${BUILD_KERNEL_DEB_HDR}"
      fi
      
      if [ ! -z "${BUILD_KERNEL_INSTSRC}" ]; then
        printStatus "installOS" "Using included `basename ${BUILD_KERNEL_DEB_SRC}`"
        BUILD_DPKG_LOCALPACKAGES="${BUILD_DPKG_LOCALPACKAGES} ${BUILD_KERNEL_DEB_SRC}"
      fi
    fi
    case ${ARMSTRAP_OS} in
      [dD]*)
        buildDebian
        ;;
      [uU]*)
        buildUbuntu
        ;;
      *)
        buildDebian
        ;;
    esac

    buildBoot
  else
    if [ ! -z "${ARMSTRAP_KERNEL_BUILDER}" ]; then
      printStatus "installOS" "Kernel Builder Starting"
      buildKernel
      exportKrnlImg ${TMP_KERNEL_IMG} ${BUILD_KERNEL_INSTIMG}
      exportKrnlSrc ${TMP_KERNEL_SRC} ${BUILD_KERNEL_INSTSRC}
      exportKrnlHdr ${TMP_KERNEL_HDR} ${BUILD_KERNEL_INSTHDR}
      printStatus "installOS" "Kernel Builder Done"
    fi
    
    if [ ! -z "${ARMSTRAP_BOOT_BUILDER}" ]; then
      local TMP_WRK="${ARMSTRAP_WRK}/uBoot"
      local TMP_CMD="${TMP_WRK}/`basename ${BUILD_BOOT_CMD}`"
      local TMP_SCR="${TMP_WRK}/`basename ${BUILD_BOOT_SCR}`"
      local TMP_FEX="${TMP_WRK}/`basename ${BUILD_BOOT_FEX}`"
      local TMP_BIN="${TMP_WRK}/`basename ${BUILD_BOOT_BIN}`"
      printStatus "installOS" "uBoot Builder Starting"
      buildSxTools
      checkDirectory ${ARMSTRAP_WRK}/uBoot
      buildUBoot ${ARMSTRAP_WRK}/uBoot
      buildFex ${TMP_CMD} ${TMP_SCR} ${TMP_FEX} ${TMP_BIN} ${TMP_WRK}
      printStatus "installOS" "uBoot Builder Done"
    fi  
  fi
}

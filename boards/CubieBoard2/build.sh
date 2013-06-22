
# installOS is called once everything is mounted and ready. 

function installOS {

  local TMP_KERNEL_IMG="${ARMSTRAP_WRK}/`basename ${BUILD_KERNEL_DIR}`"
  local TMP_KERNEL_SRC="${ARMSTRAP_WRK}/`basename ${BUILD_KERNEL_DIR}`-sources"
  local TMP_KERNEL_HDR="${ARMSTRAP_WRK}/`basename ${BUILD_KERNEL_DIR}`-headers"

  if [ -z "${ARMSTRAP_KERNEL_BUILDER}${ARMSTRAP_BOOT_BUILDER}" ]; then
    buildKernel
    exportKrnlImg ${TMP_KERNEL_IMG} ${BUILD_KERNEL_INSTIMG}
    exportKrnlSrc ${TMP_KERNEL_SRC} ${BUILD_KERNEL_INSTSRC}
    exportKrnlHdr ${TMP_KERNEL_HDR} ${BUILD_KERNEL_INSTHDR}
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
      printStatus "installOS" "uBoot Builder Starting"
      buildSxTools
      checkDirectory ${ARMSTRAP_WRK}/uBoot
      buildUBoot ${ARMSTRAP_WRK}/uBoot
      buildFex  ${ARMSTRAP_WRK}/uBoot/`basename ${BUILD_BOOT_CMD}`  ${ARMSTRAP_WRK}/uBoot/`basename ${BUILD_BOOT_SCR}` ${ARMSTRAP_WRK}/uBoot/`basename ${BUILD_BOOT_FEX}` ${ARMSTRAP_WRK}/uBoot/`basename ${BUILD_BOOT_UBOOT}`
      printStatus "installOS" "uBoot Builder Done"
    fi  
  fi
}

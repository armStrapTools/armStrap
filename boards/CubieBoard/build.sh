
# installOS is called once everything is mounted and ready. 

function installOS {

  kernelPackager

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
}

# Usage kernelPackager
function kernelPackager {
  local TMP_KERNEL_IMG="${ARMSTRAP_WRK}/`basename ${BUILD_KERNEL_DIR}`"
  local TMP_KERNEL_SRC="${ARMSTRAP_WRK}/`basename ${BUILD_KERNEL_DIR}`-sources"
  local TMP_KERNEL_HDR="${ARMSTRAP_WRK}/`basename ${BUILD_KERNEL_DIR}`-headers"

  buildKernel
  exportKrnlImg ${TMP_KERNEL_IMG} ${BUILD_KERNEL_INSTIMG}
  exportKrnlSrc ${TMP_KERNEL_SRC} ${BUILD_KERNEL_INSTSRC}
  exportKrnlHdr ${TMP_KERNEL_HDR} ${BUILD_KERNEL_INSTHDR}
}

# Usage: buildRoot
function buildRoot {
  printStatus "buildRoot" "Starting"

  bootStrap ${BUILD_ARCH} ${BUILD_ARCH_EABI} ${BUILD_DEBIAN_SUITE}

  setHostName ${BOARD_HOSTNAME}
  
  clearSourcesList
  addSource ${BUILD_DEBIAN_SOURCE} "${BUILD_DEBIAN_SUITE}" ${BUILD_DEBIAN_SOURCE_COMPONENTS}
  addSource ${BUILD_DEBIAN_SOURCE} "${BUILD_DEBIAN_SUITE}-updates" ${BUILD_DEBIAN_SOURCE_COMPONENTS}
  addSource ${BUILD_DEBIAN_SOURCE_SECURITY} "${BUILD_DEBIAN_SUITE}/updates" ${BUILD_DEBIAN_SOURCE_SECURITY_COMPONENTS}
  initSources
  
  if [ -n "${BUILD_DEBIAN_EXTRAPACKAGES}" ]; then
    if [ -n "${BOARD_SWAP}" ]; then
      installPackages "${BUILD_DEBIAN_EXTRAPACKAGES} dphys-swapfile"
      printf "CONF_SWAPSIZE=%s" ${BOARD_SWAP_SIZE} > ${BUILD_MNT_ROOT}/etc/dphys-swapfile
    else
      installPackages "${BUILD_DEBIAN_EXTRAPACKAGES}"
    fi
  fi

  configPackages ${BUILD_DEBIAN_RECONFIG}

  setRootPassword ${BOARD_PASSWORD}
  
  addInitTab "${BUILD_SERIALCON_ID}" "${BUILD_SERIALCON_RUNLEVEL}" "${BUILD_SERIALCON_TERM}" "${BUILD_SERIALCON_SPEED}" "${BUILD_SERIALCON_TYPE}"

  initFSTab
  addFSTab "${BUILD_FSTAB_ROOTDEV}" "${BUILD_FSTAB_ROOTMNT}" "${BUILD_FSTAB_ROOTFST}" "${BUILD_FSTAB_ROOTOPT}" "${UILD_FSTAB_ROOTDMP}" "${BUILD_FSTAB_ROOTPSS}"

  for i in ${BUILD_KERNEL_MODULES}; do
    addKernelModule ${i}
  done

  #addKernelModule "sw_ahci_platform" "#For SATA Support"
  #addKernelModule "lcd" "#Display and GPU"
  #addKernelModule "hdmi"
  #addKernelModule "ump"
  #addKernelModule "disp"
  #addKernelModule "mali"
  #addKernelModule "mali_drm"
  
  addIface "eth0" "${BOARD_ETH0_MODE}" "${BOARD_ETH0_IP}" "${BOARD_ETH0_MASK}" "${BOARD_ETH0_GW}"
  
  if [ "${BOARD_ETH0_MODE}" != "dhcp" ]; then
    initResolvConf
    addSearchDomain "${BOARD_DOMAIN}"
    addNameServer "${BOARD_DNS}"
  fi
  
  bootClean ${BUILD_ARCH}
  
  printStatus "buildRoot" "Done"

}

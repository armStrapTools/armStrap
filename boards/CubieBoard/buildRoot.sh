# Usage: buildRoot
function buildRoot {
  printStatus "buildRoot" "Starting"

  bootStrap ${BUILD_ARCH} ${BUILD_ARCH_EABI} ${BUILD_DEB_SUITE}

  setHostName ${BOARD_HOSTNAME}
  
  clearSourcesList
  addSource "http://ftp.debian.org/debian" "${BUILD_DEB_SUITE}" "main" "contrib" "non-free"
  addSource "http://ftp.debian.org/debian/" "${BUILD_DEB_SUITE}-updates" "main" "contrib" "non-free"
  addSource "http://security.debian.org/" "${BUILD_DEB_SUITE}/updates" "main" "contrib" "non-free"
  initSources
  
  if [ -n "${BUILD_DEB_EXTRAPACKAGES}" ]; then
    if [ -n "${BOARD_SWAP}" ]; then
      installPackages "${BUILD_DEB_EXTRAPACKAGES} dphys-swapfile"
      printf "CONF_SWAPSIZE=%s" ${BOARD_SWAP_SIZE} > ${BUILD_MNT_ROOT}/etc/dphys-swapfile
    else
      installPackages "${BUILD_DEB_EXTRAPACKAGES}"
    fi
  fi

  configPackages ${BUILD_DEB_RECONFIG}

  setRootPassword ${BOARD_PASSWORD}
  
  addInitTab "T0" "2345" "ttyS0" "115200" "vt100"

  initFSTab
  addFSTab "/dev/root" "/" "ext4" "defaults" "0" "1"

  addKernelModule "sw_ahci_platform" "#For SATA Support"
  addKernelModule "lcd" "#Display and GPU"
  addKernelModule "hdmi"
  addKernelModule "ump"
  addKernelModule "disp"
  addKernelModule "mali"
  addKernelModule "mali_drm"
  
  addIface "eth0" "${BOARD_ETH0_MODE}" "${BOARD_ETH0_IP}" "${BOARD_ETH0_MASK}" "${BOARD_ETH0_GW}"
  
  if [ "${BOARD_ETH0_MODE}" != "dhcp" ]; then
    initResolvConf
    addSearchDomain "${BOARD_DOMAIN}"
    addNameServer "${BOARD_DNS}"
  fi
  
  bootClean ${BUILD_ARCH}
  
  printStatus "buildRoot" "Done"

}

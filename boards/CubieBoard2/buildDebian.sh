# Usage: buildRoot
function buildDebian {
  printStatus "buildDebian" "Starting"

  bootStrap "${BUILD_MNT_ROOT}" "${BUILD_ARCH}" "${BUILD_ARCH_EABI}" "${BUILD_DEBIAN_SUITE}"
  
  setHostName "${BUILD_MNT_ROOT}" "${ARMSTRAP_HOSTNAME}"
  
  clearSourcesList "${BUILD_MNT_ROOT}"
  addSource "${BUILD_MNT_ROOT}" "${BUILD_DEBIAN_SOURCE}" "${BUILD_DEBIAN_SUITE}" ${BUILD_DEBIAN_SOURCE_COMPONENTS}
  addSource "${BUILD_MNT_ROOT}" "${BUILD_DEBIAN_SOURCE}" "${BUILD_DEBIAN_SUITE}-updates" ${BUILD_DEBIAN_SOURCE_COMPONENTS}
  addSource "${BUILD_MNT_ROOT}" "${BUILD_DEBIAN_SOURCE_SECURITY}" "${BUILD_DEBIAN_SUITE}/updates" ${BUILD_DEBIAN_SOURCE_SECURITY_COMPONENTS}

  initSources "${BUILD_MNT_ROOT}"
  
  installTasks "${BUILD_MNT_ROOT}" "${BUILD_DEBIAN_TASKS}"
  
  if [ -n "${BUILD_DPKG_EXTRAPACKAGES}" ]; then
    if [ -n "${ARMSTRAP_SWAP}" ]; then
      installPackages "${BUILD_MNT_ROOT}" "${BUILD_DPKG_EXTRAPACKAGES} dphys-swapfile"
      printf "CONF_SWAPSIZE=%s" "${ARMSTRAP_SWAP_SIZE}" > "${BUILD_MNT_ROOT}/etc/dphys-swapfile"
    else
      installPackages "${BUILD_MNT_ROOT}" "${BUILD_DPKG_EXTRAPACKAGES}"
    fi
  fi

  configPackages "${BUILD_MNT_ROOT}" "${BUILD_DEBIAN_RECONFIG}"
  
  BUILD_DPKG_LOCALPACKAGES="`find ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/dpkg/*.deb -maxdepth 1 -type f -print0 | xargs -0 echo` ${BUILD_DPKG_LOCALPACKAGES}"

  if [ ! -z "${BUILD_DPKG_LOCALPACKAGES}" ]; then
    for i in ${BUILD_DPKG_LOCALPACKAGES}; do
      installDPKG "${BUILD_MNT_ROOT}" ${i}
    done
  fi

  setRootPassword "${BUILD_MNT_ROOT}" "${ARMSTRAP_PASSWORD}"
  
  addInitTab "${BUILD_MNT_ROOT}" "${BUILD_SERIALCON_ID}" "${BUILD_SERIALCON_RUNLEVEL}" "${BUILD_SERIALCON_TERM}" "${BUILD_SERIALCON_SPEED}" "${BUILD_SERIALCON_TYPE}"

  initFSTab "${BUILD_MNT_ROOT}" 
  addFSTab "${BUILD_MNT_ROOT}" "${BUILD_FSTAB_ROOTDEV}" "${BUILD_FSTAB_ROOTMNT}" "${BUILD_FSTAB_ROOTFST}" "${BUILD_FSTAB_ROOTOPT}" "${UILD_FSTAB_ROOTDMP}" "${BUILD_FSTAB_ROOTPSS}"

  for i in "${BUILD_KERNEL_MODULES}"; do
    addKernelModule "${BUILD_MNT_ROOT}" "${i}"
  done

  addIface "${BUILD_MNT_ROOT}" "eth0" "${ARMSTRAP_ETH0_MODE}" "${ARMSTRAP_ETH0_IP}" "${ARMSTRAP_ETH0_MASK}" "${ARMSTRAP_ETH0_GW}"
  
  if [ "${ARMSTRAP_ETH0_MODE}" != "dhcp" ]; then
    initResolvConf "${BUILD_MNT_ROOT}" 
    addSearchDomain "${BUILD_MNT_ROOT}" "${ARMSTRAP_ETH0_DOMAIN}"
    addNameServer "${BUILD_MNT_ROOT}" "${ARMSTRAP_ETH0_DNS}"
  fi
  
  bootClean "${BUILD_MNT_ROOT}" "${BUILD_ARCH}"
  
  printStatus "buildDebian" "Done"

}

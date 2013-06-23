# Usage: buildUbuntu
function buildUbuntu {
  printStatus "buildUbuntu" "Starting"

  ubuntuStrap "${BUILD_MNT_ROOT}" "${BUILD_ARCH}" "${BUILD_ARCH_EABI}" "${BUILD_UBUNTU_VERSION}"
  
  #divertServices "${BUILD_MNT_ROOT}"
  
  insResolver "${BUILD_MNT_ROOT}"
  
  unComment "${BUILD_MNT_ROOT}/etc/apt/sources.list" "deb"
    
  setHostName "${BUILD_MNT_ROOT}" "${ARMSTRAP_HOSTNAME}"
  
  initSources "${BUILD_MNT_ROOT}"
  
  insDialog "${BUILD_MNT_ROOT}"
  
  ubuntuLocales "${BUILD_MNT_ROOT}" ${BUILD_UBUNTU_LOCALES}
  
  if [ -n "${BUILD_DPKG_EXTRAPACKAGES}" ]; then
    if [ -n "${ARMSTRAP_SWAP}" ]; then
      installPackages "${BUILD_MNT_ROOT}" tasksel ${BUILD_UBUNTU_TASKS} ${BUILD_DPKG_EXTRAPACKAGES} dphys-swapfile
      printf "CONF_SWAPSIZE=%s" "${ARMSTRAP_SWAP_SIZE}" > "${BUILD_MNT_ROOT}/etc/dphys-swapfile"
    else
      installPackages "${BUILD_MNT_ROOT}" tasksel ${BUILD_UBUNTU_TASKS} ${BUILD_DPKG_EXTRAPACKAGES}
    fi
  fi

  configPackages "${BUILD_MNT_ROOT}" "${BUILD_UBUNTU_RECONFIG}"
  
  BUILD_DPKG_LOCALPACKAGES="`find ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/dpkg/*.deb -maxdepth 1 -type f -print0 | xargs -0 echo` ${BUILD_DPKG_LOCALPACKAGES}"

  if [ ! -z "${BUILD_DPKG_LOCALPACKAGES}" ]; then
    for i in ${BUILD_DPKG_LOCALPACKAGES}; do
      installDPKG "${BUILD_MNT_ROOT}" ${i}
    done
  fi

  setRootPassword "${BUILD_MNT_ROOT}" "${ARMSTRAP_PASSWORD}"
  
  addTTY "${BUILD_MNT_ROOT}" "${BUILD_SERIALCON_RUNLEVEL}" "${BUILD_SERIALCON_TERM}" "${BUILD_SERIALCON_SPEED}" "${BUILD_SERIALCON_TYPE}"

  initFSTab "${BUILD_MNT_ROOT}" 
  addFSTab "${BUILD_MNT_ROOT}" "${BUILD_FSTAB_ROOTDEV}" "${BUILD_FSTAB_ROOTMNT}" "${BUILD_FSTAB_ROOTFST}" "${BUILD_FSTAB_ROOTOPT}" "${UILD_FSTAB_ROOTDMP}" "${BUILD_FSTAB_ROOTPSS}"

  for i in "${BUILD_KERNEL_MODULES}"; do
    addKernelModule "${BUILD_MNT_ROOT}" "${i}"
  done

  addIface "${BUILD_MNT_ROOT}" "eth0" "${ARMSTRAP_ETH0_MODE}" "${ARMSTRAP_ETH0_IP}" "${ARMSTRAP_ETH0_MASK}" "${ARMSTRAP_ETH0_GW}"
  
  installInit "${BUILD_MNT_ROOT}"

  #undivertServices "${BUILD_MNT_ROOT}"

  bootClean "${BUILD_MNT_ROOT}" "${BUILD_ARCH}"
  
  clnResolver "${BUILD_MNT_ROOT}"
  
  if [ "${ARMSTRAP_ETH0_MODE}" != "dhcp" ]; then
    initResolvConf "${BUILD_MNT_ROOT}" 
    addSearchDomain "${BUILD_MNT_ROOT}" "${ARMSTRAP_ETH0_DOMAIN}"
    addNameServer "${BUILD_MNT_ROOT}" "${ARMSTRAP_ETH0_DNS}"
  fi
  
  printStatus "buildUbuntu" "Done"
}

# Usage: buildOS
function buildOS {

  BUILD_LC_ALL="" 
  BUILD_LANGUAGE="en_US:en" 
  BUILD_LANG="en_US.UTF-8"
  
  BUILD_ARMBIAN_ROOTFS="http://armstrap.vls.beaupre.biz/rootfs/ubuntu-13.04-armv7l-hf.txz"
  BUILD_ARMBIAN_EXTRACT="tar -xJ"
  BUILD_ARMBIAN_KERNEL="http://armstrap.vls.beaupre.biz/kernel/cubieboard/install-cubieboard-kernel-desktop.sh"
  
  httpExtract "${BUILD_MNT_ROOT}" "${BUILD_ARMBIAN_ROOTFS}" "${BUILD_ARMBIAN_EXTRACT}"
  
  setHostName "${BUILD_MNT_ROOT}" "${ARMSTRAP_HOSTNAME}"
  
  chrootUpgrade "${BUILD_MNT_ROOT}"
  
  if [ -n "${BUILD_DPKG_EXTRAPACKAGES}" ]; then
    chrootInstall "${BUILD_MNT_ROOT}" "${BUILD_DPKG_EXTRAPACKAGES}"
  fi
  
  if [ -n "${ARMSTRAP_SWAP}" ]; then
    printf "CONF_SWAPSIZE=%s" "${ARMSTRAP_SWAP_SIZE}" > "${BUILD_MNT_ROOT}/etc/dphys-swapfile"
  else
    printf "CONF_SWAPSIZE=0" > "${BUILD_MNT_ROOT}/etc/dphys-swapfile"
  fi

  chrootReconfig "${BUILD_MNT_ROOT}" "${BUILD_UBUNTU_RECONFIG}"
  
  BUILD_DPKG_LOCALPACKAGES="`find ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/dpkg/*.deb -maxdepth 1 -type f -print0 | xargs -0 echo` ${BUILD_DPKG_LOCALPACKAGES}"

  if [ ! -z "${BUILD_DPKG_LOCALPACKAGES}" ]; then
    for i in ${BUILD_DPKG_LOCALPACKAGES}; do
      chrootDPKG "${BUILD_MNT_ROOT}" ${i}
    done
  fi

  setRootPassword "${BUILD_MNT_ROOT}" "${ARMSTRAP_PASSWORD}"
  
  addTTY "${BUILD_MNT_ROOT}" "${BUILD_SERIALCON_ID}" "${BUILD_SERIALCON_RUNLEVEL}" "${BUILD_SERIALCON_TERM}" "${BUILD_SERIALCON_SPEED}" "${BUILD_SERIALCON_TYPE}"

  initFSTab "${BUILD_MNT_ROOT}" 
  addFSTab "${BUILD_MNT_ROOT}" "${BUILD_FSTAB_ROOTDEV}" "${BUILD_FSTAB_ROOTMNT}" "${BUILD_FSTAB_ROOTFST}" "${BUILD_FSTAB_ROOTOPT}" "${UILD_FSTAB_ROOTDMP}" "${BUILD_FSTAB_ROOTPSS}"

  for i in "${BUILD_KERNEL_MODULES}"; do
    addKernelModule "${BUILD_MNT_ROOT}" "${i}"
  done

  addIface "${BUILD_MNT_ROOT}" "eth0" "${ARMSTRAP_ETH0_MODE}" "${ARMSTRAP_ETH0_IP}" "${ARMSTRAP_ETH0_MASK}" "${ARMSTRAP_ETH0_GW}" "${ARMSTRAP_ETH0_DOMAIN}" "${ARMSTRAP_ETH0_DNS}"
  
  installLinux "${BUILD_MNT_ROOT}" "${BUILD_ARMBIAN_KERNEL}"
}

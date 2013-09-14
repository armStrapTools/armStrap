# Usage installQEMU <ARMSTRAP_ROOT>
function installQEMU {
  if [ ! -f "${1}/usr/bin/qemu-arm-static" ]; then
    printStatus "installQEMU" "Installing QEMU Arm Emulator in `basename ${1}`."
    cp "/usr/bin/qemu-arm-static" "${1}/usr/bin" >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
}

# Usage removeQEMU <ARMSTRAP_ROOT> <ARCH>
function removeQEMU {
  if [ -f "${1}/usr/bin/qemu-arm-static" ]; then
    printStatus "RemoveQEMU" "Removing QEMU Arm Emulator from `basename ${1}`."
    rm -f "${1}/usr/bin/qemu-arm-static" >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
}

# Usage : disableServices <ARMSTRAP_ROOT>
function disableServices {
  if [ ! -f "${1}/usr/sbin/policy-rc.d.lock" ]; then
  
    printStatus "disableServices" "Disabling services startup in `basename ${1}`."

    touch "${1}/usr/sbin/policy-rc.d.lock" >> ${ARMSTRAP_LOG_FILE} 2>&1

    if [ -f "${1}/usr/sbin/policy-rc.d" ]; then
      mv  "${1}/usr/sbin/policy-rc.d" "${1}/usr/sbin/policy-rc.d.disabled" >> ${ARMSTRAP_LOG_FILE} 2>&1
    fi
  
    printf "#!/bin/sh\nexit 101\n" > "${1}/usr/sbin/policy-rc.d"
    chmod +x "${1}/usr/sbin/policy-rc.d" >> ${ARMSTRAP_LOG_FILE} 2>&1

  fi
}

# Usage : enableServices <ARMSTRAP_ROOT>
function enableServices {
  if [ -f "${1}/usr/sbin/policy-rc.d.lock" ]; then
    printStatus "enableServices" "Enabling services startup in `basename ${1}`."
    rm -f "${1}/usr/sbin/policy-rc.d" >> ${ARMSTRAP_LOG_FILE} 2>&1
  
    if [ -f "${1}/usr/sbin/policy-rc.d.disabled" ]; then
      mv  "${1}/usr/sbin/policy-rc.d.disabled" "${1}/usr/sbin/policy-rc.d" >> ${ARMSTRAP_LOG_FILE} 2>&1
    fi
    
    rm -f "${1}/usr/sbin/policy-rc.d.lock" >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
}

# usage httpExtract <DESTINATION> <FILE_URL> <EXTRACTOR_CMD>
function httpExtract {
  local TMP_DIR="${1}"
  local TMP_URL="${2}"
  shift
  shift
  
  printStatus "bootStrap" "Fetching and extracting `basename ${TMP_URL}`"
  checkDirectory "${TMP_DIR}/"
  wget -q -O - "${TMP_URL}" | ${@} -C "${TMP_DIR}/"
  checkStatus "Error while downloading/extracting ${TMP_URL}"
}

function chrootRun {
  local TMP_CHROOT=${1}
  shift

  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootRun" "Executing '${@}' in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot "${TMP_CHROOT}" ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}

function chrootShell {
  local TMP_CHROOT=${1}
  local TMP_SHELL="${1}/armstrap.shell"
  
  printf "#!/bin/sh\n\ndebian_chroot=\"${TMP_CHROOT}\" /bin/bash\n" >> "${TMP_SHELL}"
  
  chmod +x "${TMP_SHELL}"
  
  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootRun" "Executing '/bin/bash' in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot "${TMP_CHROOT}" ${@}
  
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
  
  rm -f "${TMP_SHELL}"
}

function chrootUpgrade {
  local TMP_CHROOT=${1}
  shift

  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootUpgrade" "Updating packages in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y update ${@} 2>> ${ARMSTRAP_LOG_FILE}
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y dist-upgrade ${@} 2>> ${ARMSTRAP_LOG_FILE}
    
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}

function chrootInstall {
  local TMP_CHROOT=${1}
  shift
  
  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootInstall" "Installing packages in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true install ${@} 2>> ${ARMSTRAP_LOG_FILE}
    
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}

# Usage : chrootDPKG <ARMSTRAP_ROOT> <PACKAGE_FILE>
function chrootDPKG {
  local TMP_CHROOT=${1}
  local TMP_DIR=`mktemp -d ${TMP_CHROOT}/DPKG.XXXXXX`
  local TMP_CHR=`basename ${TMP_DIR}`
  local TMP_DEB=`basename ${2}`
  
  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootDPKG" "Installing package ${TMP_DEB} in `basename ${TMP_CHROOT}`"
  cp ${2} ${TMP_DIR}/${TMP_DEB}
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/dpkg -i /${TMP_CHR}/${TMP_DEB} >> ${ARMSTRAP_LOG_FILE} 2>&1
  rm -rf ${TMP_DIR}
    
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}

# Usage : chrootReconfig <ARMSTRAP_ROOT> <PKG1> [<PKG2> ...]
function chrootReconfig {
  local TMP_CHROOT=${1}
  shift

  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootReconfig" "Reconfiguring packages ${@} in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/sbin/dpkg-reconfigure ${@}
    
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}

# Usage : chrootPassword <ARMSTRAP_ROOT> <ROOT_PASSWORD>
function chrootPassword {
  local TMP_CHROOT=${1}

  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootReconfig" "Configuring root password in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/passwd root <<EOF > /dev/null 2>&1
${2}
${2}

EOF
    
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}

function chrootKernel {
  local TMP_CHROOT="${1}"
  local TMP_KERNEL="`basename ${2}`"

  printStatus "chrootKernel" "Downloading ${TMP_KERNEL} script to `basename ${TMP_CHROOT}`"
  wget --append-output="${ARMSTRAP_LOG_FILE}" --directory-prefix="${TMP_CHROOT}/" "${2}"

  chmod +x "${TMP_CHROOT}/${TMP_KERNEL}"
  
  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootKernel" "Executing ${TMP_KERNEL} script in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /${TMP_KERNEL} "--logstderr" 2>> ${ARMSTRAP_LOG_FILE}
  
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"

  rm -f "${TMP_CHROOT}/${TMP_KERNEL}"
}

function chrootLocales {
  local TMP_CHROOT="${1}"
  local TMP_LANG="${2}"
  shift
  shift
  
  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootLocales" "Adding locale ${TMP_LANG} to avalable locales"
  
  for i in ${TMP_LANG} ${@}; do
    local TMP_LC="`echo "${i}" | cut -d "." -f 2`"
    local TMP_FN="`echo "${i}" | cut -d "_" -f 1`"

    if [ -d "${TMP_CHROOT}/var/lib/locales/supported.d" ]; then
      # For Ubuntu
      echo "${i} ${TMP_LC}" >> ${TMP_CHROOT}/var/lib/locales/supported.d/local
      echo "${i} ${TMP_LC}" >> ${TMP_CHROOT}/var/lib/locales/supported.d/${TMP_FN}
    else
      # For Debian
      echo "${i} ${TMP_LC}" >> ${TMP_CHROOT}/etc/locale.gen
    fi
    
  done
  
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/sbin/locale-gen >> ${ARMSTRAP_LOG_FILE} 2>&1
  LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/sbin/update-locale LANG=${TMP_LANG} >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}

function chrootTimeZone {
  local TMP_CHROOT="${1}"
  local TMP_TZ="${2}"
  shift
  shift
  
  if [ -f "${TMP_CHROOT}/usr/share/zoneinfo/${TMP_TZ}" ]; then  
    disableServices "${TMP_CHROOT}"
    installQEMU "${TMP_CHROOT}"
    mountPFS "${TMP_CHROOT}"

    printStatus "chrootTimeZone" "Setting timezone to ${TMP_TZ}"
    LC_ALL="" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ ln -sf /usr/share/zoneinfo/${TMP_TZ} /etc/localtime >> ${ARMSTRAP_LOG_FILE} 2>&1
    echo "${TMP_TZ}" > ${TMP_CHROOT}/etc/timezone
  
    umountPFS "${TMP_CHROOT}"
    removeQEMU "${TMP_CHROOT}"
    enableServices "${TMP_CHROOT}"
  else
    printStatus "chrootTimeZone" "WARNING: Invalid timezone ${TMP_TZ}"
  fi
}

# Usage : setHostName <ARMSTRAP_ROOT> <HOSTNAME>
function setHostName {
  printStatus "buildRoot" "Configuring /etc/hostname"
  echo "${2}" > ${1}/etc/hostname
}

# Usage : mountPFS <ARMSTRAP_ROOT>
function mountPFS {
  TMP_ISPROC="`mount -l | grep "${1}" | grep '/proc'`"
  TMP_ISSYS="`mount -l | grep "${1}" | grep '/sys'`"
  TMP_ISDEV="`mount -l | grep "${1}" | grep '/dev/pts'`"

  if [ -z "${TMP_ISPROC}" ]; then
    printStatus "mountFPS" "Mounting /proc in `basename ${1}`."
    mount --bind /proc "${1}/proc" >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi

  if [ -z "${TMP_ISSYS}" ]; then
    printStatus "mountFPS" "Mounting /sys in `basename ${1}`."
    mount --bind /sys "${1}/sys" >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi

  if [ -z "${TMP_ISDEV}" ]; then
    printStatus "mountFPS" "Mounting /dev/pts in `basename ${1}`."
    mount --bind /dev/pts "${1}/dev/pts" >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
}

function umountPFS {
  TMP_ISPROC="`mount -l | grep "${1}" | grep '/proc'`"
  TMP_ISSYS="`mount -l | grep "${1}" | grep '/sys'`"
  TMP_ISDEV="`mount -l | grep "${1}" | grep '/dev/pts'`"
  
  if [ ! -z "${TMP_ISPROC}" ]; then
    printStatus "umountFPS" "UnMounting /dev/pts in `basename ${1}`."
    umount "${1}/dev/pts" >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi

  if [ ! -z "${TMP_ISSYS}" ]; then
    printStatus "umountFPS" "UnMounting /sys in `basename ${1}`."
    umount "${1}/sys" >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
  
  if [ ! -z "${TMP_ISDEV}" ]; then
    printStatus "umountFPS" "UnMounting /proc in `basename ${1}`."
    umount "${1}/proc" >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
} 

# Usage : umountPFS <ARMSTRAP_ROOT>
function umountPFS {
  printStatus "umountPFS" "Unmounting pseudo-filesystems from `basename ${1}`"
  umount ${1}/dev/pts >> ${ARMSTRAP_LOG_FILE} 2>&1
  umount ${1}/sys >> ${ARMSTRAP_LOG_FILE} 2>&1
  umount ${1}/proc >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage addTT <ARMSTRAP_ROOT> <ID> <RUNLEVELS> <DEVICE> <SPEED> <TYPE>
function addTTY {
  if [ -f "${1}/etc/inittab" ]; then
    printStatus "addInitTab" "Configuring terminal ${2} for runlevels ${3} on device ${4} at ${5}bps (${6})"
    printf "%s:%s:respawn:/sbin/getty -L %s %s %s\n" ${2} ${3} ${4} ${5} ${6} >> ${1}/etc/inittab
  else
    local TMP_FILE="${1}/etc/init/${4}.conf"
    printStatus "addTTY" "Configuring terminal ${4} for runlevels ${3} at ${5} (${6})"
    printf "# %s - getty\n" "${4}" > ${TMP_FILE}
    printf "# This service maintains a getty on ttyS0 from the point the system is started until it is shut down again.\n\n" >> ${TMP_FILE} 
    printf "start on stopped rc or RUNLEVEL=[%s]\n" "${3}" >> ${TMP_FILE} 
    printf "stop on runlevel [!2345]\n\n" >> ${TMP_FILE} 
    printf "respawn\nexec /sbin/getty -L %s %s %s\n" "${5}" "${4}" "${6}" >> ${TMP_FILE} 
  fi
}

# Usage : initFSTab <ARMSTRAP_ROOT>
function initFSTab {
  printStatus "initFSTab" "Initializing fstab"
  printf "%- 20s % -15s %- 10s %- 15s %- 8s %- 8s\n" "#<file system>" "<mount point>" "<type>" "<options>" "<dump>" "<pass>" > ${1}/etc/fstab
}

# Usage : addFSTab <ARMSTRAP_ROOT> <file system> <mount point> <type> <options> <dump> <pass>
function addFSTab {
  local TMP_ROOT="${1}"
  shift
  
  local TMP_I=""
  
  for TMP_I in "$@"; do
    local TMP_ARR=(${TMP_I//:/ })  
    printStatus "addFSTab" "Device ${TMP_ARR[0]} will be mount as ${TMP_ARR[1]}"
    printf "%- 20s % -15s %- 10s %- 15s %- 8s %- 8s\n" ${TMP_ARR[0]} ${TMP_ARR[1]} ${TMP_ARR[2]} ${TMP_ARR[3]} ${TMP_ARR[4]} ${TMP_ARR[5]} >>${TMP_ROOT}/etc/fstab
  done
}

# Usage : addKernelModules <ARMSTRAP_ROOT> <KERNEL MODULE> [<COMMENT>]
function addKernelModule {
  local TMP_ROOT=${1}
  shift
  local TMP_MODULE=${1}
  shift
  
  printStatus "addModule" "Configuring kernel module ${1}"
  if [ ! -z "${@}" ]; then
    shift
    echo "# ${@}" >> ${TMP_ROOT}/etc/modules
  fi
  
  printf "%s\n" ${TMP_MODULE} >> ${TMP_ROOT}/etc/modules
}

# Usage : addIface <ARMSTRAP_ROOT> <INTERFACE> <MAC_ADDRESS> <dhcp|static> [<address> <netmask> <gateway>]
function addIface {
  local TMP_ROOT="${1}"
  local TMP_INTF="${2}"
  local TMP_MACA="${3}"
  local TMP_DHCP="${4}"
  local TMP_ADDR="${5}"
  local TMP_MASK="${6}"
  local TMP_GWAY="${7}"
  local TMP_DOMN="${8}"
  shift
  shift
  shift
  shift
  shift
  shift
  shift
  
  printStatus "addIface" "Configuring interface ${TMP_INTF}"
  printf "auto %s\n" ${TMP_INTF} >> ${TMP_ROOT}/etc/network/interfaces
  printf "allow-hotplug %s\n\n" ${TMP_INTF} >> ${TMP_ROOT}/etc/network/interfaces
  printf "iface %s inet %s\n" ${TMP_INTF} ${TMP_DHCP} >> ${TMP_ROOT}/etc/network/interfaces
  if [ "${TMP_DHCP}" != "dhcp" ]; then
    printStatus "addIface" "IP address : ${TMP_ADDR}/${TMP_MASK}, default gateway ${TMP_GWAY}"
    printf "  address %s\n" "${TMP_ADDR}" >> ${TMP_ROOT}/etc/network/interfaces
    printf "  netmask %s\n" "${TMP_MASK}" >> ${TMP_ROOT}/etc/network/interfaces
    printf "  gateway %s\n" "${TMP_GWAY}" >> ${TMP_ROOT}/etc/network/interfaces
    if [ ! -z "${@}" ]; then
      printf "  dns-nameserver %s" "${@}" >> ${TMP_ROOT}/etc/network/interfaces
    fi
    if [ ! -z "${6}" ]; then
      printf "  dns-search %s" "${TMP_DOMN}" >> ${TMP_ROOT}/etc/network/interfaces
    fi
  else
    printStatus "addIface" "IP address : DHCP"
  fi  
  
  if [ ! -z "${TMP_MACA}" ]; then
    printf "hwaddress ether %s:%s:%s:%s:%s:%s\n\n" "${TMP_MACA:0:2}" "${TMP_MACA:2:2}" "${TMP_MACA:4:2}" "${TMP_MACA:6:2}" "${TMP_MACA:8:2}" "${TMP_MACA:10:2}" >> ${TMP_ROOT}/etc/network/interfaces
  fi
}

function trapError {
  local TMP_DIR="$1"
  
  printStatus "trapError" "Something went wrong. Exiting."
  
  umountPFS "${TMP_DIR}"
  removeQEMU "${TMP_DIR}"
  enableServices "${TMP_DIR}"

  exit
}

function shellRun {
  local TMP_DIR="$1"
  shift

  disableServices "${TMP_DIR}"
  installQEMU "${TMP_DIR}"
  mountPFS "${TMP_DIR}"

  if [ ! -z "${1}" ]; then
    printStatus "shellRun" "About to execute '${1}' in `basename ${TMP_DIR}`."
    echo "${@}" > "${TMP_DIR}/armstrap-run.sh"
    chmod +x "${TMP_DIR}/armstrap-run.sh"
    trap "trapError ${TMP_DIR}" INT TERM EXIT
      debian_chroot="${ANF_RED}`basename ${TMP_DIR}`${ANF_DEF}" LC_ALL="" LANGUAGE="en_US:en" LANG="en_US.UTF-8" chroot "${TMP_DIR}" /bin/bash --login -c /armstrap-run.sh  >> ${ARMSTRAP_LOG_FILE} 2>&1
    trap - INT TERM EXIT
    rm -f "${TMP_DIR}/armstrap-run.sh"
  else
    printStatus "shellRun" "Entering `basename ${TMP_DIR}`."
    trap "trapError ${TMP_DIR}" INT TERM EXIT
      debian_chroot="${ANF_RED}`basename ${TMP_DIR}`${ANF_DEF}" LC_ALL="" LANGUAGE="en_US:en" LANG="en_US.UTF-8" chroot "${TMP_DIR}" /bin/bash --login
    trap - INT TERM EXIT
  fi
  printStatus "shellRun" "Exiting from `basename ${TMP_DIR}`."
  
  umountPFS "${TMP_DIR}"
  removeQEMU "${TMP_DIR}"
  enableServices "${TMP_DIR}"
}

function makeUBoot {

  printStatus "ubootBuilder" "----------------------------------------"
  printStatus "ubootBuilder" "- Board : ${2}"
  printStatus "ubootBuilder" "----------------------------------------"
  
  gitClone "${BUILD_UBUILDER_SOURCE}" "${BUILD_UBUILDER_GITSRC}" "${BUILD_UBUILDER_GITBRN}"
  
  printStatus "makeUBoot" "Compiling U-Boot for ${2}"
  make -C "${1}" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean >> ${ARMSTRAP_LOG_FILE} 2>&1  
  make -C "${1}" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- ${2} >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  checkDirectory "${3}/${2}"
  
  printStatus "makeUBoot" "Copying u-boot-sunxi-with-spl.bin to ${3}/${2}"
  cp "${1}/u-boot-sunxi-with-spl.bin" "${3}/${2}"
}


#usage makeFEXC <BUILD_TBUILDER_SOURCE> <BUILD_BOARD>
function makeFEXC {
  printStatus "makeSTools" "Compiling `basename ${1}` for ${2}"
  make -C "${1}" clean >> ${ARMSTRAP_LOG_FILE} 2>&1  
  make -C "${1}" fexc >> ${ARMSTRAP_LOG_FILE} 2>&1
}

#usage fex2bin <BUILD_TBUILDER_SOURCE> <src_fex> <dst_bin>
function fex2bin {
  printStatus "fex2bin" "Compilling `basename ${3}`"
  ${1}/fexc -v -I fex -O bin ${2} ${3} >> ${ARMSTRAP_LOG_FILE} 2>&1
}

function makeFex {
  gitClone "${BUILD_SBUILDER_SOURCE}" "${BUILD_SBUILDER_GITSRC}" "${BUILD_SBUILDER_GITBRN}"
  printStatus "makeFex" "Copying `basename ${1}` for ${2}"
  checkDirectory "${3}/${2}"
  cp "${1}" "${3}/${2}"
}

# Usage : default_installRoot
function default_installRoot {
  httpExtract "${BUILD_MNT_ROOT}" "${BUILD_ARMBIAN_ROOTFS}" "${BUILD_ARMBIAN_EXTRACT}"

  chrootLocales "${BUILD_MNT_ROOT}" "${BUILD_LANG}" "${BUILD_LANG_EXTRA}"
  chrootTimeZone "${BUILD_MNT_ROOT}" "${BUILD_TIMEZONE}"
  
  setHostName "${BUILD_MNT_ROOT}" "${ARMSTRAP_HOSTNAME}"
  
  chrootUpgrade "${BUILD_MNT_ROOT}"
  
  if [ -n "${BUILD_DPKG_EXTRAPACKAGES}" ]; then
    chrootInstall "${BUILD_MNT_ROOT}" "${BUILD_DPKG_EXTRAPACKAGES}"
  fi
  
  isTrue "${ARMSTRAP_SWAP}"  
  if [ $? -ne 0 ]; then
    printf "CONF_SWAPSIZE=%s" "${ARMSTRAP_SWAP_SIZE}" > "${BUILD_MNT_ROOT}/etc/dphys-swapfile"
  else
    printf "CONF_SWAPSIZE=0" > "${BUILD_MNT_ROOT}/etc/dphys-swapfile"
  fi

  if [ ! -z "${BUILD_ARMBIAN_RECONFIG}" ]; then
    chrootReconfig "${BUILD_MNT_ROOT}" "${BUILD_ARMBIAN_RECONFIG}"
  fi

  if [ -d "${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/dpkg" ]; then
    BUILD_DPKG_LOCALPACKAGES="`find ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/dpkg/*.deb -maxdepth 1 -type f -print0 | xargs -0 echo` ${BUILD_DPKG_LOCALPACKAGES}"
  fi

  if [ ! -z "${BUILD_DPKG_LOCALPACKAGES}" ]; then
    for i in ${BUILD_DPKG_LOCALPACKAGES}; do
      chrootDPKG "${BUILD_MNT_ROOT}" ${i}
    done
  fi

  chrootPassword "${BUILD_MNT_ROOT}" "${ARMSTRAP_PASSWORD}"
  
  addTTY "${BUILD_MNT_ROOT}" "${BUILD_SERIALCON_ID}" "${BUILD_SERIALCON_RUNLEVEL}" "${BUILD_SERIALCON_TERM}" "${BUILD_SERIALCON_SPEED}" "${BUILD_SERIALCON_TYPE}"

  initFSTab "${BUILD_MNT_ROOT}" 
  addFSTab "${BUILD_MNT_ROOT}" ${BUILD_FSTAB[@]}
  #"${BUILD_FSTAB_ROOTDEV}" "${BUILD_FSTAB_ROOTMNT}" "${BUILD_FSTAB_ROOTFST}" "${BUILD_FSTAB_ROOTOPT}" "${BUILD_FSTAB_ROOTDMP}" "${BUILD_FSTAB_ROOTPSS}"

  for i in "${BUILD_KERNEL_MODULES}"; do
    addKernelModule "${BUILD_MNT_ROOT}" "${i}"
  done

  addIface "${BUILD_MNT_ROOT}" "eth0" "${ARMSTRAP_MAC_ADDRESS}" "${ARMSTRAP_ETH0_MODE}" "${ARMSTRAP_ETH0_IP}" "${ARMSTRAP_ETH0_MASK}" "${ARMSTRAP_ETH0_GW}" "${ARMSTRAP_ETH0_DOMAIN}" "${ARMSTRAP_ETH0_DNS}"
  
}

# usage : default_installBoot
function default_installBoot {
  httpExtract "${BUILD_MNT_ROOT}/boot" "${BUILD_ARMBIAN_UBOOT}" "${BUILD_ARMBIAN_EXTRACT}"
  
  rm -f "${BUILD_BOOT_CMD}"
  touch "${BUILD_BOOT_CMD}"

  for i in "${BUILD_UBUILDER_BOOTCMD[@]}"; do
    local TMP_KND=""
    local TMP_VST=""
    local TMP_POS=$(echo `expr index "$i" =`)
    if [ $TMP_POS -ne 0 ]; then
      local TMP_LEN=$(echo `expr length "$i"`)
      let "TMP_KND=${TMP_POS} -1"
      let "TMP_VST=${TMP_POS} +1"
      local TMP_VAL=$(echo `expr substr "$i" $TMP_VST $TMP_LEN`)
      local TMP_KEY=$(echo `expr substr "$i" 1 $TMP_KND`)
      printStatus "UBOOT" "${TMP_KEY} : ${TMP_VAL}"
    else
      local TMP_KEY="$i"
      local TMP_VAL=""
      printStatus "UBOOT" "${TMP_KEY}"
    fi
    ubootSetEnv "${BUILD_BOOT_CMD}" "${TMP_KEY}" "${TMP_VAL}"
  done
  
  rm -f "${BUILD_BOOT_UENV}"
  touch "${BUILD_BOOT_UENV}"

  for i in "${BUILD_UBUILDER_BOOTUENV[@]}"; do
    ubootSetEnv "${BUILD_BOOT_UENV}" "${i}"
  done
  
  ubootImage ${BUILD_BOOT_CMD} ${BUILD_BOOT_SCR}
  
  gitClone "${BUILD_TBUILDER_SOURCE}" "${BUILD_TBUILDER_GITSRC}" "${BUILD_TBUILDER_GITBRN}"
  makeFEXC "${BUILD_TBUILDER_SOURCE}" "${BUILD_TBUILDER_FAMILLY}"
  
  if [ "${ARMSTRAP_MAC_ADDRESS}" != "" ]; then
    fexMac "${BUILD_BOOT_FEX}" "${ARMSTRAP_MAC_ADDRESS}"
  fi
  
  fex2bin "${BUILD_TBUILDER_SOURCE}" ${BUILD_BOOT_FEX} ${BUILD_BOOT_BIN}

  ddLoader "${ARMSTRAP_DEVICE}" "${BUILD_BOOT_UBOOT[@]}" 
}

# Usage : default_installKernel
function default_installKernel {
  chrootKernel "${BUILD_MNT_ROOT}" "${BUILD_ARMBIAN_KERNEL}"
}

#usage default_installOS
function default_installOS {

  funExist ${BUILD_CONFIG}_installRoot
  if [ ${?} -eq 0 ]; then
    ${BUILD_CONFIG}_installRoot
  else
    default_installRoot
  fi
  
  funExist ${BUILD_CONFIG}_installBoot
  if [ ${?} -eq 0 ]; then
    ${BUILD_CONFIG}_installBoot
  else
    default_installBoot
  fi
  
  funExist ${BUILD_CONFIG}_installKernel
  if [ ${?} -eq 0 ]; then
    ${BUILD_CONFIG}_installKernel
  else
    default_installKernel
  fi
  
}

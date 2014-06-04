# Usage installQEMU <ARMSTRAP_ROOT>
function installQEMU {
  if [ ! -f "${1}/usr/bin/qemu-arm-static" ]; then
    printStatus "installQEMU" "Installing QEMU Arm Emulator in `basename ${1}`."
    cp -v "/usr/bin/qemu-arm-static" "${1}/usr/bin" >> ${ARMSTRAP_LOG_FILE} 2>&1
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
  local TMP_PKG="`basename ${2}`"
  shift
  shift
  
  printStatus "httpExtract" "Fetching and extracting `basename ${TMP_URL}`"
  checkDirectory "${TMP_DIR}/"

  if [ -f "${ARMSTRAP_PKG}/${TMP_PKG}" ]; then
    printStatus "httpExtract" "Found local copy of ${TMP_PKG}"
    TMP_URL="${ARMSTRAP_PKG}/${TMP_PKG}"
    cat "${TMP_URL}" | ${@} -C "${TMP_DIR}/"
    checkStatus "Error while downloading/extracting ${TMP_URL}"
  else
    printStatus "httpExtract" "Fetching and extracting `basename ${TMP_URL}`"
    wget --progress=dot:mega -a ${ARMSTRAP_LOG_FILE} -O - "${TMP_URL}" | ${@} -C "${TMP_DIR}/"
    checkStatus "Error while downloading/extracting ${TMP_URL}"
  fi
}

# usage pkgExtract <DESTINATION> <FILE> <EXTRACTOR_CMD>
function pkgExtract {
  local TMP_DIR="${1}"
  local TMP_PKG="${2}"
  shift
  shift
  
  printStatus "pkgExtract" "Extracting `basename ${TMP_PKG}`"
  checkDirectory "${TMP_DIR}/"
  cat ${TMP_PKG} | ${@} -C "${TMP_DIR}/"
  checkStatus "Error while downloading/extracting ${TMP_PKG}"
}

function chrootRun {
  local TMP_CHROOT=${1}
  shift

  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootRun" "Executing '${@}' in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot "${TMP_CHROOT}" ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}

function chrootShell {
  local TMP_CHROOT=${1}
  local TMP_FSNAME="`basename ${TMP_CHROOT}`"
  
  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootRun" "Executing '/bin/bash' in ${TMP_FSNAME}"
  # We don't want anything fancy in the chroot environment
  PROMPT_COMMAND="" debian_chroot="armStrap@${TMP_FSNAME}" PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ ' LC_ALL="" LANGUAGE="en_US:us" LANG="en_US.UTF-8" chroot "${TMP_CHROOT}" "/bin/bash"
  
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}

function chrootUpgrade {
  local TMP_CHROOT=${1}
  shift

  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootUpgrade" "Updating packages in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/apt-get -q -y update ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/apt-get -q -y dist-upgrade ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
    
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
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true install ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
    
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
  cp -v ${2} ${TMP_DIR}/${TMP_DEB} >> ${ARMSTRAP_LOG_FILE} 2>&1
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/dpkg -i /${TMP_CHR}/${TMP_DEB} >> ${ARMSTRAP_LOG_FILE} 2>&1
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
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ /usr/sbin/dpkg-reconfigure ${@}
    
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
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/passwd root <<EOF > /dev/null 2>&1
${2}
${2}

EOF
    
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}


# Usage : chrootKernel <ARMSTRAP_ROOT>
function chrootKernel {
  local TMP_CHROOT="${1}"
  local TMP_KERNEL="install-linux-kernel.sh"
  
  cat >> "${TMP_CHROOT}/${TMP_KERNEL}" <<EOF  
#!/bin/bash

KERNEL_TYPE="${BOARD_KERNEL}"
KERNEL_CONFIG="${BOARD_KERNEL_CONFIG}"
KERNEL_VERSION="${BOARD_KERNEL_VERSION}"

echo "deb ${ARMSTRAP_ABUILDER_REPO_URL} \${KERNEL_TYPE} main" > /etc/apt/sources.list.d/armstrap-\${KERNEL_TYPE}.list
echo "deb-src ${ARMSTRAP_ABUILDER_REPO_URL} \${KERNEL_TYPE} main" >> /etc/apt/sources.list.d/armstrap-\${KERNEL_TYPE}.list
TMP_GNUPGHOME="\${GNUPGHOME}"
export GNUPGHOME="\$(mktemp -d)" 1>&2
chown \${USER}:\${USER} \${GNUPGHOME} 1>&2
chmod 0700 \${GNUPGHOME} 1>&2
gpg --keyserver pgpkeys.mit.edu --recv-key 1F7F94D7A99BC726 1>&2
gpg --armor --export 1F7F94D7A99BC726 | apt-key add - 1>&2
rm -rf \${GNUPGHOME} 1>&2
GNUPGHOME="\${TMP_GNUPGHOME}"

/usr/bin/apt-get -q -y -o=APT::Install-Recommends=true -o=APT::Get::AutomaticRemove=true update

KERNEL_IMG=\$(/usr/bin/apt-cache search \${KERNEL_TYPE}-linux-\${KERNEL_CONFIG}-image-\${KERNEL_VERSION} | sort -r | head -n 1 | cut -d ' ' -f 1)
KERNEL_HDR=\${KERNEL_IMG/-image-/-headers-}
KERNEL_FWR=\${KERNEL_IMG/-image-/-firmware-image-}

/usr/bin/apt-get -q -y -o=APT::Install-Recommends=true -o=APT::Install-Suggests=true -o=APT::Get::AutomaticRemove=true install \${KERNEL_IMG} \${KERNEL_HDR} \${KERNEL_FRM}
EOF

  chmod +x "${TMP_CHROOT}/${TMP_KERNEL}"
  
  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootKernel" "Executing ${TMP_KERNEL} script in `basename ${TMP_CHROOT}`"
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ /${TMP_KERNEL} >> ${ARMSTRAP_LOG_FILE} 2>&1
  
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
  
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ /usr/sbin/locale-gen >> ${ARMSTRAP_LOG_FILE} 2>&1
  LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ /usr/sbin/update-locale LANG=${TMP_LANG} >> ${ARMSTRAP_LOG_FILE} 2>&1
  
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
    LC_ALL="" LANGUAGE="${BOARD_LANGUAGE}" LANG="${BOARD_LANG}" chroot ${TMP_CHROOT}/ ln -sf /usr/share/zoneinfo/${TMP_TZ} /etc/localtime >> ${ARMSTRAP_LOG_FILE} 2>&1
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

# Usage : armStrapConfig <ARMSTRAP_ROOT> <CONFIG_PARAM>
function armStrapConfig {
  local TMP_CONF="${1}/etc/armStrap.conf"
  shift
  
  if [ ! -f ${TMP_CONF} ]; then
    touch ${TMP_CONF}
    printf "# armStap configuration. This is a normal shell script that is sourced\n" >> ${TMP_CONF}
    printf "# by various utilities that can be run once the system is installed and\n" >> ${TMP_CONF}
    printf "# running (like kernel packages). Do not modify theses values unless you\n" >> ${TMP_CONF}
    printf "# know what you're doing.\n\n" >> ${TMP_CONF}
  fi
  
  printStatus "armStrapConfig" "Configuring armStrap parameters ${@}"
  printf "%s\n" "${@}" >> ${TMP_CONF}
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
      PROMPT_COMMAND="" debian_chroot="${ANF_RED}`basename ${TMP_DIR}`${ANF_DEF}" PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ ' LC_ALL="" LANGUAGE="en_US:en" LANG="en_US.UTF-8" chroot "${TMP_DIR}" /bin/bash --login
    trap - INT TERM EXIT
  fi
  printStatus "shellRun" "Exiting from `basename ${TMP_DIR}`."
  
  umountPFS "${TMP_DIR}"
  removeQEMU "${TMP_DIR}"
  enableServices "${TMP_DIR}"
}

#usage fex2bin <ARMSTRAP_MNT> <src_fex> <dst_bin>
function fex2bin {
  printStatus "fex2bin" "Compilling `basename ${3}`"
  shellRun ${1} /usr/bin/fexc -v -I fex -O bin ${2} ${3} >> ${ARMSTRAP_LOG_FILE} 2>&1
  #${1}/fexc -v -I fex -O bin ${2} ${3} >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage : default_installRoot
function default_installRoot {
  local TMP_GUI
  guiStart
  TMP_GUI=$(guiWriter "start" "Installing RootFS" "Progress")
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Extracting RootFS")
  httpExtract "${ARMSTRAP_MNT}" "${ARMSTRAP_ABUILDER_ROOTFS_URL}/${BOARD_ROOTFS_PACKAGE}" "${ARMSTRAP_TAR_EXTRACT}"

  ARMSTRAP_GUI_PCT=$(guiWriter "add"  29 "Setting up locales")
  chrootLocales "${ARMSTRAP_MNT}" "${BOARD_LANG}" "${BOARD_LANG_EXTRA}"
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  9 "Setting up locales")
  chrootTimeZone "${ARMSTRAP_MNT}" "${BOARD_TIMEZONE}"
  
  setHostName "${ARMSTRAP_MNT}" "${ARMSTRAP_HOSTNAME}"
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Updating RootFS")
  chrootUpgrade "${ARMSTRAP_MNT}"
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  19 "Configuring RootFS")
  if [ -n "${BOARD_DPKG_EXTRAPACKAGES}" ]; then
    chrootInstall "${ARMSTRAP_MNT}" "${BOARD_DPKG_EXTRAPACKAGES}"
  fi
  
  isTrue "${ARMSTRAP_SWAP}"  
  if [ ${ARMSTRAP_SWAPSIZE} -gt 0 ]; then
    printf "CONF_SWAPFILE=%s\n" "${ARMSTRAP_SWAPFILE}" > "${ARMSTRAP_MNT}/etc/dphys-swapfile"
    printf "CONF_SWAPSIZE=%s\n" "${ARMSTRAP_SWAPSIZE}" >> "${ARMSTRAP_MNT}/etc/dphys-swapfile"
    printf "#CONF_SWAPFACTOR=%s\n" "${ARMSTRAP_SWAPFACTOR}" >> "${ARMSTRAP_MNT}/etc/dphys-swapfile"
    printf "#CONF_MAXSWAP=%s\n" "${ARMSTRAP_SWAPMAX}" >> "${ARMSTRAP_MNT}/etc/dphys-swapfile"
  else
    printf "CONF_SWAPFILE=%s\n" "${ARMSTRAP_SWAPFILE}" > "${ARMSTRAP_MNT}/etc/dphys-swapfile"
    printf "#CONF_SWAPSIZE=%s\n" "${ARMSTRAP_SWAPSIZE}" >> "${ARMSTRAP_MNT}/etc/dphys-swapfile"
    printf "CONF_SWAPFACTOR=%s\n" "${ARMSTRAP_SWAPFACTOR}" >> "${ARMSTRAP_MNT}/etc/dphys-swapfile"
    printf "CONF_MAXSWAP=%s\n" "${ARMSTRAP_SWAPMAX}" >> "${ARMSTRAP_MNT}/etc/dphys-swapfile"
  fi

  if [ ! -z "${BOARD_ROOTFS_RECONFIG}" ]; then
    chrootReconfig "${ARMSTRAP_MNT}" "${BOARD_ROOTFS_RECONFIG}"
  fi

  if [ -d "${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/dpkg" ]; then
    BOARD_DPKG_LOCALPACKAGES="`find ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/dpkg/*.deb -maxdepth 1 -type f -print0 | xargs -0 echo` ${BOARD_DPKG_LOCALPACKAGES}"
  fi
  
  if [ -d "${ARMSTRAP_BOARDS}/.defaults/dpkg" ]; then
    BOARD_DPKG_LOCALPACKAGES="`find ${ARMSTRAP_BOARDS}/.defaults/dpkg/*.deb -maxdepth 1 -type f -print0 | xargs -0 echo` ${BOARD_DPKG_LOCALPACKAGES}"
  fi

  if [ ! -z "${BOARD_DPKG_LOCALPACKAGES}" ]; then
    for i in ${BOARD_DPKG_LOCALPACKAGES}; do
      chrootDPKG "${ARMSTRAP_MNT}" ${i}
    done
  fi

  chrootPassword "${ARMSTRAP_MNT}" "${ARMSTRAP_PASSWORD}"

  addTTY "${ARMSTRAP_MNT}" "${BOARD_SERIAL_ID}" "${BOARD_SERIAL_RUNLEVEL}" "${BOARD_SERIAL_TERM}" "${BOARD_SERIAL_SPEED}" "${BOARD_SERIAL_TYPE}"

  initFSTab "${ARMSTRAP_MNT}" 
  addFSTab "${ARMSTRAP_MNT}" ${BOARD_FSTAB[@]}

  for i in "${BOARD_KERNEL_MODULES}"; do
    addKernelModule "${ARMSTRAP_MNT}" "${i}"
  done
  
  if [ ! -z ${ARMSTRAP_KERNEL_MODULES} ]; then
    for i in "${ARMSTRAP_KERNEL_MODULES}"; do
      addKernelModule "${ARMSTRAP_MNT}" "${i}"
    done
  fi
  
  if [ ! -z ${BOARD_KERNEL_DTB} ]; then
    armStrapConfig "${ARMSTRAP_MNT}" "uboot_kernel_dtb=dtbs/${BOARD_KERNEL_DTB}"
  fi
  
  if [ ! -z ${BOARD_LOADER_NAND_KERNEL} ]; then
    armStrapConfig "${ARMSTRAP_MNT}" "nand_kernel_image=${BOARD_LOADER_NAND_KERNEL}"
  fi
  
  addIface "${ARMSTRAP_MNT}" "eth0" "${ARMSTRAP_MAC_ADDRESS}" "${ARMSTRAP_ETH0_MODE}" "${ARMSTRAP_ETH0_IP}" "${ARMSTRAP_ETH0_MASK}" "${ARMSTRAP_ETH0_GW}" "${ARMSTRAP_ETH0_DOMAIN}" "${ARMSTRAP_ETH0_DNS}"
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Configuring RootFS")
  guiStop
}

# usage : default_installBoot
function default_installBoot {
  local TMP_GUI=""
  
  if [ ! -z "${BOARD_LOADER}" ]; then
    case ${BOARD_LOADER} in
      u-boot-sunxi*)
        guiStart
        TMP_GUI=$(guiWriter "start" "Installing BootLoader" "Progress")
  
        ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Extracting BootLoader")
        httpExtract "${ARMSTRAP_MNT}/boot" "${ARMSTRAP_ABUILDER_LOADER_URL}/${BOARD_CONFIG}-${BOARD_LOADER}${ARMSTRAP_TAR_EXTENSION}" "${ARMSTRAP_TAR_EXTRACT}"
    
        if [ -f ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/boot/`basename ${BOARD_LOADER_CMD}` ]; then
          cp ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/boot/`basename ${BOARD_LOADER_CMD}` ${BOARD_LOADER_CMD}
        else 
          if [ -f ${ARMSTRAP_BOARDS}/.defaults/boot/`basename ${BOARD_LOADER_CMD}` ]; then
            ${ARMSTRAP_BOARDS}/.defaults/boot/`basename ${BOARD_LOADER_CMD}` ${BOARD_LOADER_CMD} 
          else
            rm -f "${BOARD_LOADER_CMD}"
            touch "${BOARD_LOADER_CMD}"
          fi
        fi

        ARMSTRAP_GUI_PCT=$(guiWriter "add"  2 "Configuring BootLoader")
        for i in "${BOARD_LOADER_BOOTCMD[@]}"; do
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
          ubootSetEnv "${BOARD_LOADER_CMD}" "${TMP_KEY}" "${TMP_VAL}"
        done
  
        rm -f "${BOARD_LOADER_UENV}"
        touch "${BOARD_LOADER_UENV}"
        
        if [ -f ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/boot/`basename ${BOARD_LOADER_UENV}` ]; then
          cp ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/boot/`basename ${BOARD_LOADER_UENV}` ${BOARD_LOADER_UENV}
        else 
          if [ -f ${ARMSTRAP_BOARDS}/.defaults/boot/`basename ${BOARD_LOADER_UENV}` ]; then
            cp ${ARMSTRAP_BOARDS}/.defaults/boot/`basename ${BOARD_LOADER_UENV}` ${BOARD_LOADER_UENV}
          else
            rm -f "${BOARD_LOADER_UENV}"
            touch "${BOARD_LOADER_UENV}"
          fi
        fi        

        for i in "${BOARD_LOADER_BOOTUENV[@]}"; do
          ubootSetEnv "${BOARD_LOADER_UENV}" "${i}"
        done

        ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Creating BootLoader Image")  
        ubootImage ${BOARD_LOADER_CMD} ${BOARD_LOADER_SCR}
  
        if [ "${ARMSTRAP_MAC_ADDRESS}" != "" ]; then
          fexMac "${ARMSTRAP_MNT}/${BOARD_LOADER_FEX}" "${ARMSTRAP_MAC_ADDRESS}"
        fi
  
        fex2bin "${ARMSTRAP_MNT}" "${BOARD_LOADER_FEX}" "${BOARD_LOADER_BIN}"

        ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Installing BootLoader")
        ddLoader "${ARMSTRAP_DEVICE}" "${BOARD_LOADER_UBOOT[@]}" 
  
        guiStop
        ;;
      *)
        printStatus "default_installBoot" "I don't know how to install bootloader ${BOARD_LOADER}"
        ;;
   esac
 fi
}

# Usage : default_installKernel
function default_installKernel {
  local TMP_GUI
  guiStart
  TMP_GUI=$(guiWriter "start" "Installing Kernel" "Progress")
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Installing Kernel")
  chrootKernel "${ARMSTRAP_MNT}"
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  19 "Installing Kernel")
  guiStop
}

#usage default_installOS
function default_installOS {

  funExist ${BOARD_CONFIG}_installRoot
  if [ ${?} -eq 0 ]; then
    ${BOARD_CONFIG}_installRoot
  else
    default_installRoot
  fi
  
  funExist ${BOARD_CONFIG}_installBoot
  if [ ${?} -eq 0 ]; then
    ${BOARD_CONFIG}_installBoot
  else
    default_installBoot
  fi
  
  funExist ${BOARD_CONFIG}_installKernel
  if [ ${?} -eq 0 ]; then
    ${BOARD_CONFIG}_installKernel
  else
    default_installKernel
  fi
  
}

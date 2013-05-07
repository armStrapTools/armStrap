# Usage installQEMU <ARCH>
function installQEMU {
  printStatus installQEMU "Installing QEMU User Emulator (${1})"  
  cp /usr/bin/qemu-${1}-static ${BUILD_MNT_ROOT}/usr/bin
}

# Usage removeQEMU <ARCH>
function removeQEMU {
  printStatus removeQEMU "Removing QEMU User Emulator (${1})"  
  rm -f ${BUILD_MNT_ROOT}/usr/bin
}

# Usage : disableServices
function disableServices {
  printStatus "disableServices" "Disabling services startup in ${BUILD_MNT_ROOT}"
  cat > ${BUILD_MNT_ROOT}/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101 
EOF
  chmod +x ${1}/usr/sbin/policy-rc.d
}

# Usage : enableServices
function enableServices {
  printStatus "disableServices" "Enabling services startup in ${BUILD_MNT_ROOT}"
  rm -f ${BUILD_MNT_ROOT}/usr/sbin/policy-rc.d
}

# usage bootStrap <ARCH> <EABI> <SUITE> [<MIRROR>]
function bootStrap {
  if [ $# -eq 3 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${1}${2} ${3}, target is ${BUILD_MNT_ROOT}"
    debootstrap --foreign --arch ${1}${2} ${3} ${BUILD_MNT_ROOT}/ >> ${BUILD_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  elif [ $# -eq 4 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${1}${2} ${3} using mirror ${4}, target is ${BUILD_MNT_ROOT}"
    debootstrap --foreign --arch ${1}${2} ${3} ${BUILD_MNT_ROOT}/ ${4} >> ${BUILD_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  else
    checkStatus "bootStrap need 2 or 3 arguments."
  fi
  
  installQEMU ${1}
  disableServices

  printStatus "bootStrap" "Running debootstrap --second-stage"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ /debootstrap/debootstrap --second-stage >> ${BUILD_LOG_FILE} 2>&1
  checkStatus "debootstrap --second-stage failed with status ${?}"

  printStatus "bootStrap" "Running dpkg --configure -a"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ dpkg --configure -a >> ${BUILD_LOG_FILE} 2>&1
  checkStatus "dpkg --configure failed with status ${?}"
}

# Usage : setHostName <HOSTNAME>
function setHostName {
  printStatus "buildRoot" "Configuring /etc/hostname"
  cat > ${BUILD_MNT_ROOT}/etc/hostname <<EOF
${1}
EOF
}

# Usage : clearSourcesList
function clearSourcesList {
  printStatus "clearSourcesList" "Removing current sources list"
  rm -f ${BUILD_MNT_ROOT}/etc/apt/sources.list
  touch ${BUILD_MNT_ROOT}/etc/apt/sources.list
}

# Usage : addSource <URI> <DIST> <COMPONENT1> [<COMPONENT2> ...]
function addSource {
  printStatus "addSource" "Adding ${@} to the sources list"
  echo "deb ${@}" >> ${BUILD_MNT_ROOT}/etc/apt/sources.list
  echo "deb-src ${@}" >> ${BUILD_MNT_ROOT}/etc/apt/sources.list
  echo "" >> ${BUILD_MNT_ROOT}/etc/apt/sources.list
}

# Usage : initSources
function initSources {
  printStatus "initSources" "Updating sources list"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ apt-get --quiet -y update >> ${BUILD_LOG_FILE} 2>&1
  printStatus "initSources" "Updating Packages"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ apt-get --quiet -y upgrade >> ${BUILD_LOG_FILE} 2>&1
}

# Usage : installPackages <PKG1> [<PKG2> ...]
function installPackages {
  printStatus "installPackages" "Installing ${@}"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ apt-get --quiet -y install ${@} >> ${BUILD_LOG_FILE} 2>&1
}

# Usage : configPackages <PKG1> [<PKG2> ...]
function configPackages {
  printStatus "configPackages" "Configuring ${@}"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ dpkg-reconfigure ${@}
}

# Usage : setRootPassword <PASSWORD>
function setRootPassword {
  printStatus "setRootPassword" "Configuring root password"
  chroot ${BUILD_MNT_ROOT}/ passwd root <<EOF > /dev/null 2>&1
${1}
${1}

EOF
}

# Usage addInitTab <ID> <RUNLEVELS> <DEVICE> <SPEED> <TYPE>
function addInitTab {
  printStatus "addInitTab" "Configuring terminal ${1} for runlevels ${2} on device ${3} at ${4}bps (${5})"
  printf "%s:%s:respawn:/sbin/getty -L %s %s %s\n" ${1} ${2} ${3} ${4} ${5} >> ${BUILD_MNT_ROOT}/etc/inittab
}

# Usage addFSTab <file system> <mount point> <type> <options> <dump> <pass>
function addFSTab {
  printStatus "addFStab" "Device ${1} will be mount as ${2}"
  if [ ! -e "${BUILD_MNT_ROOT}/etc/fstab" ]; then
    printf "#%- 15s% -15s%- 10s%- 15s%- 10s%- 10s\n" "<file system>" "<mount point>" "<type>" "<options>" "<dump>" "<pass>" > ${BUILD_MNT_ROOT}/etc/fstab
  fi
  printf "%- 15s% -15s%- 10s%- 15s%- 10s%- 10s\n" >> ${BUILD_MNT_ROOT}/etc/fstab
}

# usage addKernelModules <KERNEL MODULE> [<COMMENT>]
function addKernelModule {

  printStatus "addModule" "Configuring kernel module ${1}"
  if [ ! -z "${2}" ]; then
    printf "\n# %s\n", ${2} >> ${BUILD_MNT_ROOT}/etc/modules
  fi
  
  printf "%s\n" ${1} >> ${BUILD_MNT_ROOT}/etc/modules
}

# Usage : addIface <INTERFACE> <dhcp|static> [<address> <netmask> <gateway>]
function addIface {
  printStatus "addIface" "Configuring interface ${1}"
  printf "auto %s\n" ${1} >> ${BUILD_MNT_ROOT}/etc/network/interfaces
  printf "allow-hotplug %s\n\n" ${1} >> ${BUILD_MNT_ROOT}/etc/network/interfaces
  printf "iface %s inet %s\n" ${1} ${2} >> ${BUILD_MNT_ROOT}/etc/network/interfaces
  if [ "${2}" != "dhcp" ]; then
    printStatus "addIface" "IP address : ${3}/${4}, default gateway ${5}"
    printf "  address %s\n" ${3} >> ${BUILD_MNT_ROOT}/etc/network/interfaces
    printf "  netmask %s\n" ${4} >> ${BUILD_MNT_ROOT}/etc/network/interfaces
    printf "  gateway %s\n\n" ${5} >> ${BUILD_MNT_ROOT}/etc/network/interfaces
  else
    printStatus "addIface" "IP address : DHCP"
    printf "\n" >> ${BUILD_MNT_ROOT}/etc/network/interfaces
  fi
}

# Usage : initResolvConf
function initResolvConf {
  printStatus "initResolvConf" "Initializing ${BUILD_MNT_ROOT}/etc/resolv.conf"
  rm -f ${BUILD_MNT_ROOT}/etc/resolv.conf
  touch ${BUILD_MNT_ROOT}/etc/resolv.conf
}

# Usage : addSearchDomain <DOMAIN>
function addSearchDomain {
  printf "addSearchDomain" "Configuring search domain to ${1}"
  printf "search %s\n" ${1} >> ${BUILD_MNT_ROOT}/etc/resolv.conf
}

# Usage : addNameServer <NS1> [<NS2> ... ]
function addNameServer {
  for i in ${@}; do
    printStatus "addNameServer" "Configuring dns server ${i}"
    printf "nameserver %s\n" ${i} >> ${BUILD_MNT_ROOT}/etc/resolv.conf
  done
}


# Usage : bootClean <ARCH>
function bootClean {
  printStatus "bootClean" "Running aptitude update"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ aptitude --quiet -y update >> ${BUILD_LOG_FILE} 2>&1
  
  printStatus "bootClean" "Running aptitude clean"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ aptitude --quiet -y clean  >> ${BUILD_LOG_FILE} 2>&1
  
  printStatus "bootClean" "Running apt-get clean"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ apt-get --quiet clean >> ${BUILD_LOG_FILE} 2>&1
  
  removeQEMU ${1}
  enableServices
}

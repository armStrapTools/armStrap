# Usage installQEMU <BOARD_ROOT> <ARCH>
function installQEMU {
  printStatus installQEMU "Installing QEMU User Emulator (${2}) to ${1}"  
  cp /usr/bin/qemu-${2}-static ${1}/usr/bin
}

# Usage removeQEMU <BOARD_ROOT> <ARCH>
function removeQEMU {
  printStatus removeQEMU "Removing QEMU User Emulator (${2}) from ${1}"  
  rm -f ${2}/usr/bin/qemu-${1}-static
}

# Usage : disableServices <BOARD_ROOT>
function disableServices {
  printStatus "disableServices" "Disabling services startup in ${1}"
  cat > ${1}/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101 
EOF
  chmod +x ${1}/usr/sbin/policy-rc.d
}

# Usage : enableServices <BOARD_ROOT>
function enableServices {
  printStatus "disableServices" "Enabling services startup in ${1}"
  rm -f ${1}/usr/sbin/policy-rc.d
}

# usage bootStrap <BOARD_ROOT> <ARCH> <EABI> <SUITE> [<MIRROR>]
function bootStrap {
  if [ $# -eq 4 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${2}${3} ${4}, target is ${1}"
    debootstrap --foreign --arch ${2}${3} ${4} ${1}/ >> ${BOARD_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  elif [ $# -eq 5 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${2}${3} ${4} using mirror ${5}, target is ${1}"
    debootstrap --foreign --arch ${2}${3} ${4} ${1}/ ${5} >> ${BOARD_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  else
    checkStatus "bootStrap need 3 or 4 arguments."
  fi
  
  installQEMU ${1} ${2}
  disableServices ${1}

  printStatus "bootStrap" "Running debootstrap --second-stage"
  LC_ALL=${BOARD_LANG} LANGUAGE=${BOARD_LANG} LANG=${BOARD_LANG} chroot ${1}/ /debootstrap/debootstrap --second-stage >> ${BOARD_LOG_FILE} 2>&1
  checkStatus "debootstrap --second-stage failed with status ${?}"

  printStatus "bootStrap" "Running dpkg --configure -a"
  LC_ALL=${BOARD_LANG} LANGUAGE=${BOARD_LANG} LANG=${BOARD_LANG} chroot ${1}/ dpkg --configure -a >> ${BOARD_LOG_FILE} 2>&1
  checkStatus "dpkg --configure failed with status ${?}"
}

# Usage : setHostName <BOARD_ROOT> <HOSTNAME>
function setHostName {
  printStatus "buildRoot" "Configuring /etc/hostname"
  cat > ${1}/etc/hostname <<EOF
${1}
EOF
}

# Usage : clearSources <BOARD_ROOT>
function clearSourcesList {
  printStatus "clearSources" "Removing current sources list"
  rm -f ${1}/etc/apt/sources.list
  touch ${1}/etc/apt/sources.list
}

# Usage : addSource <BOARD_ROOT> <URI> <DIST> <COMPONENT1> [<COMPONENT2> ...]
function addSource {
  TMP_ROOT="${1}"
  shift
  
  printStatus "addSource" "Adding ${@} to the sources list"
  echo "deb ${@}" >> ${TMP_ROOT}/etc/apt/sources.list
  echo "deb-src ${@}" >> ${TMP_ROOT}/etc/apt/sources.list
  echo "" >> ${TMP_ROOT}/etc/apt/sources.list
}

# Usage : initSources <BOARD_ROOT>
function initSources {
  printStatus "initSources" "Updating sources list"
  LC_ALL=${BOARD_LANG} LANGUAGE=${BOARD_LANG} LANG=${BOARD_LANG} chroot ${1}/ apt-get --quiet -y update >> ${BOARD_LOG_FILE} 2>&1
  printStatus "initSources" "Updating Packages"
  LC_ALL=${BOARD_LANG} LANGUAGE=${BOARD_LANG} LANG=${BOARD_LANG} chroot ${1}/ apt-get --quiet -y upgrade >> ${BOARD_LOG_FILE} 2>&1
}

# Usage : installPackages <BOARD_ROOT> <PKG1> [<PKG2> ...]
function installPackages {
  printStatus "installPackages" "Installing ${@}"
  LC_ALL=${BOARD_LANG} LANGUAGE=${BOARD_LANG} LANG=${BOARD_LANG} chroot ${1}/ apt-get --quiet -y install ${@} >> ${BOARD_LOG_FILE} 2>&1
}

# Usage : configPackages <BOARD_ROOT> <PKG1> [<PKG2> ...]
function configPackages {
  printStatus "configPackages" "Configuring ${@}"
  LC_ALL=${BOARD_LANG} LANGUAGE=${BOARD_LANG} LANG=${BOARD_LANG} chroot ${1}/ dpkg-reconfigure ${@}
}

# Usage : setRootPassword <BOARD_ROOT> <PASSWORD>
function setRootPassword {
  printStatus "setRootPassword" "Configuring root password"
  chroot ${1}/ passwd root <<EOF > /dev/null 2>&1
${1}
${1}

EOF
}

# Usage : addInitTab <BOARD_ROOT> <ID> <RUNLEVELS> <DEVICE> <SPEED> <TYPE>
function addInitTab {
  printStatus "addInitTab" "Configuring terminal ${2} for runlevels ${3} on device ${4} at ${5}bps (${6})"
  printf "%s:%s:respawn:/sbin/getty -L %s %s %s\n" ${2} ${3} ${4} ${5} ${6} >> ${1}/etc/inittab
}

# Usage : initFSTab <BOARD_ROOT>
function initFSTab {
  printStatus "initFSTab" "Initializing ${1}/etc/fstab"
  printf "%- 20s% -15s%- 10s%- 15s%- 8s%- 8s\n" "#<file system>" "<mount point>" "<type>" "<options>" "<dump>" "<pass>" > ${1}/etc/fstab
}

# Usage : addFSTab <BOARD_ROOT> <file system> <mount point> <type> <options> <dump> <pass>
function addFSTab {
  printStatus "addFSTab" "Device ${2} will be mount as ${3}"
  printf "%- 20s% -15s%- 10s%- 15s%- 8s%- 8s\n" ${2} ${3} ${4} ${5} ${6} ${7} >>${1}/etc/fstab
}

# Usage : addKernelModules <BOARD_ROOT> <KERNEL MODULE> [<COMMENT>]
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

# Usage : addIface <BOARD_ROOT> <INTERFACE> <dhcp|static> [<address> <netmask> <gateway>]
function addIface {
  TMP_ROOT="${1}"
  shift
  
  printStatus "addIface" "Configuring interface ${1}"
  printf "auto %s\n" ${1} >> ${TMP_ROOT}/etc/network/interfaces
  printf "allow-hotplug %s\n\n" ${1} >> ${TMP_ROOT}/etc/network/interfaces
  printf "iface %s inet %s\n" ${1} ${2} >> ${TMP_ROOT}/etc/network/interfaces
  if [ "${2}" != "dhcp" ]; then
    printStatus "addIface" "IP address : ${3}/${4}, default gateway ${5}"
    printf "  address %s\n" ${3} >> ${TMP_ROOT}/etc/network/interfaces
    printf "  netmask %s\n" ${4} >> ${TMP_ROOT}/etc/network/interfaces
    printf "  gateway %s\n\n" ${5} >> ${TMP_ROOT}/etc/network/interfaces
  else
    printStatus "addIface" "IP address : DHCP"
    printf "\n" >> ${TMP_ROOT}/etc/network/interfaces
  fi
}

# Usage : initResolvConf <BOARD_ROOT>
function initResolvConf {
  printStatus "initResolvConf" "Initializing ${1}/etc/resolv.conf"
  rm -f ${1}/etc/resolv.conf
  touch ${1}/etc/resolv.conf
}

# Usage : addSearchDomain <BOARD_ROOT> <DOMAIN>
function addSearchDomain {
  printf "addSearchDomain" "Configuring search domain to ${2}"
  printf "search %s\n" ${2} >> ${1}/etc/resolv.conf
}

# Usage : addNameServer <BOARD_ROOT> <NS1> [<NS2> ... ]
function addNameServer {
  TMP_ROOT=${1}
  shift
  
  for i in ${@}; do
    printStatus "addNameServer" "Configuring dns server ${i}"
    printf "nameserver %s\n" ${i} >> ${TMP_ROOT}/etc/resolv.conf
  done
}


# Usage : bootClean <BOARD_ROOT> <ARCH>
function bootClean {
  printStatus "bootClean" "Running aptitude update"
  LC_ALL=${BOARD_LANG} LANGUAGE=${BOARD_LANG} LANG=${BOARD_LANG} chroot ${1}/ aptitude --quiet -y update >> ${BOARD_LOG_FILE} 2>&1
  
  printStatus "bootClean" "Running aptitude clean"
  LC_ALL=${BOARD_LANG} LANGUAGE=${BOARD_LANG} LANG=${BOARD_LANG} chroot ${1}/ aptitude --quiet -y clean  >> ${BOARD_LOG_FILE} 2>&1
  
  printStatus "bootClean" "Running apt-get clean"
  LC_ALL=${BOARD_LANG} LANGUAGE=${BOARD_LANG} LANG=${BOARD_LANG} chroot ${1}/ apt-get --quiet clean >> ${BOARD_LOG_FILE} 2>&1
  
  removeQEMU ${1} ${2}
  enableServices ${1}
}

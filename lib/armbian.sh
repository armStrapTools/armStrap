# usage bootStrap <ARCH> <SUITE> [<MIRROR>]
function bootStrap {
  if [ $# -eq 2 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${1} ${2}, target is ${BUILD_MNT_ROOT}"
    debootstrap --foreign --arch ${1} ${2} ${BUILD_MNT_ROOT}/ >> ${BUILD_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  elif [ $# -eq 3 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${1} ${2} using mirror ${3}, target is ${BUILD_MNT_ROOT}"
    debootstrap --foreign --arch ${1} ${2} ${BUILD_MNT_ROOT}/ ${3} >> ${BUILD_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  else
    checkStatus "bootStrap need 2 or 3 arguments."
  fi
  
  printStatus "bootStrap" "Running debootstrap --second-stage"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ /debootstrap/debootstrap --second-stage >> ${BUILD_LOG_FILE} 2>&1
  checkStatus "debootstrap --second-stage failed with status ${?}"

  printStatus "bootStrap" "Running dpkg --configure -a"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ dpkg --configure -a >> ${BUILD_LOG_FILE} 2>&1
  checkStatus "dpkg --configure failed with status ${?}"
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
  rm ${BUILD_MNT_ROOT}/usr/sbin/policy-rc.d
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
  rm ${BUILD_MNT_ROOT}/etc/apt/sources.list
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

# Usage : configPackages 
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
  printf "%s:%s:respawn:/sbin/getty -L %s %s %s\n" ${1} ${2} ${3} ${4} ${5} >> ${BUILD_MNT_ROOT}/etc/inittab
}

# Usage addFStab <file system> <mount point> <type> <options> <dump> <pass>
function addFStab {
  if [ ! -e "${BUILD_MNT_ROOT}/etc/fstab" ]; then
    printf "#%- 15s% -15s%- 10s%- 15s%- 10s%- 10s\n" "<file system>" "<mount point>" "<type>" "<options>" "<dump>" "<pass>" > ${BUILD_MNT_ROOT}/etc/fstab
  fi
  printf "%- 15s% -15s%- 10s%- 15s%- 10s%- 10s\n" >> ${BUILD_MNT_ROOT}/etc/fstab
}

# usage addModules <KERNEL MODULE>
function addModule {
  printf "%s\n" {$1} >> ${BUILD_MNT_ROOT}/etc/modules
}


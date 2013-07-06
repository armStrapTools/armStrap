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

function divertServices {
  printStatus "divertServices" "Disabling Ubuntu Init"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ dpkg-divert --local --rename --add /sbin/init
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ ln -s /bin/true /sbin/init
}

function undivertServices {
  printStatus "undivertServices" "Enabling Ubuntu Init"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ unlink /sbin/init
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ dpkg-divert --rename --remove /sbin/init
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

# usage ubuntuStrap <ARMSTRAP_ROOT> <ARCH> <EABI> <VERSION>
function old_ubuntuStrap {
  printStatus "ubuntuStrap" "Fetching and extracting ubuntu-core-${4}-core-${2}${3}.tar.gz"
  wget -q -O - http://cdimage.ubuntu.com/ubuntu-core/releases/${4}/release/ubuntu-core-${4}-core-${2}${3}.tar.gz | tar -xz -C ${1}/
  
  installQEMU ${1} ${2}
  disableServices ${1}
  mountPFS ${1}
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
}

function chrootRun {
  local TMP_CHROOT=${1}
  shift

  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "chrootRun" "Executing '${@}' in `basename ${TMP_CHROOT}`"
  LC_ALL="${BUILD_LC_ALL}" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot "${TMP_CHROOT}" ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  
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
  LC_ALL="${BUILD_LC_ALL}" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot "${TMP_CHROOT}" ${@}
  
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
  LC_ALL="${BUILD_LC_ALL}" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y update ${@} 2>> ${ARMSTRAP_LOG_FILE}
  LC_ALL="${BUILD_LC_ALL}" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y dist-upgrade ${@} 2>> ${ARMSTRAP_LOG_FILE}
    
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
  LC_ALL="${BUILD_LC_ALL}" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true install ${@} 2>> ${ARMSTRAP_LOG_FILE}
    
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
  LC_ALL="${BUILD_LC_ALL}" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/dpkg -i /${TMP_CHR}/${TMP_DEB} >> ${ARMSTRAP_LOG_FILE} 2>&1
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
  LC_ALL="${BUILD_LC_ALL}" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/sbin/dpkg-reconfigure ${@}
    
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
  LC_ALL="${BUILD_LC_ALL}" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /usr/bin/passwd root <<EOF > /dev/null 2>&1
${2}
${2}

EOF
    
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"
}


# Usage : setRootPassword <ARMSTRAP_ROOT> <PASSWORD>
function setRootPassword {
  printStatus "setRootPassword" "Configuring root password"
  chroot ${1}/ /usr/bin/passwd root <<EOF > /dev/null 2>&1
${2}
${2}

EOF
}

# Usage : configPackages <ARMSTRAP_ROOT> <PKG1> [<PKG2> ...]
function configPackages {
  local TMP_ROOT=${1}
  shift

  printStatus "configPackages" "Configuring ${@}"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/sbin/dpkg-reconfigure ${@}
}

# Usage : installDPKG <ARMSTRAP_ROOT> <PACKAGE_FILE>
function installDPKG {
  local TMP_ROOT="${1}"
  local TMP_DIR=`mktemp -d ${TMP_ROOT}/DPKG.XXXXXX`
  local TMP_CHR=`basename ${TMP_DIR}`
  local TMP_DEB=`basename ${2}`

  printStatus "installDPKG" "Installing ${TMP_DEB}"
  cp ${2} ${TMP_DIR}/${TMP_DEB}
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/dpkg -i /${TMP_CHR}/${TMP_DEB} >> ${ARMSTRAP_LOG_FILE} 2>&1
  rm -rf ${TMP_DIR}
}

function installLinux {
  local TMP_CHROOT="${1}"
  local TMP_KERNEL="`basename ${2}`"
  printStatus "installLinux" "Downloading ${TMP_KERNEL} script to `basename ${TMP_CHROOT}`"
  wget --append-output="${ARMSTRAP_LOG_FILE}" --directory-prefix="${TMP_CHROOT}/" "${2}"

  chmod +x "${TMP_CHROOT}/${TMP_KERNEL}"
  
  disableServices "${TMP_CHROOT}"
  installQEMU "${TMP_CHROOT}"
  mountPFS "${TMP_CHROOT}"
  
  printStatus "installLinux" "Executing ${TMP_KERNEL} script in `basename ${TMP_CHROOT}`"
  LC_ALL="${BUILD_LC_ALL}" LANGUAGE="${BUILD_LANGUAGE}" LANG="${BUILD_LANG}" chroot ${TMP_CHROOT}/ /${TMP_KERNEL} "--logstderr" 2>> ${ARMSTRAP_LOG_FILE}
  
  umountPFS "${TMP_CHROOT}"
  removeQEMU "${TMP_CHROOT}"
  enableServices "${TMP_CHROOT}"

  rm -f "${TMP_CHROOT}/${TMP_KERNEL}"
}

# Usage : insResolver <ARMSTRAP_ROOT>
function insResolver {
  printStatus "insResolver" "Setting up temporary resolver"
  mv ${1}/etc/resolv.conf ${1}/etc/resolv.conf.orig
  cp /etc/resolv.conf ${1}/etc/resolv.conf
}

# Usage : insDialog <ARMSTRAP_ROOT>
function insDialog {
  printStatus "insDialog" "Installing apt-utils and Dialog frontend"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true install apt-utils dialog>> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage : ubuntuLocales <ARMSTRAP_ROOT> <LOCALE1> [<LOCALE2> ...]
# The first locale will be the default one.
function ubuntuLocales {
  local TMP_ROOT=${1}
  shift
  
  printStatus "ubuntuLocales" "Configuring locales ${@}"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ locale-gen ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  printStatus "ubuntuLocales" "Setting default locale to ${1}"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ update-locale LANG=${1} LC_MESSAGES=POSIX >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage : clnResolver <ARMSTRAP_ROOT>
function clnResolver {
  printStatus "clnResolver" "Restoring original resolver"
  rm -f ${1}/etc/resolv.conf
  mv ${1}/etc/resolv.conf.orig ${1}/etc/resolv.conf
}

# usage bootStrap <ARMSTRAP_ROOT> <ARCH> <EABI> <SUITE> [<MIRROR>]
function old_bootStrap {
  if [ $# -eq 4 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${2}${3} ${4}"
    debootstrap --foreign --arch ${2}${3} ${4} ${1}/ >> ${ARMSTRAP_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  elif [ $# -eq 5 ]; then
    printStatus "bootStrap" "Running debootstrap --foreign --arch ${2}${3} ${4} using mirror ${5}"
    debootstrap --foreign --arch ${2}${3} ${4} ${1}/ ${5} >> ${ARMSTRAP_LOG_FILE} 2>&1
    checkStatus "debootstrap failed with status ${?}"
  else
    checkStatus "bootStrap need 3 or 4 arguments."
  fi
  
  installQEMU ${1} ${2}
  disableServices ${1}
  mountPFS ${1}

  printStatus "bootStrap" "Running debootstrap --second-stage"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /debootstrap/debootstrap --second-stage >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "debootstrap --second-stage failed with status ${?}"

  printStatus "bootStrap" "Running dpkg --configure -a"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/dpkg --configure -a >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "dpkg --configure failed with status ${?}"
}

# Usage : setHostName <ARMSTRAP_ROOT> <HOSTNAME>
function setHostName {
  printStatus "buildRoot" "Configuring /etc/hostname"
  echo "${2}" > ${1}/etc/hostname
}

# Usage : clearSources <ARMSTRAP_ROOT>
function clearSourcesList {
  printStatus "clearSources" "Removing current sources list"
  rm -f ${1}/etc/apt/sources.list
  touch ${1}/etc/apt/sources.list
}

# Usage : addSource <ARMSTRAP_ROOT> <URI> <DIST> <COMPONENT1> [<COMPONENT2> ...]
function addSource {
  local TMP_ROOT="${1}"
  shift
  
  printStatus "addSource" "Adding ${@} to the sources list"
  echo "deb ${@}" >> ${TMP_ROOT}/etc/apt/sources.list
  echo "deb-src ${@}" >> ${TMP_ROOT}/etc/apt/sources.list
  echo "" >> ${TMP_ROOT}/etc/apt/sources.list
}

# Usage : initSources <ARMSTRAP_ROOT>
function initSources {
  printStatus "initSources" "Updating sources list"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/apt-get -q -y update >> ${ARMSTRAP_LOG_FILE} 2>&1
  printStatus "initSources" "Updating Packages"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/apt-get -q -y upgrade >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage : mountPFS <ARMSTRAP_ROOT>
function mountPFS {
  printStatus "mountPFS" "Mounting pseudo-filesystems in `basename ${1}`"
  mount --bind /proc ${1}/proc >> ${ARMSTRAP_LOG_FILE} 2>&1
  mount --bind /sys ${1}/sys >> ${ARMSTRAP_LOG_FILE} 2>&1
  mount --bind /dev/pts ${1}/dev/pts >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage : umountPFS <ARMSTRAP_ROOT>
function umountPFS {
  printStatus "umountPFS" "Unmounting pseudo-filesystems from `basename ${1}`"
  umount ${1}/dev/pts >> ${ARMSTRAP_LOG_FILE} 2>&1
  umount ${1}/sys >> ${ARMSTRAP_LOG_FILE} 2>&1
  umount ${1}/proc >> ${ARMSTRAP_LOG_FILE} 2>&1
}

# Usage : installTasks <ARMSTRAP_ROOT> <TASK1> [<TASK2> ...]
function installTasks {
  local TMP_ROOT=${1}
  shift
  
  printStatus "installTasks" "Installing tasks ${@}"
  for i in ${@}; do
    printStatus "installTask" "Running dpkg --configure -a"
    LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/dpkg --configure -a >> ${ARMSTRAP_LOG_FILE} 2>&1
    
    printStatus "installTask" "Updating Packages"
    LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/apt-get -q -y upgrade >> ${ARMSTRAP_LOG_FILE} 2>&1

    LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/tasksel --new-install install ${i}
  done
}

# Usage : installPackages <ARMSTRAP_ROOT> <PKG1> [<PKG2> ...]
function installPackages {
  local TMP_ROOT=${1}
  shift
  
  printStatus "installPackages" "Installing ${@}"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${TMP_ROOT}/ /usr/bin/debconf-apt-progress --logstderr -- /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true install ${@} 2>> ${ARMSTRAP_LOG_FILE}
}





# Usage : setRootPassword <ARMSTRAP_ROOT> <PASSWORD>
function setRootPassword {
  printStatus "setRootPassword" "Configuring root password"
  chroot ${1}/ /usr/bin/passwd root <<EOF > /dev/null 2>&1
${2}
${2}

EOF
}

# Usage : addInitTab <ARMSTRAP_ROOT> <ID> <RUNLEVELS> <DEVICE> <SPEED> <TYPE>
function addInitTab {
  printStatus "addInitTab" "Configuring terminal ${2} for runlevels ${3} on device ${4} at ${5}bps (${6})"
  printf "%s:%s:respawn:/sbin/getty -L %s %s %s\n" ${2} ${3} ${4} ${5} ${6} >> ${1}/etc/inittab
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
  printf "%- 20s% -15s%- 10s%- 15s%- 8s%- 8s\n" "#<file system>" "<mount point>" "<type>" "<options>" "<dump>" "<pass>" > ${1}/etc/fstab
}

# Usage : addFSTab <ARMSTRAP_ROOT> <file system> <mount point> <type> <options> <dump> <pass>
function addFSTab {
  printStatus "addFSTab" "Device ${2} will be mount as ${3}"
  printf "%- 20s% -15s%- 10s%- 15s%- 8s%- 8s\n" ${2} ${3} ${4} ${5} ${6} ${7} >>${1}/etc/fstab
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

# Usage : addIface <ARMSTRAP_ROOT> <INTERFACE> <dhcp|static> [<address> <netmask> <gateway>]
function addIface {
  local TMP_ROOT="${1}"
  local TMP_INTF="${2}"
  local TMP_DHCP="${3}"
  local TMP_ADDR="${4}"
  local TMP_MASK="${5}"
  local TMP_GWAY="${6}"
  local TMP_DOMN="${7}"
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
    printf "  address %s\n" ${TMP_ADDR} >> ${TMP_ROOT}/etc/network/interfaces
    printf "  netmask %s\n" ${TMP_MASK} >> ${TMP_ROOT}/etc/network/interfaces
    printf "  gateway %s\n" ${TMP_GWAY} >> ${TMP_ROOT}/etc/network/interfaces
    if [ ! -z "${@}" ]; then
      printf "  dns-nameserver %s" "${@}"
    fi
    if [ ! -z "${6}" ]; then
      printf "  dns-search %s" ${6}
    fi
    printf "\n" >> ${TMP_ROOT}/etc/network/interfaces    
  else
    printStatus "addIface" "IP address : DHCP"
    printf "\n" >> ${TMP_ROOT}/etc/network/interfaces
  fi
}

# Usage : initResolvConf <ARMSTRAP_ROOT>
function initResolvConf {
  printStatus "initResolvConf" "Initializing resolv.conf"
  rm -f ${1}/etc/resolv.conf
  touch ${1}/etc/resolv.conf
}

# Usage : addSearchDomain <ARMSTRAP_ROOT> <DOMAIN>
function addSearchDomain {
  printf "addSearchDomain" "Configuring search domain to ${2}"
  printf "search %s\n" ${2} >> ${1}/etc/resolv.conf
}

# Usage : addNameServer <ARMSTRAP_ROOT> <NS1> [<NS2> ... ]
function addNameServer {
  local TMP_ROOT=${1}
  shift
  
  for i in ${@}; do
    printStatus "addNameServer" "Configuring dns server ${i}"
    printf "nameserver %s\n" ${i} >> ${TMP_ROOT}/etc/resolv.conf
  done
}


# Usage : bootClean <ARMSTRAP_ROOT> <ARCH>
function bootClean {
  printStatus "bootClean" "Running aptitude update"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/aptitude -y update >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  printStatus "bootClean" "Running aptitude clean"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/aptitude -y clean  >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  printStatus "bootClean" "Running apt-get clean"
  LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/bin/apt-get clean >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  umountPFS ${1}
  removeQEMU ${1} ${2}
  enableServices ${1}
}

# Usage : installInit <ARMSTRAP_ROOT>
function installInit {

  if [ -d "${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/init.d" ]; then
    for i in ${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/init.d/*.sh; do
      local TMP_FNAME="`basename ${i}`"
      printStatus "installInit" "Installing init script ${TMP_FNAME}"
      cp ${i} ${1}/etc/init.d/
      chmod 755 ${1}/etc/init.d/${TMP_FNAME}
      LC_ALL=${BUILD_LC} LANGUAGE=${BUILD_LC} LANG=${BUILD_LC} chroot ${1}/ /usr/sbin/update-rc.d ${TMP_FNAME} defaults
    done
  fi
}

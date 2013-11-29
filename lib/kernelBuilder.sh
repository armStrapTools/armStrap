
#Usage : kernelBuilder <linux_dir> <config_dir> <type> <arch> <eabi> <config> <cflags> [<pre_hook> [<post_hook>]]
function kernelBuilder {
  local TMP_BUILD_CURDIR="`pwd`"
  local TMP_BUILD_WRKDIR="${1}"
  local TMP_BUILD_CFGDIR="${2}"
  local TMP_BUILD_CFGTYP="${3}"
  local TMP_BUILD_CPUARC="${4}"
  local TMP_BUILD_CPUABI="${5}"
  local TMP_BUILD_CONFIG="${6}"
  local TMP_BUILD_CFLAGS="${7}"
  local TMP_BUILD_PRHOOK="${8}"
  local TMP_BUILD_PSHOOK="${9}"
  

  local TMP_BUILD_CFGDEF="${TMP_BUILD_CFGDIR}/${TMP_BUILD_CFGTYP}-${TMP_BUILD_CONFIG}_defconfig"
  local TMP_BUILD_CFGDST="${TMP_BUILD_WRKDIR}/arch/${TMP_BUILD_CPUARC}/configs"
  
  funExist ${TMP_BUILD_PRHOOK}
  if [ ${?} -eq 0 ]; then
    printStatus "kernelBuilder" "Executing Pre-Build hook"
    ${TMP_BUILD_PRHOOK}
  fi

  printStatus "kernelBuilder" "Cleaning Kernel source directory"
  kernelMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" distclean
  checkStatus "Cannot clean kernel source directory."
  
  printStatus "kernelBuilder" "Configuring Kernel"
  cp -v "${TMP_BUILD_CFGDEF}" "${TMP_BUILD_CFGDST}/" >> ${ARMSTRAP_LOG_FILE} 2>&1
  kernelMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" "`basename ${TMP_BUILD_CFGDEF}`"
  checkStatus "Error while configuring Kernel"
  
  isTrue "${ARMSTRAP_KBUILDER_MENUCONFIG}"
  if [ $? -ne 0 ]; then
    kernelMakeNoLog "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" menuconfig
    TMP_BUILD_CONFIG="custom"
    TMP_BUILD_CFGDEF="${TMP_BUILD_CFGDIR}/${TMP_BUILD_CFGTYP}-${TMP_BUILD_CONFIG}_defconfig"
    export EXPORT_ARMSTRAP_RELEASE="-${TMP_BUILD_CONFIG}"
    
    promptYN "Do you want to save this config to be able to use it another time?"
    if [ $? -ne 1 ]; then
      printStatus "kernelBuilder" "Saving configuration as ${TMP_BUILD_CFGTYP}-custom_defconfig"
      cp -v "${TMP_BUILD_WRKDIR}/.config" "${TMP_BUILD_CFGDIR}/${TMP_BUILD_CFGTYP}-custom_defconfig" >> ${ARMSTRAP_LOG_FILE} 2>&1
    fi
  fi
  
  printStatus "kernelBuilder" "Building Kernel image"
  kernelMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" uImage
  checkStatus "Error while building kernel image"
  
  printStatus "kernelBuilder" "Building Kernel Modules"
  kernelMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" modules
  checkStatus "Error while building Kernel Modules"
  
  funExist ${TMP_BUILD_PSHOOK}
  if [ ${?} -eq 0 ]; then
    printStatus "kernelBuilder" "Executing Post-Build hook"
    ${TMP_BUILD_PSHOOK}
  fi
  
  printStatus "kernelBuilder" "Done."
}

#Usage : kernelPackager <linux_dir> <config_dir> <arch> <eabi> <config> <cflags> [<MKIMAGE> <FIRMWARE>]
function kernelPackager {
  local TMP_BUILD_WRKDIR="${1}"
  local TMP_BUILD_CFGTYP="${2}"
  local TMP_BUILD_CONFIG="${3}"
  local TMP_BUILD_CPUARC="${4}"
  local TMP_BUILD_CPUABI="${5}"
  local TMP_BUILD_CFLAGS="${6}"
  local TMP_BUILD_MKIMAG="${7}"
  local TMP_BUILD_FIRMWR="${8}"

  local TMP_BUILD_SCRDST="${TMP_BUILD_WRKDIR}/scripts/package/"  

  if [ -f "${TMP_BUILD_CFGDIR}/builddeb" ]; then
    local TMP_BUILD_SCRSRC="${TMP_BUILD_CFGDIR}/builddeb"
  else
    local TMP_BUILD_SCRSRC="${ARMSTRAP_BOARDS}/.defaults/kernel/builddeb"
  fi
  
  export KBUILD_DEBARCH="${TMP_BUILD_CPUARC}${TMP_BUILD_CPUABI}"
  export DEBEMAIL="eddy@beaupre.biz"
  export DEBFULLNAME="Eddy Beaupre" 
  export EXPORT_ARMSTRAP_TARGET="${TMP_BUILD_CFGTYP}-"
  export EXPORT_ARMSTRAP_RELEASE="-${TMP_BUILD_CONFIG}"
  export EXPORT_ARMSTRAP_REPOS="${TMP_BUILD_CFGTYP}"
  if [ ! -z "${TMP_BUILD_MKIMAG}" ]; then 
    export EXPORT_ARMSTRAP_MKIMAGE="${TMP_BUILD_MKIMAG}"
  fi
  if [ ! -z "${TMP_BUILD_FIRMWR}" ]; then 
    export EXPORT_ARMSTRAP_FIRMWARE="${TMP_BUILD_FIRMWR}"
  fi

  cp -v "${TMP_BUILD_SCRSRC}" "${TMP_BUILD_SCRDST}/" >> ${ARMSTRAP_LOG_FILE} 2>&1

  printStatus "kernelBuilder" "Creating Debian packages"
  kernelMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" deb-pkg
  checkStatus "Error while creating Debian packages"
  
  cd "${TMP_BUILD_WRKDIR}/.."
  
  printStatus "buildKernel" "Building Kernel packages."
  
  local TMP_KERNEL_SCR=""
  local TMP_KERNEL_IMG=""
  local TMP_KERNEL_HDR=""
  local TMP_KERNEL_LBC=""
  local TMP_KERNEL_FWR=""
  
  local TMP_I=""
  
  for TMP_I in *.deb; do 
    local TMP_STR="`echo ${TMP_I} | cut -d'_' -f1`"
    
    if [[ $TMP_STR == *image-* ]]; then
      TMP_KERNEL_SCR="${TMP_I/image/kernel}"
      TMP_KERNEL_SCR="${TMP_KERNEL_SCR/.deb/.sh}"
      TMP_KERNEL_SCR="${ARMSTRAP_PKG}/install-${TMP_KERNEL_SCR}"
      TMP_KERNEL_IMG="$TMP_STR"
    fi
    
    if [[ $TMP_STR == *headers-* ]]; then
      TMP_KERNEL_HDR="$TMP_STR"
    fi
	
    if [[ $TMP_STR == *libc-* ]]; then
      TMP_KERNEL_LBC="$TMP_STR"
    fi
	
    if [[ $TMP_STR == *firmware-* ]]; then
      TMP_KERNEL_FWR="$TMP_STR"
    fi
  
  done

  rm -f ${TMP_KERNEL_SCR}
  touch ${TMP_KERNEL_SCR}

  echo "#!/bin/sh" >> ${TMP_KERNEL_SCR}
  echo "" >> ${TMP_KERNEL_SCR}
  echo "KERNEL_IMG=\"${TMP_KERNEL_IMG}\"" >> ${TMP_KERNEL_SCR}
  echo "KERNEL_HDR=\"${TMP_KERNEL_HDR}\"" >> ${TMP_KERNEL_SCR}
  echo "KERNEL_LBC=\"${TMP_KERNEL_LBC}\"" >> ${TMP_KERNEL_SCR}
  echo "KERNEL_FWR=\"${TMP_KERNEL_FWR}\"" >> ${TMP_KERNEL_SCR}
  echo "" >> ${TMP_KERNEL_SCR}
  echo "touch /etc/apt/sources.list.d/armstrap.list" >> ${TMP_KERNEL_SCR}
  echo "echo \"deb http://packages.vls.beaupre.biz/apt/armstrap/ ${TMP_BUILD_CFGTYP} main\" >> /etc/apt/sources.list.d/armstrap.list" >> ${TMP_KERNEL_SCR}
  echo "echo \"deb-src http://packages.vls.beaupre.biz/apt/armstrap/ ${TMP_BUILD_CFGTYP} main\" >> /etc/apt/sources.list.d/armstrap.list" >> ${TMP_KERNEL_SCR}
  echo "TMP_GNUPGHOME=\"\${GNUPGHOME}\"" >> ${TMP_KERNEL_SCR}
  echo "export GNUPGHOME=\"\`mktemp -d\`\"" >> ${TMP_KERNEL_SCR}
  echo "chown \${USER}:\${USER} \${GNUPGHOME}" >> ${TMP_KERNEL_SCR}
  echo "chmod 0700 \${GNUPGHOME}" >> ${TMP_KERNEL_SCR}
  echo "gpg --keyserver pgpkeys.mit.edu --recv-key 1F7F94D7A99BC726" >> ${TMP_KERNEL_SCR}
  echo "gpg --armor --export 1F7F94D7A99BC726 | apt-key add -" >> ${TMP_KERNEL_SCR}
  echo "rm -rf \${GNUPGHOME}" >> ${TMP_KERNEL_SCR}
  echo "GNUPGHOME=\"\${TMP_GNUPGHOME}\"" >> ${TMP_KERNEL_SCR}
  echo "/usr/bin/debconf-apt-progress \${1} -- /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true update" >> ${TMP_KERNEL_SCR}
  echo "/usr/bin/debconf-apt-progress \${1} -- /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true install \${KERNEL_IMG} \${KERNEL_HDR} \${KERNEL_FWR}" >> ${TMP_KERNEL_SCR}
  
  for TMP_I in *.deb; do
    printStatus "kernelBuilder" "Moving `basename ${TMP_I}` to ${ARMSTRAP_PKG}"
    rm -f "${ARMSTRAP_PKG}/`basename ${TMP_I}`"
    mv "${TMP_I}" "${ARMSTRAP_PKG}"
  done
  
  cd "${TMP_BUILD_CURDIR}"
  
  printStatus "kernelBuilder" "Kernel build successfull."
  
  unset KBUILD_DEBARCH
  unset DEBEMAIL
  unset DEBFULLNAME
  unset EXPORT_ARMSTRAP_TARGET
  unset EXPORT_ARMSTRAP_RELEASE
  unset EXPORT_ARMSTRAP_REPOS
  if [ ! -z "${EXPORT_ARMSTRAP_MKIMAGE}" ]; then 
    unset EXPORT_ARMSTRAP_MKIMAGE
  fi
  if [ ! -z "${EXPORT_ARMSTRAP_FIRMWARE}" ]; then 
    unset EXPORT_ARMSTRAP_FIRMWARE
  fi
}

function kernelMake {
  local TMP_CPUARC="${1}"
  local TMP_CPUABI="${2}"
  local TMP_WRKDIR="${3}"
  local TMP_CFLAGS="${4}"
  local TMP_CCPREF="${TMP_CPUARC}-linux-gnueabi${TMP_CPUABI}"
  local TMP_ARCABI="${TMP_CPUARC}${TMP_CPUABI}"
  shift
  shift
  shift
  shift
  
  if [ -z "${TMP_CFLAGS}" ]; then
    CC=${TMP_CCPREF}-gcc dpkg-architecture -a${TMP_ARCABI} -t${TMP_CCPREF} -c make ARCH="${TMP_CPUARC}" CROSS_COMPILE="${TMP_CCPREF}-" -C "${TMP_WRKDIR}" ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  else
    CC=${TMP_CCPREF}-gcc dpkg-architecture -a${TMP_ARCABI} -t${TMP_CCPREF} -c make CFLAGS="${TMP_CFLAGS}" CXXFLAGS="${TMP_CFLAGS}" ARCH="${TMP_CPUARC}" CROSS_COMPILE="${TMP_CCPREF}-" -C "${TMP_WRKDIR}" ${@} >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
}

function kernelMakeNoLog {
  local TMP_CPUARC="${1}"
  local TMP_CPUABI="${2}"
  local TMP_WRKDIR="${3}"
  local TMP_CFLAGS="${4}"
  local TMP_CCPREF="${TMP_CPUARC}-linux-gnueabi${TMP_CPUABI}"
  local TMP_ARCABI="${TMP_CPUARC}${TMP_CPUABI}"
  shift
  shift
  shift
  shift
  
  if [ -z "${TMP_CFLAGS}" ]; then
    CC=${TMP_CCPREF}-gcc dpkg-architecture -a${TMP_ARCABI} -t${TMP_CCPREF} -c make ARCH="${TMP_CPUARC}" CROSS_COMPILE="${TMP_CCPREF}-" -C "${TMP_WRKDIR}" ${@}
  else
    CC=${TMP_CCPREF}-gcc dpkg-architecture -a${TMP_ARCABI} -t${TMP_CCPREF} -c make CFLAGS="${TMP_CFLAGS}" CXXFLAGS="${TMP_CFLAGS}" ARCH="${TMP_CPUARC}" CROSS_COMPILE="${TMP_CCPREF}-" -C "${TMP_WRKDIR}" ${@}
  fi
}

function kernelConf {
  printStatus "kernelBuilder" "----------------------------------------"
  printStatus "kernelBuilder" "-         Board : ${1}"
  printStatus "kernelBuilder" "-          Type : ${2}"
  if [ ! -z "${4}" ]; then
    printStatus "kernelBuilder" "-        Kernel : ${4}"
  fi
  printStatus "kernelBuilder" "- Configuration : ${3}"
  printStatus "kernelBuilder" "----------------------------------------"
}

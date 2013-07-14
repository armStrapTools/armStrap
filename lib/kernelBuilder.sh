
#Usage : kernelBuilder <linux_dir> <script_dir> <debian_repos> <arch> <type> <config>
function kernelBuilder {
  local TMP_BUILD_CURDIR="`pwd`"
  local TMP_BUILD_WRKDIR="${1}"
  local TMP_BUILD_CFGDIR="${2}"
  local TMP_BUILD_DEBREP="${3}"
  local TMP_BUILD_CFGARC="${4}"
  local TMP_BUILD_CFGTYP="${5}"
  local TMP_BUILD_CONFIG="${6}"

  local TMP_BUILD_CFGDEF="${TMP_BUILD_CFGDIR}/${TMP_BUILD_CFGTYP}-${TMP_BUILD_CONFIG}_defconfig"
  local TMP_BUILD_SCRSRC="${TMP_BUILD_CFGDIR}/builddeb"
  
  local TMP_BUILD_CFGDST="${TMP_BUILD_WRKDIR}/arch/${TMP_BUILD_CFGARC}/configs"
  local TMP_BUILD_SCRDST="${TMP_BUILD_WRKDIR}/scripts/package/"
  
  export KBUILD_DEBARCH="armhf"
  export DEBEMAIL="eddy@beaupre.biz"
  export DEBFULLNAME="Eddy Beaupre" 
  export EXPORT_ARMSTRAP_TARGET="${TMP_BUILD_DEBREP}-"
  export EXPORT_ARMSTRAP_RELEASE="-${TMP_BUILD_CONFIG}"
  export EXPORT_ARMSTRAP_REPOS="${TMP_BUILD_DEBREP}"
  
  printStatus "kernelBuilder" "Configuring for ${TMP_BUILD_DEBREP} (${TMP_BUILD_CFGTYP}-${TMP_BUILD_CONFIG})"
  cp "${TMP_BUILD_CFGDEF}" "${TMP_BUILD_CFGDST}/"
  cp "${TMP_BUILD_SCRSRC}" "${TMP_BUILD_SCRDST}/"
  
  printStatus "kernelBuilder" "Cleaning Kernel source directory"
  CC=arm-linux-gnueabihf-gcc dpkg-architecture -aarmhf -tarm-linux-gnueabihf -c make ARCH="arm" CROSS_COMPILE="arm-linux-gnueabihf-" -C "${TMP_BUILD_WRKDIR}" distclean >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "Cannot clean kernel source directory."

  cd "${TMP_BUILD_WRKDIR}/.."
  rm -f *.deb
  cd "${ARMSTRAP_ROOT}"
  
  printStatus "kernelBuilder" "Configuring Kernel"
  CC=arm-linux-gnueabihf-gcc dpkg-architecture -aarmhf -tarm-linux-gnueabihf -c make ARCH="arm" CROSS_COMPILE="arm-linux-gnueabihf-" -C "${TMP_BUILD_WRKDIR}" "`basename ${TMP_BUILD_CFGDEF}`" >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "Error while configuring Kernel"
  
  isTrue "${ARMSTRAP_KBUILDER_MENUCONFIG}"
  if [ $? -ne 0 ]; then
    CC=arm-linux-gnueabihf-gcc dpkg-architecture -aarmhf -tarm-linux-gnueabihf -c make ARCH="arm" CROSS_COMPILE="arm-linux-gnueabihf-" -C "${TMP_BUILD_WRKDIR}" menuconfig
    TMP_BUILD_CONFIG="custom"
    TMP_BUILD_CFGDEF="${TMP_BUILD_CFGDIR}/${TMP_BUILD_CFGTYP}-${TMP_BUILD_CONFIG}_defconfig"
    export EXPORT_ARMSTRAP_RELEASE="-${TMP_BUILD_CONFIG}"
    
    promptYN "Do you want to save this config to be able to use it another time?"
    if [ $? -ne 1 ]; then
      printStatus "kernelBuilder" "Saving configuration as ${TMP_BUILD_CFGTYP}-custom_defconfig"
      cp "${TMP_BUILD_WRKDIR}/.config" "${TMP_BUILD_CFGDIR}/${TMP_BUILD_CFGTYP}-custom_defconfig"
    fi
  fi
  
  printStatus "kernelBuilder" "Building Kernel image"
  CC=arm-linux-gnueabihf-gcc dpkg-architecture -aarmhf -tarm-linux-gnueabihf -c make -j4 ARCH="arm" CROSS_COMPILE="arm-linux-gnueabihf-" -C "${TMP_BUILD_WRKDIR}" uImage >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "Error while building kernel image"
  
  printStatus "kernelBuilder" "Building Kernel Modules"
  CC=arm-linux-gnueabihf-gcc dpkg-architecture -aarmhf -tarm-linux-gnueabihf -c make -j4 ARCH="arm" CROSS_COMPILE="arm-linux-gnueabihf-" -C "${TMP_BUILD_WRKDIR}" modules >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "Error while building Kernel Modules"
  
  printStatus "kernelBuilder" "Creating Debian packages"
  CC=arm-linux-gnueabihf-gcc dpkg-architecture -aarmhf -tarm-linux-gnueabihf -c make ARCH="arm" CROSS_COMPILE="arm-linux-gnueabihf-" -C "${TMP_BUILD_WRKDIR}" deb-pkg >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "Error while creating Debian packages"
  
  cd "${TMP_BUILD_WRKDIR}/.."
  
  printStatus "buildKernel" "Building Kernel packages."
  
  local TMP_KERNEL_IMG=""
  local TMP_KERNEL_HDR=""
  local TMP_KERNEL_LBC=""
  local TMP_KERNEL_FWR=""
  
  local TMP_KERNEL_CHANGES=""
  local TMP_KERNEL_BUILDLOG=""
  local TMP_SCRIPT=""
  
  for i in *.deb; do 
    str="`echo $i | cut -d'_' -f1`"
    
    if [[ $str == *image-* ]]; then
      TMP_KERNEL_SCR="${i/image/kernel}"
      TMP_KERNEL_SCR="${TMP_KERNEL_SCR/.deb/.sh}"
      TMP_KERNEL_SCRIPT="/var/www/armstrap/kernel/${TMP_BUILD_DEBREP}/install-${TMP_KERNEL_SCR}"
      TMP_KERNEL_IMG="$str"
    fi
    
    if [[ $str == *headers-* ]]; then
      TMP_KERNEL_HDR="$str"
    fi
	
    if [[ $str == *libc-* ]]; then
      TMP_KERNEL_LBC="$str"
    fi
	
    if [[ $str == *firmware-* ]]; then
      TMP_KERNEL_FWR="$str"
    fi
  
  done

  printStatus "buildKernel" "Creating Kernel installation script."
  if [ ! -d "`dirname ${TMP_KERNEL_SCRIPT}`" ]; then
    mkdir -p `dirname ${TMP_KERNEL_SCRIPT}`
  fi

  rm -f ${TMP_KERNEL_SCRIPT}
  touch ${TMP_KERNEL_SCRIPT}

  echo "#!/bin/sh" >> ${TMP_KERNEL_SCRIPT}
  echo "" >> ${TMP_KERNEL_SCRIPT}

  echo "KERNEL_IMG=\"${TMP_KERNEL_IMG}\"" >> ${TMP_KERNEL_SCRIPT}
  echo "KERNEL_HDR=\"${TMP_KERNEL_HDR}\"" >> ${TMP_KERNEL_SCRIPT}
  echo "KERNEL_LBC=\"${TMP_KERNEL_LBC}\"" >> ${TMP_KERNEL_SCRIPT}
  echo "KERNEL_FWR=\"${TMP_KERNEL_FWR}\"" >> ${TMP_KERNEL_SCRIPT}

  echo "" >> ${TMP_KERNEL_SCRIPT}
  echo "echo \"deb http://packages.vls.beaupre.biz/apt/armstrap/ ${TMP_BUILD_DEBREP} main\" > /etc/apt/sources.list.d/${BUILDEB_TARGET}armstrap.list" >> ${TMP_KERNEL_SCRIPT}
  echo "echo \"deb-src http://packages.vls.beaupre.biz/apt/armstrap/ ${TMP_BUILD_DEBREP} main\" >> /etc/apt/sources.list.d/${BUILDEB_TARGET}armstrap.list" >> ${TMP_KERNEL_SCRIPT}
  echo "TMP_GNUPGHOME=\"\${GNUPGHOME}\"" >> ${TMP_KERNEL_SCRIPT}
  echo "export GNUPGHOME=\"\`mktemp -d\`\"" >> ${TMP_KERNEL_SCRIPT}
  echo "chown \${USER}:\${USER} \${GNUPGHOME}" >> ${TMP_KERNEL_SCRIPT}
  echo "chmod 0700 \${GNUPGHOME}" >> ${TMP_KERNEL_SCRIPT}
  echo "gpg --keyserver pgpkeys.mit.edu --recv-key 1F7F94D7A99BC726" >> ${TMP_KERNEL_SCRIPT}
  echo "gpg --armor --export 1F7F94D7A99BC726 | apt-key add -" >> ${TMP_KERNEL_SCRIPT}
  echo "rm -rf \${GNUPGHOME}" >> ${TMP_KERNEL_SCRIPT}
  echo "GNUPGHOME=\"\${TMP_GNUPGHOME}\"" >> ${TMP_KERNEL_SCRIPT}
  echo "/usr/bin/debconf-apt-progress \${1} -- /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true update" >> ${TMP_KERNEL_SCRIPT}
  echo "/usr/bin/debconf-apt-progress \${1} -- /usr/bin/apt-get -q -y -o APT::Install-Recommends=true -o APT::Get::AutomaticRemove=true install \$KERNEL_IMG \$KERNEL_HDR \$KERNEL_FWR" >> ${TMP_KERNEL_SCRIPT}
  
  for i in *.deb ${TMP_KERNEL_SCRIPT}; do
    printStatus "kernelBuilder" "Moving `basename ${i}` to ${ARMSTRAP_PKG}"
    mv "${i}" "${ARMSTRAP_PKG}"
  done
  
  cd "${ARMSTRAP_ROOT}"
  
  printStatus "kernelBuilder" "Kernel build successfull."
  
  unset KBUILD_DEBARCH
  unset DEBEMAIL
  unset DEBFULLNAME
  unset EXPORT_ARMSTRAP_TARGET
  unset EXPORT_ARMSTRAP_RELEASE
  unset EXPORT_ARMSTRAP_REPOS
  
}

function kernelConf {
  printf "\n${ANS_BLD}${ANS_SUL}${ANF_CYN}% 20s${ANS_RST}\n\n" "KERNEL BUILDER"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Board" "${1}"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Type" "${2}"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n\n" "Configuration" "${3}"
  
}

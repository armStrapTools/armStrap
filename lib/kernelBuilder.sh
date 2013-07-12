
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
  export ARMSTRAP_TARGET="${TMP_BUILD_DEBREP}-"
  export ARMSTRAP_RELEASE="-${TMP_BUILD_CONFIG}"
  export ARMSTRAP_REPOS="${TMP_BUILD_DEBREP}"
  
  printStatus "kernelBuilder" "Configuring for ${TMP_BUILD_DEBREP} (${TMP_BUILD_CFGTYP}-${TMP_BUILD_CONFIG})"
  cp "${TMP_BUILD_CFGDEF}" "${TMP_BUILD_CFGDST}/"
  cp "${TMP_BUILD_SCRSRC}" "${TMP_BUILD_SCRDST}/"
  
  printStatus "kernelBuilder" "Cleaning Kernel source directory"
  CC=arm-linux-gnueabihf-gcc dpkg-architecture -aarmhf -tarm-linux-gnueabihf -c make ARCH="arm" CROSS_COMPILE="arm-linux-gnueabihf-" -C "${TMP_BUILD_WRKDIR}" distclean >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "Cannot clean kernel source directory."
  
  printStatus "kernelBuilder" "Configuring Kernel"
  CC=arm-linux-gnueabihf-gcc dpkg-architecture -aarmhf -tarm-linux-gnueabihf -c make ARCH="arm" CROSS_COMPILE="arm-linux-gnueabihf-" -C "${TMP_BUILD_WRKDIR}" "`basename ${TMP_BUILD_CFGDEF}`" >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkStatus "Error while configuring Kernel"
  
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
  for i in *.deb; do
    printStatus "kernelBuilder" "Moving `basename ${i}` to ${ARMSTRAP_DEB}"
    mv "${i}" "${ARMSTRAP_DEB}"
  done
  cd "${ARMSTRAP_ROOT}"
  
  printStatus "kernelBuilder" "Kernel build successfull."
  
  unset KBUILD_DEBARCH
  unset DEBEMAIL
  unset DEBFULLNAME
  unset ARMSTRAP_TARGET
  unset ARMSTRAP_RELEASE
  
}

function kernelConf {
  printf "\n${ANS_BLD}${ANS_SUL}${ANF_CYN}% 20s${ANS_RST}\n\n" "KERNEL BUILDER"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Board" "${1}"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n" "Type" "${2}"
  printf "${ANF_GRN}% 20s${ANS_RST}: %s\n\n" "Configuration" "${3}"
  
}

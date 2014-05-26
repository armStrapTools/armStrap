
#Usage : kernelMake <linux_dir> <config_dir> <type> <arch> <eabi> <config> <cflags> [<pre_hook> [<post_hook>]]
function kernelMake {
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
    printStatus "kernelMake" "Executing Pre-Build hook"
    ${TMP_BUILD_PRHOOK}
  fi

  ARMSTRAP_GUI_PCT=$(guiWriter "add"  5 "Cleaning")
  printStatus "kernelMake" "Cleaning Kernel source directory"
  ccMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" distclean
  checkStatus "Cannot clean kernel source directory."

  ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Configuring")  
  printStatus "kernelMake" "Configuring Kernel"
  cp -v "${TMP_BUILD_CFGDEF}" "${TMP_BUILD_CFGDST}/" >> ${ARMSTRAP_LOG_FILE} 2>&1
  ccMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" "`basename ${TMP_BUILD_CFGDEF}`"
  checkStatus "Error while configuring Kernel"
  
  isTrue "${ARMSTRAP_KBUILDER_MENUCONFIG}"
  if [ $? -ne 0 ]; then
    local TMP_GUI
    guiStop
    ccMakeNoLog "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" menuconfig
    TMP_BUILD_CONFIG="custom"
    TMP_BUILD_CFGDEF="${TMP_BUILD_CFGDIR}/${TMP_BUILD_CFGTYP}-${TMP_BUILD_CONFIG}_defconfig"
    export EXPORT_ARMSTRAP_RELEASE="-${TMP_BUILD_CONFIG}"
    
    promptYN "Do you want to save this config to be able to use it another time?"
    if [ $? -ne 1 ]; then
      printStatus "kernelMake" "Saving configuration as ${TMP_BUILD_CFGTYP}-custom_defconfig"
      cp -v "${TMP_BUILD_WRKDIR}/.config" "${TMP_BUILD_CFGDIR}/${TMP_BUILD_CFGTYP}-custom_defconfig" >> ${ARMSTRAP_LOG_FILE} 2>&1
    fi
    guiStart
    TMP_GUI=$(guiWriter "name" "armStrap")
    TMP_GUI=$(guiWriter "start" "Kernel Builder" "Progress")
  fi
  
  printStatus "kernelMake" "Building Kernel image"
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  4 "Building kernel image")  
  ccMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" ${BUILD_KERNEL_PARAM} uImage ${BUILD_KERNEL_EXTRA_MAKE}
  checkStatus "Error while building kernel image"
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  30 "Building kernel modules")  
  printStatus "kernelMake" "Building Kernel Modules"
  ccMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" ${BUILD_KERNEL_PARAM} modules
  checkStatus "Error while building Kernel Modules"
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  30 "Building kernel modules")  
  funExist ${TMP_BUILD_PSHOOK}
  if [ ${?} -eq 0 ]; then
    printStatus "kernelMake" "Executing Post-Build hook"
    ${TMP_BUILD_PSHOOK}
  fi
  
  printStatus "kernelMake" "Done."
}

#Usage : kernelPack <linux_dir> <config_dir> <arch> <eabi> <config> <cflags> [<MKIMAGE> <FIRMWARE>]
function kernelPack {
  local TMP_BUILD_WRKDIR="${1}"
  local TMP_BUILD_CFGDIR="${2}"
  local TMP_BUILD_CFGTYP="${3}"
  local TMP_BUILD_CPUARC="${4}"
  local TMP_BUILD_CPUABI="${5}"
  local TMP_BUILD_CONFIG="${6}"
  local TMP_BUILD_CFLAGS="${7}"
  local TMP_BUILD_MKIMAG="${8}"
  local TMP_BUILD_FIRMWR="${9}"
  
  local TMP_BUILD_SCRDST="${TMP_BUILD_WRKDIR}/scripts/package/"  
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Packaging Kernel")  
  
  if [ -f "${TMP_BUILD_CFGDIR}/builddeb" ]; then
    local TMP_BUILD_SCRSRC="${TMP_BUILD_CFGDIR}/builddeb"
  else
    local TMP_BUILD_SCRSRC="${ARMSTRAP_KERNELS}/.defaults/builddeb"
  fi
  
  export KBUILD_DEBARCH="${TMP_BUILD_CPUARC}${TMP_BUILD_CPUABI}"
  export DEBEMAIL="eddy@beaupre.biz"
  export DEBFULLNAME="Eddy Beaupre" 
  export EXPORT_ARMSTRAP_TARGET="${TMP_BUILD_CFGTYP}-"
  export EXPORT_ARMSTRAP_RELEASE="-${TMP_BUILD_CONFIG}"
  export EXPORT_ARMSTRAP_REPOS="${TMP_BUILD_CFGTYP}"
  export EXPORT_ARMSTRAP_EXTRA_DEB="${BUILD_KERNEL_EXTRA_DEB}"
  if [ ! -z "${TMP_BUILD_MKIMAG}" ]; then 
    export EXPORT_ARMSTRAP_MKIMAGE="${TMP_BUILD_MKIMAG}"
  fi
  if [ ! -z "${TMP_BUILD_FIRMWR}" ]; then 
    export EXPORT_ARMSTRAP_FIRMWARE="${TMP_BUILD_FIRMWR}"
  fi

  cp -v "${TMP_BUILD_SCRSRC}" "${TMP_BUILD_SCRDST}/" >> ${ARMSTRAP_LOG_FILE} 2>&1

  printStatus "kernelMake" "Creating Debian packages"
  ccMake "${TMP_BUILD_CPUARC}" "${TMP_BUILD_CPUABI}" "${TMP_BUILD_WRKDIR}" "${TMP_BUILD_CFLAGS}" deb-pkg
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
    local TMP_STR="${TMP_I%%_*}"
#    "`echo ${TMP_I} | cut -d'_' -f1`"
    
    if [[ $TMP_STR == *image-* ]]; then
      TMP_KERNEL_SCR="${TMP_I/image/kernel}"
      TMP_KERNEL_SCR="${TMP_KERNEL_SCR/.deb/.sh}"
      TMP_KERNEL_SCR="${ARMSTRAP_PKG}/${TMP_KERNEL_SCR}"
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
  echo "echo \"deb ${ARMSTRAP_ABUILDER_REPO_URL} ${TMP_BUILD_CFGTYP} main\" >> /etc/apt/sources.list.d/armstrap.list" >> ${TMP_KERNEL_SCR}
  echo "echo \"deb-src ${ARMSTRAP_ABUILDER_REPO_URL} ${TMP_BUILD_CFGTYP} main\" >> /etc/apt/sources.list.d/armstrap.list" >> ${TMP_KERNEL_SCR}
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
    printStatus "kernelMake" "Moving `basename ${TMP_I}` to ${ARMSTRAP_PKG}"
    rm -f "${ARMSTRAP_PKG}/`basename ${TMP_I}`"
    mv "${TMP_I}" "${ARMSTRAP_PKG}"
  done
  
  cd "${TMP_BUILD_CURDIR}"
  
  printStatus "kernelMake" "Kernel build successfull."
  
  unset KBUILD_DEBARCH
  unset DEBEMAIL
  unset DEBFULLNAME
  unset EXPORT_ARMSTRAP_TARGET
  unset EXPORT_ARMSTRAP_RELEASE
  unset EXPORT_ARMSTRAP_REPOS
  unset EXPORT_ARMSTRAP_EXTRA_DEB
  if [ ! -z "${EXPORT_ARMSTRAP_MKIMAGE}" ]; then 
    unset EXPORT_ARMSTRAP_MKIMAGE
  fi
  if [ ! -z "${EXPORT_ARMSTRAP_FIRMWARE}" ]; then 
    unset EXPORT_ARMSTRAP_FIRMWARE
  fi
  
  
  
  ARMSTRAP_GUI_PCT=$(guiWriter "add"  9 "Packaging Kernel")  
}

# usage kernelBuild <FAMILY>
function kernelBuild {
  local TMP_KRNDIR="${ARMSTRAP_KERNELS}/${1}"
  local TMP_LOG="${ARMSTRAP_LOG}/armStrap-Kernel_${1}_${ARMSTRAP_DATE}.log"
  if [ -f "${TMP_KRNDIR}/config.sh" ]; then
    local TMP_GUI
    ARMSTRAP_GUI_PCT=0
    guiStart
    TMP_GUI=$(guiWriter "name" "armStrap")
    TMP_GUI=$(guiWriter "start" "Kernel Builder (${1})" "Progress")
    printStatus "kernelBuild" "Kernel Builder"
    source ${TMP_KRNDIR}/config.sh
    rm -f ${TMP_LOG}
    mv ${ARMSTRAP_LOG_FILE} ${TMP_LOG}
    ARMSTRAP_LOG_FILE="${TMP_LOG}"
    ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Initializing kernel builder for ${1}")
    gitClone "${BUILD_KERNEL_SOURCE}" "${BUILD_KERNEL_GITSRC}" "${BUILD_KERNEL_GITBRN}"
    ARMSTRAP_GUI_PCT=$(guiWriter "add"  19 "Building kernel for ${1}")
    kernelMake "${BUILD_KERNEL_SOURCE}" "${TMP_KRNDIR}" "${BUILD_KERNEL_TYPE}" "${BUILD_KERNEL_ARCH}" "${BUILD_KERNEL_EABI}" "${BUILD_KERNEL_CONF}" "${BUILD_KERNEL_CFLAGS}" "${BUILD_KERNEL_PREHOOK}" "${BUILD_KERNEL_PSTHOOK}"
    kernelPack "${BUILD_KERNEL_SOURCE}" "${TMP_KRNDIR}" "${BUILD_KERNEL_TYPE}" "${BUILD_KERNEL_ARCH}" "${BUILD_KERNEL_EABI}" "${BUILD_KERNEL_CONF}" "${BUILD_KERNEL_CFLAGS}" "${BUILD_KERNEL_MKIMAGE}" "${BUILD_KERNEL_FIRMWARE_SRC}"
    ccMake "${BUILD_KERNEL_ARCH}" "${BUILD_KERNEL_EABI}" "${BUILD_KERNEL_SOURCE}" "${BUILD_KERNEL_CFLAGS}" distclean
    ARMSTRAP_GUI_PCT=$(guiWriter "add"  5 "Done")
    printStatus "kernelBuild" "Kernel Builder Done"
    unsetEnv "BUILD_KERNEL_"
    guiStop
  else
    printStatus "kernelBuild" "Kernel Builder is not avalable for ${1}"
  fi
}

# Usage bootBuilder <bootloader_type> <bootloader_family>
function bootBuilder {
  local TMP_BLRDIR="${ARMSTRAP_BOOTLOADERS}/${1}"
  local TMP_BLRCFG="${TMP_BLRDIR}/${2}"
  local TMP_LOG="${ARMSTRAP_LOG}/armStrap-BootLoader_${1}-${2}_${ARMSTRAP_DATE}.log"

  if [ -f "${TMP_BLRCFG}/config.sh" ]; then
    local TMP_GUI
    ARMSTRAP_GUI_PCT=0
    guiStart
    TMP_GUI=$(guiWriter "name" "armStrap")
    TMP_GUI=$(guiWriter "start" "BootLoader Builder (${1}/${2})" "Progress")
    unsetEnv "BUILD_BOOTLOADER_"
    BUILD_BOOTLOADER_TYPE="${1}"
    printStatus "bootBuilder" "Loading configuration for ${1} (${2})"
    source ${TMP_BLRCFG}/config.sh
    rm -f ${TMP_LOG}
    mv ${ARMSTRAP_LOG_FILE} ${TMP_LOG}
    ARMSTRAP_LOG_FILE="${TMP_LOG}"
    case ${BUILD_BOOTLOADER_TYPE} in
      u-boot-sunxi*) ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Initializing ${BUILD_BOOTLOADER_TYPE} for ${BUILD_BOOTLOADER_NAME}")
                      printStatus "bootBuilder" "Initializing ${BUILD_BOOTLOADER_TYPE} for ${BUILD_BOOTLOADER_NAME}"
                      gitClone "${BUILD_BOOTLOADER_SOURCE}" "${BUILD_BOOTLOADER_GITSRC}" "${BUILD_BOOTLOADER_GITBRN}"
                      ARMSTRAP_GUI_PCT=$(guiWriter "add"  19 "Initializing ${BUILD_BOOTLOADER_TYPE} for ${BUILD_BOOTLOADER_NAME}")
                      gitClone "${BUILD_BOOTLOADER_FEXSRC}" "${BUILD_BOOTLOADER_FEXGIT}" "${BUILD_BOOTLOADER_FEXBRN}"
                      ARMSTRAP_GUI_PCT=$(guiWriter "add"  5 "Cleaning")
                      printStatus "bootBuilder" "Cleaning ${BUILD_BOOTLOADER_TYPE}"
                      ccMake "${BUILD_BOOTLOADER_ARCH}" "${BUILD_BOOTLOADER_EABI}" "${BUILD_BOOTLOADER_SOURCE}" "${BUILD_BOOTLOADER_CFLAGS}" distclean
                      ARMSTRAP_GUI_PCT=$(guiWriter "add"  5 "Building")
                      printStatus "bootBuilder" "Building ${BUILD_BOOTLOADER_TYPE}"
                      ccMake "${BUILD_BOOTLOADER_ARCH}" "${BUILD_BOOTLOADER_EABI}" "${BUILD_BOOTLOADER_SOURCE}" "${BUILD_BOOTLOADER_CFLAGS}" "${BUILD_BOOTLOADER_FAMILY}_config"
                      ccMake "${BUILD_BOOTLOADER_ARCH}" "${BUILD_BOOTLOADER_EABI}" "${BUILD_BOOTLOADER_SOURCE}" "${BUILD_BOOTLOADER_CFLAGS}" "${BUILD_BOOTLOADER_TARGET}"
                      ARMSTRAP_GUI_PCT=$(guiWriter "add"  50 "Building")
                      checkDirectory "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}"
                      printStatus "bootBuilder" "Packaging ${BUILD_BOOTLOADER_TYPE}"
                      ARMSTRAP_GUI_PCT=$(guiWriter "add"  10 "Packaging")
                      if [ -f "${BUILD_BOOTLOADER_SOURCE}/u-boot-sunxi-with-spl.bin" ]; then
                        cp -v "${BUILD_BOOTLOADER_SOURCE}/u-boot-sunxi-with-spl.bin" "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      fi
                      if [ -f "${BUILD_BOOTLOADER_SOURCE}/u-boot.bin" ]; then
                        cp -v "${BUILD_BOOTLOADER_SOURCE}/u-boot.bin" "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      fi
                      if [ -f "${BUILD_BOOTLOADER_SOURCE}/u-boot.img" ]; then
                        cp -v "${BUILD_BOOTLOADER_SOURCE}/u-boot.img" "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      fi
                      if [ -f "${BUILD_BOOTLOADER_SOURCE}/spl/sunxi-spl.bin" ]; then
                        cp -v "${BUILD_BOOTLOADER_SOURCE}/spl/sunxi-spl.bin" "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      fi
                      cp -v "${BUILD_BOOTLOADER_FEXSRC}/sys_config/${BUILD_BOOTLOADER_CPU}/${BUILD_BOOTLOADER_FEX,,}" "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      if [ -f "${TMP_BLRDIR}/.defaults/readme.txt" ]; then
                        cp -v "${TMP_BLRDIR}/.defaults/readme.txt" "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      fi
                      if [ -f "${TMP_BLRCFG}/readme.txt" ]; then
                        cp -v "${TMP_BLRCFG}/readme.txt" "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}/readme_${2}.txt" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      fi
                      ARMSTRAP_GUI_PCT=$(guiWriter "add"  5 "Packaging")
                      ${ARMSTRAP_TAR_COMPRESS} "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_NAME,,}-${BUILD_BOOTLOADER_TYPE}${ARMSTRAP_TAR_EXTENSION}" -C "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}" --one-file-system . >> ${ARMSTRAP_LOG_FILE} 2>&1
                      ARMSTRAP_GUI_PCT=$(guiWriter "add"  5 "Cleaning up")
                      rm -rf "${ARMSTRAP_PKG}/${BUILD_BOOTLOADER_TYPE}_${BUILD_BOOTLOADER_NAME}" >> ${ARMSTRAP_LOG_FILE} 2>&1
                      ccMake "${BUILD_BOOTLOADER_ARCH}" "${BUILD_BOOTLOADER_EABI}" "${BUILD_BOOTLOADER_SOURCE}" "${BUILD_BOOTLOADER_CFLAGS}" distclean
                      unsetEnv "BUILD_BOOTLOADER_"
                      printStatus "bootBuilder" "Builder done."
                      ;;
                   *) printStatus "bootBuilder" "Builder is not avalable for ${1}"
                      ;;
    esac
    unsetEnv "BUILD_BOOTLOADER_"
    guiStop
  else
    printStatus "bootBuilder" "Builder is not avalable for ${1}"
  fi
}

# usage : rootfsUpdater <TYPE> <ARCH>
function rootfsUpdater {
  local TMP_RFSDIR="${ARMSTRAP_ROOTFS}/${2}"
  local TMP_RFSCFG="${TMP_RFSDIR}/${1}"
  local TMP_LOG="${ARMSTRAP_LOG}/armStrap-RootFSUpdater_${1}-${2}_${ARMSTRAP_DATE}.log"
  
  printStatus "rootfsUpdater" "${TMP_RFSCFG}"
  
  if [ -f "${TMP_RFSCFG}/config.sh" ]; then
    BUILD_ROOTFS_ARCH="${2}"
    BUILD_ROOTFS_FAMILY="${1}"
    local TMP_GUI
    ARMSTRAP_GUI_PCT=0
    guiStart
    TMP_GUI=$(guiWriter "name" "armStrap")
    TMP_GUI=$(guiWriter "start" "RootFS Updater (${1}/${2})" "Progress")

    ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Initializing")
    source ${TMP_RFSCFG}/config.sh

    printStatus "rootfsUpdater" "Loading configuration for ${BUILD_ROOTFS_TYPE} (${BUILD_ROOTFS_FAMILY}-${BUILD_ROOTFS_ARCH})"
    rm -f ${TMP_LOG}
    mv ${ARMSTRAP_LOG_FILE} ${TMP_LOG}
    ARMSTRAP_LOG_FILE="${TMP_LOG}"

    if [ -d "${BUILD_ROOTFS_SRC}" ]; then
      rm -rf "${BUILD_ROOTFS_SRC}"
    fi
    checkDirectory "${BUILD_ROOTFS_SRC}"
    
    ARMSTRAP_GUI_PCT=$(guiWriter "add"  2 "Extracting root filesystem")
    httpExtract "${BUILD_ROOTFS_SRC}" "${BUILD_ROOTFS_URL}" "${ARMSTRAP_TAR_EXTRACT}"

    ARMSTRAP_GUI_PCT=$(guiWriter "add"  31 "Updating root filesystem")    
    shellRun "${BUILD_ROOTFS_SRC}" "apt-get -q -y update && apt-get -q -y dist-upgrade && apt-get -q -y clean && apt-get -q -y autoclean"

    ARMSTRAP_GUI_PCT=$(guiWriter "add"  33 "Compressing root filesystem")    
    printStatus "rootfsUpdater" "Compressing root filesystem ${TMP_ROOTFS} to ${ARMSTRAP_PKG}"
    
    rm -f "${ARMSTRAP_PKG}/`basename ${BUILD_ROOTFS_URL}`"
    ${ARMSTRAP_TAR_COMPRESS} "${ARMSTRAP_PKG}/${BUILD_ROOTFS_ARCH}-${BUILD_ROOTFS_TYPE}-${BUILD_ROOTFS_FAMILY}${ARMSTRAP_TAR_EXTENSION}" -C "${BUILD_ROOTFS_SRC}" --one-file-system ./ >> ${ARMSTRAP_LOG_FILE} 2>&1
    
    if [ -d "${BUILD_ROOTFS_SRC}" ]; then
      rm -rf "${BUILD_ROOTFS_SRC}"
    fi    

    ARMSTRAP_GUI_PCT=$(guiWriter "add"  34 "Done")    
    printStatus "rootfsUpdater" "Root filesystem updater Done"
        
    unsetEnv "BUILD_ROOTFS_"
    guiStop
  else
    printStatus "rootfsUpdater" "Cannot find ${1} for architecture ${2}"
  fi
}

# usage : rootfsMount <TYPE> <ARCH>
function rootfsMount {
  local TMP_RFSDIR="${ARMSTRAP_ROOTFS}/${2}"
  local TMP_RFSCFG="${TMP_RFSDIR}/${1}"
  local TMP_LOG="${ARMSTRAP_LOG}/armStrap-RootFSUpdater_${1}-${2}_${ARMSTRAP_DATE}.log"
  
  printStatus "rootfsMount" "${TMP_RFSCFG}"
  
  if [ -f "${TMP_RFSCFG}/config.sh" ]; then
    BUILD_ROOTFS_ARCH="${2}"
    BUILD_ROOTFS_FAMILY="${1}"
    local TMP_GUI
    ARMSTRAP_GUI_PCT=0
    guiStart
    TMP_GUI=$(guiWriter "name" "armStrap")
    TMP_GUI=$(guiWriter "start" "RootFS Updater (${1}/${2})" "Progress")

    ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Initializing")
    source ${TMP_RFSCFG}/config.sh

    printStatus "rootfsMount" "Loading configuration for ${BUILD_ROOTFS_TYPE} (${BUILD_ROOTFS_FAMILY}-${BUILD_ROOTFS_ARCH})"
    rm -f ${TMP_LOG}
    mv ${ARMSTRAP_LOG_FILE} ${TMP_LOG}
    ARMSTRAP_LOG_FILE="${TMP_LOG}"

    if [ -d "${BUILD_ROOTFS_SRC}" ]; then
      rm -rf "${BUILD_ROOTFS_SRC}"
    fi
    checkDirectory "${BUILD_ROOTFS_SRC}"
    
    ARMSTRAP_GUI_PCT=$(guiWriter "add"  2 "Extracting root filesystem")
    httpExtract "${BUILD_ROOTFS_SRC}" "${BUILD_ROOTFS_URL}" "${ARMSTRAP_TAR_EXTRACT}"

    ARMSTRAP_GUI_PCT=$(guiWriter "add"  31 "Entering shell")
    guiStop
    shellRun "${BUILD_ROOTFS_SRC}"
    guiStart
    TMP_GUI=$(guiWriter "name" "armStrap")
    TMP_GUI=$(guiWriter "start" "RootFS Updater (${1}/${2})" "Progress")
    
    ARMSTRAP_GUI_PCT=$(guiWriter "add"  1 "Cleaning root filesystem")
    shellRun "${BUILD_ROOTFS_SRC}" "apt-get -q -y clean && apt-get -q -y autoclean && find . -name "*~" -exec rm {} \;"
    
    ARMSTRAP_GUI_PCT=$(guiWriter "add"  32 "Compressing root filesystem")    
    printStatus "rootfsMount" "Compressing root filesystem ${TMP_ROOTFS} to ${ARMSTRAP_PKG}"
    
    rm -f "${ARMSTRAP_PKG}/`basename ${BUILD_ROOTFS_URL}`"
    ${ARMSTRAP_TAR_COMPRESS} "${ARMSTRAP_PKG}/`basename ${BUILD_ROOTFS_URL}`" -C "${BUILD_ROOTFS_SRC}" --one-file-system ./ >> ${ARMSTRAP_LOG_FILE} 2>&1
    
    if [ -d "${BUILD_ROOTFS_SRC}" ]; then
      rm -rf "${BUILD_ROOTFS_SRC}"
    fi

    ARMSTRAP_GUI_PCT=$(guiWriter "add"  33 "Done")    
    printStatus "rootfsMount" "Root filesystem updater Done"
    
    unsetEnv "BUILD_ROOTFS_"
    guiStop
  else
    printStatus "rootfsMount" "Cannot find ${1} for architecture ${2}"
  fi
}

# usage repoPost <DEB_PACKAGE>
function repoPost {
    local TMP_FILE="`basename ${1}`"
    REPREPRO_BASE_DIR="${ARMSTRAP_ABUILDER_REPO}" reprepro -C main remove ${TMP_FILE%%-linux-*} ${TMP_FILE%%_*}
    REPREPRO_BASE_DIR="${ARMSTRAP_ABUILDER_REPO}" reprepro -C main includedeb ${TMP_FILE%%-linux-*} ${1}
}

function kernelPost {
  local TMP_I=""
  
  rm -f ${ARMSTRAP_PKG}/*.sh
  rm -f ${ARMSTRAP_PKG}/*.deb  
  
  if [ "$1" = "-" ]; then
    for TMP_I in ${ARMSTRAP_KERNELS}/*; do 
      kernelBuild "`basename ${TMP_I}`"
    done
  else
    if [ -f "${ARMSTRAP_KERNELS}/$1/config.sh" ]; then
      kernelBuild $1
    fi
  fi
  
  if [ ! -z "${ARMSTRAP_ABUILDER_REPO_ENABLE}" ]; then
    printStatus "armStrapPost" "Publishing kernel installer script"
    checkDirectory "${ARMSTRAP_ABUILDER_KERNEL}"
    for TMP_I in ${ARMSTRAP_PKG}/*.sh; do
      mv -v ${TMP_I} ${ARMSTRAP_ABUILDER_KERNEL}/
    done
    #indexPost
  
    printStatus "armStrapPost" "Publishing kernels"
    for TMP_I in ${ARMSTRAP_PKG}/*.deb; do
      repoPost "${TMP_I}"
      rm -f ${TMP_I}
    done

  fi
}


function loaderPost {
  local TMP_I=""
  local TMP_J=""

  checkDirectory "${ARMSTRAP_ABUILDER_LOADER}"
  for TMP_I in ${ARMSTRAP_BOOTLOADERS}/*; do
    for TMP_J in ${TMP_I}/*; do
      bootBuilder "`basename ${TMP_I}`" "`basename ${TMP_J}`"
      if [ ! -z "${ARMSTRAP_ABUILDER_REPO_ENABLE}" ]; then
        printStatus "armStrapPost" "Publishing bootloaders"
        mv -v ${ARMSTRAP_PKG}/`basename ${TMP_J}`-`basename ${TMP_I}`${ARMSTRAP_TAR_EXTENSION} ${ARMSTRAP_ABUILDER_LOADER}/
        #indexPost
      fi
    done
  done
}

function rootfsPost {
  local TMP_I=""
  local TMP_J=""

  checkDirectory "${ARMSTRAP_ABUILDER_ROOTFS}"
  for TMP_I in ${ARMSTRAP_ROOTFS}/*; do
    for TMP_J in ${TMP_I}/*; do
      rootfsUpdater "`basename ${TMP_J}`" "`basename ${TMP_I}`"
      if [ ! -z "${ARMSTRAP_ABUILDER_REPO_ENABLE}" ]; then
        printStatus "armStrapPost" "Publishing rootfs"
        mv -v ${ARMSTRAP_PKG}/`basename ${TMP_I}`-*-`basename ${TMP_J}`${ARMSTRAP_TAR_EXTENSION} ${ARMSTRAP_ABUILDER_ROOTFS}/
        #indexPost
      fi
    done
  done
  
}

function indexPost {
  local TMP_I=""
  local TMP_J=""
  
  if [ ! -z "${ARMSTRAP_ABUILDER_REPO_ENABLE}" ]; then
    printStatus "armStrapPost" "Making indexes"
    rm -f ${ARMSTRAP_ABUILDER_ROOT}/.index.txt
    touch ${ARMSTRAP_ABUILDER_ROOT}/.index.txt
    for TMP_I in ${ARMSTRAP_ABUILDER_KERNEL} ${ARMSTRAP_ABUILDER_ROOTFS} ${ARMSTRAP_ABUILDER_LOADER}; do
      for TMP_J in `find ${TMP_I} -type f | sort`; do
        echo ${TMP_J/$ARMSTRAP_ABUILDER_ROOT/} >> ${ARMSTRAP_ABUILDER_ROOT}/.index.txt
      done
    done
  fi
}

function armStrapBuild {
  kernelPost
  loaderPost
  rootfsPost
}

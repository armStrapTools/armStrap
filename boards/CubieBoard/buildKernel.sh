
# Usage buildKernel
function buildKernel {
  printStatus "buildKernel" "Starting"
  
  gitSources ${BUILD_KERNEL_GIT} ${BUILD_KERNEL_DIR} ${BUILD_KERNEL_GIT_PARAM}

  configKernel "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}" "${BUILD_BOARD_KERNEL}"
  
    kernelVersion "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}"
  
  if [ ! -z "${BUILD_KERNEL_PATCH}" ]; then
    patchKernel "${BUILD_KERNEL_DIR}" "${ARMSTRAP_BOARDS}/${ARMSTRAP_CONFIG}/kernel/${BUILD_KERNEL_PATCH}"
  fi

  editConfig "${BUILD_KERNEL_CNF}" "CONFIG_CMDLINE" "${BUILD_CONFIG_CMDLINE}"

  menuConfig "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}"

  makeKernel "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}" "${BUILD_KERNEL_NAME} modules"

}

# Usage : instalKernel <TARGET DIRECTORY> <INSTALL PACKAGE FLAG>

function exportKrnlImg {
  printStatus "exportKrnlImg" "Exporting kernel image and modules to ${1}"
  
  if [ -d "${1}" ]; then
    rm -rf ${1}
  fi

  if [ -z "${ARMSTRAP_KERNEL_VERSION}" ]; then  
    kernelVersion "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}"
  fi
  
  makeKernel "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}" "INSTALL_MOD_PATH=${1} modules_install"
  
  installKernel "${BUILD_ARCH}" "${BUILD_KERNEL_DIR}" "${BUILD_KERNEL_NAME}" "${1}/boot"
  
  rm -f "${1}/lib/modules/${ARMSTRAP_KERNEL_VERSION}/build"
  rm -f "${1}/lib/modules/${ARMSTRAP_KERNEL_VERSION}/source"

  checkDirectory ${1}/DEBIAN

  printf "Section: base\n" > ${1}/DEBIAN/control
  printf "Priority: optional\n" >> ${1}/DEBIAN/control
  printf "Homepage: https://github.com/EddyBeaupre/armStrap\n" >> ${1}/DEBIAN/control
  printf "Package: %s\n" "`basename ${1}`" >> ${1}/DEBIAN/control
  printf "Version: %s\n" "${ARMSTRAP_KERNEL_VERSION}" >> ${1}/DEBIAN/control
  printf "Maintainer: Eddy Beaupre <eddy@beaupre.biz>\n" >> ${1}/DEBIAN/control
  printf "Architecture: armhf\n" >> ${1}/DEBIAN/control
  printf "Description: Linux kernel for %s.\n" "${ARMSTRAP_CONFIG}" >> ${1}/DEBIAN/control
  
  makeDeb ${1} "${ARMSTRAP_DEB}/`basename ${1}`"
  
  if [ "${2}" == "Yes" ]; then
    BUILD_DPKG_LOCALPACKAGES="${BUILD_DPKG_LOCALPACKAGES} ${ARMSTRAP_DEB}/`basename ${1}`.deb"
  fi
}

# Usage : exportKrnlHdr <TARGET DIRECTORY> <INSTALL PACKAGE FLAG>
function exportKrnlHdr {
  printStatus "exportKrnlHdr" "Exporting kernel headers to ${1}"
  
  if [ -d "${1}" ]; then
    rm -rf ${1}
  fi
  
  if [ -z "${ARMSTRAP_KERNEL_VERSION}" ]; then  
    kernelVersion "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}"
  fi
  
  makeKernel "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}" "INSTALL_HDR_PATH=${1}/usr headers_install"
  
  checkDirectory ${1}/DEBIAN
  
  printf "Section: base\n" > ${1}/DEBIAN/control
  printf "Priority: optional\n" >> ${1}/DEBIAN/control
  printf "Homepage: https://github.com/EddyBeaupre/armStrap\n" >> ${1}/DEBIAN/control
  printf "Package: %s\n" "`basename ${1}`" >> ${1}/DEBIAN/control
  printf "Version: %s\n" "${ARMSTRAP_KERNEL_VERSION}" >> ${1}/DEBIAN/control
  printf "Maintainer: Eddy Beaupre <eddy@beaupre.biz>\n" >> ${1}/DEBIAN/control
  printf "Architecture: armhf\n" >> ${1}/DEBIAN/control
  printf "Description: Linux kernel headers for %s.\n" "${ARMSTRAP_CONFIG}" >> ${1}/DEBIAN/control
  
  makeDeb ${1} "${ARMSTRAP_DEB}/`basename ${1}`"
  
  if [ "${2}" == "Yes" ]; then
    BUILD_DPKG_LOCALPACKAGES="${BUILD_DPKG_LOCALPACKAGES} ${ARMSTRAP_DEB}/`basename ${1}`.deb"
  fi
}

# Usage : exportKrnlSrc <TARGET DIRECTORY> <INSTALL PACKAGE FLAG>
function exportKrnlSrc {
  printStatus "exportKrnlSrc" "Exporting kernel sources to ${1}"
  
  if [ -d "${1}" ]; then
    rm -rf ${1}
  fi
  
  if [ -z "${ARMSTRAP_KERNEL_VERSION}" ]; then  
    kernelVersion "${BUILD_ARCH}" "${BUILD_ARCH_PREFIX}" "${BUILD_KERNEL_DIR}"
  fi

  gitExport "${BUILD_KERNEL_DIR}" "${1}/usr/src"
  
  checkDirectory ${1}/DEBIAN
  
  printf "Section: base\n" > ${1}/DEBIAN/control
  printf "Priority: optional\n" >> ${1}/DEBIAN/control
  printf "Homepage: https://github.com/EddyBeaupre/armStrap\n" >> ${1}/DEBIAN/control
  printf "Package: %s\n" "`basename ${1}`" >> ${1}/DEBIAN/control
  printf "Version: %s\n" "${ARMSTRAP_KERNEL_VERSION}" >> ${1}/DEBIAN/control
  printf "Maintainer: Eddy Beaupre <eddy@beaupre.biz>\n" >> ${1}/DEBIAN/control
  printf "Architecture: armhf\n" >> ${1}/DEBIAN/control
  printf "Description: Linux kernel sources for %s.\n" "${ARMSTRAP_CONFIG}" >> ${1}/DEBIAN/control
  
  printf "#!/bin/bash\n\n" > ${1}/DEBIAN/postinst
  printf "ln -f -s /usr/src/linux-sunxi /lib/modules/%s/build" "${ARMSTRAP_KERNEL_VERSION}" >> ${1}/DEBIAN/postinst
  printf "ln -f -s /usr/src/linux-sunxi /lib/modules/%s/source" "${ARMSTRAP_KERNEL_VERSION}" >> ${1}/DEBIAN/postinst
  
  printf "#!/bin/bash\n\n" > ${1}/DEBIAN/postrm
  printf "rm -f /lib/modules/%s/build" "${ARMSTRAP_KERNEL_VERSION}" >> ${1}/DEBIAN/postrm
  printf "rm -f /lib/modules/%s/source" "${ARMSTRAP_KERNEL_VERSION}" >> ${1}/DEBIAN/postrm
  
  chmod 755 ${1}/DEBIAN/postinst
  chmod 755 ${1}/DEBIAN/postrm
  
  makeDeb ${1} "${ARMSTRAP_DEB}/`basename ${1}`"
  
  if [ "${2}" == "Yes" ]; then
    BUILD_DPKG_LOCALPACKAGES="${BUILD_DPKG_LOCALPACKAGES} ${ARMSTRAP_DEB}/`basename ${1}`.deb"
  fi
}

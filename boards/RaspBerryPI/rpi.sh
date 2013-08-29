function rpi_fBuilder {
  local TMP_PKG="${BUILD_CONFIG}-firmware"
  local TMP_PKG_MAN="${TMP_PKG^^}"
  local TMP_VER="1.0-1"
  local TMP_ARCH="armhf"
  local TMP_DATE="`date --rfc-3339=date`"
  local TMP_RFCD="`date --rfc-2822`"
  
  
  printStatus "rpi_fBuilder" "----------------------------------------"
  printStatus "rpi_fBuilder" "- Board : ${ARMSTRAP_CONFIG}"
  printStatus "rpi_fBuilder" "----------------------------------------"
  printStatus "rpi_fBuilder" "Firmware Builder"
  gitClone "${BUILD_RPI_FIRMWARE_SOURCE}" "${BUILD_RPI_FIRMWARE_GITSRC}" "${BUILD_RPI_FIRMWARE_GIT}"
  #rm -f "${ARMSTRAP_PKG}/${TMP_PKG}.txz"
  #printStatus "rpi_fBuilder" "Compressing firmware files to ${ARMSTRAP_PKG}"
  #${BUILD_ARMBIAN_COMPRESS} "${ARMSTRAP_PKG}/${TMP_PKG}.txz" -C "${BUILD_RPI_FIRMWARE_SOURCE}" --one-file-system --exclude=boot/kernel* --exclude=./extra --exclude=./modules --exclude-vcs . >> ${ARMSTRAP_LOG_FILE} 2>&1  
  rm -rf "${ARMSTRAP_PKG}/${TMP_PKG}"
  checkDirectory "${ARMSTRAP_PKG}/${TMP_PKG}"
  printStatus "rpi_fBuilder" "Moving firmware files to ${ARMSTRAP_PKG}/${TMP_PKG}"
  tar -C "${BUILD_RPI_FIRMWARE_SOURCE}" --one-file-system --exclude=boot/kernel* --exclude=boot/COPYING.linux  --exclude=./extra --exclude=./modules --exclude-vcs -cf - . | tar -C "${ARMSTRAP_PKG}/${TMP_PKG}" -xvf -  >> ${ARMSTRAP_LOG_FILE} 2>&1
  checkDirectory "${ARMSTRAP_PKG}/${TMP_PKG}/usr/share/doc/${TMP_PKG}/"
  checkDirectory "${ARMSTRAP_PKG}/${TMP_PKG}/usr/share/man/man7/"
  checkDirectory "${ARMSTRAP_PKG}/${TMP_PKG}/DEBIAN/"
    
  printStatus "rpi_fBuilder" "Moving documentation to /usr/share/doc/${TMP_PKG}/"
  mv "${ARMSTRAP_PKG}/${TMP_PKG}/README" "${ARMSTRAP_PKG}/${TMP_PKG}/usr/share/doc/${TMP_PKG}/"
  mv "${ARMSTRAP_PKG}/${TMP_PKG}/documentation" "${ARMSTRAP_PKG}/${TMP_PKG}/usr/share/doc/${TMP_PKG}/documentation"
  
  printStatus "rpi_fBuilder" "Copying LICENCE.broadcom to usr/share/doc/${TMP_PKG}/copyright"
  cp "${ARMSTRAP_PKG}/${TMP_PKG}/boot/LICENCE.broadcom" "${ARMSTRAP_PKG}/${TMP_PKG}/usr/share/doc/${TMP_PKG}/copyright"
    
  printStatus "rpi_fBuilder" "Generating man page"
  cat > "${ARMSTRAP_PKG}/${TMP_PKG}/usr/share/man/man7/${TMP_PKG}.7" <<EOF
.\" Copyright (c) 2013 Eddy Beaupre. All rights reserved.
.\" 
.\" Redistribution and use in source and binary forms, with or without 
.\" modification, are permitted provided that the following conditions are met:
.\" 
.\" 1. Redistributions of source code must retain the above copyright notice, this
.\"    list of conditions and the following disclaimer.
.\" 2. Redistributions in binary form must reproduce the above copyright notice,
.\"    this list of conditions and the following disclaimer in the documentation
.\"    and/or other materials provided with the distribution.
.\"         
.\" THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY
.\" EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
.\" WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
.\" DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
.\" DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
.\" (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
.\" LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
.\" ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
.\" (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
.\" THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
.TH ${TMP_PKG_MAN} 7 ${TMP_DATE} "armStrap" "armStrap Packages Reference"
.SH NAME
${TMP_PKG} \- description of the firmware file system hierarchy
.SH DESCRIPTION
The ${TMP_PKG} firmware package create the following directories:
.TP
.I /boot
*start.elf, bootcode.bin and loader.bin are the GPU firmware 
and bootloaders. Their licence is described in 
.I /boot/LICENCE.broadcom
file.
.TP
.I /hardfp
Userspace VideoCoreIV libraries built for the armv6 hardfp ABI
.TP
.I /opt/vc
Includes userspace libraries for the VideCoreIV (EGL/GLES/OpenVG etc). See 
.I /opt/vc/LICENCE 
for licencing terms
.TP
.I /usr/share/doc/raspberrypi-firmware/
documentation for programming various parts of the Raspberry PI.
.SH BUGS
This list is not exhaustive; different systems may be configured
differently.
.SH "SEE ALSO"
.BR hier (7),
.SH COLOPHON
This page is part of the
.I armStrap
project.
A description of the project,
and information about reporting bugs,
can be found at
.I https://github.com/EddyBeaupre/armStrap/
EOF
  gzip --best "${ARMSTRAP_PKG}/${TMP_PKG}/usr/share/man/man7/${TMP_PKG}.7"


  printStatus "rpi_fBuilder" "Generating control file"
  cat > "${ARMSTRAP_PKG}/${TMP_PKG}/DEBIAN/control" <<EOF
Package: ${TMP_PKG}
Source: ${BUILD_CONFIG}
Version: ${TMP_VER}
Architecture: ${TMP_ARCH}
Maintainer: Eddy Beaupre <eddy@beaupre.biz>
Suggests:
Provides:
Depends:
Section: kernel
Priority: optional
Homepage: https://github.com/EddyBeaupre/armStrap
Description: GPU firmware and BootLoader for the RaspberryPI
 This package provide the necessary firmware and bootloader
 for the Raspberry-PI, some documentation on how to program
 the device is also provided.
EOF
  
  printStatus "rpi_fBuilder" "Generating changelog.Debian"
  cat > "${ARMSTRAP_PKG}/${TMP_PKG}/usr/share/doc/${TMP_PKG}/changelog.Debian" <<EOF
${TMP_PKG} (${TMP_VER}_${TMP_ARCH}) ${TMP_PKG}; urgency=low

  * Rebuild Debian package from ${TMP_PKG} firmware repository.
    See https://github.com/raspberrypi/firmware for more information
    about the firmware

 -- Eddy Beaupre <eddy@beaupre.biz>  ${TMP_RFCD}

EOF
  gzip --best "${ARMSTRAP_PKG}/${TMP_PKG}/usr/share/doc/${TMP_PKG}/changelog.Debian"

  cd ${ARMSTRAP_PKG}
  rm -f "${ARMSTRAP_PKG}/${TMP_PKG}.deb"
  rm -f "${ARMSTRAP_PKG}/${TMP_PKG}_${TMP_VER}_${TMP_ARCH}.deb"
  printStatus "rpi_fBuilder" "Building ${TMP_PKG}_${TMP_VER}_${TMP_ARCH}.deb"
  dpkg-deb --build "${TMP_PKG}" >> ${ARMSTRAP_LOG_FILE} 2>&1
  mv "${TMP_PKG}.deb" "${TMP_PKG}_${TMP_VER}_${TMP_ARCH}.deb"  
  rm -rf "${ARMSTRAP_PKG}/${TMP_PKG}"
  printStatus "rpi_fBuilder" "Firmware Builder Done"
}


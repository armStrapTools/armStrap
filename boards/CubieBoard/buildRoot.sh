# Usage: buildRoot

function buildRoot () {
  printStatus "buildRoot" "Starting"

  printStatus "buildRoot" "Running debootstrap --foreign --arch ${BUILD_DEBIAN_ARCH} ${DEB_SUITE}"
  debootstrap --foreign --arch ${BUILD_DEBIAN_ARCH} ${DEB_SUITE} ${BUILD_MNT_ROOT}/ >> ${BUILD_LOG_FILE} 2>&1
  cp /usr/bin/qemu-${BUILD_ARCH}-static ${BUILD_MNT_ROOT}/usr/bin

  # Avoid starting up services after they are installed.
  cat > ${BUILD_MNT_ROOT}/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101 
EOF
  chmod +x ${BUILD_MNT_ROOT}/usr/sbin/policy-rc.d

  printStatus "buildRoot" "Running debootstrap --second-stage"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ /debootstrap/debootstrap --second-stage >> ${BUILD_LOG_FILE} 2>&1

  printStatus "buildRoot" "Running dpkg --configure -a"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ dpkg --configure -a >> ${BUILD_LOG_FILE} 2>&1

  printStatus "buildRoot" "Configuring /etc/hostname"
  cat > ${BUILD_MNT_ROOT}/etc/hostname <<EOF
${BOARD_HOSTNAME}
EOF

  printStatus "buildRoot" "Confiuring /etc/apt/sources.list"

  cat > ${BUILD_MNT_ROOT}/etc/apt/sources.list <<EOF
deb http://ftp.debian.org/debian ${DEB_SUITE} main contrib non-free
deb-src http://ftp.debian.org/debian ${DEB_SUITE} main contrib non-free

deb http://ftp.debian.org/debian/ ${DEB_SUITE}-updates main contrib non-free
deb-src http://ftp.debian.org/debian/ ${DEB_SUITE}-updates main contrib non-free

deb http://security.debian.org/ ${DEB_SUITE}/updates main contrib non-free
deb-src http://security.debian.org/ ${DEB_SUITE}/updates main contrib non-free
EOF

  printStatus "buildRoot" "Running apt-get update"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ apt-get --quiet -y update >> ${BUILD_LOG_FILE} 2>&1
  
  printStatus "buildRoot" "apt-get upgrade"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ apt-get --quiet -y upgrade >> ${BUILD_LOG_FILE} 2>&1
  
  if [ -n "${DEB_EXTRAPACKAGES}" ]; then
    printStatus "buildRoot" "Running apt-get -y install ${DEB_EXTRAPACKAGES}"
    LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ apt-get --quiet -y install ${DEB_EXTRAPACKAGES} >> ${BUILD_LOG_FILE} 2>&1
  fi

  if [ -n "${BOARD_SWAP}" ]; then  
    printStatus "buildRoot" "Running apt-get -y install dphys-swapfile"
    LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ apt-get --quiet -y install dphys-swapfile >> ${BUILD_LOG_FILE} 2>&1
    if [ -n "${BOARD_SWAP_SIZE}" ]; then
      printStatus "buildRoot" "Configuring /etc/dphys-swapfile"
      cat > ${BUILD_MNT_ROOT}/etc/dphys-swapfile <<EOF
CONF_SWAPSIZE=${BOARD_SWAP_SIZE}
EOF
    fi
  fi

  if [ -n "${DEB_RECONFIG}" ]; then
    printStatus "buildRoot" "Running dpkg-reconfigure ${DEB_RECONFIG}"
    echo ""
    LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ dpkg-reconfigure ${DEB_RECONFIG}
  fi

  printStatus "buildRoot" "Configuring root password"
  chroot ${BUILD_MNT_ROOT}/ passwd root <<EOF > /dev/null 2>&1
${BOARD_PASSWORD}
${BOARD_PASSWORD}
EOF

  printStatus "buildRoot" "Configuring /etc/inittab"
  cat >> ${BUILD_MNT_ROOT}/etc/inittab <<EOF
T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100
EOF

  printStatus "buildRoot" "Configuring /etc/fstab"
  cat > ${BUILD_MNT_ROOT}/etc/fstab <<EOF
#<file system>  <mount point>   <type>  <options>       <dump>  <pass>
/dev/root       /               ext4    defaults        0       1
EOF

  printStatus "buildRoot" "Configuring /etc/modules"
  cat >> ${BUILD_MNT_ROOT}/etc/modules <<EOF

#For SATA Support
sw_ahci_platform

#Display and GPU
lcd
hdmi
ump
disp
mali
mali_drm
EOF

  printStatus "buildRoot" "Configuring /etc/network/interfaces"
  cat >> ${BUILD_MNT_ROOT}/etc/network/interfaces <<END
auto eth0
allow-hotplug eth0
iface eth0 inet ${BOARD_ETH0_MODE}
END

  if [ "${BOARD_ETH0_MODE}" != "dhcp" ]; then 
    cat >> ${BUILD_MNT_ROOT}/etc/network/interfaces <<END
address ${BOARD_ETH0_IP}
netmask ${BOARD_ETH0_MASK}
gateway ${BOARD_ETH0_GW}
END
    cat > ${BUILD_MNT_ROOT}/etc/resolv.conf <<END
search ${BOARD_DOMAIN}
nameserver ${BOARD_DNS1}
nameserver ${BOARD_DNS2}
END
  fi
  
  printStatus "buildRoot" "Running aptitude update"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ aptitude --quiet -y update >> ${BUILD_LOG_FILE} 2>&1
  
  printStatus "buildRoot" "Running aptitude clean"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ aptitude --quiet -y clean  >> ${BUILD_LOG_FILE} 2>&1
  
  printStatus "buildRoot" "Running apt-get clean"
  LC_ALL=${BUILD_LANG} LANGUAGE=${BUILD_LANG} LANG=${BUILD_LANG} chroot ${BUILD_MNT_ROOT}/ apt-get --quiet clean >> ${BUILD_LOG_FILE} 2>&1

  rm ${BUILD_MNT_ROOT}/usr/bin/qemu-${BUILD_ARCH}-static  

  # Re-enable services startup
  rm ${BUILD_MNT_ROOT}/usr/sbin/policy-rc.d
  
  printStatus "buildRoot" "Done"
}

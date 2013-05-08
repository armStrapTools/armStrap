BUILD_ARCH="arm"
BUILD_ARCH_EABI="hf"
BUILD_ARCH_TYPE="linux-gnueabi"
BUILD_ARCH_COMPILER="${BUILD_ARCH}-${BUILD_ARCH_TYPE}${BUILD_ARCH_EABI}"
BUILD_ARCH_PREFIX="${BUILD_ARCH_COMPILER}-"
BUILD_ARCH_GCC_VERSION="4.7"
BUILD_ARCH_GCC_PACKAGE="gcc-${BUILD_ARCH_GCC_VERSION}-${BUILD_ARCH_COMPILER}"

BUILD_DEBIAN_ARCH="${BUILD_ARCH}${BUILD_ARCH_EABI}"

BUILD_LANG="C"

BUILD_MNT_ROOT="${BUILD_ROOT}/mnt"
BUILD_MNT_BOOT="${BUILD_MNT_ROOT}/boot"

BUILD_ROOT_DEV="/dev/mmcblk0p1"
BUILD_MAC_VENDOR=0x000246
# If BUILD_MAC_ADDRESS is set, it will be the MAC address of the board, else a mac will be randomly generated.
BUILD_MAC_ADDRESS="008010EDDF01"
BUILD_CONFIG_CMDLINE="console=tty0 console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x720p60 root=${BUILD_ROOT_DEV} rootwait panic=10"

BUILD_DEB_SUITE="wheezy"
# Not all packages can be install this way.
BUILD_DEB_EXTRAPACKAGES="nvi locales ntp ssh"
# Not all packages can (or should be) reconfigured this way.
BUILD_DEB_RECONFIG="locales tzdata"

BUILD_SCRIPTS="init.sh diskUtils.sh buildBoot.sh  buildKernel.sh  buildRoot.sh  build.sh"
BUILD_PREREQ="build-essential u-boot-tools qemu qemu-user-static debootstrap kpartx lvm2 git binfmt-support libusb-1.0-0-dev pkg-config dosfstools binfmt-support libncurses5-dev"

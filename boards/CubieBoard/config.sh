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
BUILD_SCRIPTS="init.sh diskUtils.sh buildBoot.sh  buildKernel.sh  buildRoot.sh  build.sh"
PREREQ="build-essential u-boot-tools qemu qemu-user-static debootstrap kpartx lvm2 git binfmt-support libusb-1.0-0-dev pkg-config dosfstools binfmt-support libncurses5-dev"

#BUILD_ARCH="arm"
#BUILD_ARCH_EABI="hf"
#BUILD_ARCH_TYPE="linux-gnueabi"
#BUILD_ARCH_COMPILER="${BUILD_ARCH}-${BUILD_ARCH_TYPE}${BUILD_ARCH_EABI}"
#BUILD_ARCH_PREFIX="${BUILD_ARCH_COMPILER}-"
#BUILD_ARCH_GCC_VERSION="4.7"
#BUILD_ARCH_GCC_PACKAGE="gcc-${BUILD_ARCH_GCC_VERSION}-${BUILD_ARCH_COMPILER}"

#BUILD_LC="C"

#BUILD_BOARD_KERNEL="sun4i_defconfig"
#BUILD_BOARD_KERNEL="sun4i-desktop_defconfig"

#BUILD_MNT_BOOT="${BUILD_MNT_ROOT}/boot"

#BUILD_DEBIAN_SOURCE="http://ftp.debian.org/debian"
#BUILD_DEBIAN_SOURCE_COMPONENTS="main contrib non-free"
#BUILD_DEBIAN_SOURCE_SECURITY="http://security.debian.org"
#BUILD_DEBIAN_SOURCE_SECURITY_COMPONENTS="main contrib non-free"
#BUILD_DEBIAN_TASKS="ssh-server standard"
# Not all packages can be configured this way.
#BUILD_DEBIAN_RECONFIG="locales tzdata ${ARMSTRAP_DPKG_RECONFIG}"

#BUILD_UBUNTU_VERSION="13.04"
#BUILD_UBUNTU_TASKS="minimal^ openssh-server^ server^ standard^"
#BUILD_UBUNTU_LOCALES="${LANG} en_US.UTF-8 en_US"

#BUILD_KERNEL_GIT="https://github.com/linux-sunxi/linux-sunxi.git"
#BUILD_KERNEL_GIT_BRANCH="sunxi-3.4"
#if [ -z "${BUILD_KERNEL_GIT_BRANCH}" ]; then
#  BUILD_KERNEL_GIT_PARAM=""
#  BUILD_KERNEL_DIR="${ARMSTRAP_SRC}/linux-sunxi/head"
#else
#  BUILD_KERNEL_GIT_PARAM="-b ${BUILD_KERNEL_GIT_BRANCH}"
#  BUILD_KERNEL_DIR="${ARMSTRAP_SRC}/linux-sunxi/${BUILD_KERNEL_GIT_BRANCH}"
#fi
#BUILD_KERNEL_CNF="${BUILD_KERNEL_DIR}/.config"
#BUILD_KERNEL_NAME="uImage"

#BUILD_KERNEL_SRCDST="${BUILD_MNT_ROOT}/usr/src"

# See the kernel subdirectory for all avalable patches
#if [ -z "${ARMSTRAP_KERNEL_PATCH}" ]; then
#  BUILD_KERNEL_PATCH="sun4i_desktop.patch"
#else
#  BUILD_KERNEL_PATCH="${ARMSTRAP_KERNEL_PATCH}"
#fi

# Set to Yes if you want to install tke kernel image and modules, else No.
#if [ -z "${ARMSTRAP_KERNEL_INSTIMG}" ]; then
#  BUILD_KERNEL_INSTIMG="Yes"
#else
#  BUILD_KERNEL_INSTIMG="${ARMSTRAP_KERNEL_INSTIMG}"
#fi
# Set to Yes if you want to install tke kernel sources, else to No.
#if [ -z "${ARMSTRAP_KERNEL_INSTSRC}" ]; then
#  BUILD_KERNEL_INSTSRC="Yes"
#else
#  BUILD_KERNEL_INSTSRC="${ARMSTRAP_KERNEL_INSTSRC}"
#fi
# Set to Yes if you want to install tke kernel headers, else to No. It kinda conflict with things already installed in Ubuntu...
#if [ -z "${ARMSTRAP_KERNEL_INSTHDR}" ]; then
#  BUILD_KERNEL_INSTHDR="No"
#else
#  BUILD_KERNEL_INSTHDR="${ARMSTRAP_KERNEL_INSTHDR}"
#fi

#BUILD_UBOOT_GIT="https://github.com/linux-sunxi/u-boot-sunxi.git"
#BUILD_UBOOT_GIT_BRANCH=""
#if [ -z "${BUILD_UBOOT_GIT_BRANCH}" ]; then
#  BUILD_UBOOT_GIT_PARAM=""
#  BUILD_UBOOT_DIR="${ARMSTRAP_SRC}/u-boot-sunxi/head"
#else
#  BUILD_UBOOT_GIT_PARAM="-b ${BUILD_KERNEL_GIT_BRANCH}"
#  BUILD_UBOOT_DIR="${ARMSTRAP_SRC}/u-boot-sunxi/${BUILD_KERNEL_GIT_BRANCH}"
#fi
#BUILD_UBOOT_SRCDST="${BUILD_MNT_ROOT}/usr/src"
#BUILD_UBOOT_BOARD="cubieboard"

#BUILD_SUNXI_BOARD_GIT="https://github.com/linux-sunxi/sunxi-boards.git"
#BUILD_SUNXI_BOARD_GIT_BRANCH=""
#if [ -z "${BUILD_SUNXI_BOARD_GIT_BRANCH}" ]; then
#  BUILD_SUNXI_BOARD_GIT_PARAM=""
#  BUILD_SUNXI_BOARD_DIR="${ARMSTRAP_SRC}/sunxi-board/head"
#else
#  BUILD_SUNXI_BOARD_GIT_PARAM="-b ${BUILD_KERNEL_GIT_BRANCH}"
#  BUILD_SUNXI_BOARD_DIR="${ARMSTRAP_SRC}/sunxi-board/${BUILD_KERNEL_GIT_BRANCH}"
#fi
#BUILD_SUNXI_BOARD_SRCDST="${BUILD_MNT_ROOT}/usr/src"
#BUILD_SUNXI_BOARD_CPU="a10"
#BUILD_SUNXI_BOARD_FEX="cubieboard"

#BUILD_SUNXI_TOOLS_GIT="https://github.com/linux-sunxi/sunxi-tools.git"
#BUILD_SUNXI_TOOLS_GIT_BRANCH=""
#if [ -z "${BUILD_SUNXI_TOOLS_GIT_BRANCH}" ]; then
#  BUILD_SUNXI_TOOLS_GIT_PARAM=""
#  BUILD_SUNXI_TOOLS_DIR="${ARMSTRAP_SRC}/sunxi-tools/head"
#else
#  BUILD_SUNXI_TOOLS_GIT_PARAM="-b ${BUILD_KERNEL_GIT_BRANCH}"
#  BUILD_SUNXI_TOOLS_DIR="${ARMSTRAP_SRC}/sunxi-tools/${BUILD_KERNEL_GIT_BRANCH}"
#fi
#BUILD_SUNXI_TOOLS_SRCDST="${BUILD_MNT_ROOT}/usr/src"

BUILD_SCRIPTS="init.sh build.sh"
BUILD_PREREQ="build-essential u-boot-tools qemu qemu-user-static debootstrap parted kpartx lvm2 git binfmt-support libusb-1.0-0-dev pkg-config dosfstools libncurses5-dev"

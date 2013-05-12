BUILD_ARCH="arm"
BUILD_ARCH_EABI="hf"
BUILD_ARCH_TYPE="linux-gnueabi"
BUILD_ARCH_COMPILER="${BUILD_ARCH}-${BUILD_ARCH_TYPE}${BUILD_ARCH_EABI}"
BUILD_ARCH_PREFIX="${BUILD_ARCH_COMPILER}-"
BUILD_ARCH_GCC_VERSION="4.7"
BUILD_ARCH_GCC_PACKAGE="gcc-${BUILD_ARCH_GCC_VERSION}-${BUILD_ARCH_COMPILER}"

BUILD_LC="C"

BUILD_BOARD_CPU="a10"
BUILD_BOARD="cubieboard"
BUILD_BOARD_KERNEL="sun4i_defconfig"

BUILD_MNT_ROOT="${ARMSTRAP_MNT}"
BUILD_MNT_BOOT="${BUILD_MNT_ROOT}/boot"

BUILD_SERIALCON_ID="T0"
BUILD_SERIALCON_RUNLEVEL="2345"
BUILD_SERIALCON_TERM="ttyS0"
BUILD_SERIALCON_SPEED="115200"
BUILD_SERIALCON_TYPE="vt100"

BUILD_FSTAB_ROOTDEV="/dev/root"
BUILD_FSTAB_ROOTMNT="/"
BUILD_FSTAB_ROOTFST="ext4"
BUILD_FSTAB_ROOTOPT="defaults"
BUILD_FSTAB_ROOTDMP="0"
BUILD_FSTAB_ROOTPSS="1"

BUILD_ROOT_DEV="/dev/mmcblk0p1"
BUILD_MAC_VENDOR=0x000246
BUILD_CONFIG_CMDLINE="console=tty0 console=${BUILD_SERIALCON_TERM},${BUILD_SERIALCON_SPEED} hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x720p60 root=${BUILD_ROOT_DEV} rootwait panic=10"

BUILD_DEBIAN_SOURCE="http://ftp.debian.org/debian"
BUILD_DEBIAN_SOURCE_COMPONENTS="main contrib non-free"
BUILD_DEBIAN_SOURCE_SECURITY="http://security.debian.org"
BUILD_DEBIAN_SOURCE_SECURITY_COMPONENTS="main contrib non-free"
BUILD_DEBIAN_SUITE="wheezy"
# Not all packages can be install this way.
BUILD_DEBIAN_EXTRAPACKAGES="nvi locales ntp ssh build-essential u-boot-tools parted git binfmt-support libusb-1.0-0-dev pkg-config dosfstools libncurses5-dev"
# Not all packages can (or should be) reconfigured this way.
BUILD_DEBIAN_RECONFIG="locales tzdata"

BUILD_KERNEL_GIT="https://github.com/linux-sunxi/linux-sunxi.git"
BUILD_KERNEL_GIT_PARAM="-b sunxi-3.4"
BUILD_KERNEL_DIR="${ARMSTRAP_SRC}/linux-sunxi"
BUILD_KERNEL_CNF="${BUILD_KERNEL_DIR}/.config"
BUILD_KERNEL_NAME="uImage"
BUILD_KERNEL_MODULES="sw_ahci_platform lcd hdmi ump disp mali mali_drm"
BUILD_KERNEL_SRCDST="${BUILD_MNT_ROOT}/usr/src"

BUILD_UBOOT_GIT="https://github.com/linux-sunxi/u-boot-sunxi.git"
BUILD_UBOOT_DIR="${ARMSTRAP_SRC}/u-boot-sunxi"
BUILD_UBOOT_SRCDST="${BUILD_MNT_ROOT}/usr/src"

BUILD_SUNXI_BOARD_GIT="https://github.com/linux-sunxi/sunxi-boards.git"
BUILD_SUNXI_BOARD_DIR="${ARMSTRAP_SRC}/sunxi-boards"
BUILD_SUNXI_BOARD_SRCDST="${BUILD_MNT_ROOT}/usr/src"

BUILD_SUNXI_TOOLS_GIT="https://github.com/linux-sunxi/sunxi-tools.git"
BUILD_SUNXI_TOOLS_DIR="${ARMSTRAP_SRC}/sunxi-tools"
BUILD_SUNXI_TOOLS_SRCDST="${BUILD_MNT_ROOT}/usr/src"

BUILD_BOOT_CMD="${BUILD_MNT_ROOT}/boot/boot.cmd"
BUILD_BOOT_SCR="${BUILD_MNT_ROOT}/boot/boot.scr"

BUILD_BOOT_FEX="${BUILD_MNT_ROOT}/boot/cubieboard.fex"
BUILD_BOOT_BIN="${BUILD_MNT_ROOT}/boot/script.bin"
BUILD_BOOT_BIN_LOAD="mmc 0 0x43000000 boot/script.bin"
BUILD_BOOT_KERNEL_LOAD="mmc 0 0x48000000 boot/${BUILD_KERNEL_NAME}"
BUILD_BOOT_KERNEL_ADDR="0x48000000"

BUILD_BOOT_SPL="${BUILD_UBOOT_DIR}/spl/sunxi-spl.bin"
BUILD_BOOT_SPL_SIZE="1024"
BUILD_BOOT_SPL_SEEK="8"

BUILD_BOOT_UBOOT="${BUILD_UBOOT_DIR}/u-boot.bin"
BUILD_BOOT_UBOOT_SIZE="1024"
BUILD_BOOT_UBOOT_SEEK="32"

BUILD_SCRIPTS="init.sh diskUtils.sh buildBoot.sh  buildKernel.sh  buildRoot.sh  build.sh"
BUILD_PREREQ="build-essential u-boot-tools qemu qemu-user-static debootstrap parted kpartx lvm2 git binfmt-support libusb-1.0-0-dev pkg-config dosfstools binfmt-support libncurses5-dev"

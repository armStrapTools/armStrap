##############################################################################
# Build configuration
#
# Set this to the name of the board you want to build
#ARMSTRAP_CONFIG="CubieTruck"

##############################################################################
# Basic configuration
#
# Set this to the hostname you want for the board, default is "armStrap"
#
#ARMSTRAP_HOSTNAME="armStrap"
#
# Set this to the password you want for the root user, default is "armStrap"
#
#ARMSTRAP_PASSWORD="armStrap"

##############################################################################
# TimeZone
# If you want to select the timezone, set it here. If not, America/Montreal
# is used as the default.
#
#ARMSTRAP_TIMEZONE="America/Montreal"

##############################################################################
# Locales
# By default, armStrap install the default locale of the maching used to
# run the script, if you want to change it, set it here.
#
#ARMSTRAP_LANG="fr_CA.UTF-8"
#ARMSTRAP_LANGUAGE="fr_CA:fr"
#
# If you want to install more locales, set it here.
#ARMSTRAP_LANG_EXTRA="fr_CA.ISO-8859-1"

##############################################################################
# Swapfile
# ArmStrap always create a swapfile, the default size is 128MB, you can
# adjust the swapfile configuration here. Once the board is booted you can
# always modify /etc/dphys-swapfile to change theses values.
# 
# Size of the swap file (in MB), if 0, dphys-swapfile will try to guess
# the correct size of the swapfile.
#
#ARMSTRAP_SWAPSIZE="1024"
#
# Location of the swap file
#ARMSTRAP_SWAPFILE="/var/swap"
#
# If we are autodetecting swap size, this control its size  (SWAPSIZE = 
# SWAPFACTOR x RAM)
#
#ARMSTRAP_SWAPFACTOR="2"
#
# The maximum size of the swapfile in autodetect mode
#
#ARMSTRAP_MAXSWAP=2048

##############################################################################
# OS Section
#
# Currently we support ubuntu and debian for armv7l and Raspbian for armv6l.
# Board configuration generally have debian stable as default value.
#
#ARMSTRAP_ROOTFS_FAMILY="ubuntu"
#ARMSTRAP_ROOTFS_VERSION="utopic"

##############################################################################
# Kernel Section
#
# Some board can use many kernels, the stable one is the default but you can
# try an alternate version if you wish. See armStrap -? for a list of avalable
# kernels.
#
# Sunxi-Next and mainline (official linux sources) work with the A10/A20 with
# limited support for the hardware. If you want a kernel that can handle all
# the hardware of the Cubies, use sun4i or sun7i. sun7i-ct is a special kernel
# for the CubieTruck with WiFi support.
#
#ARMSTRAP_KERNEL="mainline"
#ARMSTRAP_KERNEL_CONFIG="default"
#ARMSTRAP_KERNEL_VERSION="3.4.67"
#
# You can add kernel modules to the default ones here
#
#ARMSTRAP_KERNEL_MODULES=""

##############################################################################
# BootLoader Section
#
#
# If you want to change the kernel root device (like for installing on NAND)
# change it there... Default is to boot from first partition of SD card.
#
#ARMSTRAP_LOADER_ROOT="/dev/mmcblk0p1"
#
# Some kernels need a different bootloader. For instance, sunxi-next and
# mainline need u-boot-sunxi-next to enable the second CPU of the A20.
#
# See help for valid targets.
#
#ARMSTRAP_BOARD_LOADER="u-boot-sunxi-next"

##############################################################################
# Packages Sections
#
# If you want to install packages to the base distribution, add them here
#
#ARMSTRAP_DPKG_EXTRAPACKAGES=""
#
# If you want to reconfigure packages, add them here
#
#ARMSTRAP_DPKG_RECONFIG=""

##############################################################################
# Network configuration
#
# By default, the board will get its ip address by dhcp, uncomment and
# ajust the following if you want a static ip.
#
#ARMSTRAP_ETH0_MODE="static"
#ARMSTRAP_ETH0_IP="192.168.0.100" 
#ARMSTRAP_ETH0_MASK="255.255.255.0"
#ARMSTRAP_ETH0_GW="192.168.0.1" 
#ARMSTRAP_ETH0_DNS="8.8.8.8 8.8.4.4"
#ARMSTRAP_ETH0_DOMAIN="localhost.com"
#
# Some board need a mac address, if this is not set and the board need one,
# a pseudo random mac address will be generated. The vendor mac prefix used
# to generate the mac address is define in the board configuration.
#
#ARMSTRAP_MAC_ADDRESS="DEADBEEFBAAD"

##############################################################################
# Output configuration
#
# If you want to install directly into your SD card, put the device here. If
# it's not defined, an image will be generated.
#
#ARMSTRAP_DEVICE="/dev/sdc"
#
# If you want to name your image something else than the generated name
#
#ARMSTRAP_IMAGE_NAME="wathever_you_want_to_name_your_image.img"
#
# Specify the size of the image to be build in MB
#
#ARMSTRAP_IMAGE_SIZE="2048"

##############################################################################
# Repository Configuration
#
# Theses are used by armStrap to populate to and fetch from the
# official webserver. Unless you're me or want to create your
# own fork, there's absolutly no need to fiddle with theses.
#[B
#ARMSTRAP_ABUILDER_URL="http://archive.armstrap.net"
#ARMSTRAP_ABUILDER_ROOT="/var/www/armstrap.net"
#ARMSTRAP_ABUILDER_KERNEL="${ARMSTRAP_ABUILDER_ROOT}/kernel"
#ARMSTRAP_ABUILDER_KERNEL_URL="${ARMSTRAP_ABUILDER_URL}/kernel"
#ARMSTRAP_ABUILDER_ROOTFS="${ARMSTRAP_ABUILDER_ROOT}/rootfs"
#ARMSTRAP_ABUILDER_ROOTFS_URL="${ARMSTRAP_ABUILDER_URL}/rootfs"
#ARMSTRAP_ABUILDER_LOADER="${ARMSTRAP_ABUILDER_ROOT}/loader"
#ARMSTRAP_ABUILDER_LOADER_URL="${ARMSTRAP_ABUILDER_URL}/loader"
#ARMSTRAP_ABUILDER_LOGS="${ARMSTRAP_ABUILDER_ROOT}/logs"
#ARMSTRAP_ABUILDER_LOGS_URL="${ARMSTRAP_ABUILDER_URL}/logs"
#ARMSTRAP_ABUILDER_REPO="/var/www/armstrap.net/"
#ARMSTRAP_ABUILDER_REPO_URL="${ARMSTRAP_ABUILDER_URL}/apt/armstrap/"
#ARMSTRAP_ABUILDER_REPO_KEYSRV="pgpkeys.mit.edu"
#ARMSTRAP_ABUILDER_REPO_KEYHSH="1F7F94D7A99BC726"
#ARMSTRAP_ABUILDER_REPO_ENABLE="true"

##############################################################################
# ARM test and compilation environment
#
# Theses are used by armStrap to create an ARM environment where armStrap 
# packages can be tested or build without any ARM hardware.
#
#ARMSTRAP_ARMENV_FAMILY="ubuntu"
#ARMSTRAP_ARMENV_VERSION="utopic"
#ARMSTRAP_ARMENV_PERSISTENT="Yes"

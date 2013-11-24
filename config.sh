##############################################################################
# Build configuration
#
# Set this to the name of the board you want to build
ARMSTRAP_CONFIG="CubieBoard"

##############################################################################
# Basic configuration
#
# Set this to the hostname you want for the board
ARMSTRAP_HOSTNAME="armStrap"
# Set this to the password you want for the root user
ARMSTRAP_PASSWORD="armStrap"

##############################################################################
# TimeZone and Locales
# If you want to select the timezone, set it here. If not, America/Montreal
# is used as the default.
#ARMSTRAP_TIMEZONE="America/Montreal"
# By default, armStrap install the default locale of the maching used to
# run the script, if you want to change it, set it here.
#ARMSTRAP_LANG="fr_CA.UTF-8"
#ARMSTRAP_LANGUAGE="fr_CA:fr"
# If you want to install more locales, set it here.
#ARMSTRAP_LANG_EXTRA="fr_CA.ISO-8859-1"

##############################################################################
# Swapfile configuration
#
# If you want a swapfile, uncomment this.
#ARMSTRAP_SWAP="yes"
# If you want a fixed size swapfile, set this (in MB).
#ARMSTRAP_SWAP_SIZE="1024"

##############################################################################
# OS Sections
#
# Currently we support ubuntu and debian for CubieBoards/Hackberry, or
# Raspbian for Raspberry PI. Valid targets are:
#
# Debian: wheezy, jessie, sid
# Ubuntu: rarring, saucy
# Raspbian : rpi-wheezy
#
#ARMSTRAP_OS="rarring"

##############################################################################
# Kernel Sections
#
# Some board can use many kernels, the stable one is the default but you can
# try an alternate version if you wish. Right now, only kernel 3.4 is supported
# for CubieBoard/HackBerry and 3.6 for Raspberry PI. The default kernel is a
# general purpose kernel good for most situations.
#
#ARMSTRAP_KBUILDER_VERSION="3.4"
#ARMSTRAP_KBUILDER_CONF="default"
#
# If you want to change the kernel root device (like for installing on NAND)
# change it there... Default is to boot from first partition of SD card.
#
#ARMSTRAP_ROOT_DEV="/dev/mmcblk0p1"

##############################################################################
# Packages Sections
#
# If you want to install packages to the base distribution, add them here
#ARMSTRAP_DPKG_EXTRAPACKAGES=""
#
# If you want to reconfigure packages, add them here
#ARMSTRA__DPKG_RECONFIG=""

##############################################################################
# Network configuration
#
# If you want to use DHCP, use the following
ARMSTRAP_ETH0_MODE="dhcp"
# Or if you want a static IP use the following 
#ARMSTRAP_ETH0_MODE="static"
#ARMSTRAP_ETH0_IP="192.168.0.100" 
#ARMSTRAP_ETH0_MASK="255.255.255.0"
#ARMSTRAP_ETH0_GW="192.168.0.1" 
#ARMSTRAP_ETH0_DNS="8.8.8.8 8.8.4.4"
#ARMSTRAP_ETH0_DOMAIN="localhost.com"
# Some board need a mac address, if this is not set and the board need one,
# a pseudo random mac address will be generated. The vendor mac prefix used
# to generate the mac address is define in the board configuration.
#ARMSTRAP_MAC_ADDRESS="DEADBEEFBAAD"

##############################################################################
# Output configuration
#
# If you want to install directly into your SD card, put the device here. If
# it's not defined, an image will be generated.
ARMSTRAP_DEVICE="/dev/sdb"
# If you want to name your image something else than the generated name
#ARMSTRAP_IMAGE_NAME="wathever_you_want_to_name_your_image.img"
# Specify the size of the image to be build in MB
#ARMSTRAP_IMAGE_SIZE="2048"

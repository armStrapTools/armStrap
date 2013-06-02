##############################################################################
# Build configuration
#
# Set this to the name of the board you want to build
ARMSTRAP_CONFIG="CubieBoard"
# Set this to the hostname you want for the board
ARMSTRAP_HOSTNAME="CubieDebian"
# Set this to the password you want for the root user
ARMSTRAP_PASSWORD="debian"

##############################################################################
# Swapfile configuration
#
# If you want a swapfile, uncomment this.
ARMSTRAP_SWAP="yes"
# If you want a fixed size swapfile, set this (in MB).
ARMSTRAP_SWAP_SIZE="256"

##############################################################################
# Packages Sections
#
# If you want to install packages to the base distribution, add them here
#ARMSTRAP_DEBIAN_EXTRAPACKAGES=""
#
# If you want to reconfigure packages, add them here
#ARMSTRA__DEBIAN_RECONFIG=""

##############################################################################
# Network configuration
#
# If you want to use DHCP, use the following
ARMSTRAP_ETH0_MODE="dhcp"
# Or if you want a static IP use the following ARMSTRAP_ETH0_MODE="static"
#ARMSTRAP_ETH0_IP="192.168.0.100" ARMSTRAP_ETH0_MASK="255.255.255.0"
#ARMSTRAP_ETH0_GW="192.168.0.1" ARMSTRAP_ETH0_DNS="8.8.8.8 8.8.4.4"
#ARMSTRAP_ETH0_DOMAIN="localhost.com"
# Some board need a mac address, if this is not set and the board need one,
# a pseudo random mac address will be generated. The vendor mac prefix used
# to generate the mac address is define in the board configuration.
#ARMSTRAP_MAC_ADDRESS="008010EDDF01"

##############################################################################
# Output configuration
#
# If you want to install directly into your SD card, put the device here. If
# it's not defined, an image will be generated.
#ARMSTRAP_DEVICE="/dev/sdb"
# If you want to name your image something else than the generated name
#ARMSTRAP_IMAGE_NAME="wathever_name_you_want.img"
# Specify the size of the image to be build in MB
#ARMSTRAP_IMAGE_SIZE="2048"

# Theses must always be set for a board configuration
BUILD_CPU="a20"
BUILD_ARCH="arm"

# Theses are overrides from the default board configuration
BUILD_KERNEL_TYPE="sun7i"
BUILD_KERNEL_VERSION="3.4"
BUILD_KERNEL_CONFIG="default"

# Include the default values last.
source ${ARMSTRAP_BOARDS}/.defaults/config.sh

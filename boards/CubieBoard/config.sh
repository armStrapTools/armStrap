# Theses must always be set for a board configuration
BUILD_CPU="a10"
BUILD_ARCH="arm"

# Theses are overrides from the default board configuration

# Include the default values last.
source ${ARMSTRAP_BOARDS}/.defaults/config.sh

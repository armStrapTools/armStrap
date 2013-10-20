function rpiFirmware {
  printStatus "rpiFirmware" "Updating ${ARMSTRAP_CONFIG} firmware"

  gitClone "${BUILD_FIRMWARE_SOURCE}" "${BUILD_FIRMWARE_GITSRC}" "${BUILD_FIRMWARE_GIT}"

  printStatus "rpiFirmware" "${ARMSTRAP_CONFIG} firmware done"
}

#
# We use default_installRoot
#

#
# Two dummy functions to disable the default ones.
#

function raspberrypi_installBoot {
  printStatus "installBoot" "Not needed for ${ARMSTRAP_CONFIG}"
}

#function raspberrypi_installKernel {
#  printStatus "installKernel" "Not needed for ${ARMSTRAP_CONFIG}"
#}

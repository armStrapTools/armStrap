
# usage initBuilder <ARMSTRAP_CONFIG> <ARMSTRAP_BOARD_CONFIG>
function init {
  printStatus "initBuilder" "Initializing builder for ${ANS_BLD}${ANF_GRN}${1}${ANF_DEF}${ANS_RST}"
  
  for i in ${BUILD_SCRIPTS}; do
    if [ -f ${2}/${i} ]; then
      source ${2}/${i}
    fi
  done

  installPrereqs ${BUILD_PREREQ}  
  macAddress "${BUILD_MAC_VENDOR}"
}

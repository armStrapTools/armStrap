function installGCC {
  if [ ! -e "/etc/apt/sources.list.d/emdebian.list" ]; then
  
    cat > /etc/apt/sources.list.d/emdebian.list <<EOF
deb http://www.emdebian.org/debian/ wheezy main
deb http://www.emdebian.org/debian/ sid main
EOF
    apt-get install emdebian-archive-keyring
    apt-get update
  fi
  
  apt-get install emdebian-archive-keyring
  apt-get update
  
  apt-get install -y ${BUILD_ARCH_GCC_PACKAGE}
  for i in /usr/bin/${BUILD_ARCH_COMPILER}*-${BUILD_ARCH_GCC_VERSION} ; do ln -f -s $i ${i%%-${BUILD_ARCH_GCC_VERSION}} ; done
}

# Generate a mac address if the board need one.
function macAddress {
  if [ -n ${BUILD_MAC_VENDOR} ]; then
    if [ -z ${BUILD_MAC_ADDRESS} ]; then
      BOARD_ETH0_MAC=$( printf "%012x" $((${BUILD_MAC_VENDOR} * 16777216 + $[ $RANDOM % 16777216 ])) )
    fi
  fi
}

# init is called right after checking for root uid
function init {
  local IN=(`dpkg-query -W -f='${Status} ${Version}\n' ${BUILD_ARCH_GCC_PACKAGE} 2> /dev/null`)
  if [ "${IN[0]}" != "install" ]; then
    installGCC
  fi
  
  macAddress
}

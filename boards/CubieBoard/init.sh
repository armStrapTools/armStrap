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

# init is called right after checking for root uid
function init {
  local IN=(`dpkg-query -W -f='${Status} ${Version}\n' ${BUILD_ARCH_GCC_PACKAGE} 2> /dev/null`)
  if [ "${IN[0]}" != "install" ]; then
    installGCC
  fi
  
  macAddress "${BUILD_MAC_VENDOR}"
}

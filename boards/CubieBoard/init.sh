function installGCC {
  local IN=(`dpkg-query -W -f='${Status} ${Version}\n' emdebian-archive-keyring 2> /dev/null`)
  if [ "${IN[0]}" != "install" ]; then
    printStatus "installGCC" "Configuring emdebian repository"
    echo "deb http://www.emdebian.org/debian/ wheezy main" > /etc/apt/sources.list.d/emdebian.list
    echo "deb http://www.emdebian.org/debian/ sid main" >> /etc/apt/sources.list.d/emdebian.list
    apt-get install emdebian-archive-keyring >> ${ARMSTRAP_LOG_FILE} 2>&1
    apt-get update >> ${ARMSTRAP_LOG_FILE} 2>&1
  fi
  
  printStatus "installGCC" "Installing ${BUILD_ARCH_GCC_PACKAGE}"
  apt-get install -y ${BUILD_ARCH_GCC_PACKAGE} >> ${ARMSTRAP_LOG_FILE} 2>&1
  
  for i in /usr/bin/${BUILD_ARCH_COMPILER}*-${BUILD_ARCH_GCC_VERSION} ; do 
    printStatus "installGCC" "Creating symlink ${i%%-${BUILD_ARCH_GCC_VERSION}} for ${i}"
    ln -f -s $i ${i%%-${BUILD_ARCH_GCC_VERSION}}
  done
}

# init is called right after checking for root uid
function init {
  installPrereqs ${BUILD_PREREQ}

  printStatus "init" "${ARMSTRAP_CONFIG} Builder initializing"
  local IN=(`dpkg-query -W -f='${Status} ${Version}\n' ${BUILD_ARCH_GCC_PACKAGE} 2> /dev/null`)
  if [ "${IN[0]}" != "install" ]; then
    installGCC
  fi
  
  macAddress "${BUILD_MAC_VENDOR}"
}

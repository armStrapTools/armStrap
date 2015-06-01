import builtins
import configparser
import logging
import os
import requests
import random
import shutil
import subprocess
import sys
import tarfile
import urllib.request

from . import ui as UI

#######################################################################################
# Since armStrap must be run as root, all path are made relative to the work directory.
#

# Extract a tar file (src) to a directory (dst)
def extractTar(src, dst):
  try:
    UI.logEntering()
    checkPath(dst)
    UI.logDebug("Extracting " + getPath(src) + " to " + getPath(dst))
    xz = tarfile.open(getPath(src), 'r:*')
    xz.extractall(getPath(dst))
    xz.close()
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Download a file to the current directory
def download(url):
  try:
    UI.logEntering()
    UI.logDebug("Downloading " + url + " to " + getPath(os.path.basename(url)))
    with urllib.request.urlopen(url) as src, open(getPath(os.path.basename(url)), 'wb') as out_file:
      shutil.copyfileobj(src, out_file)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Unlink a file 
def unlinkFile(src):
  try:
    UI.logEntering()
    if os.path.isfile(getPath(src)):
      UI.logDebug("Unlinking " + getPath(src))
      os.unlink(getPath(src))
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
    
# Touch a file
def touch(fname, mode=0o666, dir_fd=None, **kwargs):
  try:
    UI.logEntering()
    UI.logDebug("Touching " + getPath(fname))
    flags = os.O_CREAT | os.O_APPEND
    with os.fdopen(os.open(getPath(fname), flags=flags, mode=mode, dir_fd=dir_fd)) as f:
      os.utime(f.fileno() if os.utime in os.supports_fd else getPath(fname), dir_fd=None if os.supports_fd else dir_fd, **kwargs)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Check if a path exist and create it. Aways work from the work directory    
def checkPath(path):
  try:
    UI.logEntering()
    if os.path.exists(getPath(path)) == False:
      UI.logDebug("Creating path " + getPath(path))
      os.makedirs(getPath(path))
    UI.logExiting()
    return getPath(path)
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Check if a path exist. Aways work from the work directory    
def isPath(path):
  try:
    UI.logEntering()
    if os.path.exists(getPath(path)) == False:
      return False
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

  
# Return a path starting at the work directory
def getPath(path):
  try:
    UI.logEntering()
    p = os.path.join(os.getcwd(), path.strip('/'))
    UI.logDebug("Complete path for " + path + " is " + p)
    UI.logExiting()
    return p
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
    
# Check if a file exist
def checkFile(file):
  try:
    UI.logEntering()
    if os.path.isfile(file):
      UI.logDebug(file + " exist")
      return True
    else:
      UI.logDebug(file + " does not exist")
      return False
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Append lines to a file    
def appendFile(file, lines):
  try:
    UI.logEntering()
    with open(file, "a") as f:
      for line in lines:
        UI.logDebug(file + " adding line " + line)
        f.write(line + "\n")
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
    
# Read armStrap config and set default values if missing.
def readArmStrapConfig():
  try:
    UI.logEntering()
    config = readConfig(src = "armStrap.ini")
    
    if config == False:
      config = configparser.ConfigParser()
    
    getConfigValue(config, 'Board', 'Branch', "sunxi")
    getConfigValue(config, 'Board', 'Model', "CubieTruck")
    getConfigValue(config, 'Board', 'HostName', "armStrap")
    getConfigValue(config, 'Board', 'TimeZone', "America/Montreal")
    getConfigValue(config, 'Board', 'Locales', "en_US.UTF-8 fr_CA.UTF-8")
    
    getConfigValue(config, 'Distribution', 'Family', "ubuntu")
    getConfigValue(config, 'Distribution', 'Version', "vivid")
   
    getConfigValue(config, 'Kernel', 'Version', "mainline")

    if getConfigSection(config, 'Networking') != False:    
      if getConfigValue(config, 'Networking', 'Mode').lower() == "static":
        getConfigValue(config, 'Networking', 'Ip', "192.168.0.100")
        getConfigValue(config, 'Networking', 'Mask', "255.255.255.0")
        getConfigValue(config, 'Networking', 'Gateway', "192.168.0.1")
        getConfigValue(config, 'Networking', 'Domain', "armstrap.net")
        getConfigValue(config, 'Networking', 'DNS', "8.8.8.8 8.8.4.4")
      else:
        getConfigValue(config, 'Networking', 'Mode', "dhcp")
    else:
      getConfigValue(config, 'Networking', 'Mode', "dhcp")
    getConfigValue(config, 'Networking', 'MacAddress', ':'.join(map(lambda x: "%02x" % x, [ 0x00, 0x02, 0x46, random.randint(0x00, 0x7f), random.randint(0x00, 0xff), random.randint(0x00, 0xff) ])))

    getConfigValue(config, 'BoardsPackages', 'InstallOptionalsPackages', "no")      

    getConfigValue(config, 'Users', 'RootPassword', "armStrap")
    getConfigValue(config, 'Users', 'UserName', "armStrap")
    getConfigValue(config, 'Users', 'UserPassword', "armStrap")
    
    if getConfigSection(config, 'SwapFile') != False:
      getConfigValue(config, 'SwapFile', 'File', "/var/swap")
      getConfigValue(config, 'SwapFile', 'Size', "1024")
      getConfigValue(config, "SwapFile", 'Factor', "2")
      getConfigValue(config, "SwapFile", 'Maximum', "2048")
    
    if getConfigValue(config, 'Output', 'Image') == False:
      getConfigValue(config, 'Output', 'Device', "/dev/mmcblk0")
    else:
      getConfigValue(config, 'Output', 'ImageSize', "2048")
    
    with open(getPath("armStrap.ini"), 'w') as configfile:
      config.write(configfile)
    
    UI.logExiting()
    return config
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
  
# Read a config file
def readConfig(src):
  try:
    UI.logEntering()
    if checkFile(src):
      UI.logDebug("Reading configuration file " + getPath(src))
      config = configparser.ConfigParser()
      config.sections()
      config.read(getPath(src))
    else:
      UI.logDebug("Configuration file " + getPath(src) + " does not exist")
      config = False
    UI.logExiting()
    return config
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Get a section from a configuration list or configParser Object, return False if it doesn't exist.
def getConfigSection(config, section):
  try:
    UI.logEntering()
    if isinstance(config, configparser.ConfigParser):
      if config.has_section(section):
        UI.logDebug(section + " found")
        UI.logExiting()
        return config[section]
    elif isinstance(config, dict):
      if section in config:
        UI.logDebug(section + " found")
        UI.logExiting()
        return config[section]
    UI.logDebug("section " + section + " not found")
    UI.logExiting()
    return False
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Get a value from a configuration list or configParser object, return False if it doesn't exist.
# Or set it to its default value if one exist.
def getConfigValue(config, section, key, defaultValue = False):
  try:
    UI.logEntering()
    if isinstance(config, configparser.ConfigParser):
      if config.has_section(section):
        if config.has_option(section, key):
          UI.logDebug("Key " + key + " found in section " + section)
          UI.logExiting()
          return config[section][key]
        else:
          UI.logDebug("Key " + key + " not found in section " + section)
          if defaultValue != False:
            setConfigValue(config = config, section = section, key = key, value = defaultValue)
            UI.logExiting()
            return config[section][key]
      else:
        UI.logDebug(section + " not found")
        if defaultValue != False:
          setConfigValue(config = config, section = section, key = key, value = defaultValue)
          UI.logExiting()
          return config[section][key]
      return False
    elif isinstance(config, dict):
      if section in config:
        if key in config[section]:
          UI.logDebug("Key " + key + " found in section " + section)
          UI.logExiting()
          return config[section][key]
        else:
          UI.logDebug("Key " + key + " not found in section " + section)
          if defaultValue != False:
            setConfigValue(config = config, section = section, key = key, value = defaultValue)
            UI.logExiting()
            return config[section][key]
      else:
        UI.logDebug(section + " not found")
        if defaultValue != False:
          setConfigValue(config = config, section = section, key = key, value = defaultValue)
          UI.logExiting()
          return config[section][key]
      return False
    else:
      UI.logDebug("Parameter config is not a supported type") 
      UI.logExiting()
      return False
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Set a value in a configuration list or configParser object.
def setConfigValue(config, section, key, value):
  try:
    UI.logEntering()
    if isinstance(config, configparser.ConfigParser):
      if not config.has_section(section):
        UI.logDebug("Creating section " + section)
        config[section] = { }
      if not config.has_option(section, key):
        UI.logDebug("Adding key " + key + " with value " + value + " to section " + section)
        config[section][key] = value
    elif isinstance(config, dict):
      if not section in config:
        UI.logDebug("Creating section " + section)
        config[section] = { }
      if not key in config[section]:
        UI.logDebug("Adding key " + key + " with value " + value + " to section " + section)
        config[section][key] = value
    else:
      UI.logExiting()
      return False
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Execute a command, capturing its output
def captureCommand(command):
  try:
    UI.logEntering()
    UI.logDebug("Capturing output of " + command)
    p = subprocess.Popen( command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (cmd_stdout_bytes, cmd_stderr_bytes) = p.communicate()
    UI.logExiting()
    return ( str(cmd_stdout_bytes.decode('utf-8')), str(cmd_stderr_bytes.decode('utf-8')) )
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
    
# Execute a command in the chroot environment, capturing its output
def captureChrootCommand(command):
  try:
    UI.logEntering()
    UI.logDebug("Capturing output of " + command + " in chroot")
    p = subprocess.Popen( "LC_ALL='' LANGUAGE='en_US:en' LANG='en_US.UTF-8' /usr/sbin/chroot " + getPath("mnt") + " " + command , shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (cmd_stdout_bytes, cmd_stderr_bytes) = p.communicate()
    UI.logExiting()
    return ( str(cmd_stdout_bytes.decode('utf-8')), str(cmd_stderr_bytes.decode('utf-8')) )
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

#Execute a command, dropping its output
def runCommand(command):
  try:
    UI.logEntering()
    UI.logDebug("Executing " + command)
    err = os.system(command + " > /dev/null 2>&1")
    UI.logDebug("Error Code : " + str(err) + ", " + os.strerror(err))
    if err != os.EX_OK:
      Exit(text = "Error while running " + command +" (Error Code " + str(err) + ", " + os.strerror(err), title = "Fatal Error", timeout = 5, exitStatus = err)
    UI.logExiting()
    return err
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

#Execute a command in the chroot environment, dropping its output
def runChrootCommand(command):
  try:
    UI.logEntering()
    UI.logDebug("Executing " + command + " in chroot")
    err = os.system("LC_ALL='' LANGUAGE='en_US:en' LANG='en_US.UTF-8' /usr/sbin/chroot " + getPath("mnt") + " " + command + " > /dev/null 2>&1")
    if err != os.EX_OK:
      UI.logWarning( "Error while running " + command +" (Error Code " + str(err) + ", " + os.strerror(err))
      raise OSError
    UI.logExiting()
    return err
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
    
#Execute apt-get -q -y [command] ih the chroot environment, with optional arguments.
def runChrootAptGet(command, arguments = False):
  try:
    UI.logEntering()
    if( arguments != False ):
      UI.logDebug("Executing apt-get " + command + " " + " ".join(arguments))
      UI.chrootProgressBox( cmd = "/usr/bin/apt-get -q -y " + command + " " + " ".join(arguments) , path = getPath("mnt"), title = "Running apt-get " + command )
    else:
      UI.logDebug("Executing apt-get " + command)
      UI.chrootProgressBox( cmd = "/usr/bin/apt-get -q -y " + command , path = getPath("mnt"), title = "Running apt-get " + command )
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

#Read a json url and return it as a dict
def loadJson(type, args = False):
  try:
    if args == False:
      url = builtins.urlInfo['baseUrl'] + "/" + builtins.urlInfo['jsonDrv'] + "?type=" + type 
    else:
      url = builtins.urlInfo['baseUrl'] + "/" + builtins.urlInfo['jsonDrv'] + "?type=" + type + "&" + "&".join(args)
    UI.logDebug("Requesting json configuration from " + url)
    return(requests.get(url).json())
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

# Copy a file    
def copyFiles(src, dst):
  try:
    UI.logEntering()
    UI.logDebug("Copying " + src + " to " + dst)
    shutil.copy(src, dst)
    UI.logExiting()
    return True
  except SystemExit:
    pass 
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
    
# List all avalables Kernels
def listKernels():
  try:
    kFormat = "{0:15} {1:31} {2}"
    print("Avalable Kernels:\n")
    print(kFormat.format("Kernel", "BootLoader", "Compatible CPU"))
    print(kFormat.format("---------------", "-------------------------------", "-------------------------------"))
    Kernels = loadJson( type = "config", args = "config=kernels".split() )
    for section in sorted(Kernels):
      print(kFormat.format(section, Kernels[section]['bootloader'], " ".join(Kernels[section]['cpu'])))
    print("")
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
    
# Liste all avalables RootFS
def listRootFS():
  try:
    rFormat = "{0:15} {1:15} {2}"
    print("Avalable Root FileSystems distributions:\n")
    print(rFormat.format("Family", "Arch", "Versions"))
    print(rFormat.format("---------------", "---------------", "----------------------------------------------"))
    rootFSList = loadJson(type = "rootfs")
    for arch in sorted(rootFSList):
      for family in sorted(rootFSList[arch]):
        print(rFormat.format(family, arch, ", ".join(sorted(list(rootFSList[arch][family].keys())))))
    print("")
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

def listBoards():
  try:
    bFormat = "{0:15} {1:15} {2}"
    print("Avalable Boards:\n")
    print(bFormat.format("Model", "Arch", "CPU"))
    print(bFormat.format("---------------", "---------------", "----------------------------------------------"))
    armStrapCfg = loadJson(type = "config", args = ("config=armstrap".split()))
    for type in sorted(armStrapCfg['Boards']['Types']):
      boardsCfg = loadJson(type = "config", args = ("config=" + type).split())
      for model in boardsCfg['Boards']['Models']:
        print(bFormat.format(model, boardsCfg['Common']['CpuArch'] + boardsCfg['Common']['CpuFamily'], boardsCfg[model]['Cpu']))
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
    
# Mount all partitions
def mountPartitions(Device, partList):
  try:
    UI.logEntering()
    order = 1
    sortedList = []
    builtins.Status.update(name = "Installing RootFS", value = "-0")
    while len(sortedList) != len(partList):
      for p in partList:
        if int(p['Mount_Order']) == order:
          order += 1
          sortedList.append( {'device': p['device'], 'Mount_Point': p['Mount_Point']} )
    for p in sortedList:
      d = checkPath("mnt/" + p['Mount_Point'].strip('/'))
      builtins.Status.update(text="Mounting partition " + p['device'] + " to " + d, percent = builtins.Status.getPercent())
      runCommand( command = "/bin/mount " + p['device'] + " " + d)
    UI.logExiting()
    return sortedList
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_IOERR)

# Unmount all partitions
def unmountPartitions():
  try:
    UI.logEntering()
    for p in builtins.partList[::-1]:
      d = checkPath("mnt/" + p['Mount_Point'].strip('/'))
      if builtins.Status != False:
        builtins.Status.update(text="Unmounting partition " + p['device'] + " from " + d, percent = builtins.Status.getPercent())
      runCommand( command = "/bin/umount " + d)
  
    if builtins.Device.find("loop") != -1:
      runCommand( command = "/sbin/losetup -d " + builtins.Device)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    pass

# Exit from armStrap.
def Exit(text = "", title = "", timeout = 0, exitStatus = os.EX_OK):
  try:
    UI.logDebug("Shutting down")
    mp = getPath("mnt")
    mountList = []
    with open("/proc/mounts", "r") as f:
      for mount in f.readlines():
        if mount.find(mp) != -1:
          mountList.append(mount.split()[1])
    for mount in sorted(mountList, reverse = True):
      os.system("/bin/umount " + mount + " > /dev/null 2>&1")
    if builtins.Status != False:
      builtins.Status.end()
    builtins.Dialog.pause(text = text, title = title, seconds = timeout, backtitle = builtins.Header)
    logging.shutdown()
    logFile = os.path.join( os.getcwd(), "armStrap.log" )
    if os.path.isfile(logFile):
      if os.stat(logFile).st_size == 0:
        os.unlink(logFile)
    os._exit(exitStatus)
  except:
    logging.exception("Caught Exception")
    os._exit(exitStatus)

import logging
import os
import shutil
import subprocess
from lib import ui as UI
from lib import utils as Utils

def installRootFS(url, config, boards, status):
  try:
    UI.logInfo("Entering")
    file = boards['Common']['CpuArch'] + boards['Common']['CpuFamily'] + "-" + config['Distribution']['Family'] + "-" + config['Distribution']['Version'] + ".txz"
    status.update(text="Downloading RootFS image " + file, percent = status.getPercent())  
    Utils.download(url + "/" + file)
    status.update(name = "Installing RootFS", value = "-5", text="Extracting RootFS image " + file, percent = status.getPercent())
    Utils.extractTar(file, "mnt")
    Utils.unlinkFile(file)
    status.update(name = "Installing RootFS", value = "-10")
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

def chrootConfig(status):
  try:
    UI.logInfo("Entering")
    shutil.copy("/usr/bin/qemu-arm-static", Utils.getPath("mnt/usr/bin/qemu-arm-static"))
    Utils.touch("mnt/usr/sbin/policy-rc.d.lock")
    if os.path.isfile(Utils.getPath("mnt/usr/sbin/policy-rc.d")):
      shutil.move(Utils.getPath("mnt/usr/sbin/policy-rc.d"), Utils.getPath("mnt/usr/sbin/policy-rc.d_save"))
    f = open(Utils.getPath("mnt/usr/sbin/policy-rc.d"), 'w')
    f.write("exit 101\n")
    f.close()
    os.chmod(Utils.getPath("mnt/usr/sbin/policy-rc.d"), 0o755 )
    Utils.runCommand(command = "/bin/mount --bind /proc " + Utils.getPath("mnt/proc"), status = status)
    Utils.runCommand(command = "/bin/mount --bind /sys " + Utils.getPath("mnt/sys"), status = status)
    Utils.runCommand(command = "/bin/mount --bind /dev/pts " + Utils.getPath("mnt/dev/pts"), status = status)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False
  
def chrootDeconfig(status):
  try:
    UI.logInfo("Entering")
    Utils.runCommand(command = "/bin/umount " + Utils.getPath("mnt/dev/pts"), status = status)
    Utils.runCommand(command = "/bin/umount " + Utils.getPath("mnt/sys"), status = status)
    Utils.runCommand(command = "/bin/umount " + Utils.getPath("mnt/proc"), status = status)
    Utils.unlinkFile("mnt/usr/sbin/policy-rc.d")
    if os.path.isfile(Utils.getPath("mnt/usr/sbin/policy-rc.d_save")):
      shutil.move(Utils.getPath("mnt/usr/sbin/policy-rc.d_save"), Utils.getPath("mnt/usr/sbin/policy-rc.d"))
    os.unlink("mnt/usr/sbin/policy-rc.d.lock")
    os.unlink("mnt/usr/bin/qemu-arm-static")
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

def chrootPasswd(Password, status):
  try:
    UI.logInfo("Entering")
    status.update(text = "Setting root password")
    PasswordNL=Password + "\n"
    proc = subprocess.Popen(['/usr/sbin/chroot', Utils.getPath("mnt"), '/usr/bin/passwd', 'root'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    proc.stdin.write(PasswordNL.encode('ascii'))
    proc.stdin.write(Password.encode('ascii'))
    proc.stdin.flush()
    stdout,stderr = proc.communicate()
    UI.logInfo("Exiting")
    return (stdout.decode('utf-8'), stderr.decode('utf-8'))
  except:
    UI.logException(False)
    return ( False, False )

def setLocales(config, status):
  try:
    UI.logInfo("Entering")
    status.update(text = "Setting locales")
    if Utils.checkFile(Utils.getPath("mnt/etc/locale.gen")):
      for locale in config['Board']['Locales'].split():
        status.update(text = "Configuring locale " + locale)
        Utils.appendFile(file = Utils.getPath("mnt/etc/locale.gen"), lines = [locale + " " + locale.split('.')[1] ] )
      status.update(text = "Running locale-gen")
      Utils.runChrootCommand(command = "/usr/sbin/locale-gen", status = status)
      status.update(text = "Running update-locale")
      Utils.runChrootCommand(command = "/usr/sbin/update-locale LANG=" + config['Board']['Locales'].split()[0] + " LC_MESSAGES=POSIX", status = status)
    else:
      for locale in config['Board']['Locales'].split():
        status.update(text = "Generating locale " + locale)
        Utils.runChrootCommand(command = "/usr/sbin/locale-gen " + locale, status = status)
      status.update(text = "Running update-locale")
      Utils.runChrootCommand(command = "/usr/sbin/update-locale LANG=" + config['Board']['Locales'].split()[0] + " LC_MESSAGES=POSIX", status = status)
      status.update(text = "Running dpkg-reconfigure locales")
      Utils.runChrootCommand(command = "/usr/sbin/dpkg-reconfigure locales", status = status)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

def setTimeZone(config, status):
  try:
    UI.logInfo("Entering")
    status.update(text = "Setting timezone to " + config['Board']['TimeZone'])
    if Utils.checkFile(Utils.getPath("mnt/usr/share/zoneinfo/" + config['Board']['TimeZone'])):
      Utils.runChrootCommand(command = "ln -sf /usr/share/zoneinfo/" + config['Board']['TimeZone'] +" /etc/localtime", status = status)
      Utils.unlinkFile("mnt/etc/timezone")
      Utils.appendFile(file = Utils.getPath("mnt/etc/timezone"), lines = [ config['Board']['TimeZone'] ])
    else:
      MessageBox(text = "TimeZone " + config['Board']['TimeZone'] + " not found. You will need to configure it manually.", title = "Non-Fatal Error", timeout = 10 )
    return True
  except:
    UI.logException(False)
    return False
    
def setSwapFile(config, status):
  try:
    UI.logInfo("Entering")
    Utils.unlinkFile("mnt/etc/dphys-swapfile")
    lines = []
    
    if config.has_option('SwapFile', 'Size'):
      lines.append("CONF_SWAPSIZE=" + config['SwapFile']['Size'])
    else:
      lines.append("#CONF_SWAPSIZE=")
    
    if config.has_option('SwapFile', 'File'):
      lines.append("CONF_SWAPFILE=" + config['SwapFile']['File'])
    else:
      lines.append("#CONF_SWAPFILE=/var/swap")
      
    if config.has_option('SwapFile', 'Factor'):
      lines.append("CONF_SWAPFACTOR=" + config['SwapFile']['Factor'])
    else:
      lines.append("#CONF_SWAPFACTOR=2")
    
    if config.has_option('SwapFile', 'Maximum'):
      lines.append("CONF_MAXSWAP=" + config['SwapFile']['Maximum'])
    else:
      lines.append("#CONF_MAXSWAP=2048")
      
    Utils.appendFile(file = Utils.getPath("mnt/etc/dphys-swapfile"), lines = lines)
    return True
  except:
    UI.logException(False)
    return False

def setHostName(config, status):
  try:
    UI.logInfo("Entering")
    status.update(text = "Setting hostname to " + config['Board']['HostName'])
    Utils.unlinkFile("mnt/etc/hostname")
    Utils.appendFile(file = Utils.getPath("mnt/etc/hostname"), lines = [config['Board']['HostName'] ])
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

def setTTY(config, status):
  try:
    UI.logInfo("Entering")
    if Utils.checkFile(Utils.getPath("mnt/etc/inittab")):
      status.update(text = "Setting inittab for " + config['Serial']['TerminalDevice'])
      line = config['Serial']['TerminalID'] + ":" + config['Serial']['RunLevel'] +":respawn:/sbin/getty -L " + config['Serial']['TerminalDevice'] + " " + config['Serial']['TerminalSpeed'] + " " + config['Serial']['TerminalType']
      Utils.appendFile(file = Utils.getPath("mnt/etc/inittab"))
    else:
      lines = []
      status.update(text = "Setting service for " + config['Serial']['TerminalDevice'])
      Utils.unlinkFile("mnt/etc/init/" + config['Serial']['TerminalDevice'] + ".conf")
      lines.append("# " + config['Serial']['TerminalDevice'] + " - getty")
      lines.append("#\n# This service maintains a getty on " + config['Serial']['TerminalDevice'] + " from the point the system is\n# started until it is shut down again.\n")
      lines.append("start on stopped rc or RUNLEVEL=[" + config['Serial']['RunLevel'] + "]\n")
      lines.append("stop on runlevel [!"+ config['Serial']['RunLevel'] + "]\n")
      lines.append("respawn\nexec /sbin/getty -L " + config['Serial']['TerminalSpeed'] + " " + config['Serial']['TerminalDevice'] + " " + config['Serial']['TerminalType'])
      Utils.appendFile(file = Utils.getPath("mnt/etc/init/" + config['Serial']['TerminalDevice'] + ".conf"), lines = lines)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

def setFsTab(config, status):
  try:
    UI.logInfo("Entering")
    partList = []
    partID = 1
    fFormat = "{0:<23} {1:<15} {2:<7} {3:<15} {4:<7} {5}"
    partList.append( fFormat.format( "# <file system>", "<mount point>", "<type>", "<options>", "<dump>", "<pass>" ) )
    status.update(text = "Configuring fstab ")
    for partition in config['Partitions']['Layout'].split( ):
      p = partition.split(':')
      partList.append( fFormat.format( config['Partitions']['Device'] + config['Partitions']['PartitionPrefix'] + str(partID), p[1], p[2], "defaults", "0", "1" ) )
      partID += 1
    Utils.unlinkFile("mnt/etc/fstab")
    Utils.appendFile(file = Utils.getPath("mnt/etc/fstab"), lines = partList)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

def setInterface(config, boards, status):
  try:
    UI.logInfo("Entering")
    interface = []
    interface.append( "auto " + boards['Network']['Interface'] )
    interface.append( "allow-hotplug " + boards['Network']['Interface'] + "\n" )
    if config.has_section("Networking"):
      if config.has_option('Networking', 'Mode'):
        if (config['Networking']['Mode'].lower() == "static"):
          interface.append( "iface " + boards['Network']['Interface'] + " inet static" )
          if config.has_option('Networking', 'Ip'):
            interface.append( "\taddress " + config['Networking']['Ip'] )
          if config.has_option('Networking', 'Mask'):
            interface.append( "\tnetmask " + config['Networking']['Mask'] )
          if config.has_option('Networking', 'Gateway'):
            interface.append( "\tgateway " + config['Networking']['Gateway'] )
          if config.has_option('Networking', 'DNS'):
            interface.append( "\tdns-nameserver " + config['Networking']['DNS'] )
          if config.has_option('Networking', 'Domain'):
            interface.append( "\tdns-search " + config['Networking']['Domain'] )
        else:
          interface.append( "iface " + boards['Network']['Interface'] + " inet dhcp" )
      else:
        interface.append( "iface " + boards['Network']['Interface'] + " inet dhcp" )
    else:
      interface.append( "iface " + boards['Network']['Interface'] + " inet dhcp" )
    interface.append( "\thwaddress ether " + config['Networking']['MacAddress'] )    
    Utils.unlinkFile("mnt/etc/network/interfaces")
    Utils.appendFile(file = Utils.getPath("mnt/etc/network/interfaces"), lines = interface)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False
  
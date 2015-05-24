import builtins
import logging
import os
import shutil
import subprocess

from lib import ui as UI
from lib import utils as Utils

def installRootFS(url):
  try:
    UI.logEntering()
    file = builtins.Boards['Common']['CpuArch'] + builtins.Boards['Common']['CpuFamily'] + "-" + builtins.Config['Distribution']['Family'] + "-" + builtins.Config['Distribution']['Version'] + ".txz"
    builtins.Status.update(text="Downloading RootFS image " + file, percent = builtins.Status.getPercent())  
    Utils.download(url + "/" + file)
    builtins.Status.update(name = "Installing RootFS", value = "-5", text="Extracting RootFS image " + file, percent = builtins.Status.getPercent())
    Utils.extractTar(file, "mnt")
    Utils.unlinkFile(file)
    builtins.Status.update(name = "Installing RootFS", value = "-10")
    UI.logExiting()
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

def chrootConfig():
  try:
    UI.logEntering()
    shutil.copy("/usr/bin/qemu-arm-static", Utils.getPath("mnt/usr/bin/qemu-arm-static"))
    Utils.touch("mnt/usr/sbin/policy-rc.d.lock")
    if os.path.isfile(Utils.getPath("mnt/usr/sbin/policy-rc.d")):
      shutil.move(Utils.getPath("mnt/usr/sbin/policy-rc.d"), Utils.getPath("mnt/usr/sbin/policy-rc.d_save"))
    f = open(Utils.getPath("mnt/usr/sbin/policy-rc.d"), 'w')
    f.write("exit 101\n")
    f.close()
    os.chmod(Utils.getPath("mnt/usr/sbin/policy-rc.d"), 0o755 )
    Utils.runCommand(command = "/bin/mount --bind /proc " + Utils.getPath("mnt/proc"))
    Utils.runCommand(command = "/bin/mount --bind /sys " + Utils.getPath("mnt/sys"))
    Utils.runCommand(command = "/bin/mount --bind /dev/pts " + Utils.getPath("mnt/dev/pts"))
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False
  
def chrootDeconfig():
  try:
    UI.logEntering()
    Utils.runCommand(command = "/bin/umount " + Utils.getPath("mnt/dev/pts"))
    Utils.runCommand(command = "/bin/umount " + Utils.getPath("mnt/sys"))
    Utils.runCommand(command = "/bin/umount " + Utils.getPath("mnt/proc"))
    Utils.unlinkFile("mnt/usr/sbin/policy-rc.d")
    if os.path.isfile(Utils.getPath("mnt/usr/sbin/policy-rc.d_save")):
      shutil.move(Utils.getPath("mnt/usr/sbin/policy-rc.d_save"), Utils.getPath("mnt/usr/sbin/policy-rc.d"))
    os.unlink("mnt/usr/sbin/policy-rc.d.lock")
    os.unlink("mnt/usr/bin/qemu-arm-static")
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

def chrootPasswd(User, Password):
  try:
    UI.logEntering()
    builtins.Status.update(text = "Setting password for user " + User)
    PasswordNL=Password + "\n"
    proc = subprocess.Popen(['/usr/sbin/chroot', Utils.getPath("mnt"), '/usr/bin/passwd', User], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    proc.stdin.write(PasswordNL.encode('ascii'))
    proc.stdin.write(Password.encode('ascii'))
    proc.stdin.flush()
    stdout,stderr = proc.communicate()
    UI.logExiting()
    return (stdout.decode('utf-8'), stderr.decode('utf-8'))
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return ( False, False )

def chrootAddUser(User, Password):
  try:
    UI.logEntering()
    builtins.Status.update(text = "Creating home directory for user " + User)
    shutil.copytree(Utils.getPath("mnt/etc/skel"), Utils.getPath("mnt/home/" + User), symlinks=True)
    Utils.runChrootCommand("/usr/sbin/useradd " + User)
    Utils.runChrootCommand("/bin/chown " + User + ":" + User + " /home/" + User)
    chrootPasswd(User = User, Password = Password)
    UI.logExiting()
    return true
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

def setLocales():
  try:
    UI.logEntering()
    builtins.Status.update(text = "Setting locales")
    if Utils.checkFile(Utils.getPath("mnt/etc/locale.gen")):
      for locale in builtins.Config['Board']['Locales'].split():
        builtins.Status.update(text = "Configuring locale " + locale)
        Utils.appendFile(file = Utils.getPath("mnt/etc/locale.gen"), lines = [locale + " " + locale.split('.')[1] ] )
      builtins.Status.update(text = "Running locale-gen")
      Utils.runChrootCommand(command = "/usr/sbin/locale-gen")
      builtins.Status.update(text = "Running update-locale")
      Utils.runChrootCommand(command = "/usr/sbin/update-locale LANG=" + builtins.Config['Board']['Locales'].split()[0] + " LC_MESSAGES=POSIX")
    else:
      for locale in builtins.Config['Board']['Locales'].split():
        builtins.Status.update(text = "Generating locale " + locale)
        Utils.runChrootCommand(command = "/usr/sbin/locale-gen " + locale)
      builtins.Status.update(text = "Running update-locale")
      Utils.runChrootCommand(command = "/usr/sbin/update-locale LANG=" + builtins.Config['Board']['Locales'].split()[0] + " LC_MESSAGES=POSIX")
      builtins.Status.update(text = "Running dpkg-reconfigure locales")
      Utils.runChrootCommand(command = "/usr/sbin/dpkg-reconfigure locales")
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

def setTimeZone():
  try:
    UI.logEntering()
    builtins.Status.update(text = "Setting timezone to " + builtins.Config['Board']['TimeZone'])
    if Utils.checkFile(Utils.getPath("mnt/usr/share/zoneinfo/" + builtins.Config['Board']['TimeZone'])):
      Utils.runChrootCommand(command = "ln -sf /usr/share/zoneinfo/" + builtins.Config['Board']['TimeZone'] +" /etc/localtime")
      Utils.unlinkFile("mnt/etc/timezone")
      Utils.appendFile(file = Utils.getPath("mnt/etc/timezone"), lines = [ builtins.Config['Board']['TimeZone'] ])
    else:
      MessageBox(text = "TimeZone " + builtins.Config['Board']['TimeZone'] + " not found. You will need to configure it manually.", title = "Non-Fatal Error", timeout = 10 )
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False
    
def setSwapFile():
  try:
    UI.logEntering()
    Utils.unlinkFile("mnt/etc/dphys-swapfile")
    lines = []
    
    if builtins.Config.has_option('SwapFile', 'Size'):
      lines.append("CONF_SWAPSIZE=" + builtins.Config['SwapFile']['Size'])
    else:
      lines.append("#CONF_SWAPSIZE=")
    
    if builtins.Config.has_option('SwapFile', 'File'):
      lines.append("CONF_SWAPFILE=" + builtins.Config['SwapFile']['File'])
    else:
      lines.append("#CONF_SWAPFILE=/var/swap")
      
    if builtins.Config.has_option('SwapFile', 'Factor'):
      lines.append("CONF_SWAPFACTOR=" + builtins.Config['SwapFile']['Factor'])
    else:
      lines.append("#CONF_SWAPFACTOR=2")
    
    if builtins.Config.has_option('SwapFile', 'Maximum'):
      lines.append("CONF_MAXSWAP=" + builtins.Config['SwapFile']['Maximum'])
    else:
      lines.append("#CONF_MAXSWAP=2048")
      
    Utils.appendFile(file = Utils.getPath("mnt/etc/dphys-swapfile"), lines = lines)
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

def setHostName():
  try:
    UI.logEntering()
    builtins.Status.update(text = "Setting hostname to " + builtins.Config['Board']['HostName'])
    Utils.unlinkFile("mnt/etc/hostname")
    Utils.appendFile(file = Utils.getPath("mnt/etc/hostname"), lines = [builtins.Config['Board']['HostName'] ])
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

def setTTY():
  try:
    UI.logEntering()
    if Utils.checkFile(Utils.getPath("mnt/etc/inittab")):
      builtins.Status.update(text = "Setting inittab for " + builtins.Boards['Serial']['TerminalDevice'])
      line = builtins.Boards['Serial']['TerminalID'] + ":" + builtins.Boards['Serial']['RunLevel'] +":respawn:/sbin/getty -L " + builtins.Boards['Serial']['TerminalDevice'] + " " + builtins.Boards['Serial']['TerminalSpeed'] + " " + builtins.Boards['Serial']['TerminalType']
      Utils.appendFile(file = Utils.getPath("mnt/etc/inittab"))
    else:
      lines = []
      builtins.Status.update(text = "Setting service for " + builtins.Boards['Serial']['TerminalDevice'])
      Utils.unlinkFile("mnt/etc/init/" + builtins.Boards['Serial']['TerminalDevice'] + ".conf")
      lines.append("# " + builtins.Boards['Serial']['TerminalDevice'] + " - getty")
      lines.append("#\n# This service maintains a getty on " + builtins.Boards['Serial']['TerminalDevice'] + " from the point the system is\n# started until it is shut down again.\n")
      lines.append("start on stopped rc or RUNLEVEL=[" + builtins.Boards['Serial']['RunLevel'] + "]\n")
      lines.append("stop on runlevel [!"+ builtins.Boards['Serial']['RunLevel'] + "]\n")
      lines.append("respawn\nexec /sbin/getty -L " + builtins.Boards['Serial']['TerminalSpeed'] + " " + builtins.Boards['Serial']['TerminalDevice'] + " " + builtins.Boards['Serial']['TerminalType'])
      Utils.appendFile(file = Utils.getPath("mnt/etc/init/" + builtins.Boards['Serial']['TerminalDevice'] + ".conf"), lines = lines)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

def setFsTab():
  try:
    UI.logEntering()
    partList = []
    partID = 1
    fFormat = "{0:<23} {1:<15} {2:<7} {3:<15} {4:<7} {5}"
    partList.append( fFormat.format( "# <file system>", "<mount point>", "<type>", "<options>", "<dump>", "<pass>" ) )
    builtins.Status.update(text = "Configuring fstab ")
    for partition in builtins.Boards['Partitions']['Layout'].split( ):
      p = partition.split(':')
      partList.append( fFormat.format( builtins.Boards['Partitions']['Device'] + builtins.Boards['Partitions']['PartitionPrefix'] + str(partID), p[1], p[2], "defaults", "0", "1" ) )
      partID += 1
    Utils.unlinkFile("mnt/etc/fstab")
    Utils.appendFile(file = Utils.getPath("mnt/etc/fstab"), lines = partList)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

def setInterface():
  try:
    UI.logEntering()
    interface = []
    interface.append( "auto " + builtins.Boards['Network']['Interface'] )
    interface.append( "allow-hotplug " + builtins.Boards['Network']['Interface'] + "\n" )
    if builtins.Config.has_section("Networking"):
      if builtins.Config.has_option('Networking', 'Mode'):
        if (builtins.Config['Networking']['Mode'].lower() == "static"):
          interface.append( "iface " + builtins.Boards['Network']['Interface'] + " inet static" )
          if builtins.Config.has_option('Networking', 'Ip'):
            interface.append( "\taddress " + builtins.Config['Networking']['Ip'] )
          if builtins.Config.has_option('Networking', 'Mask'):
            interface.append( "\tnetmask " + builtins.Config['Networking']['Mask'] )
          if builtins.Config.has_option('Networking', 'Gateway'):
            interface.append( "\tgateway " + builtins.Config['Networking']['Gateway'] )
          if builtins.Config.has_option('Networking', 'DNS'):
            interface.append( "\tdns-nameserver " + builtins.Config['Networking']['DNS'] )
          if builtins.Config.has_option('Networking', 'Domain'):
            interface.append( "\tdns-search " + builtins.Config['Networking']['Domain'] )
        else:
          interface.append( "iface " + builtins.Boards['Network']['Interface'] + " inet dhcp" )
      else:
        interface.append( "iface " + builtins.Boards['Network']['Interface'] + " inet dhcp" )
    else:
      interface.append( "iface " + builtins.Boards['Network']['Interface'] + " inet dhcp" )
    interface.append( "\thwaddress ether " + builtins.Config['Networking']['MacAddress'] )    
    Utils.unlinkFile("mnt/etc/network/interfaces")
    Utils.appendFile(file = Utils.getPath("mnt/etc/network/interfaces"), lines = interface)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False
    
def ubootSetup(Device):
  try:
    bName = builtins.Config['Board']['model'].lower()
    fName = bname + ".fex"
    UI.logDebug("Executing apt-get " + command + " " + " ".join(arguments))
    Utils.copyFiles(getPath("mnt/usr/share/armStrap-U-Boot/" + bName + "/"+ fName), getPath("mnt/boot/" + fName))
    Utils.runChrootCommand("/usr/bin/fex2bin /boot/" + fName + " /boot/script.bin")
    Utils.runCommand("/bin/dd if=" + getPath("mnt/usr/share/armStrap-U-Boot/" + bName + "/"+ fName) + " of=" + Device + " + bs=1024 seek=8")
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

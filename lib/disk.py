import builtins
import logging
import os
import sys
import subprocess
import time
from stat import *

from . import utils as Utils
from . import ui as UI

def syncFS():
  
  try:
    UI.logEntering()
    Utils.runCommand(command = "/bin/sync")
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_IOERR)
  
def partProbe(Device=""):
  try:
    UI.logEntering()
    Utils.runCommand( command = "/sbin/partprobe " + Device)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_IOERR)

def getLayout():
  try:
    UI.logEntering()
    d = []
    for i in builtins.Boards['Partitions']['Layout'].split():
      j = i.split(':')
      d.append( {'Mount_Order': j[0], 'Mount_Point': j[1], 'FileSystem': j[2], 'Size': j[3]} )
    UI.logExiting()
    return d
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)
    
def doMount(Device, Path, Bind=False):
  try:
    if Utils.isPath(Path):
      if Bind == False:
        Utils.runCommand(command = "/bin/mount " + Device + " " + Utils.getPath(Path))
      else:
        Utils.runCommand(command = "/bin/mount --bind " + Device + " " + Utils.getPath(Path))
      return True
    return False
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

def doUnMount(Path):
  try:
    if Utils.isPath(Path):
      Utils.runCommand(command = "/bin/umount " + Utils.getPath(Path))
      return True
    return False
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_SOFTWARE)

def cleanDisk(device, bs="1M", count=64):
  try:
    UI.logEntering()
    if S_ISBLK(os.stat(device).st_mode) or os.path.isfile(device):
      Utils.runCommand( command = "/bin/dd if=/dev/zero of=" + device + " bs=" + bs + " count=" + str(count) + " conv=notrunc")
    partProbe()
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_IOERR)

def formatDevice(Device, DiskLayout, percent = 0):
  try:
    UI.logEntering()
    offset = 1
    partID = 1
    step = int( ( 100 - percent) / len(DiskLayout))
    if (Device.find("loop") != -1) or (Device.find("mmcblk") != -1):
      partSlice=Device + "p"
    else:
      partSlice=Device
    partList = []
    builtins.Status.update(name = "Formatting Disk", value = "-" + str(percent), text="Cleaning " + Device, percent = builtins.Status.getPercent())
    cleanDisk(device = Device)
    time.sleep(1)
    builtins.Status.update(text="Creating label on " + Device, percent = builtins.Status.getPercent())
    Utils.runCommand( command = "/sbin/parted " + Device + " --script -- mklabel msdos")
  
    for di in DiskLayout:
      if di['FileSystem'].lower().find("fat") != -1:
        fs="fat32"
      else:
        fs=di['FileSystem']
      if int(di['Size']) != -1:
        size = int(di['Size']) + offset
      else:
        size = -1
      builtins.Status.update(text="Setting up partition " + partSlice + str(partID), percent = builtins.Status.getPercent())
      Utils.runCommand( command = "/sbin/parted " + Device + " --script -- mkpart primary " + str(fs) + " " + str(offset) + " " + str(size))
      syncFS()

      partProbe()
      builtins.Status.update(text="Waiting for partition " + partSlice + str(partID), percent = builtins.Status.getPercent())
      time.sleep(1)
      while os.path.exists(partSlice + str(partID)) == False:
        time.sleep(1)
      builtins.Status.update(text="Formatting partition " + partSlice + str(partID), percent = builtins.Status.getPercent())
      if fs == "fat32":
        Utils.runCommand( command = "/sbin/mkfs.vfat -F 32 " + partSlice + str(partID))
      else:
        Utils.runCommand( command = "/sbin/mkfs." + fs + " -q " + partSlice + str(partID))
      partList.append( {'device': partSlice + str(partID), 'Mount_Order': di['Mount_Order'], 'Mount_Point': di['Mount_Point']} )
      partID += 1
      percent += step
      builtins.Status.update(name = "Formatting Disk", value = "-" + str(percent))
      if size != -1:
        offset = size;
      else:
        break
      syncFS()
    builtins.Status.update(name = "Formatting Disk", value = "Done", text="", percent = builtins.Status.getPercent())
    UI.logExiting()
    return (Device, partList)
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_IOERR)

def formatSD():
  try:
    return formatDevice(Device = builtins.Config['Output']['Device'], DiskLayout = getLayout())
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_IOERR)

def formatIMG():
  try:
    UI.logEntering()
    if os.path.exists(Utils.getPath(builtins.Config['Output']['Image'])):
      if UI.YesNo(title = "Warning", text = "File " + builtins.Config['Output']['Image'] + " exists! Overrite?") == "cancel":
        Utils.Exit(title = "Cancel by user", text = "Will not overrite " + builtins.Config['Output']['Image'], timeout = 5)
    builtins.Status.update(name = "Formatting Disk", value = "-0", text="Creating disk image " + Utils.getPath(builtins.Config['Output']['Image']), percent = builtins.Status.getPercent())
    Utils.runCommand( command = "/usr/bin/touch " + Utils.getPath(builtins.Config['Output']['Image']))
    cleanDisk(Utils.getPath(builtins.Config['Output']['Image']), bs="1M", count=int(builtins.Config['Output']['Size']))
    builtins.Status.update(name = "Formatting Disk", value = "-25")
    (stdout, stderr) = Utils.captureCommand("/sbin/losetup -f --show " + Utils.getPath(builtins.Config['Output']['Image']))
    UI.logExiting()
    return formatDevice(Device = stdout.splitlines()[0], DiskLayout = getLayout(), percent = 25)
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_IOERR)

def isMounted():
  try:
    mountList = []
    with open("/proc/mounts", "r") as f:
      for mount in f.readlines():
        if mount.find(builtins.Config['Output']['Device']) != -1:
          return True
    return False
  except SystemExit:
    pass
  except:
    logging.exception("Caught Exception")
    sys.exit(os.EX_IOERR)

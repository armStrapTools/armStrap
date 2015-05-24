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
    UI.logException(False)
    return False
  
def partProbe(Device=""):
  try:
    UI.logEntering()
    Utils.runCommand( command = "/sbin/partprobe " + Device)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False
  UI.logExiting()

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
    UI.logException(False)
    return False

def cleanDisk(device, bs="512", count=1):
  try:
    UI.logEntering()
    if S_ISBLK(os.stat(device).st_mode) or os.path.isfile(device):
      Utils.runCommand( command = "/bin/dd if=/dev/zero of=" + device + " bs=" + bs + " count=" + str(count))
    partProbe(Device = device)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

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
      partProbe(Device = Device)
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
    UI.logException(False)
    return (False, False)

def formatSD():
  try:
    return formatDevice(Device = builtins.Config['Output']['Device'], DiskLayout = getLayout())
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return (False, False)

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
    (stdout, stderr) = captureCommand("/sbin/losetup -f --show " + Utils.getPath(builtins.Config['Output']['Image']))
    UI.logExiting()
    return formatDevice(Device = stdout.splitlines()[0], DiskLayout = getLayout(), percent = 25)
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return (False, False)

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
      d = Utils.checkPath("mnt/" + p['Mount_Point'].strip('/'))
      builtins.Status.update(text="Mounting partition " + p['device'] + " to " + d, percent = builtins.Status.getPercent())
      Utils.runCommand( command = "/bin/mount " + p['device'] + " " + d)
    UI.logExiting()
    return sortedList
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

def unmountPartitions(Device, partList):
  try:
    UI.logEntering()
    for p in partList[::-1]:
      d = Utils.checkPath("mnt/" + p['Mount_Point'].strip('/'))
      if builtins.Status != False:
        builtins.Status.update(text="Unmounting partition " + p['device'] + " from " + d, percent = builtins.Status.getPercent())
      Utils.runCommand( command = "/bin/umount " + d)
  
    if Device.find("loop") != -1:
      Utils.runCommand( command = "/sbin/losetup -d " + Device)
    UI.logExiting()
    return True
  except SystemExit:
    pass
  except:
    UI.logException(False)
    return False

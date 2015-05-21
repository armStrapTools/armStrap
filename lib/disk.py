import logging
import os
import sys
import subprocess
import time
from stat import *

from . import utils as Utils
from . import ui as UI

def syncFS(status):
  
  try:
    UI.logInfo("Entering")
    Utils.runCommand(command = "/bin/sync", status = status)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False
  
def partProbe(status, Device=""):
  try:
    UI.logInfo("Entering")
    Utils.runCommand( command = "/sbin/partprobe " + Device, status = status)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False
  UI.logInfo("Exiting")

def getLayout(config):
  try:
    UI.logInfo("Entering")
    d = []
    for i in config['Partitions']['Layout'].split():
      j = i.split(':')
      d.append( {'Mount_Order': j[0], 'Mount_Point': j[1], 'FileSystem': j[2], 'Size': j[3]} )
    UI.logInfo("Exiting")
    return d
  except:
    UI.logException(False)
    return False

def cleanDisk(device, status, bs="512", count=1):
  try:
    UI.logInfo("Entering")
    if S_ISBLK(os.stat(device).st_mode) or os.path.isfile(device):
      Utils.runCommand( command = "/bin/dd if=/dev/zero of=" + device + " bs=" + bs + " count=" + str(count), status = status)
    partProbe(Device = device, status = status)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

def formatDevice(Device, DiskLayout, status, percent = 0):
  try:
    UI.logInfo("Entering")
    offset = 1
    partID = 1
    step = int( ( 100 - percent) / len(DiskLayout))
    if (Device.find("loop") != -1) or (Device.find("mmcblk") != -1):
      partSlice=Device + "p"
    else:
      partSlice=Device
    partList = []
    status.update(name = "Formatting Disk", value = "-" + str(percent), text="Cleaning " + Device, percent = status.getPercent())
    cleanDisk(device = Device, status = status)
    time.sleep(1)
    status.update(text="Creating label on " + Device, percent = status.getPercent())
    Utils.runCommand( command = "/sbin/parted " + Device + " --script -- mklabel msdos", status = status)
  
    for di in DiskLayout:
      if di['FileSystem'].lower().find("fat") != -1:
        fs="fat32"
      else:
        fs=di['FileSystem']
      if int(di['Size']) != -1:
        size = int(di['Size']) + offset
      else:
        size = -1
      status.update(text="Setting up partition " + partSlice + str(partID), percent = status.getPercent())
      Utils.runCommand( command = "/sbin/parted " + Device + " --script -- mkpart primary " + str(fs) + " " + str(offset) + " " + str(size), status = status)
      syncFS(status = status)
      partProbe(Device = Device, status = status)
      status.update(text="Waiting for partition " + partSlice + str(partID), percent = status.getPercent())
      time.sleep(1)
      while os.path.exists(partSlice + str(partID)) == False:
        time.sleep(1)
      status.update(text="Formatting partition " + partSlice + str(partID), percent = status.getPercent())
      if fs == "fat32":
        Utils.runCommand( command = "/sbin/mkfs.vfat -F 32 " + partSlice + str(partID), status = status)
      else:
        Utils.runCommand( command = "/sbin/mkfs." + fs + " -q " + partSlice + str(partID), status = status)
      partList.append( {'device': partSlice + str(partID), 'Mount_Order': di['Mount_Order'], 'Mount_Point': di['Mount_Point']} )
      partID += 1
      percent += step
      status.update(name = "Formatting Disk", value = "-" + str(percent))
      if size != -1:
        offset = size;
      else:
        break
      syncFS(status = status)
    status.update(name = "Formatting Disk", value = "Done", text="", percent = status.getPercent())
    UI.logInfo("Exiting")
    return (Device, partList)
  except:
    UI.logException(False)
    return (False, False)

def formatSD(config, boards, status):
  try:
    return formatDevice(Device = config['Output']['Device'], DiskLayout = getLayout(boards), status = status)
  except:
    UI.logException(False)
    return (False, False)

def formatIMG(config, boards, status):
  try:
    UI.logInfo("Entering")
    if os.path.exists(Utils.getPath(config['Output']['Image'])):
      if UI.YesNo(title = "Warning", text = "File " + config['Output']['Image'] + " exists! Overrite?") == "cancel":
        Utils.Exit(title = "Cancel by user", text = "Will not overrite " + config['Output']['Image'], timeout = 5)
    status.update(name = "Formatting Disk", value = "-0", text="Creating disk image " + Utils.getPath(config['Output']['Image']), percent = status.getPercent())
    Utils.runCommand( command = "/usr/bin/touch " + Utils.getPath(config['Output']['Image']), status = status)
    cleanDisk(Utils.getPath(config['Output']['Image']), bs="1M", count=int(config['Output']['Size']))
    status.update(name = "Formatting Disk", value = "-25")
    (stdout, stderr) = captureCommand("/sbin/losetup -f --show " + Utils.getPath(config['Output']['Image']))
    UI.logInfo("Exiting")
    return formatDevice(Device = stdout.splitlines()[0], DiskLayout = getLayout(boards), status = status, percent = 25)
  except:
    UI.logException(False)
    return (False, False)

def mountPartitions(Device, partList, status):
  try:
    UI.logInfo("Entering")
    order = 1
    sortedList = []
    status.update(name = "Installing RootFS", value = "-0")
    while len(sortedList) != len(partList):
      for p in partList:
        if int(p['Mount_Order']) == order:
          order += 1
          sortedList.append( {'device': p['device'], 'Mount_Point': p['Mount_Point']} )
    for p in sortedList:
      d = Utils.checkPath("mnt/" + p['Mount_Point'].strip('/'))
      status.update(text="Mounting partition " + p['device'] + " to " + d, percent = status.getPercent())
      Utils.runCommand( command = "/bin/mount " + p['device'] + " " + d, status = status)
    UI.logInfo("Exiting")
    return sortedList
  except:
    UI.logException(False)
    return False

def unmountPartitions(Device, partList, status):
  try:
    UI.logInfo("Entering")
    for p in partList[::-1]:
      d = Utils.checkPath("mnt/" + p['Mount_Point'].strip('/'))
      if status != False:
        status.update(text="Unmounting partition " + p['device'] + " from " + d, percent = status.getPercent())
      Utils.runCommand( command = "/bin/umount " + d, status = status)
  
    if Device.find("loop") != -1:
      Utils.runCommand( command = "/sbin/losetup -d " + Device, status = status)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

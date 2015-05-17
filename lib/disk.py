import os
import sys
import subprocess
import time
from stat import *

from . import utils as Utils
from . import ui as UI

def syncFS():
  Utils.captureCommand("/bin/sync")
  
def partProbe(Device=""):
  Utils.captureCommand("/sbin/partprobe", Device)

def getLayout(config):
  d = []
  for i in config['Partitions']['Layout'].split():
    j = i.split(':')
    d.append( {'Mount_Order': j[0], 'Mount_Point': j[1], 'FileSystem': j[2], 'Size': j[3]} )
  return d

def cleanDisk(device, bs="512", count=1):
  if S_ISBLK(os.stat(device).st_mode) or os.path.isfile(device):
    Utils.captureCommand("/bin/dd", "if=/dev/zero", "of=" + device, "bs=" + bs, "count=" + str(count))
  else:
    raise

def formatDevice(Device, DiskLayout, status, percent = 0):
  offset = 1
  partID = 1
  step = int( ( 100 - percent) / len(DiskLayout))
  if Device.find("loop") != -1:
    partSlice=Device + "p"
  else:
    partSlice=Device
  partList = []
  status.update_item(name = "Formatting Disk", value = "-" + str(percent))
  status.update_main(text="Cleaning " + Device, percent = status.getPercent())
  cleanDisk(Device)
  time.sleep(1)
  status.update_main(text="Creating label on " + Device, percent = status.getPercent())
  Utils.captureCommand("/sbin/parted", Device, "--script", "--", "mklabel", "msdos")
  
  for di in DiskLayout:
    if di['FileSystem'].lower().find("fat") != -1:
      fs="fat32"
    else:
      fs=di['FileSystem']
    if int(di['Size']) != -1:
      size = int(di['Size']) + offset
    else:
      size = -1
    status.update_main(text="Setting up partition " + partSlice + str(partID), percent = status.getPercent())
    Utils.captureCommand("/sbin/parted", Device, "--script", "--", "mkpart", "primary", str(fs), str(offset), str(size))
    syncFS()
    partProbe(Device = Device)
    status.update_main(text="Waiting for partition " + partSlice + str(partID), percent = status.getPercent())
    time.sleep(1)
    while os.path.exists(partSlice + str(partID)) == False:
      time.sleep(1)
    status.update_main(text="Formatting partition " + partSlice + str(partID), percent = status.getPercent())
    if fs == "fat32":
      Utils.captureCommand("/sbin/mkfs.vfat", "-F", "32", partSlice + str(partID))
    else:
      Utils.captureCommand("/sbin/mkfs." + fs, partSlice + str(partID))
    partList.append( {'device': partSlice + str(partID), 'Mount_Order': di['Mount_Order'], 'Mount_Point': di['Mount_Point']} )
    partID += 1
    percent += step
    status.update_item(name = "Formatting Disk", value = "-" + str(percent))
    if size != -1:
      offset = size;
    else:
      break
  syncFS()
  status.update_item(name = "Formatting Disk", value = "Done")
  status.update_main(text="", percent = status.getPercent())
  return (Device, partList)

def formatSD(config, boards, status):
  return formatDevice(Device = config['Output']['Device'], DiskLayout = getLayout(boards), status = status)

def formatIMG(config, boards, status):
  if os.path.exists(Utils.getPath(config['Output']['Image'])):
    if UI.YesNo(title = "Warning", text = "File " + config['Output']['Image'] + " exists! Overrite?") == "cancel":
      Utils.Exit(title = "Cancel by user", text = "Will not overrite " + config['Output']['Image'], timeout = 5)
  status.update_item(name = "Formatting Disk", value = "-0")
  status.update_main(text="Creating disk image " + Utils.getPath(config['Output']['Image']), percent = status.getPercent())
  Utils.captureCommand("/usr/bin/touch", Utils.getPath(config['Output']['Image']))
  cleanDisk(Utils.getPath(config['Output']['Image']), bs="1M", count=int(config['Output']['Size']))
  status.update_item(name = "Formatting Disk", value = "-25")
  (stdout, stderr) = Utils.captureCommand('/sbin/losetup', '-f' , '--show', Utils.getPath(config['Output']['Image']))
  return formatDevice(Device = stdout.splitlines()[0], DiskLayout = getLayout(boards), status = status, percent = 25)

def mountPartitions(Device, partList, status):
  order = 1
  sortedList = []
  status.update_item(name = "Installing RootFS", value = "-0")
  while len(sortedList) != len(partList):
    for p in partList:
      if int(p['Mount_Order']) == order:
        order += 1
        sortedList.append( {'device': p['device'], 'Mount_Point': p['Mount_Point']} )
  for p in sortedList:
    d = Utils.checkPath("mnt/" + p['Mount_Point'].strip('/'))
    status.update_main(text="Mounting partition " + p['device'] + " to " + d, percent = status.getPercent())
    Utils.captureCommand("/bin/mount", p['device'], d)
  return sortedList

def unmountPartitions(Device, partList, status):
  for p in partList[::-1]:
    d = Utils.checkPath("mnt/" + p['Mount_Point'].strip('/'))
    status.update_main(text="Unmounting partition " + p['device'] + " from " + d, percent = status.getPercent())
    Utils.captureCommand("/bin/umount", d)
  
  if Device.find("loop") != -1:
    Utils.captureCommand('/sbin/losetup', "-d", Device)

  

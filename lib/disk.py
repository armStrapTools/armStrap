import os
import sys
import subprocess
import time
from stat import *

from . import utils as Utils
from . import ui as UI

def syncFS():
  subprocess.check_output(["/bin/sync"], stderr=subprocess.STDOUT)
  
def partProbe(device=""):
  subprocess.check_output(["/sbin/partprobe", device], stderr=subprocess.STDOUT)

def getLayout(config):
  d = []
  for i in config['Partitions']['Layout'].split():
    j = i.split(':')
    d.append( {'Mount_Order': j[0], 'Mount_Point': j[1], 'FileSystem': j[2], 'Size': j[3]} )
  return d

def cleanDisk(device, bs="512", count=1):
  if S_ISBLK(os.stat(device).st_mode) or os.path.isfile(device):
    subprocess.check_output(["/bin/dd", "if=/dev/zero", "of=" + device, "bs=" + bs, "count=" + str(count)], stderr=subprocess.STDOUT)
  else:
    raise

def formatDevice(Device, DiskLayout, status, percent = 0):
  offset = 1
  partid = 1
  step = int( ( 100 - percent) / len(DiskLayout))
  status.update_item(name = "Formatting disk", value = "-" + str(percent))
  status.update_main(text="Cleaning " + Device)
  cleanDisk(Device)
  subprocess.check_output(["/sbin/parted", Device, "--script", "--", "mklabel", "msdos"], stderr=subprocess.STDOUT)
  
  for di in DiskLayout:
    if di['FileSystem'].lower().find("fat") != -1:
      fs="fat32"
    else:
      fs=di['FileSystem']
    if int(di['Size']) != -1:
      size = int(di['Size']) + offset
    else:
      size = -1
    status.update_main(text="Setting up partition " + Device + str(partid))
    subprocess.check_output(["/sbin/parted", Device, "--script", "--", "mkpart", "primary", str(fs), str(offset), str(size)], stderr=subprocess.STDOUT)
    syncFS()
    partProbe(device = Device)
    while os.path.exists(Device + str(partid)) == False:
      time.sleep(1)
    if fs == "fat32":
      subprocess.check_output(["/sbin/mkfs.vfat", "-F", "32", Device + str(partid)], stderr=subprocess.STDOUT)
    else:
      subprocess.check_output(["/sbin/mkfs." + fs, Device + str(partid)], stderr=subprocess.STDOUT)
    partid += 1
    percent += step
    status.update_item(name = "Formatting disk", value = "-" + str(percent))
    if size != -1:
      offset = size;
    else:
      break
  syncFS()
  status.update_item(name = "Formatting disk", value = "Done")
  status.update_main(text="")
  

def formatSD(config, boards, status):
  formatDevice(config['Output']['Device'], getLayout(boards), status)

def formatIMG(config, boards, status):
  if os.path.exists(Utils.getPath(config['Output']['Image'])):
    if UI.YesNo(title = "Warning", text = "File " + config['Output']['Image'] + " exists! Overrite?") == "cancel":
      Utils.Exit(title = "Cancel by user", text = "Will not overrite " + config['Output']['Image'], timeout = 5)
  status.update_item(name = "Formatting disk", value = "-0")
  status.update_main(text="Creating disk image " + Utils.getPath(config['Output']['Image']))
  subprocess.check_output(["/usr/bin/touch", Utils.getPath(config['Output']['Image'])], stderr=subprocess.STDOUT)
  status.update_main(text="Cleaning " + config['Output']['Image'])
  cleanDisk(Utils.getPath(config['Output']['Image']), bs="1M", count=int(config['Output']['Size']))
  status.update_item(name = "Formatting disk", value = "-25")

  
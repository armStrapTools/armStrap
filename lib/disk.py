import os
import sys
import subprocess
import time
from stat import *


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

def cleanDisk(device):
  if S_ISBLK(os.stat(device).st_mode):
    subprocess.check_output(["/bin/dd", "if=/dev/zero", "of=" + device, "bs=512", "count=1"], stderr=subprocess.STDOUT)
  else:
    raise

def setupSD(config, boards):
  offset = 1
  partid = 1
  DiskLayout = getLayout(boards)
  cleanDisk(config['Output']['Device'])
  subprocess.check_output(["/sbin/parted", config['Output']['Device'], "--script", "--", "mklabel", "msdos"], stderr=subprocess.STDOUT)
  for di in DiskLayout:
    if di['FileSystem'].lower().find("fat") != -1:
      fs="fat32"
    else:
      fs=di['FileSystem']
    if int(di['Size']) != -1:
      size = int(di['Size']) + offset
    else:
      size = -1
    subprocess.check_output(["/sbin/parted", config['Output']['Device'], "--script", "--", "mkpart", "primary", str(fs), str(offset), str(size)], stderr=subprocess.STDOUT)
    syncFS()
    partProbe(device = config['Output']['Device'])
    while os.path.exists(config['Output']['Device'] + str(partid)) == False:
      time.sleep(1)
    if fs == "fat32":
      subprocess.check_output(["/sbin/mkfs.vfat", "-F", "32", config['Output']['Device'] + str(partid)], stderr=subprocess.STDOUT)
    else:
      subprocess.check_output(["/sbin/mkfs." + fs, config['Output']['Device'] + str(partid)], stderr=subprocess.STDOUT)
    partid += 1
    if size != -1:
      offset = size;
    else:
      break
  syncFS()

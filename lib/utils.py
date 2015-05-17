
import os
import shutil
import sys
import tarfile
import urllib.request
import configparser
import subprocess

from . import ui as UI

#######################################################################################
# Since armStrap must be run as root, all path are made relative to the work directory.
#

# Extract a tar file (src) to a directory (dst)
def extractTar(src, dst):
  checkPath(dst)
  xz = tarfile.open(getPath(src), 'r:*')
  xz.extractall(getPath(dst))
  xz.close()

# Download a file to the current directory
def download(url):
  with urllib.request.urlopen(url) as src, open(getPath(os.path.basename(url)), 'wb') as out_file:
    shutil.copyfileobj(src, out_file)

# Unlink a file 
def unlinkFile(src):
  if os.path.isfile(getPath(src)):
    os.unlink(getPath(src))

# Check if a path exist and create it. Aways work from the work directory    
def checkPath(path):
  if os.path.exists(getPath(path)) == False:
    os.makedirs(getPath(path))
  return getPath(path)
  
# Return a path starting at the work directory
def getPath(path):
  return os.path.join(os.getcwd(), path)

# Read a config file
def readConfig(src):
  config = configparser.ConfigParser()
  config.sections()
  config.read(getPath(src))
  return config

def Exit(text = "", title = "", timeout = 0, status = os.EX_OK):
  UI.MessageBox(text = text, title = title, timeout = timeout)
  subprocess.check_output(["/usr/bin/clear"], stderr=subprocess.STDOUT)
  sys.exit(status)


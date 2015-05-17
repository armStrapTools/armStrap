import os
import shutil
import tarfile
import urllib.request
import configparser
import subprocess

#######################################################################################
# Since armStrap must be run as root, all path are made relative to the work directory.
#

# Extract a tar file (src) to a directory (dst)
def extractTar(src, dst):
  checkPath(dst)
  xz = tarfile.open(getpath(src), 'r:*')
  xz.extractall(getpath(dst))
  xz.close()

# Download a file to the current directory
def download(url):
  with urllib.request.urlopen(url) as src, open(getpath(os.path.basename(url)), 'wb') as out_file:
    shutil.copyfileobj(src, out_file)

# Unlink a file 
def unlinkFile(src):
  if os.path.isfile(getpath(src)):
    os.unlink(getpath(src))

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

# List the partitions of a device
def listDevice(device):
  p = subprocess.Popen(['/sbin/parted', device, '--script' , 'print'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  (cmd_stdout_bytes, cmd_stderr_bytes) = p.communicate()
  (cmd_stdout, cmd_stderr) = ( cmd_stdout_bytes.decode('utf-8'), cmd_stderr_bytes.decode('utf-8'))
  return str(cmd_stdout).splitlines();

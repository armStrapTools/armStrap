import os
import shutil
import tarfile
import urllib.request
import configparser
import subprocess


def extractTar(src, dst):
  xz = tarfile.open(src, 'r:*')
  xz.extractall(dst)
  xz.close()

def download(url):
  dst = os.path.basename(url)
  with urllib.request.urlopen(url) as src, open(dst, 'wb') as out_file:
    shutil.copyfileobj(src, out_file)
    
def unlinkFile(src):
  if os.path.isfile(src):
    os.unlink(src)

# Check if a path exist and create it. Aways work from the work directory    
def checkPath(path):
  fullpath = os.path.join(os.getcwd(),path)
  if os.path.exists(getPath(path)) == False:
    os.makedirs(getPath(path))  
  return fullpath
  
# Return a path starting at the work directory
def getPath(path):
  return os.path.join(os.getcwd(), path)

def readConfig(src):
  config = configparser.ConfigParser()
  config.sections()
  config.read(getPath(src))
  return config

def listDevice(device):
  p = subprocess.Popen(['/sbin/parted', device, '--script' , 'print'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  (cmd_stdout_bytes, cmd_stderr_bytes) = p.communicate()
  
  (cmd_stdout, cmd_stderr) = ( cmd_stdout_bytes.decode('utf-8'), cmd_stderr_bytes.decode('utf-8'))
  
  return str(cmd_stdout).splitlines();

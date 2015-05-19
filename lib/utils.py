import logging
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
  try:
    checkPath(dst)
    xz = tarfile.open(getPath(src), 'r:*')
    xz.extractall(getPath(dst))
    xz.close()
  except:
    logging.exception("Exception in " + __name__ + ":")
    return False

# Download a file to the current directory
def download(url):
  try:
    with urllib.request.urlopen(url) as src, open(getPath(os.path.basename(url)), 'wb') as out_file:
      shutil.copyfileobj(src, out_file)
    return True
  except:
    logging.exception("Exception in " + __name__ + ":")
    return False

# Unlink a file 
def unlinkFile(src):
  try:
    if os.path.isfile(getPath(src)):
      os.unlink(getPath(src))
    return True
  except:
    logging.exception("Exception in " + __name__ + ":")
    return False
    
# Touch a file
def touch(fname, mode=0o666, dir_fd=None, **kwargs):
  try:
    flags = os.O_CREAT | os.O_APPEND
    with os.fdopen(os.open(getPath(fname), flags=flags, mode=mode, dir_fd=dir_fd)) as f:
      os.utime(f.fileno() if os.utime in os.supports_fd else getPath(fname), dir_fd=None if os.supports_fd else dir_fd, **kwargs)
    return True
  except:
    logging.exception("Exception in " + __name__ + ":")
    return False

# Check if a path exist and create it. Aways work from the work directory    
def checkPath(path):
  try:
    if os.path.exists(getPath(path)) == False:
      os.makedirs(getPath(path))
    return getPath(path)
  except:
    logging.exception("Exception in " + __name__ + ":")
    return False
  
# Return a path starting at the work directory
def getPath(path):
  try:
    return os.path.join(os.getcwd(), path.strip('/'))
  except:
    logging.exception("Exception in " + __name__ + ":")
    return False

# Read a config file
def readConfig(src):
  try:
    config = configparser.ConfigParser()
    config.sections()
    config.read(getPath(src))
    return config
  except:
    logging.exception("Exception in " + __name__ + ":")
    return False
  
# Execute a command, capturing its output
def captureCommand(*args):
  try:
    p = subprocess.Popen( args , stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (cmd_stdout_bytes, cmd_stderr_bytes) = p.communicate()
    return ( str(cmd_stdout_bytes.decode('utf-8')), str(cmd_stderr_bytes.decode('utf-8')) )
  except:
    logging.exception("Exception in " + __name__ + ":")
    return ( False, False )

# Exit from armStrap.
def Exit(text = "", title = "", timeout = 0, exitStatus = os.EX_OK, status = False):
  try:
    if status != False:
      status.end()
    UI.MessageBox(text = text, title = title, timeout = timeout)
    os.system("/usr/bin/clear")
  except SystemExit:
    pass
  except:
    logging.exception("Exception in " + __name__ + ":")
  finally:
    sys.exit(exitStatus)

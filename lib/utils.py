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
    UI.logInfo("Entering")
    checkPath(dst)
    xz = tarfile.open(getPath(src), 'r:*')
    xz.extractall(getPath(dst))
    xz.close()
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

# Download a file to the current directory
def download(url):
  try:
    UI.logInfo("Entering")
    with urllib.request.urlopen(url) as src, open(getPath(os.path.basename(url)), 'wb') as out_file:
      shutil.copyfileobj(src, out_file)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

# Unlink a file 
def unlinkFile(src):
  try:
    UI.logInfo("Entering")
    if os.path.isfile(getPath(src)):
      os.unlink(getPath(src))
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False
    
# Touch a file
def touch(fname, mode=0o666, dir_fd=None, **kwargs):
  try:
    UI.logInfo("Entering")
    flags = os.O_CREAT | os.O_APPEND
    with os.fdopen(os.open(getPath(fname), flags=flags, mode=mode, dir_fd=dir_fd)) as f:
      os.utime(f.fileno() if os.utime in os.supports_fd else getPath(fname), dir_fd=None if os.supports_fd else dir_fd, **kwargs)
    UI.logInfo("Exiting")
    return True
  except:
    UI.logException(False)
    return False

# Check if a path exist and create it. Aways work from the work directory    
def checkPath(path):
  try:
    UI.logInfo("Entering")
    if os.path.exists(getPath(path)) == False:
      os.makedirs(getPath(path))
    UI.logInfo("Exiting")
    return getPath(path)
  except:
    UI.logException(False)
    return False
  
# Return a path starting at the work directory
def getPath(path):
  try:
    UI.logInfo("Entering/Exiting")
    return os.path.join(os.getcwd(), path.strip('/'))
  except:
    UI.logException(False)
    return False
    
# Check if a file exist
def checkFile(file):
  try:
    UI.logInfo("Entering")
    if os.path.isfile(file):
      return True
    else:
      return False
  except:
    UI.logException(False)
    return False

# Append lines to a file    
def appendFile(file, lines):
  try:
    UI.logInfo("Entering")
    with open(file, "a") as f:
      for line in lines:
        f.write(line + "\n")
    return True
  except:
    UI.logException(False)
    return False

# Read a config file
def readConfig(src):
  try:
    UI.logInfo("Entering")
    config = configparser.ConfigParser()
    config.sections()
    config.read(getPath(src))
    UI.logInfo("Exiting")
    return config
  except:
    UI.logException(False)
    return False
  
# Execute a command, capturing its output
def captureCommand(*args):
  try:
    UI.logInfo("Entering")
    p = subprocess.Popen( args , stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (cmd_stdout_bytes, cmd_stderr_bytes) = p.communicate()
    UI.logInfo("Exiting")
    return ( str(cmd_stdout_bytes.decode('utf-8')), str(cmd_stderr_bytes.decode('utf-8')) )
  except:
    UI.logException(False)
    return ( False, False )
    
# Execute a command in the chroot environment, capturing its output
def captureChrootCommand(command):
  try:
    UI.logInfo("Entering")
    p = subprocess.Popen( "LC_ALL='' LANGUAGE='en_US:en' LANG='en_US.UTF-8' /usr/sbin/chroot " + getPath("mnt") + " " + command , shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (cmd_stdout_bytes, cmd_stderr_bytes) = p.communicate()
    UI.logInfo("Exiting")
    return ( str(cmd_stdout_bytes.decode('utf-8')), str(cmd_stderr_bytes.decode('utf-8')) )
  except:
    UI.logException(False)
    return ( False, False )

#Execute a command, dropping its output
def runCommand(command, status):
  try:
    UI.logInfo("Entering")
    UI.logInfo("About to execute: " + command)
    err = os.system(command + " > /dev/null 2>&1")
    UI.logInfo("Error Code : " + str(err) + ", " + os.strerror(err))
    if err != os.EX_OK:
      Exit(text = "Error while running " + command +" (Error Code " + str(err) + ", " + os.strerror(err), title = "Fatal Error", timeout = 5, exitStatus = err, status = status)
    UI.logInfo("Exiting")
    return err
  except:
    UI.logException(False)
    return False

#Execute a command in the chroot environment, dropping its output
def runChrootCommand(command, status):
  try:
    UI.logInfo("Entering")
    UI.logInfo("About to execute: " + command)
    err = os.system("LC_ALL='' LANGUAGE='en_US:en' LANG='en_US.UTF-8' /usr/sbin/chroot " + getPath("mnt") + " " + command + " > /dev/null 2>&1")
    if err != os.EX_OK:
      UI.logWarning( "Error while running " + command +" (Error Code " + str(err) + ", " + os.strerror(err))
      raise OSError
    UI.logInfo("Exiting")
    return err
  except:
    UI.logException(False)
    return False

# Exit from armStrap.
def Exit(text = "", title = "", timeout = 0, exitStatus = os.EX_OK, status = False):
  try:
    UI.logInfo("Shutting down")
    if status != False:
      status.end()
    UI.MessageBox(text = text, title = title, timeout = timeout)
    os.system("/usr/bin/clear")
  except SystemExit:
    pass
  except:
    UI.logException(False)
  finally:
    logFile = os.path.join( os.getcwd(), "armStrap.log" )
    logging.shutdown()
    if os.path.isfile(logFile):
      if os.stat(logFile).st_size == 0:
        os.unlink(logFile)
    sys.exit(exitStatus)

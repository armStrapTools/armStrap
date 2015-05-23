import logging
import os
import shutil
import sys
import tarfile
import urllib.request
import random
import configparser
import subprocess
import requests

from . import ui as UI

#######################################################################################
# Since armStrap must be run as root, all path are made relative to the work directory.
#

# Extract a tar file (src) to a directory (dst)
def extractTar(src, dst):
  try:
    UI.logInfo("Entering")
    checkPath(dst)
    UI.logInfo("Extracting " + getPath(src) + " to " + getPath(dst))
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
    UI.logInfo("Downloading " + url + " to " + getPath(os.path.basename(url)))
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
      UI.logInfo("Unlinking " + getPath(src))
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
    UI.logInfo("Touching " + getPath(fname))
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
      logfile("Creating path " + getPath(path))
      os.makedirs(getPath(path))
    UI.logInfo("Exiting")
    return getPath(path)
  except:
    UI.logException(False)
    return False
  
# Return a path starting at the work directory
def getPath(path):
  try:
    UI.logInfo("Entering")
    p = os.path.join(os.getcwd(), path.strip('/'))
    UI.logInfo("Complete path for " + path + " is " + p)
    UI.logInfo("Exiting")
    return p
  except:
    UI.logException(False)
    return False
    
# Check if a file exist
def checkFile(file):
  try:
    UI.logInfo("Entering")
    if os.path.isfile(file):
      UI.logInfo(file + " exist")
      return True
    else:
      UI.logInfo(file + " does not exist")
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
        UI.logInfo(file + " adding line " + line)
        f.write(line + "\n")
    return True
  except:
    UI.logException(False)
    return False
    
# Read armStrap config and set default values if missing.
def readArmStrapConfig():
  try:
    UI.logInfo("Entering")
    config = readConfig(src = "armStrap.ini")
    
    if config == False:
      config = configparser.ConfigParser()
    
    if config.has_section("Board"):
      UI.logInfo("Checking section Board")
      if not config.has_option('Board', 'Branch'):
        UI.logInfo("Adding item Branch")
        config['Board']['Branch'] = "sunxi"
      if not config.has_option('Board', 'Model'):
        UI.logInfo("Adding item Model")
        config['Board']['Model'] = "CubieTruck"
      if not config.has_option('Board', 'HostName'):
        UI.logInfo("Adding item HostName")
        config['Board']['HostName'] = "armStrap"
      if not config.has_option('Board', 'Password'):
        UI.logInfo("Adding item Password")
        config['Board']['Password'] = "armStrap"
      if not config.has_option('Board', 'TimeZone'):
        UI.logInfo("Adding item TimeZone")
        config['Board']['TimeZone'] = "America/Montreal"
      if not config.has_option('Board', 'Locales'):
        UI.logInfo("Adding item Locales")
        config['Board']['Locales'] = "en_US.UTF-8 fr_CA.UTF-8"
    else:
      UI.logInfo("Creating section Board")
      config['Board'] = { }
      config['Board']['Branch'] = "sunxi"
      config['Board']['Model'] = "CubieTruck"
      config['Board']['HostName'] = "armStrap"
      config['Board']['Password'] = "armStrap"
      config['Board']['TimeZone'] = "America/Montreal"
      config['Board']['Locales'] = "en_US.UTF-8 fr_CA.UTF-8"
      
    if config.has_section("Distribution"):
      UI.logInfo("Checking section Distribution")
      if not config.has_option('Distribution', 'Family'):
        UI.logInfo("Adding item Family")
        config['Distribution']['Family'] = "ubuntu"
      if not config.has_option('Distribution', 'Version'):
        UI.logInfo("Creating section Version")
        config['Distribution']['Version'] = "vivid"
    else:
      UI.logInfo("Creating section Distribution")
      config['Distribution'] = { }
      config['Distribution']['Family'] = "ubuntu"
      config['Distribution']['Version'] = "vivid"
      
    if config.has_section("Kernel"):
      UI.logInfo("Checking section Kernel")
      if not config.has_option('Kernel', 'Version'):
        UI.logInfo("Adding item Version")
        config['Kernel']['Version'] = "mainline"
    else:
      UI.logInfo("Creating section Kernel")
      config['Kernel'] = { }
      config['Kernel']['Version'] = "mainline"
    
    if config.has_section("Networking"):
      UI.logInfo("Checking section Networking")
      if not config.has_option('Networking', 'Mode'):
        UI.logInfo("Adding item Mode")
        config['Networking']['Mode'] = "dhcp"
      if not config.has_option('Networking', 'MacAddress'):
        UI.logInfo("Adding item MacAddress")
        config['Networking']['MacAddress'] = ':'.join(map(lambda x: "%02x" % x, [ 0x00, 0x02, 0x46, random.randint(0x00, 0x7f), random.randint(0x00, 0xff), random.randint(0x00, 0xff) ]))
    else:
      UI.logInfo("Creating section Networking")
      config['Networking'] = { }
      config['Networking']['Mode'] = "dhcp"
      config['Networking']['MacAddress'] = ':'.join(map(lambda x: "%02x" % x, [ 0x00, 0x02, 0x46, random.randint(0x00, 0x7f), random.randint(0x00, 0xff), random.randint(0x00, 0xff) ]))
      
    if config.has_section("Output"):
      UI.logInfo("Checking section Output")
      if not config.has_option('Output', 'Image'):
        if not config.has_option('Output', 'Device'):
          UI.logInfo("Adding item Device")
          config['Output']['Device'] = "/dev/mmcblk0"
    else:
      UI.logInfo("Creating section Output")
      config['Output'] = { }
      config['Output']['Device'] = "/dev/mmcblk0"
      
    with open(getPath("armStrap.ini"), 'w') as configfile:
      config.write(configfile)
    
    UI.logInfo("Exiting")
    return config
  except:
    UI.logException(False)
    return False
  
# Read a config file
def readConfig(src):
  try:
    UI.logInfo("Entering")
    if checkFile(src):
      UI.logInfo("Reading configuration file " + getPath(src))
      config = configparser.ConfigParser()
      config.sections()
      config.read(getPath(src))
    else:
      UI.logInfo("Configuration file " + getPath(src) + " does not exist")
      config = False
    UI.logInfo("Exiting")
    return config
  except:
    UI.logException(False)
    return False

# Execute a command, capturing its output
def captureCommand(command):
  try:
    UI.logInfo("Entering")
    UI.logInfo("Capturing output of " + command)
    p = subprocess.Popen( command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
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
    UI.logInfo("Capturing output of " + command + " in chroot")
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
    UI.logInfo("Executing " + command)
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
    UI.logInfo("Executing " + command + " in chroot")
    err = os.system("LC_ALL='' LANGUAGE='en_US:en' LANG='en_US.UTF-8' /usr/sbin/chroot " + getPath("mnt") + " " + command + " > /dev/null 2>&1")
    if err != os.EX_OK:
      UI.logWarning( "Error while running " + command +" (Error Code " + str(err) + ", " + os.strerror(err))
      raise OSError
    UI.logInfo("Exiting")
    return err
  except:
    UI.logException(False)
    return False
#Read a json url and return it as a dict
def loadJsonURL(url):
  try:
    UI.logInfo("Entering")
    return(requests.get(url).json())
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

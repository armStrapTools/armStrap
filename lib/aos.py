import logging
import os
import shutil
import subprocess
from lib import ui as UI
from lib import utils as Utils

def installRootFS(url, config, boards, status):
  try:
    file = boards['Common']['CpuArch'] + boards['Common']['CpuFamily'] + "-" + config['Distribution']['Family'] + "-" + config['Distribution']['Version'] + ".txz"
    status.update_main(text="Downloading RootFS image " + file, percent = status.getPercent())  
    Utils.download(url + "/" + file)
    status.update_item(name = "Installing RootFS", value = "-5")
    status.update_main(text="Extracting RootFS image " + file, percent = status.getPercent())  
    Utils.extractTar(file, "mnt")
    Utils.unlinkFile(file)
    status.update_item(name = "Installing RootFS", value = "-10")
    return True
  except:
    UI.logException(False)
    return False

def chrootConfig():
  try:
    shutil.copy("/usr/bin/qemu-arm-static", Utils.getPath("mnt/usr/bin/qemu-arm-static"))
    Utils.touch("mnt/usr/sbin/policy-rc.d.lock")
    if os.path.isfile(Utils.getPath("mnt/usr/sbin/policy-rc.d")):
      shutil.move(Utils.getPath("mnt/usr/sbin/policy-rc.d"), Utils.getPath("mnt/usr/sbin/policy-rc.d_save"))
    f = open(Utils.getPath("mnt/usr/sbin/policy-rc.d"), 'w')
    f.write("exit 101\n")
    f.close()
    os.system("/bin/mount --bind /proc " + Utils.getPath("mnt/proc"))
    os.system("/bin/mount --bind /sys " + Utils.getPath("mnt/sys"))
    os.system("/bin/mount --bind /dev/pts " + Utils.getPath("mnt/dev/pts"))
    return True
  except:
    UI.logException(False)
    return False
  
  
def chrootDeconfig():
  try:
    os.system("/bin/umount " + Utils.getPath("mnt/dev/pts"))
    os.system("/bin/umount " + Utils.getPath("mnt/sys"))
    os.system("/bin/umount " + Utils.getPath("mnt/proc"))
    Utils.unlinkFile("mnt/usr/sbin/policy-rc.d")
    if os.path.isfile(Utils.getPath("mnt/usr/sbin/policy-rc.d_save")):
      shutil.move(Utils.getPath("mnt/usr/sbin/policy-rc.d_save"), Utils.getPath("mnt/usr/sbin/policy-rc.d"))
    os.unlink(Utils.getPath("mnt/usr/sbin/policy-rc.d.lock"))
    os.unlink(Utils.getPath("mnt/usr/bin/qemu-arm-static"))
    return True
  except:
    UI.logException(False)
    return False

def chrootPasswd(Password):
  try:
    PasswordNL=Password + "\n"
    proc = subprocess.Popen(['/usr/sbin/chroot', Utils.getPath("mnt"), '/usr/bin/passwd', 'root'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    proc.stdin.write(PasswordNL.encode('ascii'))
    proc.stdin.write(Password.encode('ascii'))
    proc.stdin.flush()
    stdout,stderr = proc.communicate()
    return (stdout.decode('utf-8'), stderr.decode('utf-8'))
  except:
    UI.logException(False)
    return ( False, False )

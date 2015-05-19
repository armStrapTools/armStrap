import atexit
import logging
from dialog import Dialog
from queue import Queue
from queue import Empty
import os
import subprocess
import sys
import tempfile
import threading
import time
import logging

def constant(f):
    def fset(self, value):
        raise SyntaxError
    def fget(self):
        return f()
    return property(fget, fset)

class _Const(object):
    @constant
    def QUEUE_TIMEOUT():
        return 0.1
    @constant
    def NONE():
        return 0x00
    @constant
    def HIDDEN():
        return 0x01
    @constant
    def READONLY():
        return 0x02
    @constant
    def GUI_START():
        return 1
    @constant
    def GUI_UPDATE():
        return 2
    @constant
    def GUI_HIDE():
        return 3
    def GUI_STOP():
        return 4
    @constant
    def VERSION():
        return "1.0-Stage"

CONST = _Const()

def startLogger(Filename, Level):
    if os.path.isfile(Filename):
        os.unlink(Filename)
    logging.basicConfig(filename = Filename, level = Level)
    atexit.register(endLogger, Filename = Filename)
    
def endLogger(Filename):
    if os.path.isfile(Filename):
        if os.stat(Filename).st_size == 0:
            os.unlink(Filename)

def armStrap_Dialog():
    try:
        return Dialog(dialog = "dialog")
    except:
        logging.exception("Exception in " + __name__ + ":")
        return False

def openTempFile():
    try:
        (fd, path) = tempfile.mkstemp()
        file = open(path, 'w+b')
        return (fd, file, path)
    except:
        logging.exception("Exception in " + __name__ + ":")
        return (False, False, False)

def closeTempFile(fd, file, path):
    try:
        file.close()
        os.close(fd)
        os.remove(path)
        return True
    except:
        logging.exception("Exception in " + __name__ + ":")
        return False
 
class RunInBackground(threading.Thread):
    def __init__( self, cmd ):
        try:
            (self.fd, self.file, self.path) = openTempFile()
            self.Cmd = cmd
            super(RunInBackground, self).__init__()
            self.start()
        except:
            logging.exception("Exception in " + __name__ + ":")

    def run(self):
        try:
            os.system(self.Cmd + " > " + self.path + " 2>&1")
            closeTempFile(fd = self.fd, file = self.file, path= self.path)
        except:
            logging.exception("Exception in " + __name__ + ":")
        
            
    def getName(self):
        try:
            return self.output.name
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
        
class chrootRunInBackground(threading.Thread):
    def __init__( self, cmd, path ):
        try:
            (self.fd, self.file, self.path) = openTempFile()
            self.chrootCmd = cmd
            self.chrootPath = path
            super(chrootRunInBackground, self).__init__()
            self.start()
        except:
            logging.exception("Exception in " + __name__ + ":")
        
    def run(self):
        try:
            os.system("LC_ALL='' LANGUAGE='en_US:en' LANG='en_US.UTF-8' /usr/sbin/chroot " + self.chrootPath + " " + self.chrootCmd + " > " + self.path + " 2>&1")
            closeTempFile(fd = self.fd, file = self.file, path= self.path)
        except:
            logging.exception("Exception in " + __name__ + ":")
            
    def getName(self):
        try:
            return self.path
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
class Mixed(threading.Thread):
    def __init__(self, title = ""):
        try:
            self.queue = Queue()
            self.dialog = armStrap_Dialog()
            self.running = True
            self.active = False
            self.percent = 0
            self.text = ""
            self.title = title
            self.elements = []
            super(Mixed, self).__init__()
            self.start()
        except:
            logging.exception("Exception in " + __name__ + ":")
        
    def run(self):
        while self.running:
            try:
                command = self.queue.get(block = True, timeout = CONST.QUEUE_TIMEOUT)
                if (command['task'] == CONST.GUI_START) and (self.active == False):
                    self.active = True
                    self.dialog.mixedgauge(text=self.text, percent=self.percent, elements=self.elements, title=self.title, backtitle="armStrap version " + CONST.VERSION)
                elif (command['task'] == CONST.GUI_UPDATE) and (self.active == True):
                    self.dialog.mixedgauge(text=self.text, percent=self.percent, elements=self.elements, title=self.title, backtitle="armStrap version " + CONST.VERSION)
                elif command['task'] == CONST.GUI_HIDE:
                    self.active = False
                else:
                    self.active = False
                    self.running = False
                self.queue.task_done()
            except Empty:
                continue
            except:
                logging.exception("Exception in " + __name__ + ":")
                self.running = False
                continue
                
    def getPercent(self):
        try:
            return self.percent
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
    def getRunning(self):
        try:
            return self.running
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
    def getText(self):
        try:
            return self.text
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
    def getTitle(self):
        try:
            return self.title
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
    def getElements(self):
        try:
            return self.elements
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
    def show(self, percent = 0, text = ""):
        try:
            self.percent = percent
            self.text = text
            self.queue.put({'task': CONST.GUI_START})
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
    def update_item(self, name, value, percent = False, text = False):
        try:
            found = False;
            t = []
            for d in self.elements[:]:
                if d[0] == name:
                    t.append( (d[0], value) )
                    found = True
                else:
                    t.append( (d[0], d[1]) )
            self.elements = t
            if found == False:
                self.elements.append( (name, value) )
            if percent != False:
                self.percent = percent
                if self.percent < 0:
                    self.percent = 0
                if self.percent > 100:
                    self.percent = 100
            if (text != False) and (text != self.text):
                self.text = text
            self.queue.put({'task': CONST.GUI_UPDATE})
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
            
    def update_main(self, percent = False, text = False):
        try:
            if percent != False:
                self.percent = percent
                if self.percent < 0:
                    self.percent = 0
                if self.percent > 100:
                    self.percent = 100
            if (text != False) and (text != self.text):
                self.text = text
            self.queue.put({'task': CONST.GUI_UPDATE})
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
            
    def hide(self):
        try:
            self.queue.put({'task': CONST.GUI_HIDE})
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
    def end(self):
        try:
            if self.running:
                self.queue.put({'task': CONST.GUI_STOP})
                self.join()
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
 
class Gauge(threading.Thread):
    def __init__(self, title = ""):
        try:
            self.queue = Queue()
            self.dialog = armStrap_Dialog()
            self.running = True
            self.active = False
            self.percent = 0
            self.text = ""
            self.title = title;
            super(gauge, self).__init__()
            self.start()
        except:
            logging.exception("Exception in " + __name__ + ":")
        
    def run(self):
        while self.running:
            try:
                command = self.queue.get(block = True, timeout = CONST.QUEUE_TIMEOUT)
                if (command['task'] == CONST.GUI_START) and (self.active == False):
                        self.active = True
                        self.dialog.gauge_start(percent=self.percent, text=self.text, title=self.title, backtitle="armStrap version " + CONST.VERSION)
                elif (command['task'] == CONST.GUI_UPDATE) and (self.active == True):
                            self.dialog.gauge_update(percent=self.percent, text=self.text, update_text=command['update_text'])
                elif command['task'] == CONST.GUI_HIDE and (self.active == True):
                    if self.active == True:
                        self.dialog.gauge_stop()
                else:
                    if self.active == True:
                        self.dialog.gauge_stop()
                    
                    self.running = False
                self.queue.task_done()
            except Empty:
                continue
            except:
                logging.exception("Exception in " + __name__ + ":")
                self.running = False
                continue
    
    def show(self, percent = 0, text = ""):
        try:
            self.percent = percent
            self.text = text
            self.queue.put({'task': CONST.GUI_START})
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
        
    def update(self, percent = 0, text = ""):
        try:
            self.percent = percent
            if self.percent < 0:
                self.percent = 0
            if self.percent > 100:
                self.percent = 100
            if (text != "") and (text != self.text):
                self.text = text
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': True})
            else:
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': False})
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False

    def increment(self, percent = 0, text = ""):
        try:
            self.percent += percent
            if self.percent > 100:
                self.percent = 100
            if (text != "") and (text != self.text):
                self.text = text
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': True})
            else:
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': False})
            return True
        except:
            return False
            logging.exception("Exception in " + __name__ + ":")
    
    def decrement(self, percent = 0, text = ""):
        try:
            self.percent -= percent
            if self.percent < 0:
                self.percent = 0
            if (text != "") and (text != self.text):
                self.text = text
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': True})
            else:
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': False})
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
    def hide(self):
        try:
            self.queue.put({'task': CONST.GUI_HIDE})
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
    
    def end(self):
        try:
            if self.running:
                self.queue.put({'task': CONST.GUI_STOP})
                self.join()
            return True
        except:
            logging.exception("Exception in " + __name__ + ":")
            return False
        
def MessageBox(text = "", title = "", timeout = 0 ):
    try:
        dialog = armStrap_Dialog()
        if timeout < 1:
            dialog.msgbox(text = text, title= title, backtitle = "armStrap version " + CONST.VERSION)
        else:
            dialog.pause(text = text, title = title, seconds = timeout, backtitle = "armStrap version " + CONST.VERSION)
        return True
    except:
        logging.exception("Exception in " + __name__ + ":")
        return False
        
def YesNo(text = "", title = ""):
    try:
        dialog = armStrap_Dialog()
        return dialog.yesno(text = text, title= title, backtitle = "armStrap version " + CONST.VERSION)
    except:
        logging.exception("Exception in " + __name__ + ":")
        return False
    
def Status():
    try:
        m = Mixed(title = "Progress")
        m.show(text = "Initializing...")
        m.update_item(name = "Formatting Disk", value = "Pending")
        m.update_item(name = "Installing RootFS", value = "Pending")
        m.update_item(name = "Installing BootLoader", value = "Pending")
        m.update_item(name = "Installing Kernel", value = "Pending")
        time.sleep(1)
        return m
    except:
        logging.exception("Exception in " + __name__ + ":")
        return False
    
def ProgressBox(cmd, title = ""):
    try:
        b = RunInBackground(cmd = cmd)
        dialog = armStrap_Dialog()
        fn = b.getName()
        size = 0
        while os.path.isfile(fn):
            t = os.stat(fn).st_size
            if t != size:
                size = t
                dialog.progressbox(file_path = fn, title = title, backtitle="armStrap version " + CONST.VERSION)
            time.sleep(0.1)
        return True
    except:
        logging.exception("Exception in " + __name__ + ":")
        return False
    
def chrootProgressBox(cmd, path, title = "" ) :
    try:
        b = chrootRunInBackground(cmd = cmd, path = path)
        dialog = armStrap_Dialog()
        fn = b.getName()
        size = 0
        while os.path.isfile(fn):
            t = os.stat(fn).st_size
            if t != size:
                size = t
                dialog.progressbox(file_path = fn, title = title, backtitle="armStrap version " + CONST.VERSION)
            time.sleep(0.1)
        return True
    except:
        logging.exception("Exception in " + __name__ + ":")
        return False

# List the partitions of a device
def listDevice(device):
    try:
        p = subprocess.Popen(['/sbin/parted', device, '--script' , 'print'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        (cmd_stdout_bytes, cmd_stderr_bytes) = p.communicate()
        (cmd_stdout, cmd_stderr) = ( cmd_stdout_bytes.decode('utf-8'), cmd_stderr_bytes.decode('utf-8'))
        return str(cmd_stdout).splitlines();
    except:
        logging.exception("Exception in " + __name__ + ":")
        return False
  
def Summary(config):
    try:
        dialog = armStrap_Dialog()
        elements = [
            ("-- Board --", 1,  15, " ", 2, 2, 0, 0, CONST.HIDDEN),
            ("-- Kernel --", 1,  54, " ", 2, 2, 0, 0, CONST.HIDDEN),
            ("      Model :",  2,   1, config['Board']['Model'],           2, 15, 20, 20, CONST.READONLY),
            ("    Version :",  2,  41, config['Kernel']['Version'],        2, 55, 20, 20, CONST.READONLY),
            ("   HostName :",  3,   1, config['Board']['HostName'],        3, 15, 20, 20, CONST.READONLY),
            ("-- Distribution --", 3,  51, " ", 2, 2, 0, 0, CONST.HIDDEN),
            ("   Password :",  4,   1, config['Board']['Password'],        4, 15, 20, 20, CONST.READONLY),
            ("     Family :",  4,  41, config['Distribution']['Family'],   4, 55, 20, 20, CONST.READONLY),
            ("   TimeZone :",  5,   1, config['Board']['TimeZone'],        5, 15, 20, 20, CONST.READONLY),
            ("    Version :",  5,  41, config['Distribution']['Version'],  5, 55, 20, 20, CONST.READONLY),
            ("     Locale :",  6,   1, config['Board']['Locale'],          6, 15, 20, 20, CONST.READONLY),
            ("Root Device :",  6,  41, config['BootLoader']['RootDevice'], 6, 55, 20, 20, CONST.READONLY)]
    
        i = 7
    
        if config.has_section("SwapFile"):
            elements.append( ("-- SwapFile --",  i,  31, "", i, 45, 0, 0, CONST.READONLY) )
            i += 1
            if config.has_option('SwapFile', 'Size'):
                elements.append( ("       Size :",  i,  1, config['SwapFile']['Size'] + "MB",    i, 15, 20, 20, CONST.READONLY) )
            else:
                elements.append( ("     Factor :",  i,  1, config['SwapFile']['Factor'] + " maximum " + config['SwapFile']['Maximum'] + "MB",    i, 13, 20, 20, CONST.READONLY))
            elements.append( ("       File :",  i,  40, config['SwapFile']['File'],    i, 55, 20, 20, CONST.READONLY) )
            i += 1

        elements.append( ("-- Networking --", i, 30, "", i, 46, 0 ,0, CONST.READONLY) )
        i += 1
        if config.has_section("Networking"):
            if config['Networking']['Mode'].lower() == "static":
                elements.append(("         IP :",  i,   1, config['Networking']['Ip'],   i, 15, 20, 20, CONST.READONLY))
                elements.append(("Root Device :",  i,  41, config['Networking']['Mask'], i, 55, 20, 20, CONST.READONLY))
                i += 1
                elements.append(("    Gateway :",  i,   1, config['Networking']['Gateway'],   i, 15, 20, 20, CONST.READONLY))
                elements.append(("        DNS :",  i,  41, config['Networking']['DNS'], i, 55, 20, 20, CONST.READONLY))
                i += 1
                elements.append(("     Domain :",  i,   1, config['Networking']['Domain'],   i, 15, 20, 20, CONST.READONLY))
                elements.append(("Mac Address :",  i,  41, config['Networking']['MacAddress'], i, 55, 20, 20, CONST.READONLY))
                i += 1
            else:
                elements.append(("         IP :",  i,   1, config['Networking']['Mode'],   i, 15, 20, 20, CONST.READONLY))
                i += 1
        else:
            elements.append(("         IP :",  i,   1, "DHCP",   i, 15, 20, 20, CONST.READONLY))
            i += 1
    
        elements.append( ("-- Output --", i, 32, "", i, 46, 0 ,0, CONST.READONLY) )
        i += 1
        if config.has_option('Output', 'Device'):
            elements.append(("     Device :",  i,   1, config['Output']['Device'],   i, 15, 20, 20, CONST.READONLY))
            i += 2
            elements.append( ("Content of " + config['Output']['Device'] + ":", i, 1, "", i, 46, 0 ,0, CONST.READONLY) )
            i += 1
            for l in listDevice(config['Output']['Device']):
                elements.append( ("", i, 1, l , i, 1, 0, 0, CONST.READONLY) )
                i += 1 
        else:
            elements.append(("      Image :",  i,   1, config['Output']['Image'],   i, 15, 20, 20, CONST.READONLY))
            elements.append(("Root Device :",  i,  41, config['Output']['Size'], i, 55, 20, 20, CONST.READONLY))
    
        i += 2
    
        results = dialog.mixedform(text = "", elements = elements, title="Configuration Summary", backtitle="armStrap version " + CONST.VERSION)
    
        return results[0]
    except:
        logging.exception("Exception in " + __name__ + ":")

        return False

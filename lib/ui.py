import atexit
import builtins
from dialog import Dialog
import inspect
import logging
from queue import Queue
from queue import Empty
import os
import random
import subprocess
import sys
import tempfile
import threading
import time

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

def logDebug(message = False):
    func = inspect.currentframe().f_back.f_code
    if message == False:
        logging.debug("===:%s:%s:%i" % ( func.co_name, func.co_filename, func.co_firstlineno ) )
    else:
        logging.debug("===:%s:%s:%i %s" % ( func.co_name, func.co_filename, func.co_firstlineno, message ) )
        
def logWarning(message = False):
    func = inspect.currentframe().f_back.f_code
    if message == False:
        logging.warning("***:%s:%s:%i" % ( func.co_name, func.co_filename, func.co_firstlineno ) )
    else:
        logging.warning("***:%s:%s:%i %s" % ( func.co_name, func.co_filename, func.co_firstlineno, message ) )
        
def logInfo(message = False):
    func = inspect.currentframe().f_back.f_code
    if message == False:
        logging.info("@@@:%s:%s:%i" % ( func.co_name, func.co_filename, func.co_firstlineno ) )
    else:
        logging.info("@@@:%s:%s:%i %s" % ( func.co_name, func.co_filename, func.co_firstlineno, message ) )
        
def logException(message = False):
    func = inspect.currentframe().f_back.f_code
    if message == False:
        logging.exception("!!!:%s:%s:%i" % ( func.co_name, func.co_filename, func.co_firstlineno ) )
    else:
        logging.exception("!!!:%s:%s:%i %s" % ( func.co_name, func.co_filename, func.co_firstlineno, message ) )
        
def logEntering():
    func = inspect.currentframe().f_back.f_code
    logging.debug("+++:Entering function %s (%s)" % ( func.co_name, func.co_filename ))

def logExiting():
    func = inspect.currentframe().f_back.f_code
    logging.debug("---:Exiting function %s (%s)" % ( func.co_name, func.co_filename ))

def logEnterExit():
    func = inspect.currentframe().f_back.f_code
    logging.debug("###:Entering/Exiting function %s (%s)" % ( func.co_name, func.co_filename ))


def armStrap_Dialog():
    try:
        logEntering()
        builtins.Dialog = Dialog(dialog = "dialog")
        return builtins.Dialog
    except SystemExit:
        pass
    except:
        logException(False)
        return False

def openTempFile():
    try:
        logEntering()
        (fd, path) = tempfile.mkstemp()
        file = open(path, 'w+b')
        logExiting()
        return (fd, file, path)
    except SystemExit:
        pass
    except:
        logException(False)
        return (False, False, False)

def closeTempFile(fd, file, path):
    try:
        logEntering()
        file.close()
        os.close(fd)
        os.remove(path)
        logExiting()
        return True
    except SystemExit:
        pass
    except:
        logException(False)
        return False
 
class RunInBackground(threading.Thread):
    def __init__( self, cmd ):
        try:
            logEntering()
            (self.fd, self.file, self.path) = openTempFile()
            self.Cmd = cmd
            super(RunInBackground, self).__init__()
            self.start()
            logExiting()
        except SystemExit:
            pass
        except:
            logException(False)

    def run(self):
        try:
            logEntering()
            logDebug("Executing " + self.Cmd )
            err = os.system(self.Cmd + " > " + self.path + " 2>&1")
            if err != os.EX_OK:
                UI.logWarning( "Error while executing " + self.Cmd +" (Error Code " + str(err) + ", " + os.strerror(err))
                raise OSError
            closeTempFile(fd = self.fd, file = self.file, path= self.path)
            logExiting()
        except SystemExit:
            pass
        except:
            logException(False)
        
            
    def getName(self):
        try:
            logEnterExit()
            return self.output.name
        except SystemExit:
            pass
        except:
            logException(False)
            return False
        
class chrootRunInBackground(threading.Thread):
    def __init__( self, cmd, path ):
        try:
            logEntering()
            (self.fd, self.file, self.path) = openTempFile()
            self.chrootCmd = cmd
            self.chrootPath = path
            super(chrootRunInBackground, self).__init__()
            self.start()
            logExiting()
        except SystemExit:
            pass
        except:
            logException(False)
        
    def run(self):
        try:
            logEntering()
            logDebug("Running " + self.chrootCmd + " in the chroot environment")
            err = os.system("LC_ALL='' LANGUAGE='en_US:en' LANG='en_US.UTF-8' /usr/sbin/chroot " + self.chrootPath + " " + self.chrootCmd + " > " + self.path + " 2>&1")
            if err != os.EX_OK:
                UI.logWarning( "Error while running " + self.chrootCmd +" (Error Code " + str(err) + ", " + os.strerror(err))
                raise OSError
            closeTempFile(fd = self.fd, file = self.file, path= self.path)
            logExiting()
        except SystemExit:
            pass
        except:
            logException(False)
            
    def getName(self):
        try:
            return self.path
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
class Mixed(threading.Thread):
    def __init__(self, title = ""):
        try:
            logEntering()
            self.queue = Queue()
            self.running = True
            self.active = False
            self.percent = 0
            self.text = ""
            self.title = title
            self.elements = []
            super(Mixed, self).__init__()
            self.start()
            logExiting()
        except SystemExit:
            pass
        except:
            logException(False)
        
    def run(self):
        logEntering()
        while self.running:
            try:
                command = self.queue.get(block = True, timeout = CONST.QUEUE_TIMEOUT)
                if (command['task'] == CONST.GUI_START) and (self.active == False):
                    self.active = True
                    builtins.Dialog.mixedgauge(text=self.text, percent=self.percent, elements=self.elements, title=self.title, backtitle="armStrap version " + CONST.VERSION)
                elif (command['task'] == CONST.GUI_UPDATE) and (self.active == True):
                    builtins.Dialog.mixedgauge(text=self.text, percent=self.percent, elements=self.elements, title=self.title, backtitle="armStrap version " + CONST.VERSION)
                elif command['task'] == CONST.GUI_HIDE:
                    self.active = False
                else:
                    self.active = False
                    self.running = False
                self.queue.task_done()
            except Empty:
                continue
            except SystemExit:
                pass
            except:
                logException(False)
                self.running = False
                continue
        logExiting()
                
    def getPercent(self):
        try:
            logEnterExit()
            return self.percent
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
    def getRunning(self):
        try:
            logEnterExit()
            return self.running
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
    def getText(self):
        try:
            logEnterExit()
            return self.text
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
    def getTitle(self):
        try:
            logEnterExit()
            return self.title
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
    def getElements(self):
        try:
            logEnterExit()
            return self.elements
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
    def show(self, percent = 0, text = ""):
        try:
            logEntering()
            self.percent = percent
            self.text = text
            self.queue.put({'task': CONST.GUI_START})
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
    def update(self, name = False, value = False, percent = False, text = False):
        try:
            logEntering()
            if (name != False) and ( value != False):
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
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            logException(False)
            return False
            
    def hide(self):
        try:
            logEntering()
            self.queue.put({'task': CONST.GUI_HIDE})
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
    def end(self):
        try:
            logEntering()
            if self.running:
                self.queue.put({'task': CONST.GUI_STOP})
                self.join()
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            logException(False)
            return False
 
class Gauge(threading.Thread):
    def __init__(self, title = ""):
        try:
            logEntering()
            self.queue = Queue()
            self.running = True
            self.active = False
            self.percent = 0
            self.text = ""
            self.title = title;
            super(gauge, self).__init__()
            self.start()
            logExiting()
        except SystemExit:
            pass
        except:
            logException(False)
        
    def run(self):
        logEntering()
        while self.running:
            try:
                command = self.queue.get(block = True, timeout = CONST.QUEUE_TIMEOUT)
                if (command['task'] == CONST.GUI_START) and (self.active == False):
                        self.active = True
                        builtins.Dialog.gauge_start(percent=self.percent, text=self.text, title=self.title, backtitle="armStrap version " + CONST.VERSION)
                elif (command['task'] == CONST.GUI_UPDATE) and (self.active == True):
                            builtins.Dialog.gauge_update(percent=self.percent, text=self.text, update_text=command['update_text'])
                elif command['task'] == CONST.GUI_HIDE and (self.active == True):
                    if self.active == True:
                        builtins.Dialog.gauge_stop()
                else:
                    if self.active == True:
                        builtins.Dialog.gauge_stop()
                    
                    self.running = False
                self.queue.task_done()
            except Empty:
                continue
            except SystemExit:
                pass
            except:
                logException(False)
                self.running = False
                continue
        logExiting()
    
    def show(self, percent = 0, text = ""):
        try:
            logEntering()
            self.percent = percent
            self.text = text
            self.queue.put({'task': CONST.GUI_START})
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            logException(False)
            return False
        
    def update(self, percent = 0, text = ""):
        try:
            logEntering()
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
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            logException(False)
            return False

    def increment(self, percent = 0, text = ""):
        try:
            logEntering()
            self.percent += percent
            if self.percent > 100:
                self.percent = 100
            if (text != "") and (text != self.text):
                self.text = text
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': True})
            else:
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': False})
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            return False
            logException(False)
    
    def decrement(self, percent = 0, text = ""):
        try:
            logEntering()
            self.percent -= percent
            if self.percent < 0:
                self.percent = 0
            if (text != "") and (text != self.text):
                self.text = text
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': True})
            else:
                self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': False})
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
    def hide(self):
        try:
            logEntering()
            self.queue.put({'task': CONST.GUI_HIDE})
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            logException(False)
            return False
    
    def end(self):
        try:
            logEntering()
            if self.running:
                self.queue.put({'task': CONST.GUI_STOP})
                self.join()
            logExiting()
            return True
        except SystemExit:
            pass
        except:
            logException(False)
            return False
        
def MessageBox(text = "", title = "", timeout = 0 ):
    try:
        logEntering()
        if timeout < 1:
            builtins.Dialog.msgbox(text = text, title = title, backtitle = "armStrap version " + CONST.VERSION)
        else:
            builtins.Dialog.pause(text = text, title = title, seconds = timeout, backtitle = "armStrap version " + CONST.VERSION)
        logExiting()
        return True
    except SystemExit:
        pass
    except:
        logException(False)
        return False
        
def InfoBox(text = "", title= ""):
    try:
        logEntering()
        builtins.Dialog.infobox( text = text, title = title, backtitle = "armStrap version " + CONST.VERSION )
        return True
    except SystemExit:
        pass
    except:
        logException(False)
        return False
        
def YesNo(text = "", title = ""):
    try:
        logEnterExit()
        return builtins.Dialog.yesno(text = text, title= title, backtitle = "armStrap version " + CONST.VERSION)
    except SystemExit:
        pass
    except:
        logException(False)
        return False
    
def Status():
    try:
        logEntering()
        builtins.Status = Mixed(title = "Progress")
        builtins.Status.show(text = "Initializing...")
        builtins.Status.update(name = "Formatting Disk", value = "Pending")
        builtins.Status.update(name = "Installing RootFS", value = "Pending")
        builtins.Status.update(name = "Installing BootLoader", value = "Pending")
        builtins.Status.update(name = "Installing Kernel", value = "Pending")
        time.sleep(1)
        logExiting()
        return builtins.Status
    except SystemExit:
        pass
    except:
        logException(False)
        return False
    
def ProgressBox(cmd, title = ""):
    try:
        logEntering()
        b = RunInBackground(cmd = cmd)
        fn = b.getName()
        size = 0
        while os.path.isfile(fn):
            t = os.stat(fn).st_size
            if t != size:
                size = t
                builtins.Dialog.progressbox(file_path = fn, title = title, backtitle="armStrap version " + CONST.VERSION)
            time.sleep(0.1)
        logExiting()
        return True
    except SystemExit:
        pass
    except:
        logException(False)
        return False
    
def chrootProgressBox(cmd, path, title = "" ) :
    try:
        logEntering()
        b = chrootRunInBackground(cmd = cmd, path = path)
        fn = b.getName()
        size = 0
        while os.path.isfile(fn):
            t = os.stat(fn).st_size
            if t != size:
                size = t
                builtins.Dialog.progressbox(file_path = fn, title = title, backtitle="armStrap version " + CONST.VERSION)
            time.sleep(0.1)
        logExiting()
        return True
    except SystemExit:
        pass
    except:
        logException(False)
        return False

# List the partitions of a device
def listDevice(device):
    try:
        logEntering()
        p = subprocess.Popen(['/sbin/parted', device, '--script' , 'print'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        (cmd_stdout_bytes, cmd_stderr_bytes) = p.communicate()
        (cmd_stdout, cmd_stderr) = ( cmd_stdout_bytes.decode('utf-8'), cmd_stderr_bytes.decode('utf-8'))
        logExiting()
        return str(cmd_stdout).splitlines();
    except SystemExit:
        pass
    except:
        logException(False)
        return False
        
def Summary():
    try:
        logEntering()
        elements = [
            ("-- Board --", 1,  15, " ", 2, 2, 0, 0, CONST.HIDDEN),
            ("-- Kernel --", 1,  54, " ", 2, 2, 0, 0, CONST.HIDDEN),
            ("      Model :",  2,   1, builtins.Config['Board']['Model'],           2, 15, 20, 20, CONST.READONLY),
            ("    Version :",  2,  41, builtins.Config['Kernel']['Version'],        2, 55, 20, 20, CONST.READONLY),
            ("   HostName :",  3,   1, builtins.Config['Board']['HostName'],        3, 15, 20, 20, CONST.READONLY),
            ("-- Distribution --", 3,  51, " ", 2, 2, 0, 0, CONST.HIDDEN),
            ("Root Passwd :",  4,   1, builtins.Config['Users']['RootPassword'],        4, 15, 20, 20, CONST.READONLY),
            ("     Family :",  4,  41, builtins.Config['Distribution']['Family'],   4, 55, 20, 20, CONST.READONLY),
            ("   TimeZone :",  5,   1, builtins.Config['Board']['TimeZone'],        5, 15, 20, 20, CONST.READONLY),
            ("    Version :",  5,  41, builtins.Config['Distribution']['Version'],  5, 55, 20, 20, CONST.READONLY),
            ("    Locales :",  6,   1, builtins.Config['Board']['Locales'],         6, 15, 20, 20, CONST.READONLY),
            ("Root Device :",  6,  41, builtins.Boards['Partitions']['Device'],          6, 55, 20, 20, CONST.READONLY)]
    
        i = 7
    
        if builtins.Config.has_section("SwapFile"):
            elements.append( ("-- SwapFile --",  i,  31, "", i, 45, 0, 0, CONST.READONLY) )
            i += 1
            if builtins.Config.has_option('SwapFile', 'Size'):
                elements.append( ("       Size :",  i,  1, builtins.Config['SwapFile']['Size'] + "MB",    i, 15, 20, 20, CONST.READONLY) )
            else:
                elements.append( ("     Factor :",  i,  1, builtins.Config['SwapFile']['Factor'] + " maximum " + builtins.Config['SwapFile']['Maximum'] + "MB",    i, 13, 20, 20, CONST.READONLY))
            elements.append( ("       File :",  i,  40, builtins.Config['SwapFile']['File'],    i, 55, 20, 20, CONST.READONLY) )
            i += 1

        elements.append( ("-- Networking --", i, 30, "", i, 46, 0 ,0, CONST.READONLY) )
        i += 1
        if builtins.Config.has_section("Networking"):
            if builtins.Config['Networking']['Mode'].lower() == "static":
                elements.append(("         IP :",  i,   1, builtins.Config['Networking']['Ip'],   i, 15, 20, 20, CONST.READONLY))
                elements.append(("       Mask :",  i,  41, builtins.Config['Networking']['Mask'], i, 55, 20, 20, CONST.READONLY))
                i += 1
                elements.append(("    Gateway :",  i,   1, builtins.Config['Networking']['Gateway'],   i, 15, 20, 20, CONST.READONLY))
                elements.append(("        DNS :",  i,  41, builtins.Config['Networking']['DNS'], i, 55, 20, 20, CONST.READONLY))
                i += 1
                elements.append(("     Domain :",  i,   1, builtins.Config['Networking']['Domain'],   i, 15, 20, 20, CONST.READONLY))
                elements.append(("Mac Address :",  i,  41, builtins.Config['Networking']['MacAddress'], i, 55, 20, 20, CONST.READONLY))
                i += 1
            else:
                elements.append(("         IP :",  i,   1, builtins.Config['Networking']['Mode'],   i, 15, 20, 20, CONST.READONLY))
                elements.append(("Mac Address :",  i,  41, builtins.Config['Networking']['MacAddress'], i, 55, 20, 20, CONST.READONLY))
                i += 1
        else:
            elements.append(("         IP :",  i,   1, "dhcp",   i, 15, 20, 20, CONST.READONLY))
            elements.append(("Mac Address :",  i,  41, builtins.Config['Networking']['MacAddress'], i, 55, 20, 20, CONST.READONLY))
            i += 1
    
        elements.append( ("-- Output --", i, 32, "", i, 46, 0 ,0, CONST.READONLY) )
        i += 1
        if builtins.Config.has_option('Output', 'Device'):
            elements.append(("     Device :",  i,   1, builtins.Config['Output']['Device'],   i, 15, 20, 20, CONST.READONLY))
            i += 2
            elements.append( ("Content of " + builtins.Config['Output']['Device'] + ":", i, 1, "", i, 46, 0 ,0, CONST.READONLY) )
            i += 1
            for l in listDevice(builtins.Config['Output']['Device']):
                elements.append( ("", i, 1, l , i, 1, 0, 0, CONST.READONLY) )
                i += 1 
        else:
            elements.append(("      Image :",  i,   1, builtins.Config['Output']['Image'],   i, 15, 20, 20, CONST.READONLY))
            elements.append(("Root Device :",  i,  41, builtins.Config['Output']['Size'], i, 55, 20, 20, CONST.READONLY))
    
        i += 2
    
        results = builtins.Dialog.mixedform(text = "", elements = elements, title="Configuration Summary", backtitle="armStrap version " + CONST.VERSION)
        
        logExiting()
        return results[0]
    except SystemExit:
        pass
    except:
        logException(False)

        return False

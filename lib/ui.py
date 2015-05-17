from dialog import Dialog
from queue import Queue
from queue import Empty
import threading
import lib.utils as Utils

def constant(f):
    def fset(self, value):
        raise SyntaxError
    def fget(self):
        return f()
    return property(fget, fset)

class _Const(object):
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

def armStrap_Dialog():
    return Dialog(dialog = "dialog")

class armStrap_mixed(threading.Thread):
    def __init__(self, title = ""):
        self.queue = Queue()
        self.dialog = armStrap_Dialog()
        self.running = True
        self.active = False
        self.percent = 0
        self.text = ""
        self.title = title
        self.elements = []
        super(armStrap_mixed, self).__init__()
        self.start()
        
    def run(self):
        while self.running:
            try:
                command = self.queue.get(block=True, timeout=0.5)
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
                
    def show(self, percent = 0, text = ""):
        self.percent = percent
        self.text = text
        self.queue.put({'task': CONST.GUI_START})
    
    def update_item(self, name, value):
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
            
        self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': True})
            
    def update_main(self, percent = 0, text = ""):
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
            
    def hide(self):
        self.queue.put({'task': CONST.GUI_HIDE})
    
    def end(self):
        self.queue.put({'task': CONST.GUI_STOP})
 
class armStrap_gauge(threading.Thread):
    def __init__(self, title = ""):
        self.queue = Queue()
        self.dialog = armStrap_Dialog()
        self.running = True
        self.active = False
        self.percent = 0
        self.text = ""
        self.title = title;
        super(armStrap_gauge, self).__init__()
        self.start()
        
    def run(self):
        while self.running:
            try:
                command = self.queue.get(block=True, timeout=0.5)
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
    
    def show(self, percent = 0, text = ""):
        self.percent = percent
        self.text = text
        self.queue.put({'task': CONST.GUI_START})
    
    def update(self, percent = 0, text = ""):
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
    
    def increment(self, percent = 0, text = ""):
        self.percent += percent
        if self.percent > 100:
            self.percent = 100
        if (text != "") and (text != self.text):
            self.text = text
            self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': True})
        else:
            self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': False})
    
    def decrement(self, percent = 0, text = ""):
        self.percent -= percent
        if self.percent < 0:
            self.percent = 0
        if (text != "") and (text != self.text):
            self.text = text
            self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': True})
        else:
            self.queue.put({'task': CONST.GUI_UPDATE, 'update_text': False})
    
    def hide(self):
        self.queue.put({'task': CONST.GUI_HIDE})
    
    def end(self):
        self.queue.put({'task': CONST.GUI_STOP})
        
class armStrap_List():
    def __init__(self):
        self.data = []
        
    def set(self, name, value):
        found = False;
        t = []
        for d in self.data[:]:
            if d[0] == name:
                t.append( (d[0], value) )
                found = True
            else:
                t.append( (d[0], d[1]) )
                
        self.data = t
        
        if found == False:
            self.data.append( (name, value) )


def armStrap_Summary(config):
    dialog = armStrap_Dialog()
           #(label, yl, xl, item, yi, xi, field_length, input_length, attributes)
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
        for l in Utils.listDevice(config['Output']['Device']):
          elements.append( ("", i, 1, l , i, 1, 0, 0, CONST.READONLY) )
          i += 1
          
    else:
        elements.append(("      Image :",  i,   1, config['Output']['Image'],   i, 15, 20, 20, CONST.READONLY))
        elements.append(("Root Device :",  i,  41, config['Output']['Size'], i, 55, 20, 20, CONST.READONLY))
    
    i += 2
    
    
    dialog.mixedform(text = "", elements = elements, title="Configuration Summary", backtitle="armStrap version " + CONST.VERSION)
    
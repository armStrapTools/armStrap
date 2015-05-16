from dialog import Dialog
from queue import Queue
from queue import Empty
import threading

def constant(f):
    def fset(self, value):
        raise SyntaxError
    def fget(self):
        return f()
    return property(fget, fset)

class _Const(object):
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

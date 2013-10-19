#!/usr/bin/env python2

import os
import re
import sys

try:
   kernel_image = sys.argv[1]
except:
   kernel_image = ""

try:
   kernel_dest = sys.argv[2]
except:
   kernel_dest = "kernel.img"
   
try:
   mkimg_path = sys.argv[3]
except:
   mkimg_path = "."
   
if kernel_image == "":
  print("usage : imagetool-uncompressed.py <kernel image> <destination> <mkimage path>");
  sys.exit(0)
   
re_line = re.compile(r"0x(?P<value>[0-9a-f]{8})")

mem = [0 for i in range(32768)]

def load_to_mem(name, addr):
   f = open(name)

   for l in f.readlines():
      m = re_line.match(l)

      if m:
         value = int(m.group("value"), 16)

         for i in range(4):
            mem[addr] = int(value >> i * 8 & 0xff)
            addr += 1

   f.close()

load_to_mem(mkimg_path + "/boot-uncompressed.txt", 0x00000000)
load_to_mem(mkimg_path + "/args-uncompressed.txt", 0x00000100)

f = open(mkimg_path + "/first32k.bin", "wb")

for m in mem:
   f.write(chr(m))

f.close()

os.system("cat " + mkimg_path + "/first32k.bin " + kernel_image + " > " + kernel_dest)

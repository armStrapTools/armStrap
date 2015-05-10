armStrap
========

An universal sd/image creator for small arm development platform

WARNING
=======

You are on the development branch of armStrap, it may be broken at any moment and i do not offer any support until this branch is merged with Master!

QuickStart
----------

You need to be root to run this script. You have two options:

1) With no parameter from the command line, create an image using values found in config.sh.

2) Configure your build using the command line (Not recommended for version 0.8x, i've made
   many changes and some options have changed meanings or simply do nothing. Use the config
   file until i remove this message) :

    armStrap.sh version 1.0-stage
    Copyright (C) 2013-2014 Eddy Beaupre
    
    Usage : sudo armStrap.sh [PARAMETERS]
    
    Image/SD Builder:
      -b <BOARD>              Use board definition <BOARD>.
      -d <DEVICE>             Write to <DEVICE> instead of creating an image.
      -i <FILE>               Set image filename to <FILE>.
      -s <SIZE>               Set image size to <SIZE>MB.
      -h <HOSTNAME>           Set hostname.
      -p <PASSWORD>           Set root password.
      -w <SIZE>               Enable swapfile.
      -W                      Disable swapfile.
      -Z <SIZE>               Set swapfile size to <SIZE>MB.
      -n "<IP> <MASK> <GW>"   Set static IP.
      -N                      Set DHCP IP.
      -r "<NS1> [NS2] [NS3]"  Set nameservers.
      -e <DOMAIN>             Set search domain.
     
    Shell to SD card:
      -Z [DEVICE]             Shell into a SD card.
    
    Utilities:
      -g                      Disable GUI.
      -q                      Quiet.
      -c                      Directory Cleanup.
      -l                      Show licence.
    
    Avalable boards configuration:
    
     Board           Kernel          BootLoader      RootFS
    *A70Xh           sun7i           u-boot-sunxi    debian: stable testing unstable *ubuntu: precise trusty utopic *vivid
     A70Xh           sun7i-stage     u-boot         
     A70Xh           sunxi-next      u-boot         
     A70Xh           mainline        u-boot         
    *CubieBoard      sun4i           u-boot-sunxi    debian: stable testing unstable *ubuntu: precise trusty utopic *vivid
     CubieBoard      sun4i-stage     u-boot         
     CubieBoard      sunxi-next      u-boot         
     CubieBoard      mainline        u-boot         
    *CubieBoard2     sun7i           u-boot-sunxi    debian: stable testing unstable *ubuntu: precise trusty utopic *vivid
     CubieBoard2     sun7i-stage     u-boot         
     CubieBoard2     sunxi-next      u-boot         
     CubieBoard2     mainline        u-boot         
    *CubieTruck      sun7i-ct        u-boot          debian: stable testing unstable *ubuntu: precise trusty utopic *vivid
     CubieTruck      sun7i           u-boot-sunxi   
     CubieTruck      sun7i-stage     u-boot         
     CubieTruck      sunxi-next      u-boot         
     CubieTruck      mainline        u-boot         
    *HackBerry       sun4i           u-boot-sunxi    debian: stable testing unstable *ubuntu: precise trusty utopic *vivid
     HackBerry       sun4i-stage     u-boot         
     HackBerry       sunxi-next      u-boot         
     HackBerry       mainline        u-boot         
    
    (*) = Default configuration.
    
    With no parameter, create an image using values found in config.sh.
    
Nand Installer
--------------

A script to install the operating system in Nand, supporting the CubieBoard/HackBerry, CubieBoard2 and CubieTruck.

    Usage : armStrap-nandinstaller <cubieboard|cubieboard2|cubietruck>

Use the cubieboard target to install on CubieBoard/HackBerry.

armStrap APT repository
-----------------------
I also maintain a few repositories, mainly to support armStrap but which can also be useful to others.

To add the key needed to use the repository, you can do something like this:

    gpg --keyserver pgpkeys.mit.edu --recv-key 1F7F94D7A99BC726
    gpg --armor --export 1F7F94D7A99BC726 | apt-key add -

The repository is located at https://archive.armstrap.net/apt/ and has the following suites avalables:

* sunxi : This will be the main suite for version 1.x, while most of the feature are there, it is to be considered as unstable until version 1 is release.

Theses are the suites used by armStrap before version 1. They will be kept around for a while but probably not updated anymore.
* armStrap : General scripts and tools used by armStrap
* armv6l : Specific scripts and tools for the armv6l architecture.
* armv7l : Specific scripts and tolls for the armv7l architecture.
* bcmrpi : Kernels for bcmrpi CPU (Raspberry PI).
* sun4i : Linux 3.4 Kernel for sun4i CPU (A10).
* sun7i : Linux 3.4 Kernel for sun7i CPU (A20).
* sun7i-ct : Linux 3.4 Kernel for sun7i CPU with AP6210 WiFI/Bluetooth support.
* sunxi-next : Mainline Linux Kernel for sunxi CPU (Linux-Sunxi version).
* mainline : Official Linux Kernel for sunxi CPU.

Please note that i offer no support for theses kernels unless the issue is specific to armStrap. Use the official channels to report bugs and wishes for theses.

Also note that the repositories URL have changes, if you configured your board before february 2015, update the files located in /etc/apt/sources.list.d/ to the correct URL.

Licence
-------
Copyright (c) 2013-2014 Eddy Beaupre. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


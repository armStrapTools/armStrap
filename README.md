armStrap
========

An universal sd/image creator for small arm development platform

QuickStart
----------

You need to be root to run this script:

1) Edit armStrap.ini to suit your needs (if not present, armStrap will create one with default values).

2) As root, run ./armStrap, confirm the settings, hit enter and go take a coffee :)

Command line options
--------------------

    usage: armStrap [-h] [-v | -d] [-k] [-r] [-b] [-i]
    
    armStrap version 1.0 Release Candidate 1, (C) 2013-2015 Eddy Beaupré
    
    optional arguments:
      -h, --help     show this help message and exit
      -v, --verbose  increase logging verbosity
      -d, --debug    increase logging verbosity to maximum
      -k, --kernels  show avalable kernels
      -r, --rootfs   show avalable rootfs
      -b, --boards   show avalable boards
      -i, --ini      create a default configuration file
    
    Edit '__armStrap.ini__' to configure the target device.

armStrap.ini
------------

This file is used to select what type of device and its basic configuration. The file is divided into several sections:

Board
-----

This section is used to select what type of device and some basic information about it:

    [Board]
    branch = sunxi
    model = CubieTruck
    hostname = armStrap
    timezone = America/Montreal
    locales = en_US.UTF-8 fr_CA.UTF-8

* Branch : The general type of the device, right now only sunxi is supported, i will add bcmrpi (Raspberry PI) at a later stage
* Model : The model of the device, see __./armStrap -b__ for the list of avalable boards.
* HostName : The hostname you want for the device
* TimeZone : The timeZone you want for the device
* Locales : A list of locales you want to configure on the device, the first one become the default locale

Distribution
------------

This section is used to select what version of linux you want to install on the device:

    [Distribution]
    family = ubuntu
    version = vivid

* Family : Specify the family of the root filesystem, see __./armStrap -r__ for a list of valid distributions
* Version : Specify the version of the root filesystem.

Kernel
------

This section is used to select the kernel that will be installed:

    [Kernel]
    version = mainline

* Version : See __./armStrap -k__ for the list of avalable Kernels.

Networking
----------

This section configure the first wired interface of the device:

    [Networking]
    mode = dhcp
    macaddress = 00:02:46:52:e8:e4

or

    [Networking]
    mode = static
    ip = 192.168.0.100
    mask = 255.255.255.0
    gateway = 192.168.0.1
    domain = armstrap.net
    dns = 8.8.8.8 8.8.4.4
    macaddress = 00:02:46:52:e8:e4

* Mode : dhcp (ignore all other settings except MacAddress) or static
* MacAddress : If not set, armStrap will generate a random Mac Address starting with 00:02:46. Or you can specify one
* Ip : Static ip address of the device
* Mask : Netmask
* Gateway : Default gateway
* Domain : Default DNS search domain
* Dns : List of DNS resolver

BoardsPackages
--------------

This section configure packages that will be installed on the device during setup. I do not recommend using this unless you have very specific needs:

    [BoardsPackages]
    installoptionalspackages = no
    mandatory = ""
    optional = ""

* InstallOptionalPackages : armStrap comes with optional packages that are not installed by default (like the Nand Installer), if you want theses packages, set this option to yes
* Mandatory : A list of packages you want to install
* Optional : A list of optional packages you want to install, need InstallOptionalsPackages = yes

SwapFile
--------

This section control the creation of a swapfile using dphys-swapfile.

    [SwapFile]
    file = /var/swap
    size = 1024
    factor = 2
    maximum = 2048

* File : The location of the swap file
* Size : The Size of the swap file
* Factor : If Size is not specified, a swapfile of Ram x Factor will be automatically created
* Maximum : If Size is not specified, the maximum size of the swapfile

Users
-----

This section control the creation of a normal user and the root password:

    [Users]
    rootpassword = armStrap
    username = armStrap
    userpassword = armStrap

* RootPassword : Wathever password you want for root
* UserName : User name for the normal user (this user will be granted sudo rights)
* UserPassword : Password for your normal user

Output
------

    [Output]
    device = /dev/mmcblk0

or

    [Output]
    file = armStrap.img
    size = 2048

* Device : The target device, be cautious with this option, if you select the wrong device, it will be erased
* File : Create an image that can be dump (with dd or any other utility) to a SD card
* size : Size of the image to create

Nand Installer
--------------

A script to install the operating system in Nand, supporting the CubieBoard/HackBerry, CubieBoard2 and CubieTruck. To install the nand-installer, select InstallOptionalPackages in your configuration, or do 'sudo apt-get install armstrap-nand-installer' once your device is up and running.

    Usage : armStrap-nandinstaller <cubieboard|cubieboard2|cubietruck>

Use the cubieboard target to install on CubieBoard/HackBerry.

armStrap APT repository
-----------------------
I also maintain a few repositories, mainly to support armStrap but which can also be useful to others.

To add the key needed to use the repository, you can do something like this:

    gpg --keyserver pgpkeys.mit.edu --recv-key 1F7F94D7A99BC726
    gpg --armor --export 1F7F94D7A99BC726 | apt-key add -

The repository is located at https://archive.armstrap.net/apt/ and has the following suites avalables:

* sunxi : This is the main armStrap repository.

Theses are the suites used by armStrap before version 1. They will be kept around for a while but not updated anymore.
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
Copyright (c) 2013-2015 Eddy Beaupre. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


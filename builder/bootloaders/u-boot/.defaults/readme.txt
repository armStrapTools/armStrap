Setting mac address at boot:
----------------------------

Change the MAC parameter in the dynamic section:

[dynamic]
MAC = "deadbeefbad"

then recompile the fex file:

fex2bin <fexfile.fex> script.bin

The CubieTruck does not support setting the mac address at boot, you must
set it in the interface parameters of your operating system.

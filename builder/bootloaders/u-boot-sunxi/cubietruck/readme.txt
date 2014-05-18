
Video output configuration on the CubieTruck:
---------------------------------------------

Change the screen0_output_type parameter in cubietruck.fex to the following
value:

HDMI: screen0_output_type = 3
VGA:  screen0_output_type = 4

Then recompile the fex file and reboot:

fex2bin cubietruck.fex script.bin

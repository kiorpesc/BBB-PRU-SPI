BBB-PRU-SPI
===========

Initial work on using one PRU core as an SPI Master.

Maximum SPI clock speed is 5MHz.

The intent is to use the scratch pads to allow PRU0 to send an SPI transaction to PRU1.
PRU1 will then perform the transaction and return the result to PRU0 via the scratch pads.

I'm using a USB JTAG emulator and Code Composer Studio at the moment to inspect registers and memory.

The assembly code can be compiled with:

./pasm -V3 -b PRU_SPI.p

Once compiled, the bin file can be loaded directly into the PRU's memory using CCS.

Mode 2 is the only SPI mode implemented at the moment, because my initial test device
was mode 2.  The other modes are coming shortly.

The pins in use need to be set to the correct mode

MISO  --  P8_27  -- must be set to 0x36  (input enabled, pullup enabled, mode 6)
MOSI  --  P8_29  -- mode 5 (0x05)
SCLK  --  P8_28  -- mode 5 (0x05)
CS Pins:
	I have set up the code to allow up to eight SPI devices at one time,
	via PRU1's pins 0-7 (P8_39 -> P8_46, but not in that order)
	These must also be set to mode 5 (0x05)
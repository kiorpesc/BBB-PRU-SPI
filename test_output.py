# this converts the serial output of my Arduino-based logic analyzer
# to a command line output - gives a decent idea of what's going on

import serial

analyzer = serial.Serial('/dev/ttyACM0', 115200)

#f = open('log.txt', 'r')

strs = ['', '', '', '']

while True:
    line = analyzer.readline()
    if line[0] == '-':
        for s in strs:
            print s
        strs = ['','','','']
        print '////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////'        
    else:
        val = int(line)
        for x in range(4):
            if (val & (1 << x) != 0):
                strs[x] += '='
            else:
                strs[x] += '_'



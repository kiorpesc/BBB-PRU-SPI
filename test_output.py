# this converts the serial output of my Arduino-based logic analyzer
# to a command line output - gives a decent idea of what's going on

f = open('log.txt', 'r')

strs = ['', '', '', '']

for line in f:
    if line[0] == '-':
        for x in range(4):
            strs[x] += 'X'
    else:
        val = int(line)
        for x in range(4):
            if (val & (1 << x) != 0):
                strs[x] += '='
            else:
                strs[x] += '_'

for str in strs:
    print str

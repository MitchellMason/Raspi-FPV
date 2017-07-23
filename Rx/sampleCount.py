#!/usr/bin/env python

import sys
import time
import fileinput

def write(line):
    sys.stdout.write(line)
    sys.stdout.flush()

sps  = 0.0
totalSamples = 0
start_time = time.time()

dFrame = 0.0
lastSampleTime = 0
thisSampleTime = 0

telLine = "TEST"

try:
    while True:
        #Collect the data
        telLine = sys.stdin.readline()

        #calculate samples per second
        totalSamples += 1
        sps = totalSamples / (time.time() - start_time)
        
        #Calculate time since the last frame based on packet time stamps
        data = telLine.split(",")
        packetTime = data[0].split(":")
        thisSampleTime = float(packetTime[2])
        dFrame = thisSampleTime - lastSampleTime
        lastSampleTime = thisSampleTime

        #format the output
        output = """
samples per second: {s}
time since last frame: {d}
recent packet: {l}
""".format(
        s = sps,
        d = dFrame,
        l = telLine
    )
        
        #Write the output
        output = output.replace("\n", "\n\033[K")
        write(output)
        lines = len(output.split("\n"))
        write("\033[{}A".format(lines - 1))

except KeyboardInterrupt:
	pass

#!/usr/bin/env python

##
# This python script reads the sensor data and the config file
# After the data is read to be sent, it is printed to stdout
# and piped into wifibroadcast's tx
##

##
# TODO: Send current time (to calculate lag)
# TODO: Send battery voltage remaining (Calculated through analong inputs)
##

import sys
import json
from envirophat import *
from time import sleep
import math
import os

#How many samples we hold at any time (To smoothen out results)
sampleSize = 10
heading = []
pressure = []
oat = []
aob = []
pitch = []
speed = []
initAlt = 0
alt = []

#Global sample index
i = 0

#The order in which data will be written. Read from config
dataOrder = ""

#The sensor might be mounted so x,y,z don't line up with the aircraft
xyzMapping = ""
xPosit = 0
yPosit = 0
zPosit = 0
invertPitch = False
invertAOB = False

# The path we write data out to
outputFile = ""

def main():
    try:
        init()
        while True:
            loop()
    except KeyboardInterrupt:
        print("closing")
        leds.off()

# Convert from bars to Feet
def toAlt(hp):
    mb = hp / 100
    return (1 - pow(mb / 1013.25, 0.190284)) * 145366.45

def roundup(x):
    return int(math.ceil(x / 10.0)) * 10

def calcRoll(y, z):
    return (math.atan2(-y, z)*180.0) / math.pi

def calcPitch(x,y,z):
    return (math.atan2(x, math.sqrt(y*y+z*z)) * 180) / math.pi

def init():
    # load the order data is printed in
    if len(sys.argv) != 3:
        print("remember to feed the config file and output pipe")
        exit()

    # load the config file
    configFile = open(sys.argv[1],'r')
    configJson = json.loads(configFile.read())
    global dataOrder
    dataOrder = configJson['network']['telDataOrder']
    global xyzMapping
    global xPosit
    global yPosit
    global zPosit
    xyzMapping = configJson['TxCorrections']['xyzMapping']
    
    # We want to establish what coordinate goes where. 'X' on the sensor might 
    # not be 'X' on the aircraft. We sample x,y,z but if xyzMapping reads as
    # 'zyx' we'll flip x and z.

    for i, c in enumerate(xyzMapping):
        if c == 'x':
            xPosit = i
        if c == 'y':
            yPosit = i
        if c == 'z':
            zPosit = i
    
    # There is also a chance we'll need to invert pitch and AOB
    global invertPitch
    global invertAOB
    invertPitch = configJson['TxCorrections']['invertPitch']
    invertAOB = configJson['TxCorrections']['invertAOB']

    #Open the fifo we'll write the data out to. This line will block until 
    #a reader is attatched to the fifo. 
    global outputFile
    outputFile = open(sys.argv[2], 'w', 1)
    print("Telemetry FIFO opened")

    #Build a samples history to work with
    global heading
    global pressure
    global oat
    global aob
    global pitch
    global speed
    global initAlt
    for i in range(0,sampleSize):
        heading.append(motion.heading())
        pressure.append(weather.pressure())
        oat.append(weather.temperature())
        x,y,z = motion.accelerometer()
        
        sample = [x, y, z]
        reOrderedSample = [ sample[i] for i in [xPosit,yPosit,zPosit]]
        x = reOrderedSample[0]
        y = reOrderedSample[1]
        z = reOrderedSample[2]
        
        if invertAOB:
            aob.append(-calcRoll(y,z))
        else:
            aob.append(calcRoll(y,z))
        
        if invertPitch:
            pitch.append(-calcPitch(x,y,z))
        else:
            pitch.append(calcPitch(x,y,z))
        speed.append(-1)
    initAlt = toAlt(sum(pressure) / len(pressure))
    for i in range(0,sampleSize):
        alt.append(toAlt(pressure[i]) - initAlt)
    

def loop():
    #Boilerplate
    leds.on()
    global heading
    global pressure
    global alt
    global oat
    global aob
    global pitch
    global speed
    global initAlt
    global i
    global sampleSize
    global dataOrder
    global xPosit
    global yPosit
    global zPosit

    #Take new samples
    heading[i] = motion.heading()
    pressure[i] = weather.pressure()
    alt[i] = initAlt - toAlt(pressure[i])
    oat[i] = weather.temperature()
    x, y, z = motion.accelerometer()
    #factor in corrections
    sample = [x, y, z]
    reOrderedSample = [ sample[i] for i in [xPosit,yPosit,zPosit]]
    x = reOrderedSample[0]
    y = reOrderedSample[1]
    z = reOrderedSample[2]


    aob[i] = calcRoll(y,z)
    pitch[i] = calcPitch(x,y,z)
    
    if invertPitch:
        pitch[i] *= -1
    if invertAOB:
        aob[i] *= -1
    
    speed[i] = 0.0 #TODO
    
    #write the samples out to the fifo
    try:
        outputFile.write(dataOrder.format(
            heading = str(round(sum(heading) / len(heading), 2)),
            altitude =  str(roundup(sum(alt) / len(alt))),
            aob = str(round(sum(aob) / len(aob) , 2)),
            pitch = str(round(sum(pitch) / len(pitch), 2)),
            speed = 0.0, #TODO
            oat = str(round(sum(oat) / len(oat), 1))
        )+'\n')
    except IOError as e:
        #The reader on the pipe shut down, so we should too
        exit()

    #Prepare for the next iteration
    i = i + 1
    if i>=sampleSize:
        i = 0
    

main()

#!/usr/bin/env python

# This python script reads the sensor data and the config file
# After the data is read to be sent, it is printed to stdout
# and piped into wifibroadcast's tx

import sys
import json
from envirophat import *
from time import sleep
import math
import os

sampleSize = 10
heading = []
pressure = []
oat = []
aob = []
pitch = []
speed = []
initAlt = 0
alt = []
i = 0
dataOrder = ""
outputFile = ""

def main():
    try:
        init()
        while True:
            loop()
    except KeyboardInterrupt:
        print("closing")
        leds.off()

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
    #load the order data is printed in
    if len(sys.argv) != 3:
        print("remember to feed the config file and output pipe")
        exit()

    #load the config file
    configFile = open(sys.argv[1],'r')
    configJson = json.loads(configFile.read())
    global dataOrder
    dataOrder = configJson['network']['telDataOrder']
    
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
        aob.append(calcRoll(y,z))
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

    #Take new samples
    heading[i] = motion.heading()
    pressure[i] = weather.pressure()
    alt[i] = initAlt - toAlt(pressure[i])
    oat[i] = weather.temperature()
    x, y, z = motion.accelerometer()
    aob[i] = calcRoll(y,z)
    pitch[i] = calcPitch(x,y,z)
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
    
    sleep(0.1)

main()

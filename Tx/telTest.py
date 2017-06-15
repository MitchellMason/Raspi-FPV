#!/usr/bin/env python

from envirophat import *
import socket

ip='0.0.0.0' #accept from anywhere
port = 5904

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
conn = 0
addr = 0
sampleSize = 10
heading = []
pressure = []
oat = []
aob = []

def main():
    try:
        init()
	while True:
	    loop()
    except KeyboardInterrupt:
        print("closing")
        leds.off()
        sock.close()

def init():
    #Build a samples database
    global heading
    global pressure
    global oat
    global aob
    for i in range(0,sampleSize):
        heading.append(motion.heading())
        pressure.append(weather.pressure())
        oat.append(weather.temperature())
        x,y,z = motion.accelerometer()
        aob.append(x)

    sock.bind((ip, port))
    print("Waiting for connection")
    sock.listen(1)
    global conn
    global addr
    conn, addr = sock.accept()
    print("new connection")
    leds.on()

def loop():
    global heading
    global pressure
    global oat
    global aob
    i=0
    data = conn.recv(1024)
    if not data: return
    heading[i] = motion.heading()
    pressure[i] = weather.pressure()
    oat[i] = weather.temperature()
    x, y, z = motion.accelerometer()
    aob[i] = x
    i = i + 1
    if i>sampleSize:
        i =0
    conn.send(str(sum(heading) / len(heading)) + ':' + str(sum(pressure) / len(pressure)) + ':' + str(sum(oat) / len(oat)) + ':' + str(sum(aob) / len(aob)) + ':' + str(y) + ':' + str(z))
    

main()

#!/bin/bash

# This script tests telemetry only
echo "Raspi-FPV created by Mitchell Mason (C) 2016"

#Send the config file over bluetooth
echo "*****Serving config over bluetooth"
python initFPV.py config.json &!

#read data from the config file
echo "*****Reading config"
python jsonToTerminal.py config.json > temp.dat #UGLY HACK, BUT WE DO WHAT WE HAVE TO
source temp.dat
rm temp.dat

echo "*****Begin transmitter"
sudo killall ifplugd #stop management of interface
echo "*****Configuring antenna"
sudo ifconfig wlan_fpv down
sudo iw dev wlan_fpv set monitor otherbss fcsfail
sudo ifconfig wlan_fpv up
sudo iwconfig wlan_fpv channel 13

#telemetry
echo "*****Starting telemetry"
sudo python telemetryTx.py ./config.json /dev/stdout | sudo tx -b $packetsPerBlock -r $fec -f $bytesPerPacket -p 1 wlan_fpv

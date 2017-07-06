#!/bin/bash

# Start only a video stream for testing
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

#video
echo "*****Starting video"
sudo raspivid -ih -t 0 -w $width -h $height -fps $fps -b $bitrate -n -g $keyframerate -pf high --flush -o - | sudo tx -b $packetsPerBlock -r $fec -f $bytesPerPacket wlan_fpv

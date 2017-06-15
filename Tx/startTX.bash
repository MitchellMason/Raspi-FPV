#!/bin/bash

#Get number of interfaces. If there's only one (plus lo) then we transmit then shutdown
ifaces="$(ls -A /sys/class/net | wc -l)"
maxiFaces=1
echo "total ifaces: " $ifaces

if (($ifaces < $maxiFaces))
then
	echo "We'll shutdown at the end"
else
	echo "We won't shut down"
fi

#read data from the config file
echo "Reading config"
python jsonToTerminal.py config.json > temp.dat #UGLY HACK, BUT WE DO WHAT WE HAVE TO
source temp.dat
rm temp.dat

echo "Begin transmitter"
sudo killall ifplugd #stop management of interface
echo "configuring antenna"
sudo ifconfig wlan_fpv down
sudo iw dev wlan_fpv set monitor otherbss fcsfail
sudo ifconfig wlan_fpv up
sudo iwconfig wlan_fpv channel 13
echo "Starting capture"
#raspivid -ih -t 0 -w $width -h $height -fps $fps -b $bitrate -g $keyframerate -pf main -fl -o - | sudo /home/pi/wifibroadcast/tx -b $packetsPerBlock -r $fec -f $bytesPerPacket wlan_fpv
python telemetryTx.py config.json | sudo /home/pi/wifibroadcast/tx -m $telBytesPerPacket -b $telPacketsPerBlock -r $fec -p 1 wlan_fpv

#When we're done transmitting, safely turn off
if (($ifaces < $maxiFaces))
then
	echo "Shutdown!"
	#sudo shutdown now
fi

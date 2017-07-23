#!/bin/bash

#Used to ensure proper data flow from the drone camera and test latency. 

if [ $# != 3 ]; then
	echo "Not enough arguments provided. give b r f in that order"
	exit -1
fi

#prime the antenna
sudo killall ifplugd #stop management of interface
sudo ifconfig wlan_fpv down
sudo iw dev wlan_fpv set monitor otherbss fcsfail
sudo ifconfig wlan_fpv up
sudo iwconfig wlan_fpv channel 13

#Start the video
sudo rx -b $1 -r $2 -f $3 -p 1 wlan_fpv | python sampleCount.py

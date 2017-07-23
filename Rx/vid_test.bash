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
echo "sudo rx -b $1 -r $2 -f $3 -p 0 -u 9305 wlan_fpv"
#sudo rx -b $1 -r $2 -f $3 -p 0 wlan_fpv | /opt/vc/src/hello_pi/hello_video/hello_video.bin
sudo rx -b $1 -r $2 -f $3 -p 0 -u 9305 wlan_fpv

#PIPE=/home/pi/sketchbook/SimplePipeVideoPlayer/data/vid

echo "Making pipe"
#sudo rm -f $PIPE
#sudo mkfifo -m 0666 $PIPE

echo "Starting listener"
#sudo rx -b $1 -r $2 -f $3 -p 0 wlan_fpv | netcat -q -1 -vvv -u 127.0.0.1 -p 9305
#sudo rx -b $1 -r $2 -f $3 -p 0 wlan_fpv | python UDPServe.py #$PIPE

#echo "Piping to netcat"
#tail -f /tmp/vid | netcat -vvv -u 127.0.0.1 9305

echo "quitting"

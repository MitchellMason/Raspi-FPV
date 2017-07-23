#!/bin/bash

# This is the script that should be run at boot time, when connected to the drone
# If desired, pass '-shutdown' from the command line to safely shut down when
# finished
echo "Raspi-FPV created by Mitchell Mason (C) 2016"

shutdownFlag='-shutdown'

if [[ "$1" == "$shutdownFlag" ]];
then
    echo "On completion, we'll shut down"
fi

#Send the config file over bluetooth
echo "*****Serving config over bluetooth"
python BTConfigServer.py config.json #&!
#pid=`echo $!`

#read data from the config file
echo "*****Reading config"
python jsonToTerminal.py config.json > temp.dat #UGLY HACK, BUT WE DO WHAT WE HAVE TO
source temp.dat
rm temp.dat

#initialize the fifos
sudo rm -f /tmp/fifo0
sudo rm -f /tmp/fifo1
mkfifo /tmp/fifo0
mkfifo /tmp/fifo1

echo "*****Begin transmitter"
sudo killall ifplugd #stop management of interface
echo "*****Configuring antenna"
sudo ifconfig wlan_fpv down
sudo iw dev wlan_fpv set monitor otherbss fcsfail
sudo ifconfig wlan_fpv up
sudo iwconfig wlan_fpv channel 13


#telemetry
echo "*****Starting telemetry"
sudo python telemetryTx.py ./config.json /tmp/fifo1 &!

#video
echo "*****Starting video"
sudo raspivid -ih -t 0 -w $width -h $height -fps $fps -b $bitrate -n -g $keyframerate -pf $encprofile -if cyclicrows --flush -o /tmp/fifo0 &!

#Transmission
sudo tx -r $FECPacketsPerBlock -f $FECBlockSize -b $PacketsPerBlock -x $TransmissionsPerBlock -m $MinBytesPerFrame -s 2 wlan_fpv

#kill BT server
#sudo kill $pid

if [[ "$1" == "$shutdownFlag" ]];
then
    sudo shutdown now
fi

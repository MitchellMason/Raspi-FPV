#Used to ensure proper data flow from the drone camera and test latency. 

#prime the antenna
sudo killall ifplugd #stop management of interface
sudo ifconfig wlan_fpv down
sudo iw dev wlan_fpv set monitor otherbss fcsfail
sudo ifconfig wlan_fpv up
sudo iwconfig wlan_fpv channel 13

#Start the video
sudo rx -b 8 -r 4 -f 1024 -p 0 wlan_fpv | /opt/vc/src/hello_pi/hello_video/hello_video.bin

#primes the antenna to receive/transmit data over monitor, and 
#establishes fifo pipes

sudo rm /tmp/tel
sudo rm /tmp/vid
sudo mkfifo -m 777 /tmp/tel
sudo mkfifo -m 777 /tmp/vid

sudo killall ifplugd #stop management of interface
sudo ifconfig wlan_fpv down
sudo iw dev wlan_fpv set monitor otherbss fcsfail
sudo ifconfig wlan_fpv up
sudo iwconfig wlan_fpv channel 13
echo "	prime.bash: Antennas ready, fifos up"

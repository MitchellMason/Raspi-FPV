#egin reading from the antenna
echo "  vid.bash: Starting listener"

#First, we open a pipeline to the /tmp/vid fifo
sudo rx \
-b $packetsPerBlock \
-r $fecPacketsPerBlock \
-f $fecBlockSize -p 0 -u 9305 wlan_fpv > \
/tmp/vid &!

echo "  vid.bash: Starting netcat"
#Then, we pipe that to netcat to stream over UDP. We do this so
#the reader in processing doesn't have to read from the first sent packet
cat /tmp/vid | netcat -q -10 -p 127.0.0.1 -u 9305

echo "  vid.bash: Netcat quit"

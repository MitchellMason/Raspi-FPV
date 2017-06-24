#add some data to the pipe to prevent hang ups
echo "init" > /tmp/vid

#Begin reading from the antenna
echo "	vid.bash: Starting listener with packetsPerBlock $packetsPerBlock, fec $fec bytesPerPacket, $bytesPerPacket"
sudo rx -b $packetsPerBlock -r $fec -f $bytesPerPacket -p 0 wlan_fpv > /tmp/vid

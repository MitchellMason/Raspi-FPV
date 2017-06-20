iface=wlan_fpv

#Make the pipe that we'll read from
rm tel
mkfifo tel

#Begin reading from the antenna
sudo ./rx -b $packetsPerBlock -r $fec -f $bytesPerPacket wlan_fpv > tel

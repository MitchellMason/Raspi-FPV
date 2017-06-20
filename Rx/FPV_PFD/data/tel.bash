#establish the fifo
rm tel
mkfifo tel

#init the fifo so the reader in Processing doesn't hang
echo "init" > tel

#Begin reading from the antenna
echo "	tel.bash: Starting listener with packetsPerBlock $packetsPerBlock, fec $fec bytesPerPacket, $bytesPerPacket"
sudo rx -p 1 -b $packetsPerBlock -r $fec -f $bytesPerPacket wlan_fpv > tel

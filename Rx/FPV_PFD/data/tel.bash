#init the fifo so the reader in Processing doesn't hang
echo "init" > /tmp/tel

#Begin reading from the antenna
echo "	tel.bash: Starting listener"
sudo rx -b $packetsPerBlock -r $fecPacketsPerBlock -f $fecBlockSize -p 1 wlan_fpv > /tmp/tel

#add some data to the pipe to prevent hang ups
echo "	Adding data to /tmp/vid to initiate"
echo "test" > /tmp/vid

#Begin reading from the antenna
echo "	vid.bash: Starting listener"
sudo rx -b $packetsPerBlock -r $fecPacketsPerBlock -f $fecBlockSize -p 0 wlan_fpv > /tmp/vid

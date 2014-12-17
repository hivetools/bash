#!/bin/bash
while [ 1 ]
do
top -n 4
clear
iwconfig wlan0
echo
ifconfig wlan0
echo
#ifconfig eth0
sleep 10
clear
tail /home/hivetool/$HOSTNAME.log
echo
echo
tail /home/hivetool/error.log
sleep 10
clear
echo "TEMPerHUM log"
tail tempered.log
sleep 10
clear
echo "hivetool.log"
cat /home/hivetool/hivetool.log
sleep 10
clear
/home/hivetool/last_row.sh
sleep 10
done

#!/bin/bash
# version 0.1
# reads the Phidget Bridge board and scales the output
SCALE=`/usr/bin/python /home/hivetool/phidget.py`
INPUT_0=`echo $SCALE | grep  -o "Bridge 0: \-*[0-9]*\.[0-9]*" | grep -o "\-*[0-9]*\.[0-9]*"`
INPUT_1=`echo $SCALE | grep  -o "Bridge 1: \-*[0-9]*\.[0-9]*" | grep -o "\-*[0-9]*\.[0-9]*"`
INPUT_2=`echo $SCALE | grep  -o "Bridge 2: \-*[0-9]*\.[0-9]*" | grep -o "\-*[0-9]*\.[0-9]*"`
INPUT_3=`echo $SCALE | grep  -o "Bridge 3: \-*[0-9]*\.[0-9]*" | grep -o "\-*[0-9]*\.[0-9]*"`
MILIVOLTS_TOTAL=`echo $SCALE | grep  -o "Total: \-*[0-9]*\.[0-9]*" | grep -o "\-*[0-9]*\.[0-9]*"`

#echo "Total: $MILIVOLTS_TOTAL"
#echo "Channel 0: $INPUT_0"
#echo "Channel 1: $INPUT_1"
#echo "Channel 2: $INPUT_2"
#echo "Channel 3: $INPUT_3"

WEIGHT_TOTAL=`echo "scale=2; (($MILIVOLTS_TOTAL*31.215)+0)/1" | bc`

DATE=`date +"%Y/%m/%d %H:%M:%S"`
echo -e "$DATE $INPUT_0 $INPUT_1 $INPUT_2 $INPUT_3 $MILIVOLTS_TOTAL $WEIGHT_TOTAL" >> /home/hivetool/phidget.log

echo $WEIGHT_TOTAL

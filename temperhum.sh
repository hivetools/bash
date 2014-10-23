#!/bin/bash
# read the TEMPerHUM

while getopts d: option
do
        case "${option}"
        in
                d) DEVICE=${OPTARG};;
        esac
done

#echo "DEVICE = $DEVICE"

DATA_GOOD=0
COUNTER=1
while [ $COUNTER -lt 11 ] && [ $DATA_GOOD -eq 0 ]
do
      DATE2=`date +"%Y/%m/%d %H:%M:%S"`
      TEMPerHUM=`/usr/bin/timeout 5 /usr/local/bin/tempered $DEVICE`
      echo -ne "$DATE2 $COUNTER $? $TEMPerHUM \n" >> /home/hivetool/tempered.log
      if [[ -n $TEMPerHUM ]]
      then
        HUMIDITY=`echo $TEMPerHUM | grep  -o "\-*[0-9]*\.[0-9]\%" | grep -o "\-*[0-9]*\.[0-9]"`
        TEMP=`echo $TEMPerHUM | grep  -o "temperature \-*[0-9]*\.[0-9]" | grep -o "\-*[0-9]*\.[0-9]"`
        st=`echo "$HUMIDITY < 0" | bc`
        if [[ $st -eq 0 ]]
        then
         DATA_GOOD=1
        else
         HUMIDITY=""
         TMEP=""
        fi
      fi
      let "COUNTER += 1"
      sleep $COUNTER
done
#echo $COUNTER $TEMP $HUMIDITY

if [[ $COUNTER -gt 11 ]]
then
  echo "$DATE2 ERROR reading $DEVICE" >> /home/hivetool/error.log
fi

if test $COUNTER -gt 2
then
  echo "$DATE WARNING reading $DEVICE: retried $COUNTER" >> /home/hivetool/error.log
fi

echo $TEMP $HUMIDITY



#
# read the scale
# 
#
HX711_ZERO=$HIVE_WEIGHT_INTERCEPT
HX711_CALI=$HIVE_WEIGHT_SLOPE
#HX711_ZERO=363655
#HX711_CALI=19900
#
# read the scale
DATA_GOOD=0
COUNTER=1
while [ $COUNTER -lt 5 ] && [ $DATA_GOOD -eq 0 ]; do

COUNTS=`/usr/bin/timeout 5 /usr/local/bin/hx711 $HX711_ZERO`
WEIGHT=`echo "scale=2; ($COUNTS/$HX711_CALI)" | bc`
        if [ $WEIGHT ]
        then
         DATA_GOOD=1
        fi
      let "COUNTER += 1"
done
#echo $COUNTER $COUNTS $WEIGHT

if [ $COUNTER -gt 10 ]
then
  echo "$DATE ERROR reading Scale $DEVICE" >> /home/hivetool/error.log
  SCALE=-555
fi
if test $COUNTER -gt 2
then
  echo "$DATE WARNING reading Scale /dev/ttyS0: retried $COUNTER" >> /home/hivetool/error.log
fi

echo "$WEIGHT"


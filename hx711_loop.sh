while [ 1 ]
do
DATE=`date`
echo $DATE
COUNTS=`timeout 5 ./hx711 23000`
echo $COUNTS
WEIGHT=`echo "scale=2; ($COUNTS/20550)" | bc`
echo -e "$WEIGHT\n\r"
sleep 5
done

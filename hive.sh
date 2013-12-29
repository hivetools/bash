#!/bin/bash

# redirect stdout and stderr to logfile
rm /home/hivetool/hivetool.log
exec >>/home/hivetool/hivetool.log 2>&1

HOST=`hostname`

DATE=`date +"%Y/%m/%d %H:%M:%S"`

# read the scale
# ### NOTE this is bad as it can hang the process! ###
#
while [[ ! $SCALE ]]
do
    echo -e -n "N\r\n" > /dev/ttyUSB0
    read -t 3 SCALE < /dev/ttyUSB0
    SCALE=`echo $SCALE | gawk --posix '/^\+ [0-9]{1,3}\.[0-9] lb$/'`
done

echo "scale: $SCALE\n"

# read the TEMPerHUM
#NOTE hidraw1 may need to be replaced with the correct device

DATA_GOOD=0
COUNTER=1
while [[  $COUNTER -lt 20 && $DATA_GOOD -eq 0 ]]; do
      DATE2=`date +"%Y/%m/%d %H:%M:%S"`
      TEMPerHUM=`/usr/local/bin/tempered /dev/hidraw1`
      echo -ne "$DATE2 $COUNTER $? $TEMPerHUM \n" >> /home/hivetool/tempered.log
      if [[ -n $TEMPerHUM ]]
      then
        HUMIDITY=`echo $TEMPerHUM | grep  -o "[0-9]*\.[0-9]\%" | grep -o "[0-9]*\.[0-9]"`
        TEMP=`echo $TEMPerHUM | grep  -o "temperature \-*[0-9]*\.[0-9]" | grep -o "\-*[0-9]*\.[0-9]"`
        if [[ $HUMIDITY ]]
        then
         DATA_GOOD=1
        fi
      fi
      let "COUNTER += 1"
      sleep 1
done
echo $COUNTER $TEMP $HUMIDITY

if [[ $COUNTER -gt 19 ]]
then
  echo "$DATE2 ERROR reading /dev/hidraw1" >> /home/hivetool/error.log
fi

if test $COUNTER -gt 2
then
  echo "$DATE WARNING reading /dev/hidraw1: retried $COUNTER" >> /home/hivetool/error.log
fi


TEMP=`echo "scale=1; ($TEMP-1)" | bc`
TEMPF=`echo "scale=1; (($TEMP*9)/5)+32" | bc`

# 
# get the local weather
#
# ### NOTE replace KGADILLA1 with your local weather station ###
#
curl --retry 5 -s http://api.wunderground.com/weatherstation/WXCurrentObXML.asp?ID=KGADILLA1 > /tmp/wx.xml
temp_f=`grep temp_f /tmp/wx.xml | grep  -o "[0-9]*\.[0-9]*"`
temp_c=`grep temp_c /tmp/wx.xml | grep  -o "[0-9]*\.[0-9]*"`
wind_dir=`grep wind_dir /tmp/wx.xml | grep -o "[A-Z]*"`
wind_mph=`grep wind_mph /tmp/wx.xml | grep  -o "[0-9]*\.[0-9]*"`
wind_gust_mph=`grep wind_gust_mph /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
pressure_mb=`grep pressure_mb /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
dewpoint_f=`grep dewpoint_f /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
#solar_radiation=`grep solar_radiation /tmp/wx.xml |  grep  -o "[0-9]*"`
precip_1hr_in=`grep precip_1hr_in /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
precip_today_in=`grep precip_today_in /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`


xml_temp_f=`grep temp_f /tmp/wx.xml`
xml_temp_c=`grep temp_c /tmp/wx.xml`
xml_relative_humidity=`grep relative_humidity /tmp/wx.xml`
xml_wind_dir=`grep wind_dir /tmp/wx.xml`
xml_wind_mph=`grep wind_mph /tmp/wx.xml`
xml_wind_gust_mph=`grep wind_gust_mph /tmp/wx.xml`
xml_pressure_mb=`grep pressure_mb /tmp/wx.xml`
xml_dewpoint_f=`grep dewpoint_f /tmp/wx.xml`
#solar_radiation=`grep solar_radiation /tmp/wx.xml`
xml_precip_1hr_in=`grep precip_1hr_in /tmp/wx.xml`
xml_precip_today_in=`grep precip_today_in /tmp/wx.xml`

AMBIENT=$temp_c

#echo "Temperature " $temp_f
#echo "Wind Direction " $wind_dir
#echo "Wind Speed " $wind_mph
#echo "Gust " $wind_gust_mph
#echo "Dewpoint " $dewpoint_f
#echo "Relative Humidity " $relative_humidity
#echo "Pressure " $pressure_in
#echo "Pressure Trend " $pressure_trend
#echo "Precip This Hour " $precip_1hr_in
#echo "Precip Today " $precip_today_in


echo "<hive_data>" > /tmp/hive.xml
source /home/hivetool/xml.sh >> /tmp/hive.xml
cat /tmp/wx.xml|grep -v "xml" >> /tmp/hive.xml
echo "</hive_data>" >> /tmp/hive.xml
 
# Write everything to the log file
echo -ne "\n"$DATE $SCALE $TEMP $AMBIENT $temp_f $wind_dir $wind_mph $wind_gust_mph $dewpoint_f $relative_humidity $pressure_mb $solar_radiation $WX_EVAPOTRANSPIRATION $WX_VAPOR_PRESSURE $precip_today_in>> /home/hivetool/hive.log


#run the graphing program to create index.html and hive_graph.gif
/var/www/htdocs/graph_hive.pl

# send the data to hivetool.org
#
# ### NOTE replace user:password with the correct user and password ###
#
curl --retry 5 -k -u user:password -X POST --data-binary @/tmp/hive.xml https://hivetool.org/private/test_xml4.pl  -H 'Accept: application/xml' -H 'Content-Type: application/xml'

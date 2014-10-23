#!/bin/bash
# ##############################################################################
#                         hive.sh ver 0.4
#
# Reads hive variables, logs them and sends the data to hivetool.net
# 
# May  use:
# cpw200plus.sh         Reads weight from Adam Equipment CPW200plus scale
# temperhum.sh          Read temperature and humidity from TEMPerHUM model 2
# phidget.sh            Read weight from Phidgets Bridge board
# hx711.sh              Read weight from HX711 board
# mysql.sh              Log data to local SQL database
# ##############################################################################
#
# Set the hive name(s)
#
HIVE1_NAME="XP001"
HIVE2_NAME=""
HIVE1_ID=1
#
# Set the scale device(s) (this is usually /dev/ttyS0 or ttyUSB0)
#
HIVE1_SCALE_DEVICE="/dev/ttyUSB0"
#HIVE2_SCALE_DEVICE="/dev/ttyUSB0"

# Set the TEMPerHUM devices
# To see the devices, run tempered with no argument
#
HIVE1_TEMP_DEVICE="/dev/hidraw1"
#HIVE2_TEMP_DEVICE="/dev/hidraw3"
#HIVE1_AMBIENT_TEMP_DEVICE="/dev/hidraw5"
#
# Set the Weather Underground weather station ID
#
WX_ID="KGACLAYT6"
#
HIVE1_WEIGHT=0
HIVE1_TEMP=0
HIVE1_HUMIDITY=0
# ### END OF SETUP ###
#
#
# Redirect stdout and stderr to logfile
#
#rm /home/hivetool/hivetool.log
#exec >>/home/hivetool/hivetool.log 2>&1
#
# Get the date and time
#
DATE=`date +"%Y/%m/%d %H:%M:%S"`
#
# Read scale 1
#
#HIVE1_WEIGHT=$(source /home/hivetool/cpw200plus.sh -d $HIVE1_SCALE_DEVICE)
#set -- junk $HIVE1_WEIGHT
#shift
#HIVE1_WEIGHT=$2
echo "$HIVE1_NAME weight: $HIVE1_WEIGHT"
#
# Read scale 2
#
#HIVE2_WEIGHT=$(/home/hivetool/cpwplus200.sh -d $HIVE2_SCALE_DEVICE)
#set -- junk $HIVE2_WEIGHT
#shift
#HIVE2_WEIGHT=$2
echo "$HIVE2_NAME weight: $HIVE2_WEIGHT"
#
# Read hive 1 inside temp and humidity
#
if [ -n "$HIVE1_TEMP_DEVICE" ]
then
  TEMPerHUM=$(/home/hivetool/temperhum.sh -d $HIVE1_TEMP_DEVICE)
  set -- junk $TEMPerHUM
  shift
  HIVE1_TEMP=$1
  HIVE1_HUMIDITY=$2
  if [ -z "$HIVE1_TEMP" ]
  then
    HIVE1_TEMP="NULL"
    HIVE1_HUMIDITY="NULL"
  fi
else
  HIVE1_TEMP="NULL"
  HIVE1_HUMIDITY="NULL"
fi
echo "$HIVE1_NAME temperature: $HIVE1_TEMP humidity: $HIVE1_HUMIDITY"
#
# Read hive 2 inside temp and humidity
#
if [ -n "$HIVE2_TEMP_DEVICE" ]
then
 TEMPerHUM=$(/home/hivetool/temperhum.sh -d $HIVE2_TEMP_DEVICE)
 set -- junk $TEMPerHUM
 shift
 HIVE2_TEMP=$1
 HIVE2_HUMIDITY=$2
  if [ -z "$HIVE2_TEMP" ]
  then
    HIVE2_TEMP="NULL"
    HIVE2_HUMIDITY="NULL"
  fi
else
 HIVE2_TEMP="NULL"
 HIVE2_HUMIDITY="NULL"
fi
echo "$HIVE2_NAME temperature: $HIVE2_TEMP humidity: $HIVE2_HUMIDITY"
#
# Read outside temp and humidity
#
if [ -n "$HIVE1_AMBIENT_TEMP_DEVICE" ]
then
 TEMPerHUM=$(source /home/hivetool/temperhum.sh -d $HIVE1_AMBIENT_TEMP_DEVICE)
 set -- junk $TEMPerHUM
 shift
 HIVE1_AMBIENT_TEMP=$1
 HIVE1T_AMBIENT_HUMIDITY=$2
  if [ -z "$HIVE1_AMBIENT_TEMP" ]
  then
    HIVE1_AMBIENT_TEMP="NULL"
    HIVE1_AMBIENT_HUMIDITY="NULL"
  fi
else
 HIVE1_AMBIENT_TEMP="NULL"
 HIVE1_AMBIENT_HUMIDITY="NULL" 
fi
echo "Ambient temp: $HIVE1_AMBIENT_TEMP humidity: $HIVE1_AMBIENT_HUMIDITY"
#
# Get the weather from a local wx station via weatherunderground
#
curl --retry 5 http://api.wunderground.com/weatherstation/WXCurrentObXML.asp?ID=$WX_ID > /tmp/wx.xml
temp_f=`grep temp_f /tmp/wx.xml | grep  -o "[0-9]*\.[0-9]*"`
temp_c=`grep temp_c /tmp/wx.xml | grep  -o "[0-9]*\.[0-9]*"`
relative_humidity=`grep relative_humidity /tmp/wx.xml | grep  -o "[0-9]*"`
wind_dir=`grep wind_dir /tmp/wx.xml | grep -o "[A-Z]*"`
wind_mph=`grep wind_mph /tmp/wx.xml | grep  -o "[0-9]*\.[0-9]*"`
wind_gust_mph=`grep wind_gust_mph /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
pressure_mb=`grep pressure_mb /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
dewpoint_f=`grep dewpoint_f /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
#solar_radiation=`grep solar_radiation /tmp/wx.xml |  grep  -o "[0-9]*"`
precip_1hr_in=`grep precip_1hr_in /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
precip_today_in=`grep precip_today_in /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
#
# Write everything to hive 1 log file
#
echo -ne "\n"$DATE $HIVE1_WEIGHT $HIVE1_TEMP $HIVE1_AMBIENT_TEMP $temp_f $wind_dir $wind_mph $wind_gust_mph $dewpoint_f $relative_humidity $pressure_mb $solar_radiation $WX_EVAPOTRANSPIRATION $WX_VAPOR_PRESSURE $precip_today_in>> /home/hivetool/$HIVE1_NAME.log
#
# Write everything to hive 2 log file
#
#echo -ne "\n"$DATE $HIVE2_WEIGHT $HIVE2_TEMP $HIVE1_AMBIENT_TEMP $temp_f $wind_dir $wind_mph $wind_gust_mph $dewpoint_f $relative_humidity $pressure_mb $solar_radiation $WX_EVAPOTRANSPIRATION $WX_VAPOR_PRESSURE $precip_today_in>> /home/hivetool/$HIVE2_NAME.log
#
#
source /home/hivetool/sql.sh
#
#Run the graphing program to create index.html and hive_graph.gif
# this
#/var/www/htdocs/graph_hive.pl
#  will have to be changed to something like this:
#/var/www/htdocs/graph_hive.pl -l /home/hivetool/$HIVE1_NAME -o /var/www/htdocs/$HIVE1_NAME
#/var/www/htdocs/graph_hive.pl -l /home/hivetool/$HIVE2_NAME -o /var/www/htdocs/$HIVE2_NAME
#
#
# Create hive1 xml data file
#
# ### the variable names in xml.sh need to be changed so most of these assignments won't be necessary
#
HOST=$HIVE1_NAME
SCALE=$HIVE1_WEIGHT
TEMP=$HIVE1_TEMP
AMBIENT=$HIVE1_AMBIENT_HUMIDITY
HUMIDITY=$HIVE1_HUMIDITY
HUMIDITY_2=$HIVE1_AMBIENT_HUMIDITY
echo "<hive_data>" > /tmp/hive1.xml
source /home/hivetool/xml.sh >> /tmp/hive1.xml
cat /tmp/wx.xml|grep -v "xml" >> /tmp/hive1.xml
echo "</hive_data>" >> /tmp/hive1.xml
#
# Send hive1 data to hivetool
#
/usr/bin/curl --retry 5 -k -u user:passwd -X POST --data-binary @/tmp/hive1.xml https://hivetool.org/private/log_hive.pl  -H 'Accept: application/xml' -H 'Content-Type: application/xml' 1>/tmp/hive_command.xml
#
# Create hive2 xml data file
#
#HOST=$HIVE2_NAME
#SCALE=$HIVE2_WEIGHT
#TEMP=$HIVE2_TEMP
#AMBIENT=$HIVE1_AMBIENT_HUMIDITY
#HUMIDITY=$HIVE2_HUMIDITY
#HUMIDITY_2=$HIVE1_AMBIENT_HUMIDITY
#echo "<hive_data>" > /tmp/hive2.xml
#source /home/hivetool/xml.sh >> /tmp/hive2.xml
#source /home/hivetool/xml_wx.sh >> /tmp/hive2.xml
#echo "</hive_data>" >> /tmp/hive2.xml
#
# Send hive2 data to hivetool
#
#/usr/bin/curl --retry 5 -s -k -u user:passwd -X POST --data-binary @/tmp/hive2.xml https://hivetool.org/private/log_hive.pl  -H 'Accept: application/xml' -H 'Content-Type: application/xml' 1>/tmp/hive_command.xml


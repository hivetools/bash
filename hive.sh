#!/bin/bash
# ##############################################################################
#                         hive.sh ver 0.4
#
# Reads sensors, logs them and sends the data to hivetool.net
# 
# May  use:
# cpw200plus.sh         Reads weight from Adam Equipment CPW200plus scale
# temperhum.sh          Read temperature and humidity from TEMPerHUM model 2
# phidget.sh            Read weight from Phidgets Bridge board
# hx711.sh              Read weight from HX711 board
# xml.sh                Writes the data in XML format to upload to hivetool.org
# mysql.sh              Log data to local SQL database
# ##############################################################################
#
# Get the date and time
#
DATE=`date +"%Y/%m/%d %H:%M:%S"`
echo $DATE
#
# Read the configuration file and set the shell variables
#
IFS="="                               # set the Internal Field Separator to equal sign
while read name value; do             # split each line on the IFS (=) into 2 variables: name and value
  value=${value#\"}                   # remove leading "
  value=${value%\"}                   # remove trailing "
  export $name="$value"               # export the variables to make them available to child processes
done <"/home/hivetool/hive.conf"      # read each line from the config file
IFS=" "                               #set the IFS back to space or reading TEMPerHUM will fail
#
[ ! -z HIVE_NAME ] && HIVE1_NAME="HIVE1"

HIVE_ID=28                            # used by sql.sh to access local hivetool_raw tables
REDIRECT=0                             # set to zero turn off redirecting stdout and stderr to hivetool.log
VERBOSE=1
#
#
HIVE1_WEIGHT=0
HIVE1_TEMP=0
HIVE1_HUMIDITY=0
#
# Redirect stdout and stderr to logfile.  Useful to check for errors when run with no console (cron).
#
if [ "$REDIRECT" -gt "0" ]
then
   rm /home/hivetool/hivetool.log             # delete the last log

   exec >>/home/hivetool/hivetool.log 2>&1    # redirect stdout and stderr to logfile
fi
#
# Read scale
#
case "$HIVE_WEIGHT_SENSOR" in
        cpw200plus)
            HIVE_WEIGHT=$(/home/hivetool/cpw200plus.sh -d $HIVE_WEIGHT_DEVICE)
            set -- junk $HIVE_WEIGHT
            shift
            HIVE_WEIGHT=$2
            ;;
        HX711)
            HIVE_WEIGHT=$(/home/hivetool/hx711.sh)
            ;;
        Phidget)
            HIVE_WEIGHT=$(/home/hivetool/phidget.sh)
            ;;
        none)
            HIVE_WEIGHT="NULL"               # Set hive weight to NULL if scale type is set to "none"
            ;;
        *)
            HIVE_WEIGHT="NULL"               # Set hive weight to NULL if scale type is not set or set wrong
            echo "No scale selected or unknown HIVE1_SCALE_TYPE: $HIVE1_SCALE_TYPE"    # and display warning
esac
#
echo "$HIVE_NAME weight: $HIVE_WEIGHT"                 # print the weight to the console or to hivetool.log
#
# Read temp and humidity inside hive
#
case "$HIVE_TEMP_SENSOR" in
         TEMPerHUM)
              TEMPerHUM=$(/home/hivetool/temperhum.sh -d $HIVE_TEMP_DEV)
              set -- junk $TEMPerHUM
              shift
              HIVE_TEMP=$1
              HIVE_HUMIDITY=$2
              if [ -z "$HIVE_TEMP" ]
              then
                 HIVE_TEMP="NULL"
                 HIVE_HUMIDITY="NULL"
              fi
              ;;
           *)
              HIVE_TEMP="NULL"
              HIVE_HUMIDITY="NULL"
esac

HIVE_TEMP=`echo "scale=2; (($HIVE_TEMP*$HIVE_TEMP_SLOPE)+$HIVE_TEMP_INTERCEPT)" | bc`

echo "$HIVE_NAME temperature: $HIVE_TEMP humidity: $HIVE_HUMIDITY"  # print hive temp, humidity 
#
# Read outside temp and humidity
#
case "$AMBIENT_TEMP_SENSOR" in
         TEMPerHUM)
              TEMPerHUM=$(/home/hivetool/temperhum.sh -d $AMBIENT_TEMP_DEV)
              set -- junk $TEMPerHUM
              shift
              AMBIENT_TEMP=$1
              AMBIENT_HUMIDITY=$2
              if [ -z "$AMBIENT_TEMP" ]
              then
                 AMBIENT_TEMP="NULL"
                 AMBIENT_HUMIDITY="NULL"
              fi
              ;;
           *)
              AMBIENT_TEMP="NULL"
              AMBIENT_HUMIDITY="NULL"
esac

AMBIENT_TEMP=`echo "scale=2; (($AMBIENT_TEMP*$AMBIENT_TEMP_SLOPE)+$AMBIENT_TEMP_INTERCEPT)" | bc`
echo "Ambient temp: $AMBIENT_TEMP humidity: $AMBIENT_HUMIDITY"   # print ambient temp, humidity
#
# Get the weather from a local wx station via weatherunderground
#
curl --retry 5 http://api.wunderground.com/weatherstation/WXCurrentObXML.asp?ID=$WX_STATION_ID > /tmp/wx.xml
WX_TEMP_F=`grep temp_f /tmp/wx.xml | grep  -o "[0-9]*\.[0-9]*"`
WX_TEMP_C=`grep temp_c /tmp/wx.xml | grep  -o "[0-9]*\.[0-9]*"`
WX_RELATIVE_HUMIDITY=`grep relative_humidity /tmp/wx.xml | grep  -o "[0-9]*"`
WX_WIND_DIR=`grep wind_dir /tmp/wx.xml | grep -o "[A-Z]*"`
WX_WIND_MPH=`grep wind_mph /tmp/wx.xml | grep  -o "[0-9]*\.[0-9]*"`
WX_WIND_GUST_MPH=`grep wind_gust_mph /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
WX_PRESSURE_MB=`grep pressure_mb /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
WX_DEWPOINT_F=`grep dewpoint_f /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
WX_PRECIP_1HR_IN=`grep precip_1hr_in /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`
WX_PRECIP_TODAY_IN=`grep precip_today_in /tmp/wx.xml |  grep  -o "[0-9]*\.[0-9]*"`

if [ "$VERBOSE" -gt "0" ]
then
# This is what gets reported to the log.
#   if data is missing - graphing routine will fail.
 echo "Date-time         " $DATE
 echo "Hive Weight       " $HIVE_WEIGHT
 echo "Hive Temp         " $HIVE_TEMP
 echo "Hive Humidity     " $HIVE_HUMIDITY
 echo "Ambient Temp      " $AMBIENT_TEMP
 echo "Ambient Humidity  " $AMBIENT_TEMP
 echo "PWS Temperature   " $WX_TEMP_F
 echo "PWS Wind Degrees  " $WX_WIND_DEGREES
 echo "PWS Wind Speed    " $WX_WIND_MPH
 echo "PWS Wind Gust     " $WX_WIND_GUST_MHP
 echo "PWS Dewpoint      " $WX_DEWPOINT_F
 echo "PWS Humidity      " $WX_RELATIVE_HUMIDITY
 echo "PWS Pressure      " $WX_PRESSURE_MB
 echo "PWS Precip Today  " $WX_PRECIP_TODAY_IN
fi



#
# Append everything to a local flat text log file
#
echo -ne "\n"$DATE,$HIVE_WEIGHT,$HIVE_TEMP,$HIVE_HUMIDITY,$AMBIENT_TEMP,$AMBIENT_HUMIDITY,$WX_TEMP_F,$WX_WIND_DIR,$WX_WIND_MPH,$WX_WIND_GUST_MPH,$WX_DEWPOINT_F,$WX_RELATIVE_HUMIDITY,$WX_PRESSURE_MB,$WX_PRECIP_TODAY_IN>> /home/hivetool/$HIVE_NAME.log
#
# Insert it into a local SQL database
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
echo "<hive_data>" > /tmp/hive.xml
source /home/hivetool/xml.sh >> /tmp/hive.xml
cat /tmp/wx.xml|grep -v "xml" >> /tmp/hive.xml
echo "</hive_data>" >> /tmp/hive.xml
#
# Send hive1 data to hivetool
#
/usr/bin/curl --retry 5 -k -u user:password -X POST --data-binary @/tmp/hive.xml https://hivetool.org/private/log_hive2.pl  -H 'Accept: application/xml' -H 'Content-Type: application/xml' 1>/tmp/hive_command.xml
#
# run a remote command
#
/home/hivetool/hive_command.pl
# 
# End of hive.sh

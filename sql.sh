#!/bin/bash
echo $HIVE1_ID, $DATE, $HIVE1_WEIGHT, $HIVE1_TEMP, $HIVE1_HUMIDITY, $HIVE1_AMBIENT_TEMP, $HIVE1_AMBIENT_HUMIDITY
/usr/bin/mysql -u root -praspberry -e "USE hivetool_raw; INSERT INTO HIVE_DATA (hive_id, hive_observation_time_local, hive_weight_lbs, hive_temp_c, hive_humidity, ambient_temp_c, ambient_humidity, wx_temp_f,wx_temp_c, wx_relative_humidity, wx_wind_dir, wx_wind_mph) values ($HIVE1_ID, '$DATE', $HIVE1_WEIGHT, $HIVE1_TEMP, $HIVE1_HUMIDITY, $HIVE1_AMBIENT_TEMP, $HIVE1_AMBIENT_HUMIDITY, $temp_f, $temp_c, $relative_humidity, '$wind_dir', $wind_mph);"

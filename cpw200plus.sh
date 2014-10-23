#!/bin/bash
#
# Reads the weight from an Adam Euipment CPW200plus scale
#
#
# get the device ( -d option )
#
while getopts d: option
do
        case "${option}"

        in
                d) DEVICE=${OPTARG};;
        esac
done

# read the scale                                                                                                                                                                    
#                                                                                                                                                                                   
COUNTER=1                                                                                                                                                                           
while [[ ! $SCALE && COUNTER -lt 11 ]]                                                                                                                                              
do                                                                                                                                                                                  
    echo -e -n "N\r\n" > $DEVICE                                                                                                                                               
    read -t 3 SCALE < $DEVICE                                                                                                                                                  
    SCALE=`echo $SCALE | gawk --posix '/^\+ [0-9]{1,3}\.[0-9] lb$/'`                                                                                                                
    let "COUNTER += 1"                                                                                                                                                              
    sleep 1                                                                                                                                                                         
done                                                                                                                                                                                
                                                                                                                                                                                    
if [[ $COUNTER -gt 10 ]]
then                                                                                                                                                                                
  echo "$DATE ERROR reading Scale $DEVICE" >> /home/hivetool/error.log                                                                                                         
  SCALE=-555                                                                                                                                                                        
fi                                                                                                                                                                                  
if test $COUNTER -gt 2                                                                                                                                                              
then                                                                                                                                                                                
  echo "$DATE WARNING reading Scale /dev/ttyS0: retried $COUNTER" >> /home/hivetool/error.log                                                                                     
fi                                                                                                                                                                                  
                                                                                                                                                                                    
echo "$SCALE"                                                                                                                                          

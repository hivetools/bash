DIGITEMP=`/usr/local/bin/digitemp_DS9097U -a`
AMBIENT=`echo $DIGITEMP | awk -F " "  {'print $2'}|tr -d C`
echo $AMBIENT

#!/usr/local/bin/bash
/sbin/camcontrol devlist | grep ada | awk -F\( '{print $2'} | awk -F\, '{print $1}' |while read LINE
do
CM=$(/sbin/camcontrol cmd $LINE -a "E5 00 00 00 00 00 00 00 00 00 00 00" -r - | awk '{print $10}')
if [ "$CM" = "FF" ] ; then
echo "$LINE: SPINNING"
elif [ "$CM" = "00" ] ; then
echo "$LINE: IDLE"
else 
echo "$LINE: UNKNOWN"
fi
done

#!/bin/sh

#
# This script tests for network connectivity and restarts ppp if it is found
# to be down.
#

# --- User-modifiable variables ---

# Use this IP address if the primary address cannot be determined
secondaryaddr="195.74.0.47"

# Number of failed pings required to signify link failure
failedtrigger=5

# File to keep track of total number of failed pings
failedcountfile="/var/run/pingmonitor.missedping.count"

# Email address to send reports to
emailaccount="root"

# Set to the appropriate label in /etc/ppp/ppp.conf
isp="saunalahti"

# These options will be given to /usr/sbin/ppp
ppp_opts="-ddial"

# --- End of user-modifiable variables ---

# Load in system configuration.
if [ -f /etc/defaults/rc.conf ]; then
        . /etc/defaults/rc.conf
        source_rc_confs
elif [ -f /etc/rc.conf ]; then
        . /etc/rc.conf
fi

# only continue if the ppp link should be up
#if [ ! $ppp_enable ]; then
#        # PPP is not configured in the rc files.
#        exit 0
#elif [ "$ppp_enable" = "NO" ] || [ "$ppp_enable" = "no" ]; then
#        # PPP is not wanted
#        exit 0
#fi

# Set umask
umask 137

# Determine the default gateway for the ADSL link
primaryaddr=`ifconfig tun0 | grep 'inet ' | grep -v 255.255.255.255 | tail -1 | cut -f 2 -d '>' | cut -f 2 -d ' '`

if [ "$primaryaddr" = "" ]; then
        primaryaddr="0.0.0.0"
        secondaryaddr="0.0.0.0"
fi


# Check if we've had any previous failures
if [ -f $failedcountfile ]; then
        pingfailed=`head -n 1 $failedcountfile`
else
        pingfailed=0
fi


# Run the ping for the primary address - our default gateway.
/sbin/ping -c 5 -t 5 -q -m 2 $primaryaddr > /dev/null 2> /dev/null


# If the ping failed. Check to see if the gateway is filtered.
if [ $? -ne 0 ]; then
        # Try to pull a TTL EXCEEDED message from the gateway.
        if [ `/sbin/ping -c 1 -m 0 -n -t 1 $primaryaddr 2> /dev/null | grep -i "time to live exceeded" | grep $primaryaddr | wc -l` -eq 1 ]; then
                ping_error=0
        else
                ping_error=1
        fi
else
        # No filtering. The default gateway responded to the initial ping.
        ping_error=0
fi


#
# Ping returns a non-zero error condition if ALL the ECHO_REQUEST packets did
# not return a ECHO_REPLY. If we received just one answer then ping returns
# a zero error condition which is perfect for our tests.
#


# Check the ping status and try pinging the secondary address if it failed
if [ $ping_error -ne 0 ]; then
        /sbin/ping -c 5 -t 5 -q -m 7 $secondaryaddr > /dev/null 2> /dev/null

        if [ $? -eq 0 ]; then
                ping_error=0
        else
                ping_error=1
        fi
fi


# Test the error condition
if [ $ping_error -ne 0 ]; then
        # Update and record the failure count
        pingfailed=$(($pingfailed + 1))
        echo $pingfailed > $failedcountfile

        # Test if we've hit our failure trigger
        if [ $pingfailed -ge $failedtrigger ]; then
                # time to restart ppp so kill it first
                /usr/bin/killall ppp > /dev/null 2> /dev/null

                # wait for it to die
                sleep 5

                # really ensure ppp is dead - we can't risk two running
                /usr/bin/killall -9 ppp > /dev/null 2> /dev/null

                # wait again
                sleep 5

                # start up ppp again
                /usr/sbin/ppp $ppp_opts $isp > /dev/null 2> /dev/null

                # our work here is done
        fi
else
        # the ping worked so check if we've just recovered from a failure
        if [ $pingfailed -ge $failedtrigger ]; then

                # we have just recovered so let the admin know
                echo "PING test failed $pingfailed times" | /usr/bin/mail -s "PPP restart on `/bin/hostname -s` at `date '+%H:%M %d/%m/%y'`" $emailaccount > /dev/null 2> /dev/null
        fi


        # all's well now so remove the failure count
        rm -f $failedcountfile > /dev/null 2> /dev/null
fi


# that's it

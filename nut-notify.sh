#!/bin/sh
echo "$@" | mail -s "UPS Event on `hostname`" petteri.valkonen@iki.fi

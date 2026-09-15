#!/bin/bash

if [[ "$1" == "drastic-kk" ]]; then
    /usr/local/bin/drastic_kk.sh "$2"
elif [[ "$1" == "dsperate" ]]; then
    /opt/DSperate/dsperate.sh "$2" > /roms/1.txt 2> /roms/1.err
else
    /usr/local/bin/drastic.sh "$2"
fi
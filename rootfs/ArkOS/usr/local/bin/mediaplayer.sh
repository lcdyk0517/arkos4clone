#!/bin/bash

#sudo /usr/local/bin/oga_controls &
#ffplay -loglevel +quiet -seek_interval 1 -loop 0 -x 640 -y 480 "$1"
#sudo kill $(pidof oga_controls)
#printf "\033c" >> /dev/tty1

#. /etc/profile
#set_kill set "mpv"
sudo systemctl start mpv

output=$(/usr/local/bin/console_detect -r)
xres=$(echo "$output" | cut -d'x' -f1)
yres=$(echo "$output" | cut -d'x' -f2)

sudo /usr/bin/mpv --fullscreen --geometry=${xres}x${yres} --hwdec=auto --vo=drm --input-ipc-server=/tmp/mpvsocket --config-dir=~/.config/mpv "${1}"

sudo systemctl stop mpv
exit 0

#!/bin/bash

output=$(/usr/local/bin/console_detect -r)
xres=$(echo "$output" | cut -d'x' -f1)
yres=$(echo "$output" | cut -d'x' -f2)

res="${yres}x${xres}x1"
directory="$(dirname "$1" | cut -d "/" -f2)"
gamecontrols=$(echo "$(ls "$1" | cut -d "/" -f4 | cut -d "." -f1)")
gamecontrols_nocase=$(find "/opt/mvem/controls" -maxdepth 1 -iname "${gamecontrols}".gptk)
custom_gamecontrols_nocase=$(find "/$directory/mv/controls" -maxdepth 1 -iname "${gamecontrols}".gptk)

cd /opt/mvem

sudo chmod 666 /dev/uinput

export SDL_GAMECONTROLLERCONFIG_FILE="controls/gamecontrollerdb.txt"

if [[ -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
  if [ -f "$custom_gamecontrols_nocase" ]; then
    echo "Loading custom user controls from $custom_gamecontrols_nocase"
    LD_PRELOAD="/usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0.18.2" ./gptokeyb -1 "mvem" -c "$custom_gamecontrols_nocase" &
  elif [ -f "$gamecontrols_nocase" ]; then
    echo "Loading provided controls from $gamecontrols_nocase"
    LD_PRELOAD="/usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0.18.2" ./gptokeyb -1 "mvem" -c "$gamecontrols_nocase" &
  else
    echo "Loading default controls /opt/mvem/controls/mvem.gptk"
    LD_PRELOAD="/usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0.18.2" ./gptokeyb -1 "mvem" -c "/opt/mvem/controls/mvem.gptk" &
  fi
else
  if [ -f "$custom_gamecontrols_nocase" ]; then
    echo "Loading custom user controls from $custom_gamecontrols_nocase"
    ./gptokeyb -1 "mvem" -c "$custom_gamecontrols_nocase" &
  elif [ -f "$gamecontrols_nocase" ]; then
    echo "Loading provided controls from $gamecontrols_nocase"
    ./gptokeyb -1 "mvem" -c "$gamecontrols_nocase" &
  else
    echo "Loading default controls /opt/mvem/controls/mvem.gptk"
    ./gptokeyb -1 "mvem" -c "/opt/mvem/controls/mvem.gptk" &
  fi
fi

./mvem "$1" "$res"

unset SDL_GAMECONTROLLERCONFIG_FILE
if [[ ! -z $(pidof gptokeyb) ]]; then
  sudo kill -9 $(pidof gptokeyb)
fi
sudo systemctl restart oga_events &
printf "\033c" >> /dev/tty1
exit 0

#!/bin/bash

if [ -f "/opt/system/Advanced/Switch to main SD for Roms.sh" ]; then
  directory="roms2"
else
  directory="roms"
fi

if [[ ${1,,} == *"scan_for_new_games.easyrpg"* ]]; then
  printf "\033c" >> /dev/tty1
  for f in /$directory/easyrpg/*/; do
    if [ -d "$f" ]; then
      basefilename=$(basename "$f")

      if [[ "${basefilename,,}" != *".easyrpg"* ]] && [[ ! "$basefilename" = "images" ]]; then
        mv -f "$f" "/$directory/easyrpg/${basefilename}.easyrpg"
        printf "\nFound $basefilename and created ES menu shortcut for it" >> /dev/tty1
      fi
    fi
  done
  printf "\n\nFinished scanning the easyrpg folder for games." >> /dev/tty1
  printf "\nPlease restart emulationstaton to find the new shortcuts" >> /dev/tty1
  printf "\ncreated if any.\n" >> /dev/tty1
  sleep 5
  printf "\033c" >> /dev/tty1
else
  export LD_LIBRARY_PATH=/home/ark/.quirks/libs/easyrpg_libs:$LD_LIBRARY_PATH
  /usr/local/bin/retroarch -L /home/ark/.config/retroarch/cores/easyrpg_libretro.so "$1"
fi

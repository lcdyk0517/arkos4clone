#!/bin/bash

if [[ "$1" == *"Scan_for_new_games.pymo"* ]]; then
  sudo chmod 777 "$1"
  "$1"
else
  export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
  /usr/local/bin/cpymo "$1"
fi

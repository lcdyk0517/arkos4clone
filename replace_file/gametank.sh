#!/bin/bash

if [[ $1 == "standalone" ]]; then
  sudo /usr/local/bin/gametankkeydemon.py &
  sudo /opt/gametank/gametank_hotkeys -c /opt/gametank/gametank.gptk  &
  /opt/gametank/GameTankEmulator "$2"
  GPTOKEYB_PID="$(pidof gametank_hotkeys 2>/dev/null || true)"
  if [[ -n "$GPTOKEYB_PID" ]]; then
    sudo kill -9 $GPTOKEYB_PID
  fi
else
  /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
fi
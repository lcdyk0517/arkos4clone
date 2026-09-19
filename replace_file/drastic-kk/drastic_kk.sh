#!/bin/bash

directory="$(dirname "$1" | cut -d "/" -f2)"

if  [[ ! -d "/${directory}/nds/backup" ]]; then
  mkdir /${directory}/nds/backup
fi
if  [[ ! -d "/${directory}/nds/cheats" ]]; then
  mkdir /${directory}/nds/cheats
fi
if  [[ ! -d "/${directory}/nds/savestates" ]]; then
  mkdir /${directory}/nds/savestates
fi
if  [[ ! -d "/${directory}/nds/slot2" ]]; then
  mkdir /${directory}/nds/slot2
fi

sudo /usr/local/bin/drastickeydemon.py &

cd /opt/drastic-kk

if grep -q '<string name="Language" value="zh-CN" />' /home/ark/.emulationstation/es_settings.cfg; then
    export LANG=zh_CN.UTF-8
    target="/opt/drastic-kk/resources/cheats/zh_CN/usrcheat.dat"
else
    target="/opt/drastic-kk/resources/cheats/es_EN/usrcheat.dat"
fi

if [ -L /opt/drastic-kk/usrcheat.dat ]; then
    if [ "$(readlink /opt/drastic-kk/usrcheat.dat)" != "$target" ]; then
        sudo rm -f /opt/drastic-kk/usrcheat.dat
        sudo ln -sf "$target" /opt/drastic-kk/usrcheat.dat
    fi
else
    sudo ln -sf "$target" /opt/drastic-kk/usrcheat.dat
fi

sudo ./drastic_hotkeys -c /opt/drastic-kk/drastic.gptk  &

if [[ -f /boot/.console ]]; then
  CUR_VAL="$(tr -d '\r\n' < "/boot/.console" || true)"
  case "$CUR_VAL" in
    u8|dr28s|r50s)
      LD_PRELOAD=./libs/libSDL2-2.0.so.0.3200.10.rotate270
    ;;
    a10miniv2)
      LD_PRELOAD=./libs/libSDL2-2.0.so.0.3200.10.rotate180
    ;;
    xf28)
      LD_PRELOAD=./libs/libSDL2-2.0.so.0.3200.10.rotate90
    ;;
    *)
      LD_PRELOAD=./libs/libSDL2-2.0.so.0.3200.10
    ;;
  esac
  LD_PRELOAD="$LD_PRELOAD" ./drastic "$1"
fi

GPTOKEYB_PID="$(pidof drastic_hotkeys 2>/dev/null || true)"
if [[ -n "$GPTOKEYB_PID" ]]; then
  sudo kill -9 $GPTOKEYB_PID
fi

sudo killall python3

sudo systemctl restart oga_events &

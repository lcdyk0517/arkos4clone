#!/bin/bash

directory="$(dirname "$1" | cut -d "/" -f2)"

for d in backup cheats savestates slot2; do
  if [[ ! -d "/${directory}/nds/$d" ]]; then
    mkdir /${directory}/nds/${d}
  fi
  if [[ -d "/opt/drastic/$d" && ! -L "/opt/drastic/$d" ]]; then
    cp -n /opt/drastic/${d}/* /${directory}/nds/${d}/
    rm -rf /opt/drastic/${d}/
  fi
  ln -sf /${directory}/nds/${d} /opt/drastic/
done

echo "VAR=drastic" > /home/ark/.config/KILLIT
sudo systemctl restart killer_daemon.service

cd /opt/drastic
sudo ./drastic_hotkeys &
./drastic "$1"

GPTOKEYB_PID="$(pidof drastic_hotkeys 2>/dev/null || true)"
if [[ -n "$GPTOKEYB_PID" ]]; then
  sudo kill -9 $GPTOKEYB_PID
fi

sudo systemctl restart ogage &

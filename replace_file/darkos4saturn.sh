#!/bin/bash

if [[ $1 == *"standalone"* ]]; then
  directory=$(dirname "$2" | cut -d "/" -f2)
  cd /opt/yabasanshiro
  if [[ ! -f "input.cfg" ]]; then
    if [[ -f "keymapv2.json" ]]; then
      rm -f keymapv2.json
    fi
    cp -f /etc/emulationstation/es_input.cfg input.cfg
  fi
  echo "VAR=yaba" > /home/ark/.config/KILLIT
  sudo systemctl restart killer_daemon.service
  if grep -q '<string name="Language" value="zh-CN" />' /home/ark/.emulationstation/es_settings.cfg; then
    export LANG=zh_CN.UTF-8 
    export LC_ALL=zh_CN.UTF-8
  fi
  if [[ $1 == *"pi4"* ]]; then
    YABA_BIN="./yabasanshiro-pi4"
    if [[ ! -d "/$directory/saturn/yabasanshiro-pi4" ]]; then
      mkdir /$directory/saturn/yabasanshiro-pi4
    fi
  elif [[ $1 == *"2412"* ]]; then
    YABA_BIN="./yabasanshiro-2412"
    if [[ ! -d "/$directory/saturn/yabasanshiro-2412" ]]; then
      mkdir /$directory/saturn/yabasanshiro-2412
    fi
  else
    YABA_BIN="./yabasanshiro"
    if [[ ! -d "/$directory/saturn/yabasanshiro" ]]; then
      mkdir /$directory/saturn/yabasanshiro
    fi
  fi
  if [[ $1 == *"-bios"* ]]; then
    if [[ ! -f "/$directory/bios/saturn_bios.bin" ]]; then
      printf "\033c" >> /dev/tty1
      printf "\033[1;33m" >> /dev/tty1
      printf "\n I don't detect a saturn_bios.bin bios file in the" >> /dev/tty1
      printf "\n /$directory/bios folder.  Either place one in that" >> /dev/tty1
      printf "\n location or switch to the standalone-nobios emulator." >> /dev/tty1
      sleep 10
      printf "\033[0m" >> /dev/tty1
    else
      LD_LIBRARY_PATH=/home/ark/.quirks/libs/yabasanshiro_libs/ $YABA_BIN -r 3 -i "$2" -b /$directory/bios/saturn_bios.bin
    fi
  else
    LD_LIBRARY_PATH=/home/ark/.quirks/libs/yabasanshiro_libs/ $YABA_BIN -r 3 -i "$2"
  fi
  sudo systemctl stop killer_daemon.service
  sudo systemctl restart ogage &
  cd ~
elif  [[ $1 == "retroarch" ]]; then
  /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
elif [[ $1 == "retroarch32" ]]; then
  /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
elif [[ $1 == "retrorun" ]]; then
  directory=$(dirname "$3" | cut -d "/" -f2)
  if [[ ! -f "/$directory/bios/saturn_bios.bin" ]]; then
    printf "\033c" >> /dev/tty1
    printf "\033[1;33m" >> /dev/tty1
    printf "\n I don't detect a saturn_bios.bin bios file in the" >> /dev/tty1
    printf "\n /$directory/bios folder.  Either place one in that" >> /dev/tty1
    printf "\n location or switch to the standalone-nobios emulator." >> /dev/tty1
    sleep 10
    printf "\033[0m" >> /dev/tty1
  fi
  if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
    sudo rg351p-js2xbox --silent -t oga_joypad &
    sleep 1
    sudo ln -s /dev/input/event4 /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
    sudo chmod 777 /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
    /usr/local/bin/retrorun -n -s /$directory/saturn -d /$directory/bios /home/ark/.config/retroarch/cores/"$2"_libretro.so "$3"
    sudo kill $(pidof rg351p-js2xbox)
    sudo rm /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
  else
    /usr/local/bin/retrorun -n -s /$directory/saturn -d /$directory/bios /home/ark/.config/retroarch/cores/"$2"_libretro.so "$3"
  fi
else
  directory=$(dirname "$3" | cut -d "/" -f2)
  if [[ ! -f "/$directory/bios/saturn_bios.bin" ]]; then
    printf "\033c" >> /dev/tty1
    printf "\033[1;33m" >> /dev/tty1
    printf "\n I don't detect a saturn_bios.bin bios file in the" >> /dev/tty1
    printf "\n /$directory/bios folder.  Either place one in that" >> /dev/tty1
    printf "\n location or switch to the standalone-nobios emulator." >> /dev/tty1
    sleep 10
    printf "\033[0m" >> /dev/tty1
  fi
  if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
    sudo rg351p-js2xbox --silent -t oga_joypad &
    sleep 1
    sudo ln -s /dev/input/event4 /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
    sudo chmod 777 /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
    /usr/local/bin/retrorun32 -n -s /$directory/saturn -d /$directory/bios /home/ark/.config/retroarch32/cores/"$2"_libretro.so "$3"
    sudo kill $(pidof rg351p-js2xbox)
    sudo rm /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
  else
    /usr/local/bin/retrorun32 -n -s /$directory/saturn -d /$directory/bios /home/ark/.config/retroarch32/cores/"$2"_libretro.so "$3"
  fi
fi

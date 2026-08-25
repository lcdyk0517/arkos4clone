#!/bin/bash

ESUDO=""

if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
  param_device="anbernic"
elif [[ -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
  if [[ ! -z $(cat /etc/emulationstation/es_input.cfg | grep "190000004b4800000010000001010000") ]]; then
    param_device="oga"
  else
    param_device="rk2020"
  fi
elif [[ -e "/dev/input/by-path/platform-odroidgo3-joypad-event-joystick" ]]; then
  param_device="ogs"
elif [[ -e "/dev/input/by-path/platform-singleadc-joypad-event-joystick" ]]; then
  param_device="rg503"
else
  param_device="chi"
fi

if grep -q '<string name="Language" value="zh-CN" />' /home/ark/.emulationstation/es_settings.cfg; then
  export LANG=zh_CN.UTF-8 
  export LC_ALL=zh_CN.UTF-8
fi

if [[ $1 == *"standalone"* ]]; then
  directory=$(dirname "$2" | cut -d "/" -f2)
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
  cd /opt/yabasanshiro
  if [[ ! -f "input.cfg" ]]; then
    if [[ -f "keymapv2.json" ]]; then
      rm -f keymapv2.json
    fi
    cp -f /etc/emulationstation/es_input.cfg input.cfg
  fi
  sudo /opt/quitter/oga_controls yaba $param_device &
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
      $YABA_BIN  -r 3 -i "$2" -b /$directory/bios/saturn_bios.bin
    fi
  else
    $YABA_BIN  -r 3 -i "$2"
  fi
  if [[ ! -z $(pidof oga_controls) ]]; then
    sudo kill -9 $(pidof oga_controls)
  fi
  sudo systemctl restart oga_events &
  cd ~
elif  [[ $1 == "retroarch" ]]; then
  /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
elif [[ $1 == "retroarch32" ]]; then
  /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
elif [[ $1 == "retrorun"* ]]; then
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
  directory=$(dirname "$3" | cut -d "/" -f2)
  CURDIRECTORYSET="$(grep "retrorun_screenshot_folder = " /home/ark/.config/retrorun.cfg | cut -d "/" -f2-3)"
  if [[ "${CURDIRECTORYSET}" != "${directory}/saturn" ]]; then
    sed -i "/retrorun_screenshot_folder \=/c\retrorun_screenshot_folder \= \/$directory\/saturn" /home/ark/.config/retrorun.cfg
  fi
  if [[ $1 == "retrorun" ]]; then
    RETRORUN_BIN="/usr/local/bin/retrorun"
  elif [[ $1 == "retrorun32" ]]; then
    RETRORUN_BIN="/usr/local/bin/retrorun32"
  elif [[ $1 == "retrorunsdl" ]]; then
    RETRORUN_BIN="/usr/local/bin/retrorunsdl"
  else
    RETRORUN_BIN="/usr/local/bin/retrorunsdl32"
  fi
  $ESUDO $RETRORUN_BIN -c /home/ark/.config/retrorun.cfg --triggers -s /$directory/saturn -d /$directory/bios /home/ark/.config/retroarch/cores/"$2"_libretro.so "$3"
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
  directory=$(dirname "$3" | cut -d "/" -f2)
  CURDIRECTORYSET="$(grep "retrorun_screenshot_folder = " /home/ark/.config/retrorun.cfg | cut -d "/" -f2-3)"
  if [[ "${CURDIRECTORYSET}" != "${directory}/saturn" ]]; then
    sed -i "/retrorun_screenshot_folder \=/c\retrorun_screenshot_folder \= \/$directory\/saturn" /home/ark/.config/retrorun.cfg
  fi
  $ESUDO /usr/local/bin/retrorun32 -c /home/ark/.config/retrorun.cfg --triggers -s /$directory/saturn -d /$directory/bios /home/ark/.config/retroarch32/cores/"$2"_libretro.so "$3"
fi

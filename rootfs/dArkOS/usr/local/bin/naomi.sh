#!/bin/bash

ESUDO=""

if  [[ $1 == "retroarch" ]]; then
  /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
elif [[ $1 == "retroarch32" ]]; then
  /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
elif [[ $1 == *"standalone"* ]]; then
  echo "VAR=flycast" > /home/ark/.config/KILLIT
  sudo systemctl restart killer_daemon.service
  rm -rf "/home/ark/.local/share/flycast"
  directory=$(dirname "$2" | cut -d "/" -f2)
  [ -d "/$directory/bios/dc" ] || mkdir -p "/$directory/bios/dc"
  ln -sf "/$directory/bios/dc" "/home/ark/.local/share/flycast"
  sdl_controllerconfig="190000004b4800000011000000010000,GO-Super Gamepad,x:b3,a:b0,b:b1,y:b2,back:b12,start:b13,dpleft:b10,dpdown:b9,dpright:b11,dpup:b8,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftstick:b14,rightstick:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux,"
  if [[ $1 == *"-2022"* ]]; then
      FLYCAST_BIN="/opt/flycastsa/flycast-2022"
  elif [[ $1 == *"-r7"* ]]; then
      FLYCAST_BIN="/opt/flycastsa/flycast-r7"
  else
      FLYCAST_BIN="/opt/flycastsa/flycast"
  fi
  if grep -q '<string name="Language" value="zh-CN" />' /home/ark/.emulationstation/es_settings.cfg; then
      SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 $FLYCAST_BIN "$2"
  else
      SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" $FLYCAST_BIN "$2"
  fi
  sudo systemctl stop killer_daemon.service
  sudo systemctl restart ogage &
elif [[ $1 == "retrorun"* ]]; then
  directory=$(dirname "$3" | cut -d "/" -f2)
  CURDIRECTORYSET="$(grep "retrorun_screenshot_folder = " /home/ark/.config/retrorun.cfg | cut -d "/" -f2-3)"
  if [[ "${CURDIRECTORYSET}" != "${directory}/naomi" ]]; then
    sed -i "/retrorun_screenshot_folder \=/c\retrorun_screenshot_folder \= \/$directory\/naomi" /home/ark/.config/retrorun.cfg
  fi
  if [[ $1 == "retrorun" ]]; then
    RETRORUN_BIN="/opt/retrorun/retrorun"
    CORE=""
    LD_LIBRARY_PATH=/home/ark/.quirks/libs/retrorun_libs/64/:$LD_LIBRARY_PATH
  elif [[ $1 == "retrorun32" ]]; then
    RETRORUN_BIN="/opt/retrorun/retrorun32"
    CORE="32"
    export LD_LIBRARY_PATH=/home/ark/.quirks/libs/retrorun_libs/32/:$LD_LIBRARY_PATH
  elif [[ $1 == "retrorunsdl" ]]; then
    RETRORUN_BIN="/opt/retrorun/retrorunsdl"
    CORE=""
    export LD_LIBRARY_PATH=/home/ark/.quirks/libs/retrorun_libs/64/:$LD_LIBRARY_PATH
  else
    RETRORUN_BIN="/opt/retrorun/retrorunsdl32"
    CORE="32"
    export LD_LIBRARY_PATH=/home/ark/.quirks/libs/retrorun_libs/32/:$LD_LIBRARY_PATH
  fi
  $ESUDO $RETRORUN_BIN -c /home/ark/.config/retrorun.cfg --triggers -s /$directory/naomi -d /$directory/bios /home/ark/.config/retroarch$CORE/cores/"$2"_libretro.so "$3"
  printf "\033c" >> /dev/tty1
else
  directory=$(dirname "$3" | cut -d "/" -f2)
  CURDIRECTORYSET="$(grep "retrorun_screenshot_folder = " /home/ark/.config/retrorun.cfg | cut -d "/" -f2-3)"
  if [[ "${CURDIRECTORYSET}" != "${directory}/naomi" ]]; then
    sed -i "/retrorun_screenshot_folder \=/c\retrorun_screenshot_folder \= \/$directory\/naomi" /home/ark/.config/retrorun.cfg
  fi
  $ESUDO /usr/local/bin/retrorun32 -c /home/ark/.config/retrorun.cfg --triggers -s /$directory/naomi -d /$directory/bios /home/ark/.config/retroarch32/cores/"$2"_libretro.so "$3"
  printf "\033c" >> /dev/tty1
fi

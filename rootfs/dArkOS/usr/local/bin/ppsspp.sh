#!/bin/bash

opt_config_directory_std="/opt/ppsspp/backupforromsfolder/ppsspp"
opt_config_directory_2021="/opt/ppsspp-2021/backupforromsfolder/ppsspp"

directory=$(dirname "$2" | cut -d "/" -f2)
roms_config_directory_std="/$directory/psp/ppsspp"
roms_config_directory_2021="/$directory/psp/ppsspp-2021"

directory=$(dirname "$2" | cut -d "/" -f2)

rm /home/ark/.config/ppsspp

if [[ $1 == "standalone" ]] || [[ $1 == "standalone-vulkan" ]]; then
  ln -sf $roms_config_directory_std/ /home/ark/.config/ppsspp
  if [[ ! -d "$roms_config_directory_std" ]]; then
    cp -rf $opt_config_directory_std/ $roms_config_directory_std/
  fi
  if [[ ! -f "$roms_config_directory_std/PSP/SYSTEM/controls.ini" ]]; then
    cp -rf $opt_config_directory_std/PSP/SYSTEM/controls.ini $roms_config_directory_std/PSP/SYSTEM/controls.ini
  fi
  if [[ ! -f "$roms_config_directory_std/PSP/SYSTEM/ppsspp.ini.sdl" ]]; then
    cp -rf $opt_config_directory_std/PSP/SYSTEM/ppsspp.ini.sdl $roms_config_directory_std/PSP/SYSTEM/ppsspp.ini.sdl
  fi
  echo "VAR=PPSSPPSDL" > /home/ark/.config/KILLIT
  sudo systemctl restart killer_daemon.service
  cp -f $roms_config_directory_std/PSP/SYSTEM/ppsspp.ini.sdl $roms_config_directory_std/PSP/SYSTEM/ppsspp.ini
  if [[ $1 == "standalone-vulkan" ]]; then
   sed -i '/^GraphicsBackend =/c\GraphicsBackend = 3 (VULKAN)' $roms_config_directory_std/PSP/SYSTEM/ppsspp.ini
  else
   sed -i '/^GraphicsBackend =/c\GraphicsBackend = 0 (OPENGL)' $roms_config_directory_std/PSP/SYSTEM/ppsspp.ini
  fi
  /opt/ppsspp/PPSSPPSDL --fullscreen "$2"
  cp -f $roms_config_directory_std/PSP/SYSTEM/ppsspp.ini $roms_config_directory_std/PSP/SYSTEM/ppsspp.ini.sdl
  sudo systemctl stop killer_daemon.service
elif [[ $1 == "standalone-2021" ]] || [[ $1 == "standalone-2021-vulkan" ]]; then
  ln -sf $roms_config_directory_2021/ /home/ark/.config/ppsspp
  if [[ ! -d "$roms_config_directory_2021" ]]; then
    cp -rf $opt_config_directory_2021/ $roms_config_directory_2021/
  fi
  if [[ ! -f "$roms_config_directory_2021/PSP/SYSTEM/controls.ini" ]]; then
    cp -rf $opt_config_directory_2021/PSP/SYSTEM/controls.ini $roms_config_directory_2021/PSP/SYSTEM/controls.ini
  fi
  if [[ ! -f "$roms_config_directory_2021/PSP/SYSTEM/ppsspp.ini.sdl" ]]; then
    cp -rf $opt_config_directory_2021/PSP/SYSTEM/ppsspp.ini.sdl $roms_config_directory_2021/PSP/SYSTEM/ppsspp.ini.sdl
  fi
  export SDL_AUDIODRIVER=alsa
  echo "VAR=PPSSPPSDL" > /home/ark/.config/KILLIT
  sudo systemctl restart killer_daemon.service
  cp -f $roms_config_directory_2021/PSP/SYSTEM/ppsspp.ini.sdl $roms_config_directory_2021/PSP/SYSTEM/ppsspp.ini
  if [[ $1 == "standalone-2021-vulkan" ]]; then
   sed -i '/^GraphicsBackend =/c\GraphicsBackend = 3 (VULKAN)' $roms_config_directory_2021/PSP/SYSTEM/ppsspp.ini
  else
   sed -i '/^GraphicsBackend =/c\GraphicsBackend = 0 (OPENGL)' $roms_config_directory_2021/PSP/SYSTEM/ppsspp.ini
  fi
  /opt/ppsspp-2021/PPSSPPSDL --fullscreen "$2"
  cp -f $roms_config_directory_2021/PSP/SYSTEM/ppsspp.ini $roms_config_directory_2021/PSP/SYSTEM/ppsspp.ini.sdl
  sudo systemctl stop killer_daemon.service
  unset SDL_AUDIODRIVER
else
  if [[ ! -d "/$directory/psp/PSP" ]]; then
    mkdir /$directory/psp/PSP
  fi
  if [[ ! -d "/$directory/psp/PSP/SAVEDATA" ]]; then
    mkdir /$directory/psp/PSP/SAVEDATA
  fi
  if [[ ! -d "/$directory/psp/SAVEDATA" ]]; then
    mkdir /$directory/psp/SAVEDATA
  fi
  /usr/local/bin/watchpsp.sh $directory &
  /usr/local/bin/retroarch -L /home/ark/.config/retroarch/cores/ppsspp_libretro.so "$2"
  sudo kill -9 $(pidof watchpsp.sh)
fi

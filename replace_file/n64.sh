#!/bin/bash

if [ -f "/boot/rk3326-rg351v-linux.dtb" ] || [ -f "/boot/rk3326-rg351mp-linux.dtb" ] || [ -f "/boot/rk3326-r33s-linux.dtb" ] || [ -f "/boot/rk3326-r35s-linux.dtb" ] || [ -f "/boot/rk3326-r36s-linux.dtb" ] || [ -f "/boot/rk3326-gameforce-linux.dtb" ] || [ -f "/boot/rk3566.dtb" ] || [ -f "/boot/rk3566-OC.dtb" ] || [ -f "/boot/.console" ] ; then
  xres="$(cat /sys/class/graphics/fb0/modes | grep -o -P '(?<=:).*(?=p-)' | cut -dx -f1)"
  yres="$(cat /sys/class/graphics/fb0/modes | grep -o -P '(?<=:).*(?=p-)' | cut -dx -f2)"
else
  xres="$(cat /sys/class/graphics/fb0/modes | grep -o -P '(?<=:).*(?=p-)' | cut -dx -f2)"
  yres="$(cat /sys/class/graphics/fb0/modes | grep -o -P '(?<=:).*(?=p-)' | cut -dx -f1)"
fi

if [ "$#" -gt 2 ]; then
  game="${3}"
else
  game="${2}"
fi

# The standalone mupen64plus emulator doesn not support 7z or zip archive files.  We'll take care of that here
ext="${game##*.}"
if ([[ "${ext,,}" == "zip" ]] || [[ "${ext,,}" == "7z" ]]) && [[ $1 == *"standalone"* ]]; then
  if [ ! -d "/dev/shm/n64roms" ]; then
    mkdir -p /dev/shm/n64roms
  else
    rm -rf /dev/shm/n64roms/*
  fi
  # game variable will be updated with the file that is found in the 7z or zip archive
  ROM="$game"
  if [[ "${ext,,}" == "zip" ]]; then
    unzip -qq -o "$ROM" -d /dev/shm/n64roms/
  else
    7z e "$ROM" -bd -aoa -o/dev/shm/n64roms/
  fi
  if [ $? != 0 ]; then
    printf "\nCouldn't decompress $ROM\nSomething seems to be wrong with this archive." > /dev/tty1
    sleep 5
    printf "\033c" > /dev/tty1
    exit
  fi

  for CART in z64 Z64 n64 N64 v64 V64; do
    game=`find /dev/shm/n64roms/ -iname "*.${CART}" | tac | head -n 1`
    if [ ! -z "$game" ]; then
      break;
    fi
  done
  if [ -z "$game" ]; then
    printf "\nCouldn't find a compatible rom of type .z64 .Z64 .n64 .N64 .v64 .V64 in $ROM\n" > /dev/tty1
    sleep 5
    printf "\033c" > /dev/tty1
    exit
  fi
fi

if [[ $1 == "standalone-Rice" ]]; then
  if [[ $2 == "Widescreen_Aspect" ]]; then
    /opt/mupen64plus/mupen64plus --resolution "${xres}x${yres}" --plugindir /opt/mupen64plus --gfx mupen64plus-video-rice.so --corelib /opt/mupen64plus/libmupen64plus.so.2 --datadir /opt/mupen64plus "$game"
  else
    ricewidthhack=$(((yres * 4) / 3))
    /opt/mupen64plus/mupen64plus --resolution "${ricewidthhack}x${yres}" --plugindir /opt/mupen64plus --gfx mupen64plus-video-rice.so --corelib /opt/mupen64plus/libmupen64plus.so.2 --datadir /opt/mupen64plus "$game"
  fi
elif [[ $1 == "standalone-Glide64mk2" ]]; then
  if [[ $2 == "Widescreen_Aspect" ]]; then
    /opt/mupen64plus/mupen64plus --set Video-Glide64mk2[aspect]=1 --resolution "${xres}x${yres}" --plugindir /opt/mupen64plus --gfx mupen64plus-video-glide64mk2.so --corelib /opt/mupen64plus/libmupen64plus.so.2 --datadir /opt/mupen64plus "$game"
  else
    /opt/mupen64plus/mupen64plus --set Video-Glide64mk2[aspect]=-1 --resolution "${xres}x${yres}" --plugindir /opt/mupen64plus --gfx mupen64plus-video-glide64mk2.so --corelib /opt/mupen64plus/libmupen64plus.so.2 --datadir /opt/mupen64plus "$game"
  fi
elif [[ $1 == "standalone-GlideN64" ]]; then
  if [[ $2 == "Widescreen_Aspect" ]]; then
    /opt/mupen64plus/mupen64plus --set Video-GLideN64[ThreadedVideo]=True --set Video-GLideN64[UseNativeResolutionFactor]=1 --set Video-GLideN64[AspectRatio]=3 --resolution "${xres}x${yres}" --plugindir /opt/mupen64plus --gfx mupen64plus-video-GLideN64.so --corelib /opt/mupen64plus/libmupen64plus.so.2 --datadir /opt/mupen64plus "$game"
  else
    /opt/mupen64plus/mupen64plus --set Video-GLideN64[ThreadedVideo]=True --set Video-GLideN64[UseNativeResolutionFactor]=1 --set Video-GLideN64[AspectRatio]=1 --resolution "${xres}x${yres}" --plugindir /opt/mupen64plus --gfx mupen64plus-video-GLideN64.so --corelib /opt/mupen64plus/libmupen64plus.so.2 --datadir /opt/mupen64plus "$game"
  fi
else
  /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
fi


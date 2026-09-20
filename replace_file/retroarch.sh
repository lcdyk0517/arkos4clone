#!/usr/bin/env bash

sudo chmod 666 /dev/tty0
printf "\033c" > /dev/tty0
dialog --clear

emulator=$(basename "$0")

# ---------------------------------------------------------------------------
# 核心需要的 glibc 比 2.30 新时，走 glibc 2.42 loader 运行
# （探测原理：抓取核心里内嵌的 GLIBC_2.x 版本符号，取最高版本比较）
# 用这段替换脚本里原来的探测块
SYS_LIBSTDCXX=/lib/aarch64-linux-gnu/libstdc++.so.6
RUNNER=()
for a in "$@"; do
  case "$a" in
  *.so|*.so.*)
    [ -f "$a" ] || continue
    [ -x /opt/glibc-2.42/64/lib/ld-linux-aarch64.so.1 ] || break
    need_glibc="$(grep -aoE 'GLIBC_2\.[0-9]+' "$a" 2>/dev/null | sed 's/GLIBC_//' | sort -V | tail -1)"
    need_cxxabi="$(grep -aoE 'CXXABI_1\.[0-9.]+' "$a" 2>/dev/null | sort -Vu | tail -1)"
    sys_cxxabi="$(grep -aoE 'CXXABI_1\.[0-9.]+' "$SYS_LIBSTDCXX" 2>/dev/null | sort -Vu | tail -1)"
    hit=""
    if [ -n "$need_glibc" ]; then
      newest="$(printf '%s\n2.30\n' "$need_glibc" | sort -V | tail -1)"
      [ "$newest" != "2.30" ] && hit=1
    fi
    if [ -z "$hit" ] && [ -n "$need_cxxabi" ] && [ -n "$sys_cxxabi" ]; then
      newest="$(printf '%s\n%s\n' "$need_cxxabi" "$sys_cxxabi" | sort -Vu | tail -1)"
      [ "$newest" = "$need_cxxabi" ] && [ "$need_cxxabi" != "$sys_cxxabi" ] && hit=1
    fi
    if [ -n "$hit" ]; then
      RUNNER=(/opt/glibc-2.42/64/lib/ld-linux-aarch64.so.1 --library-path \
        /opt/glibc-2.42/64/lib:/usr/local/lib/aarch64-linux-gnu:/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu)
      break
    fi
    ;;
  esac
done
# ---------------------------------------------------------------------------

. /usr/local/bin/buttonmon.sh

Test_Button_X
if [ "$?" -eq "10" ]; then
  core="$(echo "$@" | grep -o -P '(?<=cores\/).*(?=_libretro.so)')"
  game="$(echo "$@" | grep -o -P '(?<=_libretro.so ).*(?=)')"
  nonetplay=( "arduous" "atari800" "bluemsx" "coolcv" "dosbox" \
              "duckstation" "easyrpg" "ecwolf" \
              "fake08" "flycast" "flycast32_rumble" "flycast_rumble" \
              "flycast_xtreme" "freechaf" "freeintv" "fuse" "gambatte" \
              "gw" "hatari" "mgba" "mgba_rumble" "mupen64plus" \
              "mupen64plus_next" "nekop2" "o2em" "onscripter" \
              "parallel_n64" "pcsx_rearmed" "pcsx_rearmed_rumble" \
              "pokemini" "ppsspp" "prosystem" "puae" "puae2021" \
              "px68k" "reicast_xtreme" "same_cdi" "scummvm" "swanstation" \
              "theodore" "uae4arm" "uzem" "vbam" "vba_next" "vecx" \
              "vemulator" "vice_x128" "vice_x64" "vice_xplus4" \
              "vice_xvic" "wasm4" "x1" )
  if [ ! -z $core ] && [[ ${nonetplay[@]} =~ $core ]]; then
    msgbox "The $core emulation core does not support netplay."
    exit 0
  fi
  netplay.sh "$core" "$game" "$emulator"
  results="$(echo $?)"
  if [ "$results" -eq "250" ]; then
    "${RUNNER[@]}" /opt/retroarch/bin/${emulator} -c /home/ark/.config/${emulator}/retroarch.cfg -H --nick=ArkOS_Host_"${core}"_Session_"$(cat /sys/class/net/wlan0/address | awk -F':' '{ print $4$5$6}')" "$@"
  elif [ "$results" -eq "138" ]; then
    "${RUNNER[@]}" /opt/retroarch/bin/${emulator} -c /home/ark/.config/${emulator}/retroarch.cfg --connect=192.168.1.1 --nick=ArkOS_Client_"${core}"_Session_"$(cat /sys/class/net/wlan0/address | awk -F':' '{ print $4$5$6}')" "$@"
  elif [ "$results" -eq "139" ]; then
    "${RUNNER[@]}" /opt/retroarch/bin/${emulator} -c /home/ark/.config/${emulator}/retroarch.cfg --connect=192.168.1.1 --nick=ArkOS_Spectator_"${core}"_Session_"$(cat /sys/class/net/wlan0/address | awk -F':' '{ print $4$5$6}')" --appendconfig=/home/ark/.config/${emulator}/retroarch.cfg.spectate "$@"
  elif [ "$results" -eq "230" ]; then
    continue
  fi
  
  reset
  sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz

  if [[ "$(iw dev wlan0 info | grep ssid | cut -c 7-30)" == *"ArkOS_"* ]] || [ -z "$(iw dev wlan0 info | grep ssid | cut -c 7-30)" ]; then
    arkos_ap_mode.sh Disable
  fi
  if [ "$results" -ne "230" ]; then
    exit 0
  fi
fi

if [ -f "/boot/rk3566.dtb" ] || [ -f "/boot/rk3566-OC.dtb" ]; then
  /usr/local/bin/controller_setup.sh

  if [ "$(ls /dev/input/ | wc -l)" -gt "7" ]; then
    testJoy=$(timeout 1 sdljoytest | grep Found)
    testJoy=$(echo "$testJoy" | cut -d " " -f6)
    if [ "$testJoy" -gt "1" ]; then
      "${RUNNER[@]}" /opt/retroarch/bin/${emulator} -c /home/ark/.config/${emulator}/retroarch.cfg --appendconfig=/home/ark/.config/${emulator}/retroarch.cfg.ext "$@"
    else
      "${RUNNER[@]}" /opt/retroarch/bin/${emulator} -c /home/ark/.config/${emulator}/retroarch.cfg "$@"
    fi
  else
    "${RUNNER[@]}" /opt/retroarch/bin/${emulator} -c /home/ark/.config/${emulator}/retroarch.cfg "$@"
  fi
else
  "${RUNNER[@]}" /opt/retroarch/bin/${emulator} -c /home/ark/.config/${emulator}/retroarch.cfg "$@"
fi
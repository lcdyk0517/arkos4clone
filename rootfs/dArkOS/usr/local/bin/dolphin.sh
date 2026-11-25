#!/bin/bash
# EmulationStation launcher for standalone Dolphin: dolphin.sh <gc|wii> <rom>
# The user directory is <sd>/gc (saves, memory cards, Wii NAND, states), shared
# by both systems and kept on the same SD card as the ROM.

rom="$2"
sd="$(echo "${rom}" | cut -d/ -f2)"
user_dir="/${sd}/gc"
defaults="/opt/dolphin/defaults/Config"

mkdir -p "${user_dir}/Config"
for f in "${defaults}"/*.ini; do
  [ -f "${user_dir}/Config/$(basename "${f}")" ] || cp "${f}" "${user_dir}/Config/"
done

export XDG_RUNTIME_DIR=/run/user/1000
# Dolphin's SDL input backend reads this mapping; exit is Start+Select.
export SDL_GAMECONTROLLERCONFIG="190000004b4800000011000000010000,GO-Super Gamepad,x:b2,a:b1,b:b0,y:b3,back:b12,start:b13,dpleft:b10,dpdown:b9,dpright:b11,dpup:b8,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftstick:b14,rightstick:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux,"
# ArkOS restores ES through the killer daemon on the native path. The loader path
# below cannot be seen by it, so the binary also quits on Start+Select by itself.
echo "VAR=dolphin-emu-nog" > /home/ark/.config/KILLIT
sudo systemctl restart killer_daemon.service
# ArkOS 2.30 cannot load this GCC 14 / trixie binary directly. When the
# bundled glibc runtime is installed, start through its loader; dArkOS runs
# the binary natively.
if [ -x /opt/glibc-2.42/64/lib/ld-linux-aarch64.so.1 ]; then
  /opt/glibc-2.42/64/lib/ld-linux-aarch64.so.1 \
    --library-path /opt/dolphin/lib:/opt/glibc-2.42/64/lib:/usr/lib/aarch64-linux-gnu:/lib/aarch64-linux-gnu \
    /opt/dolphin/dolphin-emu-nogui -p drm -u "${user_dir}" -e "${rom}" > /tmp/dolphin.log 2>&1
else
  LD_LIBRARY_PATH="/opt/dolphin/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" \
    /opt/dolphin/dolphin-emu-nogui -p drm -u "${user_dir}" -e "${rom}" > /tmp/dolphin.log 2>&1
fi
sudo systemctl stop killer_daemon.service

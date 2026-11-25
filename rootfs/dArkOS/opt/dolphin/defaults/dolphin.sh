#!/bin/bash
# EmulationStation launcher for standalone Dolphin: dolphin.sh <gc|wii> <rom>
# The user directory is <sd>/gc (saves, memory cards, Wii NAND, states), shared
# by both systems and kept on the same SD card as the ROM.

rom="$2"
sd="$(echo "${rom}" | cut -d/ -f2)"
user_dir="/${sd}/gc"
defaults="/opt/dolphin/defaults/Config"

# Dolphin needs Vulkan, which the 4.4 kernel does not provide. Show a notice
# and wait for A/B instead of dropping the user back with a black screen.
case "$(uname -r)" in
  4.4*)
    export TERM=linux
    sudo chmod 666 /dev/tty1 2>/dev/null
    printf "\033c" > /dev/tty1
    dialog --title "Dolphin" --infobox $'Vulkan is not available on the 4.4 kernel.\n\nSwitch to the 5.10 kernel and launch Dolphin again.\n\nPress A or B to exit.' 12 64 > /dev/tty1 2>&1
    . /usr/local/bin/buttonmon.sh 2>/dev/null
    dev="/dev/input/event${event_num:-2}"
    btn_a="${event_btn_a:-BTN_EAST}"
    btn_b="${event_btn_b:-BTN_SOUTH}"
    while :; do
      evtest --query "$dev" EV_KEY "$btn_a" >/dev/null 2>&1
      [ $? -eq 10 ] && break
      evtest --query "$dev" EV_KEY "$btn_b" >/dev/null 2>&1
      [ $? -eq 10 ] && break
      sleep 0.1
    done
    printf "\033c" > /dev/tty1
    exit 0
    ;;
esac

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

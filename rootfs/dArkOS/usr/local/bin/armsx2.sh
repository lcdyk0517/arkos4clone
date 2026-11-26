#!/bin/bash
# ARMSX2 (PS2) launcher for dArkOS 3326, modelled on the 3562 ps2.sh:
# per-card data root on the SD card, key INI fields repaired on every start
# because ARMSX2 rewrites them on an abnormal exit.
ROM="${1:-}"

# ARMSX2 needs Vulkan, which the 4.4 kernel does not provide.
case "$(uname -r)" in
  4.4*)
    export TERM=linux
    sudo chmod 666 /dev/tty1 2>/dev/null
    printf "\033c" > /dev/tty1
    dialog --title "ARMSX2" --infobox $'Vulkan is not available on the 4.4 kernel.\n\nSwitch to the 5.10 kernel and launch ARMSX2 again.\n\nPress A or B to exit.' 12 64 > /dev/tty1 2>&1
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

DATA=/roms/ps2/armsx2
APP=/opt/armsx2/bin/armsx2-sdl
[ -x "$APP" ] || { echo "PS2: missing $APP"; sleep 5; exit 1; }

mkdir -p "$DATA"/{memcards,sstates,snaps,cache,textures,cheats,patches,logs,inputprofiles} \
         "$DATA/.config/ARMSX2/inis" "$DATA/.local/share"

# First start on a fresh card: take the previous ~/.config/ARMSX2 (BIOS,
# memory cards, settings) with us.
if [ -d /home/ark/.config/ARMSX2 ] && [ ! -f "$DATA/.config/ARMSX2/inis/PCSX2.ini" ]; then
  cp -a /home/ark/.config/ARMSX2/. "$DATA/.config/ARMSX2/" 2>/dev/null
fi

INI="$DATA/.config/ARMSX2/inis/PCSX2.ini"

# ARMSX2's DataRoot is $XDG_CONFIG_HOME/ARMSX2, so point HOME at the card.
export HOME="$DATA"
export XDG_CONFIG_HOME="$DATA/.config"
export XDG_DATA_HOME="$DATA/.local/share"

# A PS2 BIOS is 4-8 MB; a PS1 one (512K) next to it is skipped by ARMSX2 itself.
BIOS_DIR=""
for d in /roms/bios /roms/ps2/bios /roms2/bios "$DATA/.config/ARMSX2/bios" /home/ark/.config/ARMSX2/bios; do
  [ -d "$d" ] || continue
  if [ -n "$(find "$d" -maxdepth 1 -iname 'SCPH*.BIN' -size +3M 2>/dev/null | head -1)" ]; then
    BIOS_DIR="$d"
    break
  fi
done

# Key settings: Renderer 14 (Vulkan). Auto (-1) is what makes it exit before the
# GS comes up, i.e. the "flash quit". OpenPauseMenu/QuitApplication are written
# here because ARMSX2 restores its keyboard defaults on exit.
repair_ini() {
  [ -f "$INI" ] || return 0

  grep -q '^SettingsVersion' "$INI" || return 1
  sed -i -E 's|^Renderer = .*|Renderer = 14|' "$INI"
  [ -n "$BIOS_DIR" ] && sed -i "s|^Bios = .*|Bios = $BIOS_DIR|" "$INI"

  sed -i -E '/^(OpenPauseMenu|QuitApplication)[[:space:]]*=/d' "$INI"
  if grep -q '^\[Hotkeys\]' "$INI"; then
    awk -v a="OpenPauseMenu = SDL-0/Back & SDL-0/FaceWest" \
        -v b="QuitApplication = SDL-0/Start & SDL-0/Back" \
        '{ print } /^\[Hotkeys\]/{ print a; print b }' "$INI" > "$INI.tmp" && mv "$INI.tmp" "$INI"
  else
    printf '\n[Hotkeys]\nOpenPauseMenu = SDL-0/Back & SDL-0/FaceWest\nQuitApplication = SDL-0/Start & SDL-0/Back\n' >> "$INI"
  fi
}

# A missing/incomplete INI is rebuilt by ARMSX2 itself with our defaults, then
# repaired on the following start.
if ! repair_ini; then
  rm -f "$INI"
fi

# A single-track .cue defeats ARMSX2's CDVD open; use the .bin it names.
case "${ROM##*.}" in
  cue|CUE)
    _bn=$(sed -n 's/^FILE "\(.*\)" BINARY.*/\1/p' "$ROM" 2>/dev/null | head -1)
    if [ -n "$_bn" ] && [ "$(grep -c '^[[:space:]]*TRACK' "$ROM" 2>/dev/null)" = "1" ] \
       && [ -f "$(dirname "$ROM")/$_bn" ]; then
      ROM="$(dirname "$ROM")/$_bn"
    fi
    ;;
esac

export SDL_VIDEODRIVER=kmsdrm
export SDL_AUDIODRIVER=alsa
export VK_ICD_FILENAMES=/opt/malisx2/malisx2.json
export SDL_GAMECONTROLLERCONFIG="190000004b4800000011000000010000,GO-Super Gamepad,x:b2,a:b1,b:b0,y:b3,back:b12,start:b13,dpleft:b10,dpdown:b9,dpright:b11,dpup:b8,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftstick:b14,rightstick:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux,"

# Follow the ES language, as kodi.sh does: zh-CN switches ARMSX2's UI too.
if grep -q '<string name="Language" value="zh-CN" />' \
      /home/ark/.emulationstation/es_settings.cfg 2>/dev/null; then
	export ARMSX2_LANGUAGE=zh-CN
fi

LOG="$DATA/logs/last_run.log"
# ArkOS 2.30 cannot load a trixie binary directly: start it through the bundled
# glibc runtime, as dolphin.sh does. dArkOS4Clone runs a current glibc (2.41),
# so there the binary starts natively.
if [ -x /opt/glibc-2.42/64/lib/ld-linux-aarch64.so.1 ]; then
	/opt/glibc-2.42/64/lib/ld-linux-aarch64.so.1 \
		--library-path /opt/armsx2/lib:/opt/glibc-2.42/64/lib:/usr/lib/aarch64-linux-gnu:/lib/aarch64-linux-gnu \
		"$APP" ${ROM:+"$ROM"} > "$LOG" 2>&1
	RC=$?
else
	LD_LIBRARY_PATH="/opt/armsx2/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
		"$APP" ${ROM:+"$ROM"} > "$LOG" 2>&1
	RC=$?
fi

# Started by hand with ES stopped: bring the UI back instead of leaving tty1.
if ! systemctl is-active --quiet emulationstation; then
  sudo systemctl start emulationstation
fi
sync
exit $RC

#!/usr/bin/env bash
set -euo pipefail

# =============== Paths ===============
BOOTINI="/boot/boot.ini"
CONSOLE_FILE="/boot/.console"
QUIRKS_DIR="/home/ark/.quirks"
ES_CFG_NAME="es_input.cfg"
RETRO64_NAME="retroarch64.cfg"
RETRO32_NAME="retroarch32.cfg"
PAD_NAME="pad.txt"
FIXPAD_PATH="$QUIRKS_DIR/fix_pad.sh"

# =============== Helpers ===============
msg() {
  if [[ -w /dev/tty1 ]]; then
    echo "[adjust-keys] $*" > /dev/tty1
  fi
  echo "[adjust-keys] $*"
}

warn() {
  if [[ -w /dev/tty1 ]]; then
    echo "[adjust-keys][WARN] $*" > /dev/tty1
  fi
  echo "[adjust-keys][WARN] $*" >&2
}


cp_if_exists() {
  local src="$1" dst="$2" isfile="${3:-no}"
  if [[ -e "$src" ]]; then
    if [[ "$isfile" == "yes" ]]; then
      mkdir -p "$(dirname "$dst")"
      if cp -a "$src" "$dst" 2>/dev/null; then
        :
      else
        sudo install -m 0755 -D "$src" "$dst"
        sudo chown --reference="$src" "$dst" 2>/dev/null || true
        sudo touch -r "$src" "$dst" 2>/dev/null || true
      fi
      sudo chmod 0755 "$dst" || true
    else
      mkdir -p "$dst"
      sudo cp -a "$src" "$dst/"
    fi
    msg "Copied: $src -> $dst"
  else
    warn "Source not found, skip: $src"
  fi
}

apply_quirks_for() {
  local dtbval="$1"
  local base="$QUIRKS_DIR/$dtbval"

  if [[ ! -d "$base" ]]; then
    warn "Quirks dir not found: $base -> skip applying"
    return 0
  fi

  msg "Applying quirks for: $dtbval"

  # fix es
  cp_if_exists "$base/$ES_CFG_NAME" "/etc/emulationstation" "no"

  # fix retroarch
  local src_udev="$base/udev"
  if [[ -d "$src_udev" ]]; then
    mkdir -p /home/ark/.config/retroarch/autoconfig/udev
    mkdir -p /home/ark/.config/retroarch32/autoconfig/udev
    cp_if_exists "$src_udev/." "/home/ark/.config/retroarch/autoconfig/udev" "no"
    cp_if_exists "$src_udev/." "/home/ark/.config/retroarch32/autoconfig/udev" "no"
  fi
  cp_if_exists "$base/$RETRO64_NAME" "/home/ark/.config/retroarch/retroarch.cfg" "yes"
  cp_if_exists "$base/$RETRO32_NAME" "/home/ark/.config/retroarch32/retroarch.cfg" "yes"
  
  # fix ppsspp
  if [[ "$dtbval" == "r36s" ]]; then
    cp_if_exists "$QUIRKS_DIR/controls.ini.r36s" "/opt/ppsspp/backupforromsfolder/ppsspp/PSP/SYSTEM/controls.ini" "yes"
    [ -d "/roms/psp/ppsspp/PSP/SYSTEM" ] && cp_if_exists "$QUIRKS_DIR/controls.ini.r36s" "/roms/psp/ppsspp/PSP/SYSTEM/controls.ini" "yes"
    [ -d "/roms2/psp/ppsspp/PSP/SYSTEM" ] && cp_if_exists "$QUIRKS_DIR/controls.ini.r36s" "/roms2/psp/ppsspp/PSP/SYSTEM/controls.ini" "yes"
  else
    cp_if_exists "$QUIRKS_DIR/controls.ini.clone" "/opt/ppsspp/backupforromsfolder/ppsspp/PSP/SYSTEM/controls.ini" "yes"
    [ -d "/roms/psp/ppsspp/PSP/SYSTEM" ] && cp_if_exists "$QUIRKS_DIR/controls.ini.clone" "/roms/psp/ppsspp/PSP/SYSTEM/controls.ini" "yes"
    [ -d "/roms2/psp/ppsspp/PSP/SYSTEM" ] && cp_if_exists "$QUIRKS_DIR/controls.ini.clone" "/roms2/psp/ppsspp/PSP/SYSTEM/controls.ini" "yes"
  fi

  # fix drastic
  if [[ "$dtbval" == "r36s" ]]; then
    cp_if_exists "$QUIRKS_DIR/drastic.cfg.r36s" "/opt/drastic/config/drastic.cfg" "yes"
  elif [[ "$dtbval" == "mymini" || "$dtbval" == "k36s" ]]; then
    cp_if_exists "$QUIRKS_DIR/drastic.cfg.mymini" "/opt/drastic/config/drastic.cfg" "yes"
  else
    cp_if_exists "$QUIRKS_DIR/drastic.cfg.clone" "/opt/drastic/config/drastic.cfg" "yes"
  fi

  # fix pm
  if [[ -f "$FIXPAD_PATH" ]]; then
    chmod 0777 "$FIXPAD_PATH" || true
    local padfile="$base/$PAD_NAME"
    if [[ -f "$padfile" ]]; then
      "$FIXPAD_PATH" "$padfile" /
    else
      warn "pad.txt not found: $padfile"
    fi
  else
    warn "fix_pad.sh not found: $FIXPAD_PATH"
  fi
  cp_if_exists "$QUIRKS_DIR/control.txt" "/opt/system/Tools/PortMaster/control.txt" "yes"

  # ogage快捷键修复
  case "$dtbval" in
    xf40h|xf35h|mymini)
      msg "set ogage: $dtbval -> ogage.select.conf"
      cp_if_exists "$QUIRKS_DIR/ogage.select.conf" "/home/ark/ogage.conf" "yes"
      ;;
    k36s|r36pro|r36ultra|r36max|hg36)
      msg "set ogage: $dtbval -> ogage.mode.conf"
      cp_if_exists "$QUIRKS_DIR/ogage.mode.conf" "/home/ark/ogage.conf" "yes"
      ;;
    r36s)
      msg "set ogage: $dtbval -> ogage.happy5.conf"
      cp_if_exists "$QUIRKS_DIR/ogage.happy5.conf" "/home/ark/ogage.conf" "yes"
      ;;
  esac
  sudo systemctl stop oga_events
  cp_if_exists "$QUIRKS_DIR/ogage" "/usr/local/bin/ogage" "yes"
  sudo systemctl start oga_events

}

# =============== Main ===============
if [[ -f "$CONSOLE_FILE" ]]; then
  LABEL="$(tr -d '\r\n' < "$CONSOLE_FILE")"
  msg "Using LABEL from $CONSOLE_FILE: $LABEL"
else
  DTB="$(grep -oE 'load[[:space:]]+mmc[[:space:]]+1:1[[:space:]]+\$\{dtb_loadaddr\}[[:space:]]+[[:graph:]]+' "$BOOTINI" \
        | awk '{print $NF}' | tail -n1 | xargs basename || true)"
  LABEL="${DTB%.dtb}"
  echo "$LABEL" > "$CONSOLE_FILE"
  msg "Generated new .console with LABEL=$LABEL"
fi

apply_quirks_for "$LABEL"

msg "Adjust keys complete."
sleep 5
exit 0

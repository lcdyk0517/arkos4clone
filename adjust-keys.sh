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
  echo "[adjust-keys] $*" | tee -a /dev/tty1
}
warn() {
  echo "[adjust-keys][WARN] $*" | tee -a /dev/tty1 >&2
}

cp_if_exists() {
  local src="$1" dst="$2" isfile="${3:-no}"
  if [[ -e "$src" ]]; then
    if [[ "$isfile" == "yes" ]]; then
      mkdir -p "$(dirname "$dst")"
      if cp -a "$src" "$dst" 2>/dev/null; then
        :
      else
        install -m 0755 -D "$src" "$dst"
        chown --reference="$src" "$dst" 2>/dev/null || true
        touch -r "$src" "$dst" 2>/dev/null || true
      fi
      chmod 0755 "$dst" || true
    else
      mkdir -p "$dst"
      cp -a "$src" "$dst/"
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

  cp_if_exists "$base/$ES_CFG_NAME" "/etc/emulationstation" "no"

  local src_udev="$base/udev"
  if [[ -d "$src_udev" ]]; then
    mkdir -p /home/ark/.config/retroarch/autoconfig/udev
    mkdir -p /home/ark/.config/retroarch32/autoconfig/udev
    cp_if_exists "$src_udev/." "/home/ark/.config/retroarch/autoconfig/udev" "no"
    cp_if_exists "$src_udev/." "/home/ark/.config/retroarch32/autoconfig/udev" "no"
  fi

  cp_if_exists "$base/$RETRO64_NAME" "/home/ark/.config/retroarch/retroarch.cfg" "yes"
  cp_if_exists "$base/$RETRO32_NAME" "/home/ark/.config/retroarch32/retroarch.cfg" "yes"

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
  if [[ -f "$FIXPM_PATH" ]]; then
    chmod 0777 "$FIXPM_PATH" || warn "chmod failed on $FIXPM_PATH"
    if [[ -f "$padfile" ]]; then
      "$FIXPM_PATH"
    else
      warn "fix-pm.sh run failed"
    fi
  else
    warn "fix-pm.shnot found: $FIXPAD_PATH"
  fi
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
exit 0

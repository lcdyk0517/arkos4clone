#!/usr/bin/env bash
set -euo pipefail

# Test
# if [[ -w /dev/tty1 ]]; then
#   exec > /dev/tty1 2>&1
# fi

# =============== DTB -> LABEL 映射（按你的表）===============
# 从 /boot/boot.ini 中匹配：load mmc 1:1 ${dtb_loadaddr} <DTB>
BOOTINI="/boot/boot.ini"
DTB=""
if [[ -r "$BOOTINI" ]]; then
  # 容忍失败：整条管道最后加 || true
  DTB="$(grep -oE 'load[[:space:]]+mmc[[:space:]]+1:1[[:space:]]+\$\{dtb_loadaddr\}[[:space:]]+[[:graph:]]+' "$BOOTINI" \
        | awk '{print $NF}' | tail -n1 | xargs -r basename || true)"
else
  warn "boot.ini not readable: $BOOTINI"
fi
declare -A dtb2label=(
  [rk3326-mymini-linux.dtb]=mymini
  [rk3326-r36max-linux.dtb]=r36max
  [rk3326-xf35h-linux.dtb]=xf35h
  [rk3326-xf36pro-linux.dtb]=r36pro
  [rk3326-xf40h-linux.dtb]=xf40h
  [rk3326-xf40v-linux.dtb]=xf40v
  [rk3326-hg36-linux.dtb]=hg36
  [rk3326-r36ultra-linux.dtb]=r36ultra
  [rk3326-k36s-linux.dtb]=k36s
  [rk3326-rx6h-linux.dtb]=rx6h
)
declare -A console_profile=(
  [mymini]=480p
  [xf35h]=480p
  [r36pro]=480p
  [r36s]=480p
  [k36s]=480p
  [hg36]=480p
  [rx6h]=480p
  [r36max]=720p
  [xf40h]=720p
  [xf40v]=720p
  [r36ultra]=720p
)
declare -A ogage_conf_map=(
  [xf40h]=select
  [xf35h]=select
  [mymini]=select
  [rx6h]=select
  [k36s]=mode
  [r36pro]=mode
  [hg36]=mode
  [r36ultra]=mode
  [r36max]=mode
  [r36s]=happy5
  # 按需增删：  [机型]=select|mode
)
rk915_set=("xf40h" "xf40v" "xf35h" "r36ultra" "k36s")   # 按需增删
LABEL="${dtb2label[$DTB]:-r36s}"   # 默认 r36s
# =============== 路径配置（可按需调整）===============
SRC_CONSOLES_DIR="/boot/consoles/files"               # 源机型库
QUIRKS_DIR="/home/ark/.quirks"                  # 目标机型库
CONSOLE_FILE="/boot/.console"                   # 当前生效机型标记
ES_CFG_NAME="es_input.cfg"                      # 位于每个机型目录
RETRO64_NAME="retroarch64.cfg"                  # 位于每个机型目录
RETRO32_NAME="retroarch32.cfg"                  # 位于每个机型目录
PAD_NAME="pad.txt"                              # 位于每个机型目录
FIXPAD_PATH="$QUIRKS_DIR/fix_pad.sh"            # 你的 fix_pad.sh 所在处

# =============== 小工具函数（英文输出 / 中文注释）===============
msg()  { echo "[clone.sh] $*"; }
warn() { echo "[clone.sh][WARN] $*" >&2; }
err()  { echo "[clone.sh][ERR ] $*" >&2; }

# 如果源存在则复制；isfile=yes 时以文件目标安装（保持权限 0755）
cp_if_exists() {
  local src="$1" dst="$2" isfile="${3:-no}"
  if [[ -e "$src" ]]; then
    if [[ "$isfile" == "yes" ]]; then
      mkdir -p "$(dirname "$dst")"
      # 保留属主/属组/时间戳等
      if cp -a "$src" "$dst" 2>/dev/null; then
        :
      else
        # 极端情况下的兜底：还用 install，但把所有权按源文件纠正回去
        install -m 0755 -D "$src" "$dst"
        sudo chown --reference="$src" "$dst" 2>/dev/null || true
        sudo touch -r "$src" "$dst" 2>/dev/null || true
      fi
      # 统一权限为 0755（不影响属主/属组）
      sudo chmod 0755 "$dst" || true
    else
      mkdir -p "$dst"
      cp -a "$src" "$dst/"
    fi
    msg "Copied: $src -> $dst"
  else
    warn "Source not found, skip: $src"
  fi
}

apply_ogage_conf() {
  local dtbval="$1" kind conf
  # 键不存在时，kind 为空串（避免 set -u 爆炸）
  kind="${ogage_conf_map[$dtbval]-}"

  case "$kind" in
    select) conf="$QUIRKS_DIR/ogage.select.conf" ;;
    mode)   conf="$QUIRKS_DIR/ogage.mode.conf" ;;
    happy5)   conf="$QUIRKS_DIR/ogage.happy5.conf" ;;
    *)      conf="" ;;
  esac

  if [[ -n "$conf" ]]; then
    msg "change hotkey: $dtbval -> $(basename "$conf")"
    cp_if_exists "$conf" "/home/ark/ogage.conf" "yes"
  else
    msg "hotkey unchanged for: $dtbval (no mapping)"
  fi
}

# 依据 LABEL 执行“拷贝并运行 fix_pad”
apply_quirks_for() {
  local dtbval="$1"
  local base="$QUIRKS_DIR/$dtbval"

  # 若机型目录不存在，直接跳过（符合你的要求）
  if [[ ! -d "$base" ]]; then
    warn "Quirks dir not found: $base -> skip applying"
    return 0
  fi

  msg "Applying quirks for: $dtbval"

  # 1) es_input.cfg -> /etc/emulationstation/
  cp_if_exists "$base/$ES_CFG_NAME" "/etc/emulationstation" "no"

  # 2) udev/* -> 两个 autoconfig 目录
  local src_udev="$base/udev"
  if [[ -d "$src_udev" ]]; then
    mkdir -p /home/ark/.config/retroarch/autoconfig/udev
    mkdir -p /home/ark/.config/retroarch32/autoconfig/udev
    cp_if_exists "$src_udev/." "/home/ark/.config/retroarch/autoconfig/udev" "no"
    cp_if_exists "$src_udev/." "/home/ark/.config/retroarch32/autoconfig/udev" "no"
  else
    warn "udev dir not found: $src_udev"
  fi

  # 3) retroarch64.cfg -> retroarch/retroarch.cfg
  cp_if_exists "$base/$RETRO64_NAME" "/home/ark/.config/retroarch/retroarch.cfg" "yes"

  # 4) retroarch32.cfg -> retroarch32/retroarch.cfg
  cp_if_exists "$base/$RETRO32_NAME" "/home/ark/.config/retroarch32/retroarch.cfg" "yes"

  # 5) controls.ini -> SYSTEM/controls.ini
  if [[ "$dtbval" == "r36s" ]]; then
    cp_if_exists "$QUIRKS_DIR/controls.ini.r36s" "/opt/ppsspp/backupforromsfolder/ppsspp/PSP/SYSTEM/controls.ini" "yes"
    [ -d "/roms/psp/ppsspp/PSP/SYSTEM" ] && cp_if_exists "$QUIRKS_DIR/controls.ini.r36s" "/roms/psp/ppsspp/PSP/SYSTEM/controls.ini" "yes" || true
    [ -d "/roms2/psp/ppsspp/PSP/SYSTEM" ] && cp_if_exists "$QUIRKS_DIR/controls.ini.r36s" "/roms2/psp/ppsspp/PSP/SYSTEM/controls.ini" "yes" || true
  else
    cp_if_exists "$QUIRKS_DIR/controls.ini.clone" "/opt/ppsspp/backupforromsfolder/ppsspp/PSP/SYSTEM/controls.ini" "yes"
    [ -d "/roms/psp/ppsspp/PSP/SYSTEM" ] && cp_if_exists "$QUIRKS_DIR/controls.ini.clone" "/roms/psp/ppsspp/PSP/SYSTEM/controls.ini" "yes"  || true
    [ -d "/roms2/psp/ppsspp/PSP/SYSTEM" ] && cp_if_exists "$QUIRKS_DIR/controls.ini.clone" "/roms2/psp/ppsspp/PSP/SYSTEM/controls.ini" "yes" || true
  fi

  # 6) drastic.cfg -> /opt/drastic/config/drastic.cfg
  if [[ "$dtbval" == "r36s" ]]; then
    cp_if_exists "$QUIRKS_DIR/drastic.cfg.r36s" "/opt/drastic/config/drastic.cfg" "yes"
  elif [[ "$dtbval" == "mymini" || "$dtbval" == "k36s" ]]; then
    cp_if_exists "$QUIRKS_DIR/drastic.cfg.mymini" "/opt/drastic/config/drastic.cfg" "yes"
  else
    cp_if_exists "$QUIRKS_DIR/drastic.cfg.clone" "/opt/drastic/config/drastic.cfg" "yes"
  fi

  # 7) fix_pad.sh
  if [[ -f "$FIXPAD_PATH" ]]; then
    chmod +x "$FIXPAD_PATH" || warn "chmod failed on $FIXPAD_PATH"
    local padfile="$base/$PAD_NAME"
    if [[ -f "$padfile" ]]; then
      msg "Start fix_pad $(date +'%F %T')"
      if ! "$FIXPAD_PATH" "$padfile" / </dev/null; then
        warn "fix_pad returned non-zero (ignored)"
      fi
      msg "End   fix_pad $(date +'%F %T')"
    else
      warn "pad.txt not found: $padfile (skip fix_pad)"
    fi
  else
    warn "fix_pad.sh not found: $FIXPAD_PATH"
  fi


  # 8) fix ogage
  apply_ogage_conf "$dtbval"
}

install_profile_assets() {
  local prof="$1"
  case "$prof" in
    480p|720p)
      cp_if_exists "$QUIRKS_DIR/$prof/351Files" "/opt/351Files" "no"
      cp_if_exists "$QUIRKS_DIR/$prof/drastic/TF1/libSDL2-2.0.so.0.3000.2" "/opt/drastic/TF1/" "yes"
      cp_if_exists "$QUIRKS_DIR/$prof/drastic/TF2/libSDL2-2.0.so.0.3000.2" "/opt/drastic/TF2/" "yes"
      cp_if_exists "$QUIRKS_DIR/$prof/drastic/bg" "/roms/nds" "no"
      [[ -d "/roms2/nds/bg" ]] && cp_if_exists "$QUIRKS_DIR/$prof/drastic/bg" "/roms2/nds" "no" || true
      ;;
    *) msg "No profile assets for: $prof" ;;
  esac
}

copy_file() {
  [[ -f "$CONSOLE_FILE" ]] && cur_console="$(tr -d '\r\n' < "$CONSOLE_FILE")" || cur_console=""
  [[ -n "$cur_console" ]] && install_profile_assets "${console_profile[$cur_console]}"

  if [[ "$cur_console" == "r36s" ]]; then
    cp_if_exists "/opt/351Files/351Files.r36s" "/opt/351Files/351Files" "yes"
  fi

  cp_if_exists "$QUIRKS_DIR/control.txt" "/opt/system/Tools/PortMaster/control.txt" "yes"
}

copt_add_libs() {
  if [[ -d "/roms/ports/libs" ]]; then
    cp_if_exists /roms/ports/libs /opt/system/Tools/PortMaster/libs "no"
    sudo rm -rf /roms/ports/libs/
  fi
}


# =============== 执行开始 ===============
msg "DTB filename: ${DTB:-<empty>}, LABEL: $LABEL"

# 先同步 /boot/consoles -> ~/.quirks（有 rsync 用 rsync）
# 暂时不需要这个，构建包时手动添加
# if [[ -d "$SRC_CONSOLES_DIR" ]]; then
#   mkdir -p "$QUIRKS_DIR"
#   if command -v rsync >/dev/null 2>&1; then
#     rsync -a --delete "$SRC_CONSOLES_DIR"/ "$QUIRKS_DIR"/
#   else
#     cp -a "$SRC_CONSOLES_DIR"/. "$QUIRKS_DIR"/
#   fi
#   # 删除源目录（复制完成后）
#   rm -rf "$SRC_CONSOLES_DIR"
#   msg "Consoles synced to: $QUIRKS_DIR"
# else
#   warn "Consoles dir not found: $SRC_CONSOLES_DIR (continue)"
# fi

# 检测 /boot/fix_audio.sh 是否存在
if [ -f "/boot/fix_audio.sh" ]; then
  mkdir -p /opt/system/clone
  cp -f "/boot/fix_audio.sh" "/opt/system/clone/Toggle Audio.sh"
  "/boot/fix_audio.sh"
  rm -rf "/boot/fix_audio.sh"
  echo "[boot] Copied fix_audio.sh -> /opt/system/clone/Toggle Audio.sh"
fi

# 按规则处理 /boot/.console
if [[ ! -f "$CONSOLE_FILE" ]]; then
  clear
  echo "==============================="
  echo "   arkos for clone lcdyk  ..."
  echo "==============================="
  sleep 2
  echo "$LABEL" > "$CONSOLE_FILE"
  msg "Wrote new console file: $CONSOLE_FILE -> $LABEL"
  apply_quirks_for "$LABEL"
  copy_file
  sleep 5
else
  CUR_VAL="$(tr -d '\r\n' < "$CONSOLE_FILE" || true)"
  if [[ "$CUR_VAL" == "$LABEL" ]]; then
    copt_add_libs 
    msg "Console unchanged ($CUR_VAL); nothing to do."
  else
    (
      # ==== 所有输出都到 tty1 ====
      # 复位/清屏并回到左上角
      printf '\033c'
      echo "==============================="
      echo "   arkos for clone lcdyk  ..."
      echo "==============================="
      echo
      echo "[firstboot.sh] old config: ${CUR_VAL}"
      echo "[firstboot.sh] new config: ${LABEL}"
      echo
      # 顺序保持不变：先写 .console，再应用 quirks（避免重入时再次触发）
      echo "$LABEL" | sudo tee "$CONSOLE_FILE" > /dev/null
      apply_quirks_for "$LABEL"
      copy_file
      sleep 5
    ) > /dev/tty1 2>&1
  fi
fi
# 安装915wifi驱动
if [[ -f "$CONSOLE_FILE" ]]; then
  cur_console="$(tr -d '\r\n' < "$CONSOLE_FILE")"
  for x in "${rk915_set[@]}"; do
    if [[ "$cur_console" == "$x" ]]; then
      msg "insmod rk915.ko: $cur_console"
      sudo insmod -f /usr/lib/modules/4.4.189/kernel/drivers/net/wireless/rk915.ko
      break
    fi
  done
fi

msg "Done."
exit 0

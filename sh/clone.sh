#!/usr/bin/env bash
# 注意：不使用 set -e，避免命令失败时脚本意外退出

# ============================================================
# ArkOS4Clone 开机配置脚本
# 功能：设备检测、配置应用、OTA更新、国际化
# ============================================================

# ==================== 路径配置 ====================
QUIRKS_DIR="/home/ark/.quirks"
CONSOLE_FILE="/boot/.console"
CONSOLE_DETECT="/usr/local/bin/console_detect"
LOG_FILE="/boot/clone_log.txt"

# ==================== 权限检查 ====================
if [[ $EUID -ne 0 ]]; then
  echo "[clone.sh] 此脚本需要 root 权限运行，请使用: sudo $0 $@"
  exit 1
fi

# ==================== 日志函数 ====================
# 每次启动清空日志
: > "$LOG_FILE" 2>/dev/null || true
msg()  { echo "[clone.sh] $*" | tee -a "$LOG_FILE"; }
warn() { echo "[clone.sh][WARN] $*" | tee -a "$LOG_FILE" >&2; }
err()  { echo "[clone.sh][ERR ] $*" | tee -a "$LOG_FILE" >&2; }

# ==================== 设备检测 ====================
# 设备信息变量
DEVICE_NAME=""
SCREEN_WIDTH=640
SCREEN_HEIGHT=480
JOYSTICK_COUNT=2
HOTKEY_TYPE="happy5"
SCREEN_ROTATION=0
LED_TYPE="unsupported"

# ==================== 常量设置 ====================
SDL2_VERSION="libSDL2-2.0.so.0.3200.10"

detect_device() {
  if [[ -x "$CONSOLE_DETECT" ]]; then
    eval "$("$CONSOLE_DETECT" -s)"
    msg "Device: $DEVICE_NAME, ${SCREEN_WIDTH}x${SCREEN_HEIGHT}, joy=$JOYSTICK_COUNT, hotkey=$HOTKEY_TYPE, rot=$SCREEN_ROTATION, led=$LED_TYPE"
  else
    warn "console_detect not found, using defaults"
    DEVICE_NAME="r36s"
  fi
}

get_console_label() {
  tr -d '\r\n' < "$CONSOLE_FILE" 2>/dev/null || true
}

# ==================== 工具函数 ====================
cp_if_exists() {
  local src="$1" dst="$2" isfile="${3:-no}"
  [[ -e "$src" ]] || { warn "Source not found: $src"; return 1; }
  
  if [[ "$isfile" == "yes" ]]; then
    mkdir -p "$(dirname "$dst")"
    # 先删除目标文件（如果存在），确保能正确覆盖
    rm -f "$dst" 2>/dev/null || true
    # 使用 -L 解引用符号链接，确保复制实际文件
    cp -L "$src" "$dst" 2>/dev/null || install -m 0755 -D "$src" "$dst"
    sudo chmod 0755 "$dst" 2>/dev/null || true
  else
    mkdir -p "$dst"
    cp -a "$src" "$dst/"
    sudo chmod -R 0755 "$dst" 2>/dev/null || true
  fi
  sudo chown -R ark:ark "$dst" 2>/dev/null || true
  msg "Copied: $src -> $dst"
}

# ==================== OTA 更新 ====================
maybe_apply_ota_update() {
  local tar_path=""
  # 检查 update-arkos.tar 或 update-darkos.tar
  for name in update-arkos.tar update-darkos.tar; do
    [[ -f "/roms/$name" ]] && tar_path="/roms/$name" && break
    [[ -f "/roms2/$name" ]] && tar_path="/roms2/$name" && break
  done
  [[ -z "$tar_path" ]] && return 0

  # 检查升级包是否与当前系统匹配
  local is_darkos=false
  grep -q "dArkOS" /usr/share/plymouth/themes/text.plymouth 2>/dev/null && is_darkos=true
  
  if [[ "$is_darkos" == "true" && "$tar_path" != *darkos* ]]; then
    err "Mismatch: current=dArkOS, package=ArkOS. Use update-darkos.tar"
    return 0
  fi
  if [[ "$is_darkos" == "false" && "$tar_path" == *darkos* ]]; then
    err "Mismatch: current=ArkOS, package=dArkOS. Use update-arkos.tar"
    return 0
  fi

  local tmpdir="/home/ark/.ota_update" TTY="/dev/tty1"
  local ota_title="ArkOS4Clone OTA"
  [[ "$is_darkos" == "true" ]] && ota_title="dArkOS4Clone OTA"
  
  msg "OTA package found: $tar_path"
  sudo rm -rf "$tmpdir" 2>/dev/null || true
  sudo mkdir -p "$tmpdir" || { err "Failed to create OTA dir"; return 0; }

  {
    printf '\033c'
    echo "==============================="; echo "        $ota_title        "; echo "==============================="
    echo; echo "[OTA] Package: $tar_path"; echo "[OTA] Step 1/2: Extracting... (Do NOT power off)"
  } > "$TTY"

  if ! sudo tar -xf "$tar_path" -C "$tmpdir" VERSION install.sh CHUNKS META chunks 2>&1 | tee -a "$LOG_FILE" >> "$TTY"; then
    err "OTA extract failed"
    sudo rm -rf "$tmpdir" 2>/dev/null || true
    return 0
  fi

  echo "[OTA] Step 2/2: Running install.sh" >> "$TTY"
  [[ -f "$tmpdir/install.sh" ]] || { err "install.sh not found"; sudo rm -rf "$tmpdir"; return 0; }
  sudo chmod +x "$tmpdir/install.sh"
  
  if ! sudo env OTA_TAR_PATH="$tar_path" LOG_FILE="$LOG_FILE" bash "$tmpdir/install.sh" 2>&1 | tee -a "$LOG_FILE" >> "$TTY"; then
    err "OTA install failed"
    sudo rm -rf "$tmpdir" 2>/dev/null || true
    return 0
  fi

  sudo rm -f "$tar_path" 2>/dev/null || true
  sudo rm -rf "$tmpdir" 2>/dev/null || true
  sudo rm -f "$CONSOLE_FILE" 2>/dev/null || true
  sync

  {
    echo; echo "[OTA] SUCCESS"; echo "[OTA] Update package removed"
    for i in {10..1}; do echo "[OTA] Powering off in ${i}s..."; sleep 1; done
  } >> "$TTY"

  msg "OTA applied, powering off"
  sleep 2; poweroff -f || true; exit 0
}

# ==================== 配置应用函数 ====================
apply_hotkey_conf() {
  msg "apply_hotkey_conf: HOTKEY_TYPE=$HOTKEY_TYPE"
  local ogage_conf ra_conf="$QUIRKS_DIR/retroarch64.cfg" ra32_conf="$QUIRKS_DIR/retroarch32.cfg"

  # 根据 HOTKEY_TYPE 选择 ogage 配置
  case "$HOTKEY_TYPE" in
    select) 
      ogage_conf="$QUIRKS_DIR/ogage.select.conf"
      hotkey_btn="12"
      ;;
    happy5) 
      ogage_conf="$QUIRKS_DIR/ogage.happy5.conf"
      hotkey_btn="16"
      ;;
    *)      
      ogage_conf=""
      hotkey_btn=""
      ;;
  esac

  # 复制 ogage 配置
  [[ -n "$ogage_conf" ]] && cp_if_exists "$ogage_conf" "/home/ark/ogage.conf" "yes"
  
  # 复制 RetroArch 配置
  cp_if_exists "$ra_conf" "/home/ark/.config/retroarch/retroarch.cfg" "yes" || true
  cp_if_exists "$ra32_conf" "/home/ark/.config/retroarch32/retroarch.cfg" "yes" || true
  
  # 根据热键类型修改 input_enable_hotkey_btn
  if [[ -n "$hotkey_btn" ]]; then
    msg "Setting input_enable_hotkey_btn = $hotkey_btn for HOTKEY_TYPE=$HOTKEY_TYPE"
    for cfg in /home/ark/.config/retroarch/retroarch.cfg /home/ark/.config/retroarch32/retroarch.cfg; do
      [[ -f "$cfg" ]] || continue
      if grep -q '^input_enable_hotkey_btn' "$cfg" 2>/dev/null; then
        sed -i 's/^input_enable_hotkey_btn = ".*"/input_enable_hotkey_btn = "'"$hotkey_btn"'"/' "$cfg" 2>/dev/null
      else
        echo "input_enable_hotkey_btn = \"$hotkey_btn\"" >> "$cfg"
      fi
    done
    msg "Set hotkey_btn=$hotkey_btn in RetroArch configs"
  fi
}

apply_ppsspp_config() {
  local joy_type="$1" roms_dir
  for roms_dir in "/roms/psp" "/roms2/psp" "/opt/ppsspp/backupforromsfolder"; do
    [[ -d "$roms_dir" ]] || continue
    local target="$roms_dir/ppsspp/PSP/SYSTEM"
    cp_if_exists "$QUIRKS_DIR/${joy_type}Joy/controls.ini"     "$target/controls.ini"       "yes" || true
    cp_if_exists "$QUIRKS_DIR/${joy_type}Joy/ppsspp.ini"       "$target/ppsspp.ini"         "yes" || true
    cp_if_exists "$QUIRKS_DIR/${joy_type}Joy/ppsspp.ini.sdl"   "$target/ppsspp.ini.sdl"     "yes" || true
  done
}

apply_joy_conf() {
  msg "apply_joy_conf: JOYSTICK_COUNT=$JOYSTICK_COUNT"

  # 根据是否存在双摇杆进行按键映射
  case "$JOYSTICK_COUNT" in
    0|1) apply_ppsspp_config "none" ;;
    2)   apply_ppsspp_config "dual" ;;
  esac
}

apply_input() {
  msg "apply_input: CONSOLE_FILE=$CONSOLE_FILE"

  # 复制 RA ES 的默认输入 
  cp_if_exists "$QUIRKS_DIR/retroarch64.cfg" "/home/ark/.config/retroarch/retroarch.cfg" "yes" || true
  cp_if_exists "$QUIRKS_DIR/retroarch32.cfg" "/home/ark/.config/retroarch32/retroarch.cfg" "yes" || true
  cp_if_exists "$QUIRKS_DIR/es_input.cfg" "/etc/emulationstation/es_input.cfg" "yes" || true

  # 调整布局为 OZONE
  for cfg in /home/ark/.config/retroarch*/retroarch.cfg*; do
    sed -i 's/menu_driver = ".*"/menu_driver = "ozone"/' "$cfg" 2>/dev/null || true
  done
}

apply_sdl_rotation() {
  local angle="$1"
  local sdl32="/usr/lib/arm-linux-gnueabihf/$SDL2_VERSION"
  local sdl64="/usr/lib/aarch64-linux-gnu/$SDL2_VERSION"
  
  # 角度为 0 时使用 norotate 文件恢复原始库
  if [[ "$angle" == "0" ]]; then
    msg "Restoring original SDL (no rotation)"
    local src32="$QUIRKS_DIR/rotate/sdl2/32/$SDL2_VERSION.norotate"
    local src64="$QUIRKS_DIR/rotate/sdl2/64/$SDL2_VERSION.norotate"
    local ra_suffix="norotate"
  else
    local src32="$QUIRKS_DIR/rotate/sdl2/32/$SDL2_VERSION.rotate${angle}"
    local src64="$QUIRKS_DIR/rotate/sdl2/64/$SDL2_VERSION.rotate${angle}"
    local ra_suffix="$angle"
  fi
  
  # 检查源文件类型并记录
  if [[ -L "$src64" ]]; then
    msg "Source (64bit) is symlink: $src64 -> $(readlink "$src64")"
  elif [[ -f "$src64" ]]; then
    msg "Source (64bit) is regular file: $src64 ($(stat -c%s "$src64" 2>/dev/null || echo "unknown") bytes)"
  fi
  
  # 删除目标位置的符号链接（如果存在）
  rm -f "$sdl64" "$sdl32" 2>/dev/null || true
  
  # 复制实际文件
  cp_if_exists "$src64" "$sdl64" "yes" || true
  cp_if_exists "$src32" "$sdl32" "yes" || true
  
  # 重建符号链接（正确的链接方向）
  # libSDL2.so -> libSDL2-2.0.so -> libSDL2-2.0.so.0 -> $SDL2_VERSION (实际文件)
  msg "Rebuilding SDL2 symlinks..."
  local sdl64_dir="${sdl64%/*}"
  local sdl32_dir="${sdl32%/*}"
  
  # 64-bit links
  ln -sf "$(basename $sdl64)" "$sdl64_dir/libSDL2-2.0.so.0" && msg "  Created: libSDL2-2.0.so.0 -> $(basename $sdl64)" || warn "  Failed: libSDL2-2.0.so.0"
  ln -sf "libSDL2-2.0.so.0" "$sdl64_dir/libSDL2-2.0.so" && msg "  Created: libSDL2-2.0.so -> libSDL2-2.0.so.0" || warn "  Failed: libSDL2-2.0.so"
  ln -sf "libSDL2-2.0.so" "$sdl64_dir/libSDL2.so" && msg "  Created: libSDL2.so -> libSDL2-2.0.so" || warn "  Failed: libSDL2.so"
  
  # 32-bit links
  ln -sf "$(basename $sdl32)" "$sdl32_dir/libSDL2-2.0.so.0" && msg "  Created: libSDL2-2.0.so.0 -> $(basename $sdl32)" || warn "  Failed: libSDL2-2.0.so.0 (32)"
  ln -sf "libSDL2-2.0.so.0" "$sdl32_dir/libSDL2-2.0.so" && msg "  Created: libSDL2-2.0.so -> libSDL2-2.0.so.0 (32)" || warn "  Failed: libSDL2-2.0.so (32)"
  ln -sf "libSDL2-2.0.so" "$sdl32_dir/libSDL2.so" && msg "  Created: libSDL2.so -> libSDL2-2.0.so (32)" || warn "  Failed: libSDL2.so (32)"
}

apply_rotate_file() {
  msg "Screen rotation: $SCREEN_ROTATION degrees"
  apply_sdl_rotation "$SCREEN_ROTATION"
}

apply_all_quirks() {
  msg "Applying quirks for: $DEVICE_NAME"
  msg "QUIRKS_DIR: $QUIRKS_DIR"
  if [[ -d "$QUIRKS_DIR" ]]; then
    msg "Quirks directory exists, contents:"
    ls -la "$QUIRKS_DIR" 2>&1 | tee -a "$LOG_FILE" || true
    # ES RA 文件替换
    apply_input
    # PPSSPP 快捷键映射
    apply_joy_conf
    # RA OGAGE 快捷键映射
    apply_hotkey_conf
    # SDL2 旋转
    apply_rotate_file
  else
    warn "QUIRKS_DIR does not exist: $QUIRKS_DIR"
  fi
}

# ==================== 音频配置 ====================
setup_audio() {
  local state; state="$(amixer get 'Playback Path' 2>/dev/null | grep -oP "Item0: '\K\w+" || true)"
  if [[ "$state" == "OFF" || "$state" == "HP" ]]; then
    msg "Switching audio to SPK"
    amixer set 'Playback Path' 'SPK' || true
    sudo alsactl store || true
  fi
  cp_if_exists "$QUIRKS_DIR/asoundrc" "/home/ark/.asoundrc" "yes" || true
}

# ==================== 国际化配置 ====================
apply_localization() {
  local lang="$1" es_lang ra_lang ppsspp_lang timezone
  # ES 语言 RA 语言 ppsspp语言 时区
  case "$lang" in
    cn) es_lang="zh-CN"; ra_lang="12"; ppsspp_lang="zh_CN"; timezone="Asia/Shanghai" ;;
    ko) es_lang="ko";    ra_lang="10"; ppsspp_lang="ko_KR"; timezone="Asia/Seoul" ;;
    *)  return 0 ;;
  esac

  msg "Applying $lang localization"
  
  # EmulationStation
  local es_cfg="/home/ark/.emulationstation/es_settings.cfg"
  if grep -q "Language" "$es_cfg" 2>/dev/null; then
    sed -i "s/<string name=\"Language\" value=\"[^\"]*\"/<string name=\"Language\" value=\"$es_lang\"/" "$es_cfg" || true
  else
    echo "<string name=\"Language\" value=\"$es_lang\" />" >> "$es_cfg"
  fi

  # Timezone
  sudo rm -f /etc/localtime
  ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime

  # PPSSPP
  for dir in /opt/ppsspp/backupforromsfolder/ppsspp/PSP/SYSTEM /roms/psp/ppsspp/PSP/SYSTEM /roms2/psp/ppsspp/PSP/SYSTEM; do
    [[ -d "$dir" ]] || continue
    for ini in ppsspp.ini ppsspp.ini.go ppsspp.ini.sdl; do
      sed -i "s/Language = en_US/Language = $ppsspp_lang/g" "$dir/$ini" 2>/dev/null || true
    done
  done

  # RetroArch
  for cfg in /home/ark/.config/retroarch/retroarch.cfg /home/ark/.config/retroarch32/retroarch.cfg; do
    sed -i "s/user_language = \"[^\"]*\"/user_language = \"$ra_lang\"/" "$cfg" 2>/dev/null || true
    sed -i "s/user_language = \"[^\"]*\"/user_language = \"$ra_lang\"/" "${cfg}.bak" 2>/dev/null || true
  done

  # option 单独处理
  sudo rm -f "/opt/system/gamelist.xml"
  [[ "$lang" == "cn" ]] && cp_if_exists "$QUIRKS_DIR/option-gamelist.xml" "/opt/system/gamelist.xml" "yes" || true
}

# ==================== 主流程 ====================
main() {
  # 在调用 console_detect 之前先记录 .console 是否存在
  local first_boot="no"
  [[ ! -f "$CONSOLE_FILE" ]] && first_boot="yes"
  
  # 获取 boot.ini 检测的设备名（用于检测 DTB 变化）
  local bootini_device=""
  if [[ -x "$CONSOLE_DETECT" ]]; then
    bootini_device="$("$CONSOLE_DETECT" -b 2>/dev/null || true)"
  fi
  
  # 设备检测
  detect_device

  # OTA 检查
  maybe_apply_ota_update

  # 处理 .console 文件
  local cur_val; cur_val="$(get_console_label)"
  
  # 检测 DTB 是否变化（boot.ini 设备与 .console 不同）
  local dtb_changed="no"
  if [[ -n "$bootini_device" && "$cur_val" != "$bootini_device" ]]; then
    dtb_changed="yes"
    msg "DTB changed detected: .console=$cur_val, boot.ini=$bootini_device"
  fi
  
  if [[ "$first_boot" == "yes" ]]; then
    # 首次启动
    printf '\033c'
    echo "==============================="; echo "   arkos for clone lcdyk  ..."; echo "==============================="
    sleep 2
    # sudo chown -R ark:ark "$QUIRKS_DIR" > /dev/null
    echo "$DEVICE_NAME" | sudo tee "$CONSOLE_FILE"  2>/dev/null || true
    msg "First boot, device=$DEVICE_NAME"
    echo "$DEVICE_NAME" | sudo tee /etc/hostname >/dev/null
    sudo hostnamectl set-hostname "$DEVICE_NAME" || true
    # 更新挂载点下的 /etc/hosts（不存在才添加）
    if ! grep -q "127.0.1.1.*$DEVICE_NAME" "/etc/hosts" 2>/dev/null; then
        sudo sed -i "/127.0.1.1/d" "/etc/hosts"
        echo "127.0.1.1    $DEVICE_NAME" | sudo tee -a "/etc/hosts" >/dev/null
    fi
    apply_all_quirks
    sleep 5
    sudo systemctl unmask systemd-journald.service systemd-journald.socket 2>/dev/null || true
    sudo systemctl enable --now systemd-journald.service systemd-journald.socket 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true
    # 驱动加载
    msg "Running depmod -a"
    sudo depmod -a 2>/dev/null || true
  elif [[ "$dtb_changed" == "yes" || "$cur_val" != "$DEVICE_NAME" ]]; then
    # 设备切换（DTB 变化或机型变化）
    local new_device old_device
    if [[ "$dtb_changed" == "yes" ]]; then
      old_device="$cur_val"
      new_device="$bootini_device"
      msg "DTB changed: $old_device -> $new_device"
      # 更新 .console 文件
      echo "$bootini_device" | sudo tee "$CONSOLE_FILE" > /dev/null
      # 重新检测设备信息（因为设备变了）
      if [[ -x "$CONSOLE_DETECT" ]]; then
        eval "$("$CONSOLE_DETECT" -s)"
        msg "Re-detected: $DEVICE_NAME, ${SCREEN_WIDTH}x${SCREEN_HEIGHT}, joy=$JOYSTICK_COUNT, hotkey=$HOTKEY_TYPE, rot=$SCREEN_ROTATION, led=$LED_TYPE"
      fi
    else
      old_device="$cur_val"
      new_device="$DEVICE_NAME"
      msg "Console changed: $old_device -> $new_device"
      echo "$DEVICE_NAME" | sudo tee "$CONSOLE_FILE" > /dev/null
    fi
    echo "$bootini_device" | sudo tee /etc/hostname >/dev/null
    sudo hostnamectl set-hostname "$bootini_device" || true
    # 更新挂载点下的 /etc/hosts（不存在才添加）
    if ! grep -q "127.0.1.1.*$bootini_device" "/etc/hosts" 2>/dev/null; then
        sudo sed -i "/127.0.1.1/d" "/etc/hosts"
        echo "127.0.1.1    $bootini_device" | sudo tee -a "/etc/hosts" >/dev/null
    fi
    sudo systemctl daemon-reload 2>/dev/null || true
    # 驱动加载
    msg "Running depmod -a"
    sudo depmod -a 2>/dev/null || true
    (
      printf '\033c'
      echo "==============================="; echo "   arkos for clone lcdyk  ..."; echo "==============================="
      echo; echo "Device changed!"; echo "old: $old_device"; echo "new: $new_device"
      apply_all_quirks
      sleep 5
    ) > /dev/tty1 2>&1
    sudo systemctl unmask systemd-journald.service systemd-journald.socket 2>/dev/null || true
    sudo systemctl enable --now systemd-journald.service systemd-journald.socket 2>/dev/null || true
  else
    msg "Console unchanged: $cur_val"
  fi

  # 音频配置
  setup_audio

  # 国际化
  [[ -f "/boot/.cn" ]] && { apply_localization "cn"; sudo rm -f /boot/.cn; }
  [[ -f "/boot/.ko" ]] && { apply_localization "ko"; sudo rm -f /boot/.ko; }

  # Last game
  if [[ -x /home/ark/.config/lastgame.sh ]]; then
      msg "Executing lastgame.sh..."
      sudo -u ark /home/ark/.config/lastgame.sh
      msg "lastgame.sh completed"
  else
      msg "lastgame.sh not found or not executable"
  fi

  msg "Done. device=$DEVICE_NAME"
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

# =============== DTB -> LABEL 映射（按你的表）===============
# 从 /boot/boot.ini 中匹配：load mmc 1:1 ${dtb_loadaddr} <DTB>
BOOTINI="/boot/boot.ini"
DTB="$(grep -oE 'load[[:space:]]+mmc[[:space:]]+1:1[[:space:]]+\$\{dtb_loadaddr\}[[:space:]]+[[:graph:]]+' "$BOOTINI" \
      | awk '{print $NF}' | tail -n1 | xargs basename || true)"

case "$DTB" in
  rk3326-mymini-linux.dtb)   LABEL="mymini" ;;
  rk3326-r36max-linux.dtb)   LABEL="r36max" ;;
  rk3326-xf35h-linux.dtb)    LABEL="xf35h" ;;
  rk3326-xf36pro-linux.dtb)  LABEL="r36pro" ;;
  rk3326-xf40h-linux.dtb)    LABEL="xf40h" ;;
  rk3326-xf40v-linux.dtb)    LABEL="xf40v" ;;
  rk3326-hg36-linux.dtb)     LABEL="r36pro" ;;
  *)                         LABEL="r36s"   ;;  # 默认
esac
rk915_set=("xf40h" "xf40v" "xf35h")   # 按需增删
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

# 如果源存在则复制；isfile=yes 时以文件目标安装（保持权限 0644）
cp_if_exists() {
  local src="$1" dst="$2" isfile="${3:-no}"
  if [[ -e "$src" ]]; then
    if [[ "$isfile" == "yes" ]]; then
      install -m 0644 -D "$src" "$dst"
    else
      mkdir -p "$dst"
      cp -a "$src" "$dst/"
    fi
    msg "Copied: $src -> $dst"
  else
    warn "Source not found, skip: $src"
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

  # 5) fix_pad.sh
  if [[ -f "$FIXPAD_PATH" ]]; then
    chmod 0777 "$FIXPAD_PATH" || warn "chmod failed on $FIXPAD_PATH"
    local padfile="$base/$PAD_NAME"
    if [[ -f "$padfile" ]]; then
      # 全盘：把最后的 / 改成 . 可做局部测试
      "$FIXPAD_PATH" "$padfile" /
    else
      warn "pad.txt not found: $padfile (skip fix_pad)"
    fi
  else
    warn "fix_pad.sh not found: $FIXPAD_PATH"
  fi
}

# =============== 执行开始 ===============
msg "DTB filename: ${DTB:-<empty>}, LABEL: $LABEL"

# 先同步 /boot/consoles -> ~/.quirks（有 rsync 用 rsync）
if [[ -d "$SRC_CONSOLES_DIR" ]]; then
  mkdir -p "$QUIRKS_DIR"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$SRC_CONSOLES_DIR"/ "$QUIRKS_DIR"/
  else
    cp -a "$SRC_CONSOLES_DIR"/. "$QUIRKS_DIR"/
  fi
  # 删除源目录（复制完成后）
  rm -rf "$SRC_CONSOLES_DIR"
  msg "Consoles synced to: $QUIRKS_DIR"
else
  warn "Consoles dir not found: $SRC_CONSOLES_DIR (continue)"
fi

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
else
  CUR_VAL="$(tr -d '\r\n' < "$CONSOLE_FILE" || true)"
  if [[ "$CUR_VAL" == "$LABEL" ]]; then
    msg "Console unchanged ($CUR_VAL); nothing to do."
  else
    msg "Console changed: $CUR_VAL -> $LABEL; applying new quirks."
    echo "$LABEL" > "$CONSOLE_FILE"
    apply_quirks_for "$LABEL"
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

#!/usr/bin/env bash
set -euo pipefail

# ============================================
# ArkOS4Clone OTA 升级包制作脚本（保持原有流程）
#
# 输出文件：
#   ./update.tar   （放到设备 /roms/update.tar）
#
# update.tar 内部结构：
#   VERSION
#   install.sh      # 设备端执行（流式抽取 chunks/ 与 uboot/）
#   META            # (新增) 只描述“本次交付文件”的权限/属主要求
#   CHUNKS
#   chunks/
#     00_boot.tar
#     10_root_usr_etc.tar
#     20_root_opt.tar
#     30_root_home.tar
#     40_root_misc.tar
#   uboot/
#     idbloader.img
#     uboot.img
#     trust.img
#
# 关键目标：
# - 不改变你原本“做哪些事”的流程（包含 uboot 刷写、清理、删除等）
# - 复制阶段不改任何“已有文件/目录”的权限属主
# - 仅对“本次 OTA 交付的文件”按离线注入脚本修正权限/属主（通过 META）
# ============================================

# 生成版本信息
UPDATE_DATE="$(TZ=Asia/Shanghai date +%m%d%Y)"
MODDER="kk&lcdyk"
VERSION="ArkOS4Clone-${UPDATE_DATE}-${MODDER}"

# 工作目录与临时构建目录
WORKDIR="$(pwd)"
STAGE="/tmp/_ota_stage"
PAYLOAD_BOOT="${STAGE}/payload/boot"
PAYLOAD_ROOT="${STAGE}/payload/root"
OUT_TAR="${WORKDIR}/update.tar"

# boot 分区（FAT32）专用 rsync 参数（不保存 owner/perms）
RSYNC_BOOT_OPTS="-rltD --no-owner --no-group --no-perms --omit-dir-times"

# ----------------- helpers -----------------
copy_file() { local src="$1" dstdir="$2"; [[ -e "$src" ]] || return 0; mkdir -p "$dstdir"; cp -f "$src" "$dstdir/"; }
copy_tree() { local src="$1" dstdir="$2"; [[ -e "$src" ]] || return 0; mkdir -p "$dstdir"; cp -a "$src" "$dstdir/"; }
copy_tree_contents() { local srcdir="$1" dstdir="$2"; [[ -d "$srcdir" ]] || return 0; mkdir -p "$dstdir"; cp -a "$srcdir"/. "$dstdir"/; }

# ----------------- META generator -----------------
META_FILE="${STAGE}/META"
meta_init() {
  : > "$META_FILE"
  {
    echo "# META: permissions/ownership for files delivered by this OTA"
    echo "# format: MODE UID:GID PATH"
    echo "# MODE can be ---- (means: only chown, do not chmod)"
  } >> "$META_FILE"
}
meta_add() { printf "%s %s %s\n" "$1" "$2" "$3" >> "$META_FILE"; }
meta_finalize_dedupe() {
  grep -v '^[[:space:]]*$' "$META_FILE" | awk '!seen[$0]++' > "${META_FILE}.tmp"
  mv -f "${META_FILE}.tmp" "$META_FILE"
}

# 清理旧的构建目录
rm -rf "$STAGE"
mkdir -p "$PAYLOAD_BOOT" "$PAYLOAD_ROOT"

echo "== 构建 payload/boot =="

# consoles -> /boot/consoles（排除 consoles/files）
mkdir -p "$PAYLOAD_BOOT/consoles"
# shellcheck disable=SC2086
rsync $RSYNC_BOOT_OPTS --exclude='files' ./consoles/ "$PAYLOAD_BOOT/consoles/"

# clone.sh 在 OTA 中必须直接生成为 /boot/firstboot.sh
cp -f ./sh/clone.sh "$PAYLOAD_BOOT/firstboot.sh"

# 其他 boot 工具保持原文件名
cp -f ./dtb_selector_macos \
      ./dtb_selector_win32.exe \
      "$PAYLOAD_BOOT/" 2>/dev/null || true

# DTB 选择器提示标记文件
touch "$PAYLOAD_BOOT/USE_DTB_SELECT_TO_SELECT_DEVICE" 2>/dev/null || true

echo "== 构建 payload/root =="

echo "== 注入设备怪癖 =="
mkdir -p "$PAYLOAD_ROOT/home/ark/.quirks"
cp -r ./consoles/files/* "$PAYLOAD_ROOT/home/ark/.quirks/" 2>/dev/null || true

echo "== 注入 Clone 配置与工具 =="
mkdir -p "$PAYLOAD_ROOT/usr/bin" \
         "$PAYLOAD_ROOT/usr/local/bin"
cp -f ./bin/mcu_led ./bin/ws2812 "$PAYLOAD_ROOT/usr/bin/" 2>/dev/null || true
cp -f ./bin/sdljoymap ./bin/sdljoytest "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -f ./bin/console_detect "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

echo "== 注入 rk915 固件 =="
mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware/"
cp -f ./bin/rk915_*.bin "$PAYLOAD_ROOT/usr/lib/firmware/" 2>/dev/null || true

echo "== 注入 aic8800DC 固件 =="
mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware/aic8800DC"
cp -f ./bin/aic8800DC/* "$PAYLOAD_ROOT/usr/lib/firmware/aic8800DC/" 2>/dev/null || true

echo "== 注入 351Files 资源 =="
mkdir -p "$PAYLOAD_ROOT/opt/351Files/res"
cp -r ./res/* "$PAYLOAD_ROOT/opt/351Files/res/" 2>/dev/null || true

echo "== 注入启动脚本（replace_file/*.sh） =="
mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
cp -f ./replace_file/*.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

echo "== 注入 adc-key 服务 =="
mkdir -p "$PAYLOAD_ROOT/etc/systemd/system"
cp -f ./bin/adc-key/adckeys.py "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -f ./bin/adc-key/adckeys.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -f ./bin/adc-key/adckeys.service "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true

echo "== 注入核心与 EmulationStation 文件 =="
mkdir -p "$PAYLOAD_ROOT/home/ark/.config/retroarch/cores" \
         "$PAYLOAD_ROOT/home/ark/.config/retroarch32/cores" \
         "$PAYLOAD_ROOT/etc/emulationstation" \
         "$PAYLOAD_ROOT/usr/bin/emulationstation/resources/"
cp -f ./mod_so/64/* "$PAYLOAD_ROOT/home/ark/.config/retroarch/cores/" 2>/dev/null || true
cp -f ./mod_so/32/* "$PAYLOAD_ROOT/home/ark/.config/retroarch32/cores/" 2>/dev/null || true
cp -f ./replace_file/es_systems.cfg "$PAYLOAD_ROOT/etc/emulationstation/" 2>/dev/null || true
cp -f ./replace_file/es_systems.cfg.dual "$PAYLOAD_ROOT/etc/emulationstation/" 2>/dev/null || true
cp -rf ./replace_file/resources/* \
      "$PAYLOAD_ROOT/usr/bin/emulationstation/resources/" 2>/dev/null || true

# 注意：es_input.cfg 的删除在 install.sh 中完成
mkdir -p "$PAYLOAD_ROOT/usr/bin/emulationstation"
cp -r ./replace_file/emulationstation \
      "$PAYLOAD_ROOT/usr/bin/emulationstation/emulationstation" 2>/dev/null || true

echo "== 注入 drastic =="
mkdir -p "$PAYLOAD_ROOT/opt/drastic"
cp -a ./replace_file/drastic/. "$PAYLOAD_ROOT/opt/drastic/" 2>/dev/null || true
rm -rf "$PAYLOAD_ROOT/opt/drastic/patch" 2>/dev/null || true

echo "== 注入 drastic-kk =="
mkdir -p "$PAYLOAD_ROOT/opt/drastic-kk"
cp -a ./replace_file/drastic-kk/. "$PAYLOAD_ROOT/opt/drastic-kk/" 2>/dev/null || true
rm -rf "$PAYLOAD_ROOT/opt/drastic-kk/patch" 2>/dev/null || true

echo "== 注入 json-c3 库（drastic-kk 依赖） =="
mkdir -p "$PAYLOAD_ROOT/usr/lib/aarch64-linux-gnu/"
cp -f ./bin/json-c3/* "$PAYLOAD_ROOT/usr/lib/aarch64-linux-gnu/" 2>/dev/null || true

echo "== 更新 PPSSPP1.20.2 =="
mkdir -p "$PAYLOAD_ROOT/opt/ppsspp"
cp -a ./replace_file/ppsspp/. "$PAYLOAD_ROOT/opt/ppsspp/" 2>/dev/null || true

echo "== 更新 ScummVM v2026.1.0 =="
mkdir -p "$PAYLOAD_ROOT/opt/scummvm"
cp -a ./replace_file/scummvm/. "$PAYLOAD_ROOT/opt/scummvm/" 2>/dev/null || true

echo "== 注入 retrorun =="
mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
cp -r ./replace_file/retrorun/retrorun32 "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -r ./replace_file/retrorun/retrorun "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

echo "== 注入 pymo =="
cp -r ./replace_file/pymo/cpymo "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -r ./replace_file/pymo/pymo.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
# mkdir -p "$PAYLOAD_ROOT/tempthemes/es-theme-nes-box"
# cp -r ./replace_file/pymo/pymo \
#       "$PAYLOAD_ROOT/tempthemes/es-theme-nes-box/" 2>/dev/null || true

echo "== 注入 ogage =="
cp -r ./replace_file/ogage "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
mkdir -p "$PAYLOAD_ROOT/home/ark/.quirks"
cp -r ./replace_file/ogage "$PAYLOAD_ROOT/home/ark/.quirks/" 2>/dev/null || true

echo "== 注入 services / tools =="
mkdir -p "$PAYLOAD_ROOT/etc/systemd/system" \
         "$PAYLOAD_ROOT/opt/system/Advanced" \
         "$PAYLOAD_ROOT/usr/local/bin"
cp -r ./replace_file/services/351mp.service \
      "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true
cp -r "./replace_file/tools/Enable Quick Mode.sh" \
      "$PAYLOAD_ROOT/opt/system/Advanced/" 2>/dev/null || true
cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" \
      "$PAYLOAD_ROOT/opt/system/Advanced/" 2>/dev/null || true
cp -r "./replace_file/tools/Enable Quick Mode.sh" \
      "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -r "./replace_file/tools/Disable Quick Mode.sh" \
      "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -r "./replace_file/tools/Switch to main SD for Roms.sh" \
      "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" \
      "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

# ========= 新增：复制 replace_file/modules -> /usr/lib/modules =========
echo "== 注入 modules（replace_file/modules -> /usr/lib/modules） =="
if [[ -d "./replace_file/modules" ]]; then
  mkdir -p "$PAYLOAD_ROOT/usr/lib/modules"
  cp -a ./replace_file/modules/. "$PAYLOAD_ROOT/usr/lib/modules/" 2>/dev/null || true
fi

echo "== 注入 Jason3_Scripte 工具 =="
mkdir -p "$PAYLOAD_ROOT/opt/system/Tools"
cp -r "./Jason3_Scripte/wifi-toggle/Wifi-toggle.sh" "$PAYLOAD_ROOT/opt/system/Wifi-Toggle.sh" 2>/dev/null || true
cp -r "./Jason3_Scripte/InfoSystem/InfoSystem.sh" "$PAYLOAD_ROOT/opt/system/Tools/System Info.sh" 2>/dev/null || true
cp -r "./Jason3_Scripte/GhostLoader/GhostLoader.sh" "$PAYLOAD_ROOT/opt/system/Tools/Ghost Loader.sh" 2>/dev/null || true
cp -r "./Jason3_Scripte/Bluetooth-Manager/Bluetooth Manager.sh" "$PAYLOAD_ROOT/opt/system/Tools/" 2>/dev/null || true
cp -r "./Jason3_Scripte/Bluetooth-Manager/patch.pak" "$PAYLOAD_ROOT/opt/system/Tools/" 2>/dev/null || true

# ========= ROMS.TAR 被明确排除（OTA 不处理用户数据） =========
echo "== 跳过 roms.tar（设计如此） =="

# -----------------------------
# 写入 VERSION / META / install.sh
# -----------------------------
echo "== 写入 VERSION / META / install.sh =="

cat > "$STAGE/VERSION" <<EOF
$VERSION
EOF

# ---- META：只描述“本次交付文件”的权限/属主（对齐离线注入脚本）----
meta_init

# quirks：chown + 777
meta_add "0777" "1002:1002" "/home/ark/.quirks/*"

# Tools：chown + 777
meta_add "0777" "1002:1002" "/usr/bin/mcu_led"
meta_add "0777" "1002:1002" "/usr/bin/ws2812"
meta_add "0777" "1002:1002" "/usr/local/bin/sdljoytest"
meta_add "0777" "1002:1002" "/usr/local/bin/sdljoymap"
meta_add "0777" "1002:1002" "/usr/local/bin/console_detect"

# rk915 固件 777
meta_add "0777" "1002:1002" "/usr/lib/firmware/rk915_*.bin"

# 351Files：chown + 777（并会在 install.sh 做 351Files -> old 的重命名）
meta_add "0777" "1002:1002" "/opt/351Files"
meta_add "0777" "1002:1002" "/opt/351Files/*"

# replace_file/*.sh 中那 10 个：1002:1002 + 777
for f in atomiswave.sh dreamcast.sh naomi.sh saturn.sh n64.sh pico8.sh drastic.sh drastic_kk.sh choose_drastic_ver.sh mediaplayer.sh get_last_played.sh; do
  meta_add "0777" "1002:1002" "/usr/local/bin/$f"
done

# adckeys：py/sh/service 全部 777
meta_add "0777" "1002:1002" "/usr/local/bin/adckeys.py"
meta_add "0777" "1002:1002" "/usr/local/bin/adckeys.sh"
meta_add "0777" "1002:1002" "/etc/systemd/system/adckeys.service"

# cores：chown + 777
meta_add "0777" "1002:1002" "/home/ark/.config/retroarch/cores/*"
meta_add "0777" "1002:1002" "/home/ark/.config/retroarch32/cores/*"

# ES cfg：777（owner 你离线没强制，按 ark 用户更合理，这里跟随 1002:1002）
meta_add "0777" "1002:1002" "/etc/emulationstation/es_systems.cfg"
meta_add "0777" "1002:1002" "/etc/emulationstation/es_systems.cfg.dual"

# drastic：1002:1002 + 777
meta_add "0777" "1002:1002" "/opt/drastic"
meta_add "0777" "1002:1002" "/opt/drastic/*"

# drastic-kk：1002:1002 + 777
meta_add "0777" "1002:1002" "/opt/drastic-kk"
meta_add "0777" "1002:1002" "/opt/drastic-kk/*"

# ppsspp1.21.1：1002:1002 + 777
meta_add "0777" "1002:1002" "/opt/ppsspp"
meta_add "0777" "1002:1002" "/opt/ppsspp/*"

# ScummVM v2026.1.0：1002:1002 + 777
meta_add "0777" "1002:1002" "/opt/scummvm"
meta_add "0777" "1002:1002" "/opt/scummvm/*"

# json-c3 库：1002:1002 + 777
meta_add "0777" "1002:1002" "/usr/lib/aarch64-linux-gnu/libjson-c.so*"

# pymo：777
meta_add "0777" "1002:1002" "/usr/local/bin/cpymo"
meta_add "0777" "1002:1002" "/usr/local/bin/pymo.sh"

# Jason3_Scripte 工具：777
meta_add "0777" "1002:1002" "/opt/system/Wifi-Toggle.sh"
meta_add "0777" "1002:1002" "/opt/system/Tools/*.sh"
meta_add "0777" "1002:1002" "/opt/system/Tools/patch.pak"

# /opt/system 下脚本权限：777
meta_add "0777" "1002:1002" "/opt/system/*.sh"
meta_add "0777" "1002:1002" "/opt/system/Advanced/*.sh"

# aic8800DC 固件：777
meta_add "0777" "1002:1002" "/usr/lib/firmware/aic8800DC"
meta_add "0777" "1002:1002" "/usr/lib/firmware/aic8800DC/*"

# resources：777
meta_add "0777" "1002:1002" "/usr/bin/emulationstation/resources"
meta_add "0777" "1002:1002" "/usr/bin/emulationstation/resources/*"

# emulationstation：777
meta_add "0777" "1002:1002" "/usr/bin/emulationstation/emulationstation"
meta_add "0777" "1002:1002" "/usr/bin/emulationstation/emulationstation/*"

# retrorun：777
meta_add "0777" "1002:1002" "/usr/local/bin/retrorun32"
meta_add "0777" "1002:1002" "/usr/local/bin/retrorun"

# ogage：777
meta_add "0777" "1002:1002" "/usr/local/bin/ogage"
meta_add "0777" "1002:1002" "/home/ark/.quirks/ogage"

# pymo theme：777
meta_add "0777" "1002:1002" "/tempthemes/es-theme-nes-box/pymo"

# services：777
meta_add "0777" "1002:1002" "/etc/systemd/system/351mp.service"
meta_add "0777" "1002:1002" "/lib/systemd/system/mpv.service"

# tools scripts：777
meta_add "0777" "1002:1002" "/usr/local/bin/Enable Quick Mode.sh"
meta_add "0777" "1002:1002" "/usr/local/bin/Disable Quick Mode.sh"
meta_add "0777" "1002:1002" "/usr/local/bin/Switch to main SD for Roms.sh"
meta_add "0777" "1002:1002" "/usr/local/bin/Switch to SD2 for Roms.sh"

# modules：777
meta_add "0777" "1002:1002" "/usr/lib/modules"

meta_finalize_dedupe

# -----------------------------
# install.sh（保持原有做事，改权限方式为 META）
# -----------------------------
cat > "$STAGE/install.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$BASE/payload"

OTA_TAR_PATH="${OTA_TAR_PATH:-}"
CHUNKS_FILE="$BASE/CHUNKS"
META_FILE="$BASE/META"
LOG_FILE="${LOG_FILE:-/boot/clone_log.txt}"
OTA_LOG="/roms/update.log"

# 日志函数：同时输出到控制台和日志文件
log() {
  local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $*" | tee -a "$OTA_LOG" | tee -a "$LOG_FILE"
}
log_cmd() {
  log "[CMD] $*"
  "$@" 2>&1 | tee -a "$OTA_LOG" | tee -a "$LOG_FILE" || return $?
}
log_result() {
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    log "[OK] $*"
  else
    log "[FAIL] $* (rc=$rc)"
  fi
  return $rc
}

# 初始化日志
: > "$OTA_LOG" 2>/dev/null || true
log "========== OTA Update Start =========="
log "OTA_TAR_PATH: $OTA_TAR_PATH"
log "BASE: $BASE"
log "VERSION: $(cat "$BASE/VERSION" 2>/dev/null || echo 'unknown')"

have_systemctl() { command -v systemctl >/dev/null 2>&1; }

svc_stop_disable() {
  local svc="$1"
  have_systemctl || return 0
  log "Stopping service: $svc"
  systemctl stop "$svc" 2>/dev/null || true
  systemctl disable "$svc" 2>/dev/null || true
  systemctl reset-failed "$svc" 2>/dev/null || true
}

log "=== Step 0: Backup user configs ==="
BACKUP_FILE="/home/ark/arkos4clone.tar"
BACKUP_ITEMS=(
  "/roms/psp/ppsspp/PSP/SYSTEM"
  "/roms2/psp/ppsspp/PSP/SYSTEM"
  "/home/ark/.config/retroarch/retroarch.cfg"
  "/home/ark/.config/retroarch32/retroarch.cfg"
)

# 收集存在的文件/目录
BACKUP_LIST=()
for item in "${BACKUP_ITEMS[@]}"; do
  if [[ -e "$item" ]]; then
    BACKUP_LIST+=("$item")
    log "Will backup: $item"
  else
    log "Skip (not found): $item"
  fi
done

# 打包备份
if [[ ${#BACKUP_LIST[@]} -gt 0 ]]; then
  if tar -cf "$BACKUP_FILE" "${BACKUP_LIST[@]}" 2>/dev/null; then
    log "Backup created: $BACKUP_FILE (${#BACKUP_LIST[@]} items)"
  else
    log "Backup failed"
  fi
else
  log "No items to backup, skipping"
fi

# 先停掉可能冲突/要替换的服务（存在才动）
log "=== Step 1: Stop conflicting services ==="
for s in adckeys.service batt_led.service ddtbcheck.service 351mp.service mpv.service oga_events; do
  if [[ -e "/etc/systemd/system/$s" || -e "/lib/systemd/system/$s" ]]; then
    svc_stop_disable "$s"
  fi
done

log "=== Step 2: Find boot partition ==="
# 查找 boot 分区挂载点
BOOT_MP="$(findmnt -n -o TARGET /dev/mmcblk0p1 2>/dev/null || true)"
[[ -z "$BOOT_MP" ]] && BOOT_MP="/boot"
log "Boot mount point: $BOOT_MP"

# ====== 保持原有清理（不改权限，只删文件）======
log "=== Step 3: Cleanup before apply ==="
cleanup_before_apply() {
  log "Cleaning: $BOOT_MP/consoles"
  rm -rf "$BOOT_MP/consoles" 2>/dev/null || true
  log "Cleaning: $BOOT_MP/dtb_selector.exe"
  rm -f  "$BOOT_MP/dtb_selector.exe" 2>/dev/null || true
  log "Cleaning: /opt/system/Clone"
  rm -rf "/opt/system/Clone" 2>/dev/null || true
  log "Cleaning: /opt/drastic"
  rm -rf "/opt/drastic" 2>/dev/null || true
  log "Cleaning: /opt/drastic-kk"
  rm -rf "/opt/drastic-kk" 2>/dev/null || true
}
cleanup_before_apply

# 你要求的 boot 清理（与离线一致）
log "Cleaning boot files..."
rm -rf "$BOOT_MP/BMPs" "$BOOT_MP/ScreenFiles" 2>/dev/null || true
rm -f  "$BOOT_MP/boot.ini" "$BOOT_MP"/*.dtb "$BOOT_MP"/*.orig "$BOOT_MP"/*.tony \
      "$BOOT_MP/Image" "$BOOT_MP"/*.bmp "$BOOT_MP/WHERE_ARE_MY_ROMS.txt" 2>/dev/null || true
rm -f  "$BOOT_MP/DTB Change Tool.exe" 2>/dev/null || true

log "Remounting boot as rw"
mount -o remount,rw "$BOOT_MP" 2>/dev/null || true

# ====== (新增) 只对 META 列出的文件修正权限/属主 ======
apply_meta() {
  local count=0
  [[ -f "$META_FILE" ]] || { log "META file not found"; return 0; }
  log "Applying META permissions..."
  while read -r mode ug path; do
    [[ -z "${mode:-}" || -z "${ug:-}" || -z "${path:-}" ]] && continue
    [[ "${mode:0:1}" == "#" ]] && continue
    # allow globs in PATH
    for p in $path; do
      [[ -e "$p" || -L "$p" ]] || continue
      chown -h "$ug" "$p" 2>/dev/null || true
      if [[ "$mode" != "----" ]]; then
        chmod "$mode" "$p" 2>/dev/null || true
      fi
      ((count++)) || true
    done
  done < "$META_FILE"
  log "META applied: $count entries"
}

apply_chunk_stream() {
  local target="$1" member="$2"
  local OTA_TMP="/home/ark/.ota"
  local dest="/"
  [[ "$target" == "boot" ]] && dest="$BOOT_MP"

  rm -rf "$OTA_TMP" 2>/dev/null || true
  mkdir -p "$OTA_TMP"

  tar -xO -f "$OTA_TAR_PATH" "$member" | tar -xf - -C "$OTA_TMP"

  if [[ "$target" == "boot" ]]; then
    rsync -rltD --omit-dir-times --no-owner --no-group --no-perms \
      "$OTA_TMP/" "$dest/"
  else
    # 关键：复制阶段不改已有权限/属主
    rsync -rltD --omit-dir-times --no-owner --no-group --no-perms \
      "$OTA_TMP/" "$dest/"
  fi

  rm -rf "$OTA_TMP"
}

apply_legacy_rsync() {
  echo "[OTA] legacy mode: rsync payload"
  if [[ -d "$PAYLOAD/boot" ]]; then
    rsync -rltD --omit-dir-times --no-owner --no-group --no-perms \
      "$PAYLOAD/boot/" "$BOOT_MP/"
  fi
  if [[ -d "$PAYLOAD/root" ]]; then
    # legacy 也按“不改权限/owner”的策略
    rsync -rltD --omit-dir-times --no-owner --no-group --no-perms \
      "$PAYLOAD/root/" "/"
  fi
}

log "=== Step 4: Apply chunks ==="
# 应用更新（优先 chunks 流式模式）
if [[ -n "$OTA_TAR_PATH" && -f "$OTA_TAR_PATH" && -f "$CHUNKS_FILE" ]]; then
  while read -r t m; do
    [[ -z "${t:-}" || -z "${m:-}" ]] && continue
    log "Applying chunk: $m"
    apply_chunk_stream "$t" "$m"
    sync || true
  done < "$CHUNKS_FILE"
  log "All chunks applied"
else
  log "Using legacy rsync mode"
  apply_legacy_rsync
fi

log "=== Step 5: Flash uboot ==="
# ====== 保持原有：刷写 uboot（从 update.tar 流式读入）======
dd_from_tar() {
  local member="$1" seek="$2"
  if ! tar -tf "$OTA_TAR_PATH" "$member" >/dev/null 2>&1; then
    log "uboot member not found, skip: $member"
    return 0
  fi
  log "Flashing: $member (seek=$seek)"
  tar -xO -f "$OTA_TAR_PATH" "$member" | dd of=/dev/mmcblk0 conv=notrunc bs=512 seek="$seek" 2>&1 | tee -a "$OTA_LOG" | tee -a "$LOG_FILE"
}

if [[ -b "/dev/mmcblk0" && -n "$OTA_TAR_PATH" && -f "$OTA_TAR_PATH" ]]; then
  dd_from_tar "uboot/idbloader.img" 64
  dd_from_tar "uboot/uboot.img" 16384
  dd_from_tar "uboot/trust.img" 24576
  sync || true
  log "uboot flashed successfully"
else
  log "Skipping uboot flash (no mmcblk0 or no tar)"
fi

log "=== Step 6: Update plymouth theme ==="
PLYMOUTH_THEME="/usr/share/plymouth/themes/text.plymouth"

# 检测当前系统是否为 dArkOS
IS_DARKOS="false"
if [[ -f "$PLYMOUTH_THEME" ]]; then
  CURRENT_TITLE="$(grep '^title=' "$PLYMOUTH_THEME" 2>/dev/null || true)"
  if [[ "$CURRENT_TITLE" == *dArkOS* ]]; then
    IS_DARKOS="true"
    log "Detected: dArkOS system"
  else
    log "Detected: ArkOS system"
  fi
fi

# 根据检测结果设置标题
if [[ -f "$BASE/VERSION" && -f "$PLYMOUTH_THEME" ]]; then
  VER_RAW="$(cat "$BASE/VERSION" 2>/dev/null || true)"
  UPDATE_DATE="$(echo "$VER_RAW" | cut -d- -f2)"
  MODDER="$(echo "$VER_RAW" | cut -d- -f3-)"
  if [[ "$IS_DARKOS" == "true" ]]; then
    sed -i "/^title=/c\title=dArkOS4Clone (${UPDATE_DATE})(${MODDER})" "$PLYMOUTH_THEME" 2>/dev/null || true
    log "Plymouth updated: dArkOS4Clone (${UPDATE_DATE})(${MODDER})"
  else
    sed -i "/^title=/c\title=ArkOS4Clone (${UPDATE_DATE})(${MODDER})" "$PLYMOUTH_THEME" 2>/dev/null || true
    log "Plymouth updated: ArkOS4Clone (${UPDATE_DATE})(${MODDER})"
  fi
fi

log "=== Step 7: Cleanup old files ==="
# ====== 保持原有：删服务文件、删 es_input、删 imageshift、删工具等 ======
rm -f /etc/systemd/system/batt_led.service 2>/dev/null && log "Removed: batt_led.service" || true
rm -f /etc/systemd/system/ddtbcheck.service 2>/dev/null && log "Removed: ddtbcheck.service" || true
chmod 777 /lib/systemd/system/mpv.service 2>/dev/null && log "Fixed: mpv.service chmod 777" || true

rm -f /etc/emulationstation/es_input.cfg 2>/dev/null && log "Removed: es_input.cfg" || true

sed -i '/imageshift\.sh/d' /var/spool/cron/crontabs/root 2>/dev/null && log "Removed: imageshift.sh from cron" || true
rm -f /home/ark/.config/imageshift.sh 2>/dev/null && log "Removed: imageshift.sh" || true

rm -rf /opt/system/DeviceType 2>/dev/null && log "Removed: DeviceType" || true
rm -rf "/opt/system/Change LED to Red.sh" 2>/dev/null && log "Removed: Change LED to Red.sh" || true
rm -rf "/opt/system/Update.sh" 2>/dev/null && log "Removed: Update.sh" || true
rm -rf "/opt/system/Wifi.sh" 2>/dev/null && log "Removed: Wifi.sh" || true
rm -rf "/opt/system/Network Info.sh" 2>/dev/null && log "Removed: Network Info.sh" || true
rm -rf "/opt/system/Enable Remote Services.sh" 2>/dev/null && log "Removed: Enable Remote Services.sh" || true
rm -rf "/opt/system/Disable Remote Services.sh" 2>/dev/null && log "Removed: Disable Remote Services.sh" || true
rm -rf "/opt/system/Change Time.sh" 2>/dev/null && log "Removed: Change Time.sh" || true
rm -rf "/opt/system/Advanced/NDS Overlays" 2>/dev/null && log "Removed: NDS Overlays" || true
rm -rf "/opt/system/Advanced/Change Ports SDL.sh" 2>/dev/null && log "Removed: Change Ports SDL.sh" || true
find /opt/system/Advanced -name 'Restore*.sh' ! -name 'Restore ArkOS Settings.sh' -exec rm -f {} + 2>/dev/null || true
rm -rf "/opt/system/Advanced/Screen - Switch to Original Screen Timings.sh" 2>/dev/null || true
rm -rf "/opt/system/Advanced/Reset EmulationStation Controls.sh" 2>/dev/null || true
rm -rf "/opt/system/Advanced/Fix Global Hotkeys.sh" 2>/dev/null || true

# 351Files 重命名（保持原逻辑）
if [[ -e "/opt/351Files/351Files" ]]; then
  mv "/opt/351Files/351Files" "/opt/351Files/351Files.old" 2>/dev/null && log "Renamed: 351Files -> 351Files.old" || true
fi

log "=== Step 8: Apply permissions (META) ==="
# ====== (关键新增) 最后只修正“我们交付文件”的权限/属主 ======
apply_meta

log "=== Step 9: Fix modules permissions ==="
# modules 权限修复：777 + 1002:1002
fix_modules_perms() {
  local base="/usr/lib/modules/4.4.189"
  [[ -d "$base" ]] || { log "modules dir not found: $base"; return 0; }
  log "Fixing modules: $base"
  chown -R 1002:1002 "$base" 2>/dev/null || true
  chmod -R 777 "$base" 2>/dev/null || true
  local ko_count; ko_count=$(find "$base" -name "*.ko" 2>/dev/null | wc -l)
  log "Fixed $ko_count .ko files"
  if command -v depmod >/dev/null 2>&1; then
    depmod -a 4.4.189 2>/dev/null && log "depmod completed" || true
  fi
}
fix_modules_perms

log "=== Step 10: Enable services ==="
# systemd：按你旧逻辑启用 adckeys
if have_systemctl; then
  systemctl daemon-reload 2>/dev/null || true
  systemctl enable adckeys.service 2>/dev/null && log "Enabled: adckeys.service" || true
  systemctl restart adckeys.service 2>/dev/null && log "Started: adckeys.service" || true
  chmod 777 /usr/local/bin/ogage 2>/dev/null && log "Fixed: ogage chmod 777" || true
fi

sync
log "========== OTA Update Complete =========="
log "OTA SUCCESS"
EOF
chmod +x "$STAGE/install.sh"

# -----------------------------
# 把 uboot 三件套打进 update.tar（保持原有）
# -----------------------------
echo "== 打包 uboot 镜像（uboot/*.img） =="
mkdir -p "$STAGE/uboot"
cp -f ./uboot/idbloader.img "$STAGE/uboot/" 2>/dev/null || true
cp -f ./uboot/uboot.img     "$STAGE/uboot/" 2>/dev/null || true
cp -f ./uboot/trust.img     "$STAGE/uboot/" 2>/dev/null || true

# -----------------------------
# 生成 chunks + CHUNKS 清单（分包流式）
# -----------------------------
echo "== 生成 chunks（分包） =="

CHUNK_DIR="$STAGE/chunks"
rm -rf "$CHUNK_DIR" 2>/dev/null || true
mkdir -p "$CHUNK_DIR"

# boot chunk
tar --numeric-owner --owner=0 --group=0 -C "$PAYLOAD_BOOT" -cf "$CHUNK_DIR/00_boot.tar" .

# root chunks（按目录拆）
tar --numeric-owner --owner=0 --group=0 -C "$PAYLOAD_ROOT" -cf "$CHUNK_DIR/10_root_usr_etc.tar" ./usr ./etc 2>/dev/null || true
tar --numeric-owner --owner=1002 --group=1002 -C "$PAYLOAD_ROOT" -cf "$CHUNK_DIR/20_root_opt.tar" ./opt 2>/dev/null || true
tar --numeric-owner --owner=1002 --group=1002 -C "$PAYLOAD_ROOT" -cf "$CHUNK_DIR/30_root_home.tar" ./home 2>/dev/null || true
tar --numeric-owner --owner=0 --group=0 -C "$PAYLOAD_ROOT" -cf "$CHUNK_DIR/40_root_misc.tar" ./var ./lib ./sbin ./bin ./run ./root ./media ./mnt ./tmp 2>/dev/null || true

cat > "$STAGE/CHUNKS" <<'EOF'
boot chunks/00_boot.tar
root chunks/10_root_usr_etc.tar
root chunks/20_root_opt.tar
root chunks/30_root_home.tar
root chunks/40_root_misc.tar
EOF

# -----------------------------
# 打包生成 update.tar（新增 META，但其它结构不变）
# -----------------------------
echo "== 打包 update.tar =="
rm -f "$OUT_TAR" 2>/dev/null || true
tar --numeric-owner --owner=0 --group=0 -C "$STAGE" -cf "$OUT_TAR" \
  VERSION install.sh META CHUNKS chunks uboot

# 清理临时构建目录
rm -rf "$STAGE"

echo "== 完成 =="
echo "版本号: $VERSION"
echo "输出文件: $OUT_TAR"

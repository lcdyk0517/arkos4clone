#!/usr/bin/env bash
set -euo pipefail

# ============================================
# ArkOS4Clone OTA 升级包制作脚本
#
# 用法：
#   sudo ./build_update_tar.sh           # 构建 ArkOS 版本 (update-arkos.tar)
#   sudo ./build_update_tar.sh -d        # 构建 dArkOS 版本 (update-darkos.tar)
#   sudo ./build_update_tar.sh darkos    # 构建 dArkOS 版本
#
# payload 直接由仓库的 boot/ 与 rootfs/ 目录树生成：
#   dArkOS: boot/dArkOS + rootfs/dArkOS          (777 / 1000:1000)
#   ArkOS : 先 dArkOS 再 ArkOS 分层覆盖           (777 / 1002:1002)
#
# 输出文件：
#   ./update-arkos.tar / ./update-darkos.tar （放到设备 /roms/update.tar）
# ============================================

# 解析命令行参数
ARKOS_IMAGE_NAME=""
for arg in "$@"; do
  case "${arg,,}" in  # 转小写比较
    -d|darkos|darkos4clone)
      ARKOS_IMAGE_NAME="dArkOS"
      ;;
  esac
done

# 生成版本信息
UPDATE_DATE="$(TZ=Asia/Shanghai date +%Y%m%d)"
MODDER="kk&lcdyk"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
WORKDIR="$SCRIPT_DIR"
STAGE="${ARKOS_STAGE:-/tmp/_ota_stage}"
PAYLOAD_BOOT="${STAGE}/payload/boot"
PAYLOAD_ROOT="${STAGE}/payload/root"

# boot 分区（FAT32）专用 rsync 参数
RSYNC_BOOT_OPTS="-rltcD --no-owner --no-group --no-perms --omit-dir-times"

# ----------------- helpers -----------------
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

# OTA 里同样可能带着未解压的大核心
echo "== 解压大型核心 (.so.xz -> .so，已解压则跳过) =="
while IFS= read -r -d '' core_xz; do
  core_so="${core_xz%.xz}"
  if [[ ! -f "$core_so" ]]; then
    echo "解压 $core_xz (解压后删除压缩包)"
    if ! xz -d -T0 "$core_xz"; then
      echo "[ERROR] 解压失败: $core_xz"
      exit 1
    fi
  fi
done < <(find rootfs -name '*.so.xz' -print0)


if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
  # ============================================================
  # dArkOS (UID=1000)
  # ============================================================
  echo "=== 构建 dArkOS OTA 包 (777 / 1000:1000) ==="
  VERSION="dArkOS4Clone-${UPDATE_DATE}-${MODDER}"
  CHOWN_USER="1000:1000"
  OUT_TAR="${WORKDIR}/update-darkos.tar"

  echo "== 构建 payload/boot (sync boot/dArkOS) =="
  rsync $RSYNC_BOOT_OPTS boot/dArkOS/ "$PAYLOAD_BOOT/"
  cp -f boot/dArkOS/clone.sh "$PAYLOAD_BOOT/firstboot.sh"
  touch "$PAYLOAD_BOOT/USE_DTB_SELECT_TO_SELECT_DEVICE" 2>/dev/null || true

  echo "== 构建 payload/root (sync rootfs/dArkOS) =="
  # OTA 不升级固件与 PortMaster:
  #  - usr/lib/firmware 固件与系统镜像强绑定，OTA 不动
  #  - opt/system/Tools 在设备上是 /roms/tools 的 bind 挂载点 (PortMaster 所在)，OTA 不写入
  rsync -a --checksum --exclude=usr/lib/firmware --exclude=opt/system/Tools rootfs/dArkOS/ "$PAYLOAD_ROOT/"


else
  # ============================================================
  # ArkOS (UID=1002)：先 dArkOS 后 ArkOS 分层覆盖
  # ============================================================
  echo "=== 构建 ArkOS OTA 包 (777 / 1002:1002) ==="
  VERSION="ArkOS4Clone-${UPDATE_DATE}-${MODDER}"
  CHOWN_USER="1002:1002"
  OUT_TAR="${WORKDIR}/update-arkos.tar"

  echo "== 构建 payload/boot (sync boot/dArkOS + boot/ArkOS) =="
  rsync $RSYNC_BOOT_OPTS boot/dArkOS/ "$PAYLOAD_BOOT/"
  rsync $RSYNC_BOOT_OPTS boot/ArkOS/ "$PAYLOAD_BOOT/"
  cp -f boot/dArkOS/clone.sh "$PAYLOAD_BOOT/firstboot.sh"
  touch "$PAYLOAD_BOOT/USE_DTB_SELECT_TO_SELECT_DEVICE" 2>/dev/null || true

  echo "== 构建 payload/root (sync rootfs/dArkOS + rootfs/ArkOS) =="
  # OTA 不升级固件与 PortMaster (Tools 为 /roms/tools 的 bind 挂载点，见上)
  rsync -a --checksum --exclude=usr/lib/firmware --exclude=opt/system/Tools rootfs/dArkOS/ "$PAYLOAD_ROOT/"
  rsync -a --checksum --exclude=usr/lib/firmware --exclude=opt/system/Tools rootfs/ArkOS/ "$PAYLOAD_ROOT/"

fi

# -----------------------------
# META：由 payload 自动生成（所有交付文件 0777 + CHOWN_USER）
# -----------------------------
echo "== 写入 VERSION / META =="
cat > "$STAGE/VERSION" <<EOF
$VERSION
EOF

meta_init
# 空格替换为 ?：apply_meta 按词遍历时用 glob 匹配带空格的文件名
( cd "$PAYLOAD_ROOT" && find . -mindepth 1 | sed 's|^\./||; s| |?|g' ) | while IFS= read -r p; do
  meta_add "0777" "$CHOWN_USER" "/$p"
done

# 镜像自带但不在 payload 里的路径
if [[ "$ARKOS_IMAGE_NAME" != *dArkOS* ]]; then
  # ArkOS: 修正镜像自带 mpv.service 的属主
  meta_add "0777" "$CHOWN_USER" "/lib/systemd/system/mpv.service"
fi
meta_finalize_dedupe

# -----------------------------
# install.sh（通用，自动检测 dArkOS/ArkOS）
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

log() {
  local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $*" | tee -a "$OTA_LOG" | tee -a "$LOG_FILE"
}
log_cmd() {
  log "[CMD] $*"
  "$@" 2>&1 | tee -a "$OTA_LOG" | tee -a "$LOG_FILE" || return $?
}

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

# 检测当前系统类型
PLYMOUTH_THEME="/usr/share/plymouth/themes/text.plymouth"
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

# 根据系统类型设置权限用户
if [[ "$IS_DARKOS" == "true" ]]; then
  CHOWN_USER="1000:1000"
else
  CHOWN_USER="1002:1002"
fi
log "CHOWN_USER: $CHOWN_USER"

log "=== Step 0: Backup user configs ==="
BACKUP_FILE="/home/ark/arkos4clone.tar"
BACKUP_ITEMS=(
  "/roms/psp/ppsspp/PSP/SYSTEM"
  "/roms2/psp/ppsspp/PSP/SYSTEM"
  "/home/ark/.config/retroarch/retroarch.cfg"
  "/home/ark/.config/retroarch32/retroarch.cfg"
)

BACKUP_LIST=()
for item in "${BACKUP_ITEMS[@]}"; do
  if [[ -e "$item" ]]; then
    BACKUP_LIST+=("$item")
    log "Will backup: $item"
  else
    log "Skip (not found): $item"
  fi
done

if [[ ${#BACKUP_LIST[@]} -gt 0 ]]; then
  if tar -cf "$BACKUP_FILE" "${BACKUP_LIST[@]}" 2>/dev/null; then
    log "Backup created: $BACKUP_FILE (${#BACKUP_LIST[@]} items)"
  else
    log "Backup failed"
  fi
else
  log "No items to backup, skipping"
fi

log "=== Step 1: Stop conflicting services ==="
for s in zram-swap.service batteryplus.service es-status-daemon.service batt_led.service ddtbcheck.service 351mp.service mpv.service oga_events; do
  if [[ -e "/etc/systemd/system/$s" || -e "/lib/systemd/system/$s" ]]; then
    svc_stop_disable "$s"
  fi
done

log "=== Step 2: Find boot partition ==="
BOOT_MP="$(findmnt -n -o TARGET /dev/mmcblk0p1 2>/dev/null || true)"
[[ -z "$BOOT_MP" ]] && BOOT_MP="/boot"
log "Boot mount point: $BOOT_MP"

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

log "Cleaning boot files..."
rm -rf "$BOOT_MP/BMPs" "$BOOT_MP/ScreenFiles" 2>/dev/null || true
rm -f  "$BOOT_MP/boot.ini" "$BOOT_MP"/*.dtb "$BOOT_MP"/*.orig "$BOOT_MP"/*.tony \
      "$BOOT_MP/Image" "$BOOT_MP"/*.bmp "$BOOT_MP/WHERE_ARE_MY_ROMS.txt" 2>/dev/null || true
rm -f  "$BOOT_MP/DTB Change Tool.exe" 2>/dev/null || true

log "Remounting boot as rw"
mount -o remount,rw "$BOOT_MP" 2>/dev/null || true

apply_meta() {
  local count=0
  [[ -f "$META_FILE" ]] || { log "META file not found"; return 0; }
  log "Applying META permissions (CHOWN_USER=$CHOWN_USER)..."
  while read -r mode ug path; do
    [[ -z "${mode:-}" || -z "${ug:-}" || -z "${path:-}" ]] && continue
    [[ "${mode:0:1}" == "#" ]] && continue
    # 使用实际的 CHOWN_USER 替换 META 中的值
    for p in $path; do
      [[ -e "$p" || -L "$p" ]] || continue
      chown -h "$CHOWN_USER" "$p" 2>/dev/null || true
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
  local dest="/"
  [[ "$target" == "boot" ]] && dest="$BOOT_MP"

  # 直接从 OTA 包流式解到目标分区，不经中转目录
  # (旧实现先解到 /home/ark/.ota 再 rsync，p2 出厂剩余空间不足以容纳 root 级 chunk)
  # tar 记录的属主/权限 (root / 1002) 随流生效，META 随后统一兜底 0777+chown
  # --exclude: 兼容仍携带固件/Tools 的旧版 OTA 包，设备端统一忽略
  if ! tar -xO -f "$OTA_TAR_PATH" "$member" 2>>"$OTA_LOG" | tar -x --warning=no-timestamp --exclude='opt/system/Tools' --exclude='usr/lib/firmware' -C "$dest" 2>>"$OTA_LOG"; then
    log "ERROR: chunk apply failed: $member (detail in $OTA_LOG)"
    log "ERROR: OTA aborted to avoid a partially applied update. The package is kept."
    exit 1
  fi
}

apply_legacy_rsync() {
  log "ERROR: legacy rsync mode is no longer supported: OTA packages do not carry payload/."
  log "       (clone.sh extracts only VERSION/install.sh/CHUNKS/META; CHUNKS file missing or stale?)"
  exit 1
}

log "=== Step 4: Apply chunks ==="
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
if [[ -f "$BASE/VERSION" && -f "$PLYMOUTH_THEME" ]]; then
  VER_RAW="$(cat "$BASE/VERSION" 2>/dev/null || true)"
  UPDATE_DATE="$(echo "$VER_RAW" | cut -d- -f2)"
  MODDER="$(echo "$VER_RAW" | cut -d- -f3-)"
  # 新版 payload 已直接使用正式文件名 (atomiswave.sh / es_systems.cfg 等)，
  # 旧版按系统改名/删除 darkos4* 的逻辑随目录树重构一并移除
  if [[ "$IS_DARKOS" == "true" ]]; then
    sed -i "/^title=/c\title=dArkOS4Clone (${UPDATE_DATE})(${MODDER})" "$PLYMOUTH_THEME" 2>/dev/null || true
    log "Plymouth updated: dArkOS4Clone (${UPDATE_DATE})(${MODDER})"
  else
    sed -i "/^title=/c\title=ArkOS4Clone (${UPDATE_DATE})(${MODDER})" "$PLYMOUTH_THEME" 2>/dev/null || true
    log "Plymouth updated: ArkOS4Clone (${UPDATE_DATE})(${MODDER})"
  fi
fi

log "=== Step 7: Cleanup old files ==="
rm -f /etc/systemd/system/batt_led.service 2>/dev/null && log "Removed: batt_led.service" || true
rm -f /etc/systemd/system/ddtbcheck.service 2>/dev/null && log "Removed: ddtbcheck.service" || true
chmod 777 /lib/systemd/system/mpv.service 2>/dev/null && log "Fixed: mpv.service chmod 777" || true

# Remove legacy SD switch scripts (replaced by ES ROMS SD CARD setting)
rm -f "/usr/local/bin/Switch to SD2 for Roms.sh" 2>/dev/null && log "Removed: Switch to SD2 for Roms.sh (usr/local/bin)" || true
rm -f "/usr/local/bin/Switch to main SD for Roms.sh" 2>/dev/null && log "Removed: Switch to main SD for Roms.sh (usr/local/bin)" || true
rm -f "/usr/local/bin/Read from SD1 and SD2 for Roms" 2>/dev/null && log "Removed: Switch to main SD for Roms.sh (usr/local/bin)" || true
rm -f "/opt/system/Advanced/Switch to SD2 for Roms.sh" 2>/dev/null && log "Removed: Switch to SD2 for Roms.sh (Advanced)" || true
rm -f "/opt/system/Advanced/Switch to main SD for Roms.sh" 2>/dev/null && log "Removed: Switch to main SD for Roms.sh (Advanced)" || true
rm -f "/opt/system/Advanced/Read from SD1 and SD2 for Roms.sh" 2>/dev/null && log "Removed: Read from SD1 and SD2 for Roms.sh" || true
rm -f "/opt/system/Advanced/Read from SD1 and SD2 for Roms" 2>/dev/null && log "Removed: Read from SD1 and SD2 for Roms" || true

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

log "=== Step 8: Apply permissions (META) ==="
apply_meta

log "=== Step 9: Fix modules permissions ==="
fix_modules_perms() {
  local base="/usr/lib/modules/4.4.189"
  [[ -d "$base" ]] || { log "modules dir not found: $base"; return 0; }
  log "Fixing modules: $base"
  chown -R $CHOWN_USER "$base" 2>/dev/null || true
  chmod -R 777 "$base" 2>/dev/null || true
  local ko_count; ko_count=$(find "$base" -name "*.ko" 2>/dev/null | wc -l)
  log "Fixed $ko_count .ko files"
  if command -v depmod >/dev/null 2>&1; then
    depmod -a 4.4.189 2>/dev/null && log "depmod completed" || true
  fi
}
fix_modules_perms

log "=== Step 10: Enable services ==="
if have_systemctl; then
  systemctl daemon-reload 2>/dev/null || true
  systemctl enable es-status-daemon.service 2>/dev/null && log "Enabled: es-status-daemon.service" || true
  systemctl restart es-status-daemon.service 2>/dev/null && log "Started: es-status-daemon.service" || true
  chmod 777 /usr/local/bin/ogage 2>/dev/null && log "Fixed: ogage chmod 777" || true
fi

sync
log "========== OTA Update Complete =========="
log "OTA SUCCESS"
EOF
chmod +x "$STAGE/install.sh"

# -----------------------------
# 打包 uboot 镜像
# -----------------------------
echo "== 打包 uboot 镜像 =="
mkdir -p "$STAGE/uboot"
cp -f ./uboot/idbloader.img "$STAGE/uboot/" 2>/dev/null || true
cp -f ./uboot/uboot.img     "$STAGE/uboot/" 2>/dev/null || true
cp -f ./uboot/trust.img     "$STAGE/uboot/" 2>/dev/null || true

# -----------------------------
# 生成 chunks
# -----------------------------
echo "== 生成 chunks =="
CHUNK_DIR="$STAGE/chunks"
rm -rf "$CHUNK_DIR" 2>/dev/null || true
mkdir -p "$CHUNK_DIR"

ROOT_UID="${CHOWN_USER%%:*}"
tar --numeric-owner --owner=0 --group=0 -C "$PAYLOAD_BOOT" -cf "$CHUNK_DIR/00_boot.tar" .
tar --numeric-owner --owner=0 --group=0 -C "$PAYLOAD_ROOT" -cf "$CHUNK_DIR/10_root_usr_etc.tar" ./usr ./etc 2>/dev/null || true
tar --numeric-owner --owner="$ROOT_UID" --group="$ROOT_UID" -C "$PAYLOAD_ROOT" -cf "$CHUNK_DIR/20_root_opt.tar" ./opt 2>/dev/null || true
tar --numeric-owner --owner="$ROOT_UID" --group="$ROOT_UID" -C "$PAYLOAD_ROOT" -cf "$CHUNK_DIR/30_root_home.tar" ./home 2>/dev/null || true
tar --numeric-owner --owner=0 --group=0 -C "$PAYLOAD_ROOT" -cf "$CHUNK_DIR/40_root_misc.tar" ./var ./lib ./sbin ./bin ./run ./root ./media ./mnt ./tmp 2>/dev/null || true

cat > "$STAGE/CHUNKS" <<'EOF'
boot chunks/00_boot.tar
root chunks/10_root_usr_etc.tar
root chunks/20_root_opt.tar
root chunks/30_root_home.tar
root chunks/40_root_misc.tar
EOF

# -----------------------------
# 打包 update.tar
# -----------------------------
echo "== 打包 update.tar =="
rm -f "$OUT_TAR" 2>/dev/null || true
tar --numeric-owner --owner=0 --group=0 -C "$STAGE" -cf "$OUT_TAR" \
  VERSION install.sh META CHUNKS chunks uboot

rm -rf "$STAGE"

echo "== 完成 =="
echo "版本号: $VERSION"
echo "输出文件: $OUT_TAR"

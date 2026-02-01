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
rsync $RSYNC_BOOT_OPTS --exclude='files' ./consoles/ "$PAYLOAD_BOOT/consoles/"

# clone.sh 在 OTA 中必须直接生成为 /boot/firstboot.sh
cp -f ./sh/clone.sh "$PAYLOAD_BOOT/firstboot.sh"

# 其他 boot 工具保持原文件名
cp -f ./dtb_selector_macos \
      ./dtb_selector_win32.exe \
      ./sh/expandtoexfat.sh \
      "$PAYLOAD_BOOT/" 2>/dev/null || true

# DTB 选择器提示标记文件
touch "$PAYLOAD_BOOT/USE_DTB_SELECT_TO_SELECT_DEVICE" 2>/dev/null || true

echo "== 构建 payload/root =="

echo "== 注入设备怪癖 =="
mkdir -p "$PAYLOAD_ROOT/home/ark/.quirks"
cp -r ./consoles/files/* "$PAYLOAD_ROOT/home/ark/.quirks/" 2>/dev/null || true

echo "== 注入 Clone 配置与工具 =="
mkdir -p "$PAYLOAD_ROOT/opt/system/Clone" \
         "$PAYLOAD_ROOT/usr/bin" \
         "$PAYLOAD_ROOT/usr/local/bin"
cp -f ./sh/joyled.sh "$PAYLOAD_ROOT/opt/system/Clone/" 2>/dev/null || true
cp -f ./sh/sdljoytest.sh "$PAYLOAD_ROOT/opt/system/Clone/" 2>/dev/null || true
cp -f ./bin/mcu_led ./bin/ws2812 "$PAYLOAD_ROOT/usr/bin/" 2>/dev/null || true
cp -f ./bin/sdljoymap ./bin/sdljoytest "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

echo "== 注入 rk915 驱动与固件 =="
mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware" \
         "$PAYLOAD_ROOT/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/mediatek" \
         "$PAYLOAD_ROOT/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/rockchip_wlan/rk915"
cp -f ./bin/mt7610u_sta.ko \
      "$PAYLOAD_ROOT/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/mediatek/" 2>/dev/null || true
cp -f ./bin/rk915_*.bin "$PAYLOAD_ROOT/usr/lib/firmware/" 2>/dev/null || true
cp -f ./bin/rk915.ko \
      "$PAYLOAD_ROOT/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/rockchip_wlan/rk915/" 2>/dev/null || true

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
         "$PAYLOAD_ROOT/usr/bin/emulationstation/resources/locale/zh-CN"
cp -f ./mod_so/64/* "$PAYLOAD_ROOT/home/ark/.config/retroarch/cores/" 2>/dev/null || true
cp -f ./mod_so/32/* "$PAYLOAD_ROOT/home/ark/.config/retroarch32/cores/" 2>/dev/null || true
cp -f ./replace_file/es_systems.cfg "$PAYLOAD_ROOT/etc/emulationstation/" 2>/dev/null || true
cp -f ./replace_file/es_systems.cfg.dual "$PAYLOAD_ROOT/etc/emulationstation/" 2>/dev/null || true
cp -f ./replace_file/emulationstation2.po \
      "$PAYLOAD_ROOT/usr/bin/emulationstation/resources/locale/zh-CN/" 2>/dev/null || true

# 注意：es_input.cfg 的删除在 install.sh 中完成
mkdir -p "$PAYLOAD_ROOT/usr/bin/emulationstation"
cp -r ./replace_file/emulationstation \
      "$PAYLOAD_ROOT/usr/bin/emulationstation/emulationstation" 2>/dev/null || true

echo "== 注入 drastic =="
mkdir -p "$PAYLOAD_ROOT/opt/drastic"
cp -a ./replace_file/drastic/. "$PAYLOAD_ROOT/opt/drastic/" 2>/dev/null || true
rm -rf "$PAYLOAD_ROOT/opt/drastic/patch" 2>/dev/null || true

# NDS Overlay
mkdir -p "$PAYLOAD_ROOT/opt/system/Advanced/NDS Overlays"
cp -a ./replace_file/nds_sh/* \
      "$PAYLOAD_ROOT/opt/system/Advanced/NDS Overlays/" 2>/dev/null || true

echo "== 注入 retrorun =="
mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
cp -r ./replace_file/retrorun/retrorun32 "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -r ./replace_file/retrorun/retrorun "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

echo "== 注入 pymo =="
cp -r ./replace_file/pymo/cpymo "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
cp -r ./replace_file/pymo/pymo.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
mkdir -p "$PAYLOAD_ROOT/tempthemes/es-theme-nes-box"
cp -r ./replace_file/pymo/pymo \
      "$PAYLOAD_ROOT/tempthemes/es-theme-nes-box/" 2>/dev/null || true

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

# quirks：只 chown，不 chmod（避免误伤用户已有文件）
meta_add "----" "1002:1002" "/home/ark/.quirks/*"

# Clone：chown + 755
meta_add "0755" "1002:1002" "/opt/system/Clone"
meta_add "0755" "1002:1002" "/opt/system/Clone/*"

# Tools：chown + 755
meta_add "0755" "1002:1002" "/usr/bin/mcu_led"
meta_add "0755" "1002:1002" "/usr/bin/ws2812"
meta_add "0755" "1002:1002" "/usr/local/bin/sdljoytest"
meta_add "0755" "1002:1002" "/usr/local/bin/sdljoymap"

# rk915：ko 644；固件 755（按你离线脚本）
meta_add "0644" "0:0" "/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/rockchip_wlan/rk915/rk915.ko"
meta_add "0755" "0:0" "/usr/lib/firmware/rk915_*.bin"

# 351Files：chown + 755（并会在 install.sh 做 351Files -> old 的重命名）
meta_add "0755" "1002:1002" "/opt/351Files"
meta_add "0755" "1002:1002" "/opt/351Files/*"

# replace_file/*.sh 中那 6 个：root:root + 777
for f in atomiswave.sh dreamcast.sh naomi.sh saturn.sh n64.sh pico8.sh; do
  meta_add "0777" "0:0" "/usr/local/bin/$f"
done

# adckeys：py/sh 777；service 644
meta_add "0777" "0:0" "/usr/local/bin/adckeys.py"
meta_add "0777" "0:0" "/usr/local/bin/adckeys.sh"
meta_add "0644" "0:0" "/etc/systemd/system/adckeys.service"

# cores：只 chown，不 chmod
meta_add "----" "1002:1002" "/home/ark/.config/retroarch/cores/*"
meta_add "----" "1002:1002" "/home/ark/.config/retroarch32/cores/*"

# ES cfg：777（owner 你离线没强制，按 ark 用户更合理，这里跟随 1002:1002）
meta_add "0777" "1002:1002" "/etc/emulationstation/es_systems.cfg"
meta_add "0777" "1002:1002" "/etc/emulationstation/es_systems.cfg.dual"

# drastic：1002:1002 + 775
meta_add "0775" "1002:1002" "/opt/drastic"
meta_add "0775" "1002:1002" "/opt/drastic/*"

# pymo：777（离线脚本是 777）
meta_add "0777" "0:0" "/usr/local/bin/cpymo"
meta_add "0777" "0:0" "/usr/local/bin/pymo.sh"

# 临时修复：mediaplayer 777（按你旧脚本）
meta_add "0777" "0:0" "/usr/local/bin/mediaplayer.sh"

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

have_systemctl() { command -v systemctl >/dev/null 2>&1; }

svc_stop_disable() {
  local svc="$1"
  have_systemctl || return 0
  systemctl stop "$svc" 2>/dev/null || true
  systemctl disable "$svc" 2>/dev/null || true
  systemctl reset-failed "$svc" 2>/dev/null || true
}

# 先停掉可能冲突/要替换的服务（存在才动）
for s in adckeys.service batt_led.service ddtbcheck.service 351mp.service mpv.service; do
  if [[ -e "/etc/systemd/system/$s" || -e "/lib/systemd/system/$s" ]]; then
    svc_stop_disable "$s"
  fi
done

# 查找 boot 分区挂载点
BOOT_MP="$(findmnt -n -o TARGET /dev/mmcblk0p1 2>/dev/null || true)"
[[ -z "$BOOT_MP" ]] && BOOT_MP="/boot"

# ====== 保持原有清理（不改权限，只删文件）======
cleanup_before_apply() {
  rm -rf "$BOOT_MP/consoles" 2>/dev/null || true
  rm -f  "$BOOT_MP/dtb_selector.exe" 2>/dev/null || true
  rm -rf "/opt/system/Clone" 2>/dev/null || true
}
cleanup_before_apply

# 你要求的 boot 清理（与离线一致）
rm -rf "$BOOT_MP/BMPs" "$BOOT_MP/ScreenFiles" 2>/dev/null || true
rm -f  "$BOOT_MP/boot.ini" "$BOOT_MP"/*.dtb "$BOOT_MP"/*.orig "$BOOT_MP"/*.tony \
      "$BOOT_MP/Image" "$BOOT_MP"/*.bmp "$BOOT_MP/WHERE_ARE_MY_ROMS.txt" 2>/dev/null || true
rm -f  "$BOOT_MP/DTB Change Tool.exe" 2>/dev/null || true

mount -o remount,rw "$BOOT_MP" 2>/dev/null || true

# ====== (新增) 只对 META 列出的文件修正权限/属主 ======
apply_meta() {
  [[ -f "$META_FILE" ]] || return 0
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
    done
  done < "$META_FILE"
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
    # 关键：复制阶段不改已有权限/属主（保持你原有“复制哪些文件”的内容不变）
    rsync -rltD --omit-dir-times --no-owner --no-group --no-perms \
      "$OTA_TMP/" "$dest/"

    # modules：保持原逻辑的“删除同步”
    if [[ -d "$OTA_TMP/usr/lib/modules" ]]; then
      mkdir -p /usr/lib/modules
      rsync -rltD --delete --omit-dir-times --no-owner --no-group --no-perms \
        "$OTA_TMP/usr/lib/modules/" "/usr/lib/modules/"
    fi

    if command -v depmod >/dev/null 2>&1; then
      depmod -a 4.4.189 2>/dev/null || true
    fi
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

# 应用更新（优先 chunks 流式模式）
if [[ -n "$OTA_TAR_PATH" && -f "$OTA_TAR_PATH" && -f "$CHUNKS_FILE" ]]; then
  while read -r t m; do
    [[ -z "${t:-}" || -z "${m:-}" ]] && continue
    apply_chunk_stream "$t" "$m"
    sync || true
  done < "$CHUNKS_FILE"
else
  apply_legacy_rsync
fi

# ====== 保持原有：刷写 uboot（从 update.tar 流式读入）======
dd_from_tar() {
  local member="$1" seek="$2"
  if ! tar -tf "$OTA_TAR_PATH" "$member" >/dev/null 2>&1; then
    echo "[OTA] uboot member not found, skip: $member"
    return 0
  fi
  echo "[OTA] flashing: $member (seek=$seek)"
  tar -xO -f "$OTA_TAR_PATH" "$member" | dd of=/dev/mmcblk0 conv=notrunc bs=512 seek="$seek" 2>&1 | tee -a "$LOG_FILE"
}

if [[ -b "/dev/mmcblk0" && -n "$OTA_TAR_PATH" && -f "$OTA_TAR_PATH" ]]; then
  dd_from_tar "uboot/idbloader.img" 64
  dd_from_tar "uboot/uboot.img" 16384
  dd_from_tar "uboot/trust.img" 24576
  sync || true
fi

# plymouth title: ArkOS4Clone (MMDDYYYY)(MODDER) ——保持原逻辑
PLYMOUTH_THEME="/usr/share/plymouth/themes/text.plymouth"
if [[ -f "$BASE/VERSION" && -f "$PLYMOUTH_THEME" ]]; then
  VER_RAW="$(cat "$BASE/VERSION" 2>/dev/null || true)"
  UPDATE_DATE="$(echo "$VER_RAW" | cut -d- -f2)"
  MODDER="$(echo "$VER_RAW" | cut -d- -f3-)"
  sed -i "/^title=/c\title=ArkOS4Clone (${UPDATE_DATE})(${MODDER})" "$PLYMOUTH_THEME" 2>/dev/null || true
fi

# ====== 保持原有：删服务文件、删 es_input、删 imageshift、删工具等 ======
rm -f /etc/systemd/system/batt_led.service 2>/dev/null || true
rm -f /etc/systemd/system/ddtbcheck.service 2>/dev/null || true

rm -f /etc/emulationstation/es_input.cfg 2>/dev/null || true

sed -i '/imageshift\.sh/d' /var/spool/cron/crontabs/root 2>/dev/null || true
rm -f /home/ark/.config/imageshift.sh 2>/dev/null || true

rm -rf /opt/system/DeviceType 2>/dev/null || true
rm -rf "/opt/system/Change LED to Red.sh" 2>/dev/null || true
rm -rf "/opt/system/Advanced/Change Ports SDL.sh" 2>/dev/null || true
find /opt/system/Advanced -name 'Restore*.sh' ! -name 'Restore ArkOS Settings.sh' -exec rm -f {} + 2>/dev/null || true
rm -rf "/opt/system/Advanced/Screen - Switch to Original Screen Timings.sh" 2>/dev/null || true
rm -rf "/opt/system/Advanced/Reset EmulationStation Controls.sh" 2>/dev/null || true
rm -rf "/opt/system/Advanced/Fix Global Hotkeys.sh" 2>/dev/null || true

# 351Files 重命名（保持原逻辑）
if [[ -e "/opt/351Files/351Files" ]]; then
  mv "/opt/351Files/351Files" "/opt/351Files/351Files.old" 2>/dev/null || true
fi

# ====== (关键新增) 最后只修正“我们交付文件”的权限/属主 ======
apply_meta

# 维持你旧的 modules 修复（只动 /usr/lib/modules/4.4.189）
fix_modules_perms() {
  local base="/usr/lib/modules/4.4.189"
  [[ -d "$base" ]] || return 0
  chown -R root:root "$base" 2>/dev/null || true
  find "$base" -type d -exec chmod 755 {} + 2>/dev/null || true
  find "$base" -type f -exec chmod 644 {} + 2>/dev/null || true
  if command -v depmod >/dev/null 2>&1; then
    depmod -a 4.4.189 2>/dev/null || true
  fi
}
fix_modules_perms

# systemd：按你旧逻辑启用 adckeys
if have_systemctl; then
  systemctl daemon-reload 2>/dev/null || true
  systemctl enable adckeys.service 2>/dev/null || true
  systemctl restart adckeys.service 2>/dev/null || true
fi

sync
echo "[OTA] SUCCESS"
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

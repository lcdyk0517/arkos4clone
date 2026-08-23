#!/usr/bin/env bash
set -euo pipefail

# ============================================
# ArkOS4Clone OTA 升级包制作脚本
#
# 用法：
#   sudo ./build_update_tar.sh           # 构建 ArkOS 版本
#   sudo ./build_update_tar.sh -d        # 构建 dArkOS 版本
#   sudo ./build_update_tar.sh darkos    # 构建 dArkOS 版本
#
# 输出文件：
#   ./update.tar   （放到设备 /roms/update.tar）
# ============================================

# 解析命令行参数
ARKOS_IMAGE_NAME=""
for arg in "$@"; do
  case "${arg,,}" in  # 转小写比较
    -d|darkos|darkos4clone|darkos4clone)
      ARKOS_IMAGE_NAME="dArkOS"
      ;;
  esac
done

# 生成版本信息
UPDATE_DATE="$(TZ=Asia/Shanghai date +%m%d%Y)"
MODDER="kk&lcdyk"

# 工作目录与临时构建目录
WORKDIR="$(pwd)"
STAGE="/tmp/_ota_stage"
PAYLOAD_BOOT="${STAGE}/payload/boot"
PAYLOAD_ROOT="${STAGE}/payload/root"

# boot 分区（FAT32）专用 rsync 参数
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

if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
  # ============================================================
  # dArkOS 专用逻辑 (UID=1000)
  # ============================================================
  echo "=== 检测到 dArkOS 镜像，构建 dArkOS OTA 包 ==="
  VERSION="dArkOS4Clone-${UPDATE_DATE}-${MODDER}"
  CHOWN_USER="1000:1000"
  OUT_TAR="${WORKDIR}/update-darkos.tar"

  echo "== 构建 payload/boot =="
  mkdir -p "$PAYLOAD_BOOT/consoles"
  rsync $RSYNC_BOOT_OPTS --exclude='files' ./consoles/ "$PAYLOAD_BOOT/consoles/"
  # dArkOS 使用 logo-darkos
  if [[ -d "$PAYLOAD_BOOT/consoles/logo-darkos" ]]; then
    rm -rf "$PAYLOAD_BOOT/consoles/logo"
    mv "$PAYLOAD_BOOT/consoles/logo-darkos" "$PAYLOAD_BOOT/consoles/logo"
  fi
  cp -f ./sh/clone.sh "$PAYLOAD_BOOT/firstboot.sh"
  cp -f ./sh/darkos-expandtoexfat.sh "$PAYLOAD_BOOT/expandtoexfat.sh"
  cp -f ./dtb_selector_macos ./dtb_selector_win32.exe ./dtb_selector_linux32 "$PAYLOAD_BOOT/" 2>/dev/null || true
  touch "$PAYLOAD_BOOT/USE_DTB_SELECT_TO_SELECT_DEVICE" 2>/dev/null || true

  echo "== 构建 payload/root =="
  echo "== 注入设备怪癖 =="
  mkdir -p "$PAYLOAD_ROOT/home/ark/.quirks"
  cp -r ./consoles/files/* "$PAYLOAD_ROOT/home/ark/.quirks/" 2>/dev/null || true

  echo "== 注入 Clone 配置与工具 =="
  mkdir -p "$PAYLOAD_ROOT/usr/bin" "$PAYLOAD_ROOT/usr/local/bin"
  cp -f ./bin/mcu_led ./bin/ws2812 "$PAYLOAD_ROOT/usr/bin/" 2>/dev/null || true
  cp -f ./bin/sdljoymap ./bin/sdljoytest "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./bin/console_detect "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 添加 dArkOS 固件 =="
  if [[ -d "./replace_file/firmware" ]]; then
    mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware"
    cp -rf ./replace_file/firmware/. "$PAYLOAD_ROOT/usr/lib/firmware/" 2>/dev/null || true
  fi

  echo "== 注入 rk915 固件 =="
  mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware/"
  cp -f ./bin/rk915/* "$PAYLOAD_ROOT/usr/lib/firmware/" 2>/dev/null || true

  echo "== 注入 swt6621s 固件 =="
  mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware/"
  cp -f ./bin/swt6621s/* "$PAYLOAD_ROOT/usr/lib/firmware/" 2>/dev/null || true

  echo "== 注入 aic8800DC 固件 =="
  mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware/aic8800DC"
  cp -f ./bin/aic8800DC/* "$PAYLOAD_ROOT/usr/lib/firmware/aic8800DC/" 2>/dev/null || true

  echo "== 注入 351Files 资源 =="
  mkdir -p "$PAYLOAD_ROOT/opt/351Files/res"
  cp -r ./res/* "$PAYLOAD_ROOT/opt/351Files/res/" 2>/dev/null || true
  cp -r ./replace_file/351Files "$PAYLOAD_ROOT/opt/351Files/" 2>/dev/null || true

  echo "== 注入 dArkOS 启动脚本 =="
  mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
  cp -f ./replace_file/darkos4atomiswave.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/darkos4dreamcast.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/darkos4naomi.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/darkos4saturn.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/darkos4n64.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/darkos4pico8.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/darkos4get_last_played.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/drastic.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/drastic_kk.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/choose_drastic_ver.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/choose_ons_ver.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/onscripter.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/freej2me.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/mediaplayer.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入 es-service 服务 =="
  mkdir -p "$PAYLOAD_ROOT/etc/systemd/system"
  cp -f ./bin/es-service/es-status-daemon.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./bin/es-service/es-status-daemon.service "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true

  echo "== 注入 zram 服务 =="
  mkdir -p "$PAYLOAD_ROOT/etc/systemd/system"
  cp -f ./bin/zram-service/zram-setup.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./bin/zram-service/zram.conf "$PAYLOAD_ROOT/etc/" 2>/dev/null || true
  cp -f ./bin/zram-service/zram-swap.service "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true

  echo "== 注入 batteryplus 服务 =="
  mkdir -p "$PAYLOAD_ROOT/etc/systemd/system"
  mkdir -p "$PAYLOAD_ROOT/etc/batteryplus/"
  cp -f ./bin/batteryplus-service/batteryplus "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./bin/batteryplus-service/batteryplus.conf "$PAYLOAD_ROOT/etc/batteryplus/" 2>/dev/null || true
  cp -f ./bin/batteryplus-service/batteryplus.service "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true

  echo "== 添加 Gamma =="
  mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
  cp -f ./replace_file/gamma/gamma "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入核心与 EmulationStation 文件 =="
  mkdir -p "$PAYLOAD_ROOT/home/ark/.config/retroarch/cores" \
           "$PAYLOAD_ROOT/home/ark/.config/retroarch32/cores" \
           "$PAYLOAD_ROOT/etc/emulationstation" \
           "$PAYLOAD_ROOT/usr/bin/emulationstation/resources/"
  cp -f ./mod_so/64/* "$PAYLOAD_ROOT/home/ark/.config/retroarch/cores/" 2>/dev/null || true
  cp -f ./mod_so/32/* "$PAYLOAD_ROOT/home/ark/.config/retroarch32/cores/" 2>/dev/null || true
  cp -f ./replace_file/darkos4es_systems.cfg "$PAYLOAD_ROOT/etc/emulationstation/" 2>/dev/null || true
  cp -f ./replace_file/darkos4es_systems.cfg.dual "$PAYLOAD_ROOT/etc/emulationstation/" 2>/dev/null || true
  cp -rf ./replace_file/resources/* "$PAYLOAD_ROOT/usr/bin/emulationstation/resources/" 2>/dev/null || true
  mkdir -p "$PAYLOAD_ROOT/usr/bin/emulationstation"
  cp -r ./replace_file/emulationstation "$PAYLOAD_ROOT/usr/bin/emulationstation/emulationstation" 2>/dev/null || true

  echo "== 注入 drastic =="
  mkdir -p "$PAYLOAD_ROOT/opt/drastic"
  cp -a ./replace_file/drastic/. "$PAYLOAD_ROOT/opt/drastic/" 2>/dev/null || true

  echo "== 注入 drastic-kk =="
  mkdir -p "$PAYLOAD_ROOT/opt/drastic-kk"
  cp -a ./replace_file/drastic-kk/. "$PAYLOAD_ROOT/opt/drastic-kk/" 2>/dev/null || true

  echo "== 添加 onscripter-sa =="
  mkdir -p "$PAYLOAD_ROOT/opt/onscripter"
  cp -a ./replace_file/onscripter/. "$PAYLOAD_ROOT/opt/onscripter/" 2>/dev/null || true

  echo "== 添加 freej2me-sa =="
  mkdir -p "$PAYLOAD_ROOT/opt/freej2mesa"
  cp -a ./replace_file/freej2mesa/. "$PAYLOAD_ROOT/opt/freej2mesa/" 2>/dev/null || true

  echo "== 改用自适应分辨率 Retroarch 1.22.2 =="
  mkdir -p "$PAYLOAD_ROOT/opt/retroarch/bin/"
  cp -a ./replace_file/retroarch/retroarch "$PAYLOAD_ROOT/opt/retroarch/bin/" 2>/dev/null || true
  cp -a ./replace_file/retroarch/retroarch32 "$PAYLOAD_ROOT/opt/retroarch/bin/" 2>/dev/null || true

  echo "== 注入 json-c3 库 =="
  mkdir -p "$PAYLOAD_ROOT/usr/lib/aarch64-linux-gnu/"
  cp -f ./bin/json-c3/* "$PAYLOAD_ROOT/usr/lib/aarch64-linux-gnu/" 2>/dev/null || true

  echo "== 更新和添加 flycastsa =="
  mkdir -p "$PAYLOAD_ROOT/opt/flycastsa"
  cp -a ./replace_file/flycastsa/. "$PAYLOAD_ROOT/opt/flycastsa/" 2>/dev/null || true

  echo "== 更新和添加 yabasanshiro-sa =="
  mkdir -p "$PAYLOAD_ROOT/opt/yabasanshiro"
  cp -a ./replace_file/yabasanshiro/. "$PAYLOAD_ROOT/opt/yabasanshiro/" 2>/dev/null || true

  echo "== 注入 retrorun =="
  mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
  cp -r ./replace_file/retrorun/retrorun32 "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r ./replace_file/retrorun/retrorun "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入 pymo =="
  cp -r ./replace_file/pymo/cpymo "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r ./replace_file/pymo/pymo.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入 ogage =="
  cp -r ./replace_file/ogage "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  mkdir -p "$PAYLOAD_ROOT/home/ark/.quirks"
  cp -r ./replace_file/ogage "$PAYLOAD_ROOT/home/ark/.quirks/" 2>/dev/null || true

  echo "== 注入 services / tools =="
  mkdir -p "$PAYLOAD_ROOT/etc/systemd/system" \
           "$PAYLOAD_ROOT/opt/system/Advanced" \
           "$PAYLOAD_ROOT/opt/system/Tools" \
           "$PAYLOAD_ROOT/usr/local/bin"
  cp -r ./replace_file/services/351mp.service "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true
  cp -r "./replace_file/tools/Enable Quick Mode.sh" "$PAYLOAD_ROOT/opt/system/Advanced/" 2>/dev/null || true
  cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$PAYLOAD_ROOT/opt/system/Advanced/" 2>/dev/null || true
  cp -r "./replace_file/tools/Enable Quick Mode.sh" "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r "./replace_file/tools/Disable Quick Mode.sh" "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r "./replace_file/tools/Switch to main SD for Roms.sh" "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r "./replace_file/tools/Ports Fix.sh" "$PAYLOAD_ROOT/opt/system/Tools/" 2>/dev/null || true

  echo "== 注入 modules =="
  if [[ -d "./replace_file/modules" ]]; then
    mkdir -p "$PAYLOAD_ROOT/usr/lib/modules"
    cp -a ./replace_file/modules/. "$PAYLOAD_ROOT/usr/lib/modules/" 2>/dev/null || true
  fi

  echo "== 注入 Jason3_Scripte 工具 =="
  cp -r "./Jason3_Scripte/wifi-toggle/Wifi-toggle.sh" "$PAYLOAD_ROOT/opt/system/Wifi-Toggle.sh" 2>/dev/null || true
  cp -r "./Jason3_Scripte/InfoSystem/InfoSystem.sh" "$PAYLOAD_ROOT/opt/system/Tools/System Info.sh" 2>/dev/null || true
  cp -r "./Jason3_Scripte/GhostLoader/GhostLoader.sh" "$PAYLOAD_ROOT/opt/system/Tools/Ghost Loader.sh" 2>/dev/null || true
  cp -r "./Jason3_Scripte/Bluetooth-Manager/Bluetooth Manager.sh" "$PAYLOAD_ROOT/opt/system/Tools/" 2>/dev/null || true
  cp -r "./Jason3_Scripte/Bluetooth-Manager/patch.pak" "$PAYLOAD_ROOT/opt/system/Tools/" 2>/dev/null || true

  echo "== 跳过 roms.tar（设计如此） =="

  # ---- META：dArkOS 权限 1000:1000 ----
  echo "== 写入 VERSION / META / install.sh =="
  cat > "$STAGE/VERSION" <<EOF
$VERSION
EOF

  meta_init
  meta_add "0777" "1000:1000" "/home/ark/.quirks/*"
  meta_add "0777" "1000:1000" "/usr/bin/mcu_led"
  meta_add "0777" "1000:1000" "/usr/bin/ws2812"
  meta_add "0777" "1000:1000" "/usr/local/bin/sdljoytest"
  meta_add "0777" "1000:1000" "/usr/local/bin/sdljoymap"
  meta_add "0777" "1000:1000" "/usr/local/bin/console_detect"
  meta_add "0777" "1000:1000" "/usr/lib/firmware/rk915_*.bin"
  meta_add "0777" "1000:1000" "/usr/lib/firmware/SWT6621S_*.bin"
  meta_add "0777" "1000:1000" "/usr/lib/firmware/aic8800DC"
  meta_add "0777" "1000:1000" "/usr/lib/firmware/aic8800DC/*"
  meta_add "0777" "1000:1000" "/opt/351Files"
  meta_add "0777" "1000:1000" "/opt/351Files/*"
  for f in darkos4atomiswave.sh darkos4dreamcast.sh darkos4naomi.sh darkos4saturn.sh darkos4n64.sh darkos4pico8.sh darkos4get_last_played.sh drastic.sh drastic_kk.sh choose_drastic_ver.sh mediaplayer.sh onscripter.sh freej2me.sh choose_ons_ver.sh gamma; do
    meta_add "0777" "1000:1000" "/usr/local/bin/$f"
  done
  meta_add "0777" "1000:1000" "/usr/local/bin/es-status-daemon.sh"
  meta_add "0777" "1000:1000" "/etc/systemd/system/es-status-daemon.service"
  meta_add "0777" "1000:1000" "/etc/zram.conf"
  meta_add "0777" "1000:1000" "/usr/local/bin/zram-setup.sh"
  meta_add "0777" "1000:1000" "/etc/systemd/system/zram-swap.service"
  meta_add "0777" "1000:1000" "/etc/batteryplus/batteryplus.conf"
  meta_add "0777" "1000:1000" "/usr/local/bin/batteryplus"
  meta_add "0777" "1000:1000" "/etc/systemd/system/batteryplus.service"
  meta_add "0777" "1000:1000" "/home/ark/.config/retroarch/cores/*"
  meta_add "0777" "1000:1000" "/home/ark/.config/retroarch32/cores/*"
  meta_add "0777" "1000:1000" "/etc/emulationstation/darkos4es_systems.cfg"
  meta_add "0777" "1000:1000" "/etc/emulationstation/darkos4es_systems.cfg.dual"
  meta_add "0777" "1000:1000" "/opt/drastic"
  meta_add "0777" "1000:1000" "/opt/drastic/*"
  meta_add "0777" "1000:1000" "/opt/drastic-kk"
  meta_add "0777" "1000:1000" "/opt/drastic-kk/*"
  meta_add "0777" "1000:1000" "/opt/onscripter"
  meta_add "0777" "1000:1000" "/opt/onscripter/*"
  meta_add "0777" "1000:1000" "/opt/freej2mesa"
  meta_add "0777" "1000:1000" "/opt/freej2mesa/*"
  meta_add "0777" "1000:1000" "/opt/retroarch/bin/"
  meta_add "0777" "1000:1000" "/opt/retroarch/bin/*"
  meta_add "0777" "1000:1000" "/opt/flycastsa"
  meta_add "0777" "1000:1000" "/opt/flycastsa/*"
  meta_add "0777" "1000:1000" "/opt/yabasanshiro"
  meta_add "0777" "1000:1000" "/opt/yabasanshiro/*"
  meta_add "0777" "1000:1000" "/usr/lib/aarch64-linux-gnu/libjson-c.so*"
  meta_add "0777" "1000:1000" "/usr/local/bin/cpymo"
  meta_add "0777" "1000:1000" "/usr/local/bin/pymo.sh"
  meta_add "0777" "1000:1000" "/opt/system/Wifi-Toggle.sh"
  meta_add "0777" "1000:1000" "/opt/system/Tools/*.sh"
  meta_add "0777" "1000:1000" "/opt/system/Tools/patch.pak"
  meta_add "0777" "1000:1000" "/opt/system/*.sh"
  meta_add "0777" "1000:1000" "/opt/system/Advanced/*.sh"
  meta_add "0777" "1000:1000" "/usr/bin/emulationstation/resources"
  meta_add "0777" "1000:1000" "/usr/bin/emulationstation/resources/*"
  meta_add "0777" "1000:1000" "/usr/bin/emulationstation/emulationstation"
  meta_add "0777" "1000:1000" "/usr/bin/emulationstation/emulationstation/*"
  meta_add "0777" "1000:1000" "/usr/local/bin/retrorun32"
  meta_add "0777" "1000:1000" "/usr/local/bin/retrorun"
  meta_add "0777" "1000:1000" "/usr/local/bin/ogage"
  meta_add "0777" "1000:1000" "/home/ark/.quirks/ogage"
  meta_add "0777" "1000:1000" "/etc/systemd/system/351mp.service"
  meta_add "0777" "1000:1000" "/usr/local/bin/Enable Quick Mode.sh"
  meta_add "0777" "1000:1000" "/usr/local/bin/Disable Quick Mode.sh"
  meta_add "0777" "1000:1000" "/usr/local/bin/Switch to main SD for Roms.sh"
  meta_add "0777" "1000:1000" "/usr/local/bin/Switch to SD2 for Roms.sh"
  meta_add "0777" "1000:1000" "/usr/lib/modules"
  meta_finalize_dedupe

else
  # ============================================================
  # ArkOS 专用逻辑 (UID=1002)
  # ============================================================
  echo "=== 检测到 ArkOS 镜像，构建 ArkOS OTA 包 ==="
  VERSION="ArkOS4Clone-${UPDATE_DATE}-${MODDER}"
  CHOWN_USER="1002:1002"
  OUT_TAR="${WORKDIR}/update-arkos.tar"

  echo "== 构建 payload/boot =="
  mkdir -p "$PAYLOAD_BOOT/consoles"
  rsync $RSYNC_BOOT_OPTS --exclude='files' ./consoles/ "$PAYLOAD_BOOT/consoles/"
  # ArkOS 删除 logo-darkos
  rm -rf "$PAYLOAD_BOOT/consoles/logo-darkos" 2>/dev/null || true
  cp -f ./sh/clone.sh "$PAYLOAD_BOOT/firstboot.sh"
  cp -f ./sh/expandtoexfat.sh "$PAYLOAD_BOOT/expandtoexfat.sh"
  cp -f ./dtb_selector_macos ./dtb_selector_win32.exe ./dtb_selector_linux32 "$PAYLOAD_BOOT/" 2>/dev/null || true
  touch "$PAYLOAD_BOOT/USE_DTB_SELECT_TO_SELECT_DEVICE" 2>/dev/null || true

  echo "== 构建 payload/root =="
  echo "== 注入设备怪癖 =="
  mkdir -p "$PAYLOAD_ROOT/home/ark/.quirks"
  cp -r ./consoles/files/* "$PAYLOAD_ROOT/home/ark/.quirks/" 2>/dev/null || true

  echo "== 注入 Clone 配置与工具 =="
  mkdir -p "$PAYLOAD_ROOT/usr/bin" "$PAYLOAD_ROOT/usr/local/bin"
  cp -f ./bin/mcu_led ./bin/ws2812 "$PAYLOAD_ROOT/usr/bin/" 2>/dev/null || true
  cp -f ./bin/sdljoymap ./bin/sdljoytest "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./bin/console_detect "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入 rk915 固件 =="
  mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware/"
  cp -f ./bin/rk915/* "$PAYLOAD_ROOT/usr/lib/firmware/" 2>/dev/null || true

  echo "== 注入 swt6621s 固件 =="
  mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware/"
  cp -f ./bin/swt6621s/* "$PAYLOAD_ROOT/usr/lib/firmware/" 2>/dev/null || true

  echo "== 注入 aic8800DC 固件 =="
  mkdir -p "$PAYLOAD_ROOT/usr/lib/firmware/aic8800DC"
  cp -f ./bin/aic8800DC/* "$PAYLOAD_ROOT/usr/lib/firmware/aic8800DC/" 2>/dev/null || true

  echo "== 注入 351Files 资源 =="
  mkdir -p "$PAYLOAD_ROOT/opt/351Files/res"
  cp -r ./res/* "$PAYLOAD_ROOT/opt/351Files/res/" 2>/dev/null || true
  cp -r ./replace_file/351Files "$PAYLOAD_ROOT/opt/351Files/" 2>/dev/null || true

  echo "== 注入 ArkOS 启动脚本 =="
  mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
  cp -f ./replace_file/atomiswave.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/dreamcast.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/naomi.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/saturn.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/n64.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/easyrpg.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/mvem.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/gametank.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/gametankkeydemon.py "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/flash.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/pico8.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/drastic.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/drastic_kk.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/choose_drastic_ver.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/choose_ons_ver.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/onscripter.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/freej2me.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/mediaplayer.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./replace_file/get_last_played.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入 es-service 服务 =="
  mkdir -p "$PAYLOAD_ROOT/etc/systemd/system"
  cp -f ./bin/es-service/es-status-daemon.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./bin/es-service/es-status-daemon.service "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true

  echo "== 注入 zram 服务 =="
  mkdir -p "$PAYLOAD_ROOT/etc/systemd/system"
  cp -f ./bin/zram-service/zram-setup.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./bin/zram-service/zram.conf "$PAYLOAD_ROOT/etc/" 2>/dev/null || true
  cp -f ./bin/zram-service/zram-swap.service "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true

  echo "== 注入 batteryplus 服务 =="
  mkdir -p "$PAYLOAD_ROOT/etc/systemd/system"
  mkdir -p "$PAYLOAD_ROOT/etc/batteryplus/"
  cp -f ./bin/batteryplus-service/batteryplus "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -f ./bin/batteryplus-service/batteryplus.conf "$PAYLOAD_ROOT/etc/batteryplus/" 2>/dev/null || true
  cp -f ./bin/batteryplus-service/batteryplus.service "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true

  echo "== 添加 Gamma =="
  mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
  cp -f ./replace_file/gamma/gamma "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入核心与 EmulationStation 文件 =="
  mkdir -p "$PAYLOAD_ROOT/home/ark/.config/retroarch/cores" \
           "$PAYLOAD_ROOT/home/ark/.config/retroarch32/cores" \
           "$PAYLOAD_ROOT/etc/emulationstation" \
           "$PAYLOAD_ROOT/usr/bin/emulationstation/resources/"
  cp -f ./mod_so/64/* "$PAYLOAD_ROOT/home/ark/.config/retroarch/cores/" 2>/dev/null || true
  cp -f ./mod_so/arkos_64/* "$PAYLOAD_ROOT/home/ark/.config/retroarch/cores/" 2>/dev/null || true
  cp -f ./mod_so/32/* "$PAYLOAD_ROOT/home/ark/.config/retroarch32/cores/" 2>/dev/null || true
  cp -f ./mod_so/arkos_32/* "$PAYLOAD_ROOT/home/ark/.config/retroarch32/cores/" 2>/dev/null || true
  cp -f ./replace_file/es_systems.cfg "$PAYLOAD_ROOT/etc/emulationstation/" 2>/dev/null || true
  cp -f ./replace_file/es_systems.cfg.dual "$PAYLOAD_ROOT/etc/emulationstation/" 2>/dev/null || true
  cp -rf ./replace_file/resources/* "$PAYLOAD_ROOT/usr/bin/emulationstation/resources/" 2>/dev/null || true
  mkdir -p "$PAYLOAD_ROOT/usr/bin/emulationstation"
  cp -r ./replace_file/emulationstation "$PAYLOAD_ROOT/usr/bin/emulationstation/emulationstation" 2>/dev/null || true

  echo "== 注入 drastic =="
  mkdir -p "$PAYLOAD_ROOT/opt/drastic"
  cp -a ./replace_file/drastic/. "$PAYLOAD_ROOT/opt/drastic/" 2>/dev/null || true

  echo "== 注入 drastic-kk =="
  mkdir -p "$PAYLOAD_ROOT/opt/drastic-kk"
  cp -a ./replace_file/drastic-kk/. "$PAYLOAD_ROOT/opt/drastic-kk/" 2>/dev/null || true

  echo "== 添加 onscripter-sa =="
  mkdir -p "$PAYLOAD_ROOT/opt/onscripter"
  cp -a ./replace_file/onscripter/. "$PAYLOAD_ROOT/opt/onscripter/" 2>/dev/null || true

  echo "== 添加 freej2me-sa =="
  mkdir -p "$PAYLOAD_ROOT/opt/freej2mesa"
  cp -a ./replace_file/freej2mesa/. "$PAYLOAD_ROOT/opt/freej2mesa/" 2>/dev/null || true

  echo "== 改用自适应分辨率 Retroarch 1.22.2 =="
  mkdir -p "$PAYLOAD_ROOT/opt/retroarch/bin/"
  cp -a ./replace_file/retroarch/retroarch "$PAYLOAD_ROOT/opt/retroarch/bin/" 2>/dev/null || true
  cp -a ./replace_file/retroarch/retroarch32 "$PAYLOAD_ROOT/opt/retroarch/bin/" 2>/dev/null || true

  echo "== 注入 json-c3 库 =="
  mkdir -p "$PAYLOAD_ROOT/usr/lib/aarch64-linux-gnu/"
  cp -f ./bin/json-c3/* "$PAYLOAD_ROOT/usr/lib/aarch64-linux-gnu/" 2>/dev/null || true

  echo "== 更新 Fake08-sa =="
  mkdir -p "$PAYLOAD_ROOT/opt/fake08"
  cp -a ./replace_file/fake08/. "$PAYLOAD_ROOT/opt/fake08/" 2>/dev/null || true

  echo "== 更新 PPSSPP 1.20.4 =="
  mkdir -p "$PAYLOAD_ROOT/opt/ppsspp"
  cp -a ./replace_file/ppsspp/. "$PAYLOAD_ROOT/opt/ppsspp/" 2>/dev/null || true

  echo "== 替换 PPSSPP-2021 =="
  mkdir -p "$PAYLOAD_ROOT/opt/ppsspp-2021"
  cp -a ./replace_file/ppsspp-2021/. "$PAYLOAD_ROOT/opt/ppsspp-2021/" 2>/dev/null || true

  echo "== 更新 mupen64plus =="
  mkdir -p "$PAYLOAD_ROOT/opt/mupen64plus"
  cp -a ./replace_file/mupen64plus/. "$PAYLOAD_ROOT/opt/mupen64plus/" 2>/dev/null || true

  echo "== 更新 ScummVM v2026.3.0 =="
  mkdir -p "$PAYLOAD_ROOT/opt/scummvm"
  cp -a ./replace_file/scummvm/. "$PAYLOAD_ROOT/opt/scummvm/" 2>/dev/null || true

  echo "== 更新和添加 flycastsa =="
  mkdir -p "$PAYLOAD_ROOT/opt/flycastsa"
  cp -a ./replace_file/flycastsa/. "$PAYLOAD_ROOT/opt/flycastsa/" 2>/dev/null || true

  echo "== 更新 duckstation =="
  mkdir -p "$PAYLOAD_ROOT/opt/duckstation"
  cp -a ./replace_file/duckstation/. "$PAYLOAD_ROOT/opt/duckstation/" 2>/dev/null || true

  echo "== 添加 rufflesa =="
  mkdir -p "$PAYLOAD_ROOT/opt/rufflesa"
  cp -a ./replace_file/rufflesa/. "$PAYLOAD_ROOT/opt/rufflesa/" 2>/dev/null || true

  echo "== 添加 gametank-sa =="
  mkdir -p "$PAYLOAD_ROOT/opt/gametank"
  cp -a ./replace_file/gametank/. "$PAYLOAD_ROOT/opt/gametank/" 2>/dev/null || true

  echo "== 注入 retrorun =="
  mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
  cp -r ./replace_file/retrorun/. "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入 pymo =="
  cp -r ./replace_file/pymo/cpymo "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r ./replace_file/pymo/pymo.sh "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入 ogage =="
  cp -r ./replace_file/ogage "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  mkdir -p "$PAYLOAD_ROOT/home/ark/.quirks"
  cp -r ./replace_file/ogage "$PAYLOAD_ROOT/home/ark/.quirks/" 2>/dev/null || true

  echo "== 更新和添加 yabasanshiro-sa =="
  mkdir -p "$PAYLOAD_ROOT/opt/yabasanshiro"
  cp -a ./replace_file/yabasanshiro/. "$PAYLOAD_ROOT/opt/yabasanshiro/" 2>/dev/null || true

  echo "== 添加 krkr2 =="
  mkdir -p "$PAYLOAD_ROOT/opt/krkr2"
  cp -a ./replace_file/krkr2/. "$PAYLOAD_ROOT/opt/krkr2/" 2>/dev/null || true

  echo "== 添加 OpenborFF =="
  mkdir -p "$PAYLOAD_ROOT/opt/OpenBorFF"
  cp -a ./replace_file/OpenBorFF/. "$PAYLOAD_ROOT/opt/OpenBorFF/" 2>/dev/null || true
  cp -a ./replace_file/OpenBor/. "$PAYLOAD_ROOT/opt/OpenBor/" 2>/dev/null || true

  echo "== 注入 services / tools =="
  mkdir -p "$PAYLOAD_ROOT/etc/systemd/system" \
           "$PAYLOAD_ROOT/opt/system/Advanced" \
           "$PAYLOAD_ROOT/opt/system/Tools" \
           "$PAYLOAD_ROOT/usr/local/bin"
  cp -r ./replace_file/services/351mp.service "$PAYLOAD_ROOT/etc/systemd/system/" 2>/dev/null || true
  cp -r "./replace_file/tools/Enable Quick Mode.sh" "$PAYLOAD_ROOT/opt/system/Advanced/" 2>/dev/null || true
  cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$PAYLOAD_ROOT/opt/system/Advanced/" 2>/dev/null || true
  cp -r "./replace_file/tools/Enable Quick Mode.sh" "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r "./replace_file/tools/Disable Quick Mode.sh" "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r "./replace_file/tools/Switch to main SD for Roms.sh" "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true
  cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$PAYLOAD_ROOT/usr/local/bin/" 2>/dev/null || true

  echo "== 注入 modules =="
  if [[ -d "./replace_file/modules" ]]; then
    mkdir -p "$PAYLOAD_ROOT/usr/lib/modules"
    cp -a ./replace_file/modules/. "$PAYLOAD_ROOT/usr/lib/modules/" 2>/dev/null || true
  fi

  echo "== 注入 Jason3_Scripte 工具 =="
  cp -r "./Jason3_Scripte/wifi-toggle/Wifi-toggle.sh" "$PAYLOAD_ROOT/opt/system/Wifi-Toggle.sh" 2>/dev/null || true
  cp -r "./Jason3_Scripte/InfoSystem/InfoSystem.sh" "$PAYLOAD_ROOT/opt/system/Tools/System Info.sh" 2>/dev/null || true
  cp -r "./Jason3_Scripte/GhostLoader/GhostLoader.sh" "$PAYLOAD_ROOT/opt/system/Tools/Ghost Loader.sh" 2>/dev/null || true
  cp -r "./Jason3_Scripte/Bluetooth-Manager/Bluetooth Manager.sh" "$PAYLOAD_ROOT/opt/system/Tools/" 2>/dev/null || true
  cp -r "./Jason3_Scripte/Bluetooth-Manager/patch.pak" "$PAYLOAD_ROOT/opt/system/Tools/" 2>/dev/null || true

  echo "== 跳过 roms.tar（设计如此） =="

  # ---- META：ArkOS 权限 1002:1002 ----
  echo "== 写入 VERSION / META / install.sh =="
  cat > "$STAGE/VERSION" <<EOF
$VERSION
EOF

  meta_init
  meta_add "0777" "1002:1002" "/home/ark/.quirks/*"
  meta_add "0777" "1002:1002" "/usr/bin/mcu_led"
  meta_add "0777" "1002:1002" "/usr/bin/ws2812"
  meta_add "0777" "1002:1002" "/usr/local/bin/sdljoytest"
  meta_add "0777" "1002:1002" "/usr/local/bin/sdljoymap"
  meta_add "0777" "1002:1002" "/usr/local/bin/console_detect"
  meta_add "0777" "1002:1002" "/usr/lib/firmware/rk915_*.bin"
  meta_add "0777" "1002:1002" "/usr/lib/firmware/SWT6621S_*.bin"
  meta_add "0777" "1002:1002" "/usr/lib/firmware/aic8800DC"
  meta_add "0777" "1002:1002" "/usr/lib/firmware/aic8800DC/*"
  meta_add "0777" "1002:1002" "/opt/351Files"
  meta_add "0777" "1002:1002" "/opt/351Files/*"
  for f in atomiswave.sh dreamcast.sh naomi.sh saturn.sh n64.sh mvem.sh easyrpg.sh gametank.sh flash.sh gametankkeydemon.py pico8.sh drastic.sh drastic_kk.sh choose_drastic_ver.sh mediaplayer.sh get_last_played.sh choose_ons_ver.sh onscripter.sh freej2me.sh gamma; do
    meta_add "0777" "1002:1002" "/usr/local/bin/$f"
  done
  meta_add "0777" "1002:1002" "/usr/local/bin/es-status-daemon.sh"
  meta_add "0777" "1002:1002" "/etc/systemd/system/es-status-daemon.service"
  meta_add "0777" "1002:1002" "/etc/zram.conf"
  meta_add "0777" "1002:1002" "/usr/local/bin/zram-setup.sh"
  meta_add "0777" "1002:1002" "/etc/systemd/system/zram-swap.service"
  meta_add "0777" "1002:1002" "/etc/batteryplus/batteryplus.conf"
  meta_add "0777" "1002:1002" "/usr/local/bin/batteryplus"
  meta_add "0777" "1002:1002" "/etc/systemd/system/batteryplus.service"
  meta_add "0777" "1002:1002" "/home/ark/.config/retroarch/cores/*"
  meta_add "0777" "1002:1002" "/home/ark/.config/retroarch32/cores/*"
  meta_add "0777" "1002:1002" "/etc/emulationstation/es_systems.cfg"
  meta_add "0777" "1002:1002" "/etc/emulationstation/es_systems.cfg.dual"
  meta_add "0777" "1002:1002" "/opt/drastic"
  meta_add "0777" "1002:1002" "/opt/drastic/*"
  meta_add "0777" "1002:1002" "/opt/drastic-kk"
  meta_add "0777" "1002:1002" "/opt/drastic-kk/*"
  meta_add "0777" "1002:1002" "/opt/onscripter"
  meta_add "0777" "1002:1002" "/opt/onscripter/*"
  meta_add "0777" "1002:1002" "/opt/freej2mesa"
  meta_add "0777" "1002:1002" "/opt/freej2mesa/*"
  meta_add "0777" "1002:1002" "/opt/retroarch/bin/"
  meta_add "0777" "1002:1002" "/opt/retroarch/bin/*"
  meta_add "0777" "1002:1002" "/opt/fake08"
  meta_add "0777" "1002:1002" "/opt/fake08/*"
  meta_add "0777" "1002:1002" "/opt/ppsspp"
  meta_add "0777" "1002:1002" "/opt/ppsspp/*"
  meta_add "0777" "1002:1002" "/opt/ppsspp-2021"
  meta_add "0777" "1002:1002" "/opt/ppsspp-2021/*"
  meta_add "0777" "1002:1002" "/opt/mupen64plus"
  meta_add "0777" "1002:1002" "/opt/mupen64plus/*"
  meta_add "0777" "1002:1002" "/opt/scummvm"
  meta_add "0777" "1002:1002" "/opt/scummvm/*"
  meta_add "0777" "1002:1002" "/opt/flycastsa"
  meta_add "0777" "1002:1002" "/opt/flycastsa/*"
  meta_add "0777" "1002:1002" "/opt/duckstation"
  meta_add "0777" "1002:1002" "/opt/duckstation/*"
  meta_add "0777" "1002:1002" "/opt/yabasanshiro"
  meta_add "0777" "1002:1002" "/opt/yabasanshiro/*"
  meta_add "0777" "1002:1002" "/opt/krkr2"
  meta_add "0777" "1002:1002" "/opt/krkr2/*"
  meta_add "0777" "1002:1002" "/opt/OpenBorFF"
  meta_add "0777" "1002:1002" "/opt/OpenBorFF/*"
  meta_add "0777" "1002:1002" "/opt/OpenBor"
  meta_add "0777" "1002:1002" "/opt/OpenBor/*"
  meta_add "0777" "1002:1002" "/usr/lib/aarch64-linux-gnu/libjson-c.so*"
  meta_add "0777" "1002:1002" "/usr/local/bin/cpymo"
  meta_add "0777" "1002:1002" "/usr/local/bin/pymo.sh"
  meta_add "0777" "1002:1002" "/opt/system/Wifi-Toggle.sh"
  meta_add "0777" "1002:1002" "/opt/system/Tools/*.sh"
  meta_add "0777" "1002:1002" "/opt/system/Tools/patch.pak"
  meta_add "0777" "1002:1002" "/opt/system/*.sh"
  meta_add "0777" "1002:1002" "/opt/system/Advanced/*.sh"
  meta_add "0777" "1002:1002" "/usr/bin/emulationstation/resources"
  meta_add "0777" "1002:1002" "/usr/bin/emulationstation/resources/*"
  meta_add "0777" "1002:1002" "/usr/bin/emulationstation/emulationstation"
  meta_add "0777" "1002:1002" "/usr/bin/emulationstation/emulationstation/*"
  meta_add "0777" "1002:1002" "/usr/local/bin/retrorun32"
  meta_add "0777" "1002:1002" "/usr/local/bin/retrorun"
  meta_add "0777" "1002:1002" "/usr/local/bin/retrorunsdl32"
  meta_add "0777" "1002:1002" "/usr/local/bin/retrorunsdl"
  meta_add "0777" "1002:1002" "/usr/local/bin/ogage"
  meta_add "0777" "1002:1002" "/home/ark/.quirks/ogage"
  meta_add "0777" "1002:1002" "/etc/systemd/system/351mp.service"
  meta_add "0777" "1002:1002" "/lib/systemd/system/mpv.service"
  meta_add "0777" "1002:1002" "/usr/local/bin/Enable Quick Mode.sh"
  meta_add "0777" "1002:1002" "/usr/local/bin/Disable Quick Mode.sh"
  meta_add "0777" "1002:1002" "/usr/local/bin/Switch to main SD for Roms.sh"
  meta_add "0777" "1002:1002" "/usr/local/bin/Switch to SD2 for Roms.sh"
  meta_add "0777" "1002:1002" "/usr/lib/modules"
  meta_finalize_dedupe
fi

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
  local OTA_TMP="/home/ark/.ota"
  local dest="/"
  [[ "$target" == "boot" ]] && dest="$BOOT_MP"

  rm -rf "$OTA_TMP" 2>/dev/null || true
  mkdir -p "$OTA_TMP"

  tar -xO -f "$OTA_TAR_PATH" "$member" | tar -xf - -C "$OTA_TMP"

  rsync -rltD --omit-dir-times --no-owner --no-group --no-perms \
    "$OTA_TMP/" "$dest/"

  rm -rf "$OTA_TMP"
}

apply_legacy_rsync() {
  echo "[OTA] legacy mode: rsync payload"
  if [[ -d "$PAYLOAD/boot" ]]; then
    rsync -rltD --omit-dir-times --no-owner --no-group --no-perms \
      "$PAYLOAD/boot/" "$BOOT_MP/"
  fi
  if [[ -d "$PAYLOAD/root" ]]; then
    rsync -rltD --omit-dir-times --no-owner --no-group --no-perms \
      "$PAYLOAD/root/" "/"
  fi
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
  if [[ "$IS_DARKOS" == "true" ]]; then
    sed -i "/^title=/c\title=dArkOS4Clone (${UPDATE_DATE})(${MODDER})" "$PLYMOUTH_THEME" 2>/dev/null || true
    log "Plymouth updated: dArkOS4Clone (${UPDATE_DATE})(${MODDER})"
    # dArkOS: 重命名 darkos4* 脚本
    mv "/usr/local/bin/darkos4atomiswave.sh" "/usr/local/bin/atomiswave.sh" 2>/dev/null || true
    mv "/usr/local/bin/darkos4dreamcast.sh" "/usr/local/bin/dreamcast.sh" 2>/dev/null || true
    mv "/usr/local/bin/darkos4naomi.sh" "/usr/local/bin/naomi.sh" 2>/dev/null || true
    mv "/usr/local/bin/darkos4saturn.sh" "/usr/local/bin/saturn.sh" 2>/dev/null || true
    mv "/usr/local/bin/darkos4n64.sh" "/usr/local/bin/n64.sh" 2>/dev/null || true
    mv "/usr/local/bin/darkos4pico8.sh" "/usr/local/bin/pico8.sh" 2>/dev/null || true
    mv "/usr/local/bin/darkos4get_last_played.sh" "/usr/local/bin/get_last_played.sh" 2>/dev/null || true
    mv "/etc/emulationstation/darkos4es_systems.cfg" "/etc/emulationstation/es_systems.cfg" 2>/dev/null || true
    mv "/etc/emulationstation/darkos4es_systems.cfg.dual" "/etc/emulationstation/es_systems.cfg.dual" 2>/dev/null || true
  else
    sed -i "/^title=/c\title=ArkOS4Clone (${UPDATE_DATE})(${MODDER})" "$PLYMOUTH_THEME" 2>/dev/null || true
    log "Plymouth updated: ArkOS4Clone (${UPDATE_DATE})(${MODDER})"
    # ArkOS: 删除 darkos4* 脚本
    rm "/usr/local/bin/darkos4atomiswave.sh" 2>/dev/null || true
    rm "/usr/local/bin/darkos4dreamcast.sh" 2>/dev/null || true
    rm "/usr/local/bin/darkos4naomi.sh" 2>/dev/null || true
    rm "/usr/local/bin/darkos4saturn.sh" 2>/dev/null || true
    rm "/usr/local/bin/darkos4n64.sh" 2>/dev/null || true
    rm "/usr/local/bin/darkos4pico8.sh" 2>/dev/null || true
    rm "/usr/local/bin/darkos4get_last_played.sh" 2>/dev/null || true
    rm "/etc/emulationstation/darkos4es_systems.cfg" 2>/dev/null || true
    rm "/etc/emulationstation/darkos4es_systems.cfg.dual" 2>/dev/null || true
  fi
fi

log "=== Step 7: Cleanup old files ==="
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

tar --numeric-owner --owner=0 --group=0 -C "$PAYLOAD_BOOT" -cf "$CHUNK_DIR/00_boot.tar" .
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
